import Foundation
import Parsley
import Saga
import SagaPathKit

let sagaVersion: String = {
  guard
    let data = try? Data(contentsOf: URL(fileURLWithPath: "Package.resolved")),
    let resolved = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
    let pins = resolved["pins"] as? [[String: Any]],
    let saga = pins.first(where: { $0["identity"] as? String == "saga" }),
    let state = saga["state"] as? [String: Any],
    let version = state["version"] as? String
  else {
    return "local"
  }
  return version
}()

let docOrder = ["index", "Installation", "GettingStarted", "Architecture", "AdvancedUsage", "Migrate"]

/// Maps symbol names (e.g. "Writer") to the doc articles that mention them.
nonisolated(unsafe) var symbolMentions: [String: [(title: String, url: String)]] = [:]

func docSorting(_ a: Item<DocMetadata>, _ b: Item<DocMetadata>) -> Bool {
  let aIndex = docOrder.firstIndex(of: a.filenameWithoutExtension) ?? 999
  let bIndex = docOrder.firstIndex(of: b.filenameWithoutExtension) ?? 999
  if aIndex != bIndex {
    return aIndex < bIndex
  }
  return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
}

/// Bolds the first word in blockquotes that ends with a colon (e.g. "Note:", "Warning:").
func boldBlockquoteKeywords(_ html: String) -> String {
  html.replacingOccurrences(
    of: #"(<blockquote>\s*<p>)(\w+):\s*"#,
    with: #"$1<div class="font-bold text-zinc-200 capitalize">$2</div> "#,
    options: .regularExpression
  )
}

private struct CachedMention: Codable {
  let title: String
  let url: String
}

func rewriteMarkdownDocs(inputPath: Path) throws {
  let docsPath = inputPath + "docs"
  let markerPath = docsPath + ".rewritten.json"

  // If already rewritten in this dev session, load cached mentions and skip
  if markerPath.exists {
    let data: Data = try markerPath.read()
    let cached = try JSONDecoder().decode([String: [CachedMention]].self, from: data)
    for (symbol, mentions) in cached {
      symbolMentions[symbol] = mentions.map { (title: $0.title, url: $0.url) }
    }
    return
  }

  let docs = try docsPath.recursiveChildren().filter { $0.extension == "md" }

  // Build a mapping of filename (without extension) → (title, url)
  var docTitles: [String: String] = [:]
  var docUrls: [String: String] = [:]
  for doc in docs {
    let markdown: String = try doc.read()
    let filename = doc.lastComponentWithoutExtension
    let relativePath = doc.parent().string.replacingOccurrences(of: docsPath.string, with: "")
    let urlPath = "/docs\(relativePath)/\(filename.lowercased())/"
    docUrls[filename] = urlPath
    if let firstLine = markdown.split(separator: "\n", maxSplits: 1).first,
       firstLine.hasPrefix("# ")
    {
      let title = String(firstLine.dropFirst(2))
        .replacingOccurrences(of: "``", with: "")
        .trimmingCharacters(in: .whitespaces)
      docTitles[filename] = title
    }
  }

  for doc in docs {
    let markdown: String = try doc.read()
    let rewritten = rewriteMarkdown(markdown: markdown, docTitles: docTitles, docUrls: docUrls)
    try doc.write(rewritten)

    // Collect symbol mentions for "Mentioned in" on API pages
    let filename = doc.lastComponentWithoutExtension
    let title = docTitles[filename] ?? filename
    let url = docUrls[filename] ?? "/docs/\(filename.lowercased())/"
    let mentionedSymbols = extractSymbolMentions(markdown: markdown)
    for symbol in mentionedSymbols {
      symbolMentions[symbol, default: []].append((title: title, url: url))
    }
  }

  // Deduplicate mentions (a symbol may be referenced multiple times in one article)
  for (symbol, mentions) in symbolMentions {
    var seen = Set<String>()
    symbolMentions[symbol] = mentions.filter { seen.insert($0.url).inserted }
  }

  // Cache mentions so subsequent dev rebuilds can skip rewriting
  let cacheable = symbolMentions.mapValues { $0.map { CachedMention(title: $0.title, url: $0.url) } }
  let data = try JSONEncoder().encode(cacheable)
  try markerPath.write(data)
}

/// We get Markdown with DocC syntax, that normal markdown parsers don't understand,
/// so we rewrite the markdown to normal syntax.
func rewriteMarkdown(markdown: String, docTitles: [String: String], docUrls: [String: String]) -> String {
  var result = markdown

  // Rewrite ``Symbol`` or ``Parent/member`` → linked code span
  // ``Saga`` → [`Saga`](/api/saga/)
  // ``Saga/createPage(_:using:)`` → [`createPage(_:using:)`](/api/saga/#createpage(_:using:))
  // But not headings like # ``Saga``
  let backtickPattern = "(?<!# )``([^\\n`]+)``"
  let backtickRegex = try! NSRegularExpression(pattern: backtickPattern)
  for match in backtickRegex.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
    if let contentRange = Range(match.range(at: 1), in: result),
       let fullRange = Range(match.range, in: result)
    {
      let content = String(result[contentRange])
      let replacement: String
      if let slashIndex = content.firstIndex(of: "/") {
        let parent = String(content[content.startIndex ..< slashIndex])
        let member = String(content[content.index(after: slashIndex)...])
        replacement = "[`\(member)`](/api/\(parent.lowercased())/#\(member.lowercased()))"
      } else {
        replacement = "[`\(content)`](/api/\(content.lowercased())/)"
      }
      result.replaceSubrange(fullRange, with: replacement)
    }
  }

  // Rewrite <doc:Filename> → [Title](/docs/filename/)
  let docPattern = "<doc:(\\w+)>"
  let docRegex = try! NSRegularExpression(pattern: docPattern)
  for match in docRegex.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
    if let nameRange = Range(match.range(at: 1), in: result),
       let fullRange = Range(match.range, in: result)
    {
      let filename = String(result[nameRange])
      let title = docTitles[filename] ?? filename
      let url = docUrls[filename] ?? "/docs/\(filename.lowercased())/"
      result.replaceSubrange(fullRange, with: "[\(title)](\(url))")
    }
  }

  // Rewrite [text](doc:Filename) → [text](/docs/filename/)
  let docLinkPattern = "\\](\\(doc:(\\w+)\\))"
  let docLinkRegex = try! NSRegularExpression(pattern: docLinkPattern)
  for match in docLinkRegex.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
    if let outerRange = Range(match.range(at: 1), in: result),
       let nameRange = Range(match.range(at: 2), in: result)
    {
      let filename = String(result[nameRange])
      let url = docUrls[filename] ?? "/docs/\(filename.lowercased())/"
      result.replaceSubrange(outerRange, with: "(\(url))")
    }
  }

  // Rewrite - Parameters: / - Returns: into styled HTML definition lists
  let lines = result.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
  var output: [String] = []
  var i = 0
  while i < lines.count {
    let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

    if trimmed == "- Parameters:" {
      i += 1
      var params: [(String, String)] = []
      while i < lines.count {
        let paramLine = lines[i].trimmingCharacters(in: .whitespaces)
        if paramLine.hasPrefix("- Returns:") {
          break
        }
        if paramLine.hasPrefix("- "), let colonIndex = paramLine.dropFirst(2).firstIndex(of: ":") {
          let name = String(paramLine[paramLine.index(paramLine.startIndex, offsetBy: 2) ..< colonIndex])
          var desc = String(paramLine[paramLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
          i += 1
          // Collect continuation lines (indented, not a new parameter or Returns)
          while i < lines.count {
            let nextLine = lines[i]
            let nextTrimmed = nextLine.trimmingCharacters(in: .whitespaces)
            if nextTrimmed.isEmpty || nextTrimmed.hasPrefix("- ") {
              break
            }
            desc += "  \n" + nextTrimmed
            i += 1
          }
          params.append((name, desc))
        } else {
          break
        }
      }
      if !params.isEmpty {
        output.append("<h2>Parameters</h2>")
        output.append("<dl>")
        for (name, desc) in params {
          output.append("<dt class=\"font-semibold mt-4\"><code>\(name)</code></dt>")
          output.append("<dd class=\"pl-8\">\(inlineMarkdown(desc))</dd>")
        }
        output.append("</dl>")
      }
      continue
    }

    if trimmed.hasPrefix("- Returns:") {
      let desc = String(trimmed.dropFirst("- Returns:".count)).trimmingCharacters(in: .whitespaces)
      output.append("<h2>Return Value</h2>")
      output.append(inlineMarkdown(desc))
      i += 1
      continue
    }

    output.append(lines[i])
    i += 1
  }
  result = output.joined(separator: "\n")

  return result
}

/// Extracts symbol names referenced via ``Symbol`` or ``Parent/member`` in DocC markdown.
/// Returns a set of top-level symbol names (the parent for qualified references).
func extractSymbolMentions(markdown: String) -> Set<String> {
  var symbols = Set<String>()
  let pattern = "(?<!# )``([^\\n`]+)``"
  let regex = try! NSRegularExpression(pattern: pattern)
  for match in regex.matches(in: markdown, range: NSRange(markdown.startIndex..., in: markdown)) {
    if let range = Range(match.range(at: 1), in: markdown) {
      let content = String(markdown[range])
      if let slashIndex = content.firstIndex(of: "/") {
        symbols.insert(String(content[content.startIndex ..< slashIndex]))
      } else {
        symbols.insert(content)
      }
    }
  }
  return symbols
}

func inlineMarkdown(_ text: String) -> String {
  return (try? Parsley.html(text, options: [.unsafe], syntaxExtensions: [])) ?? text
}
