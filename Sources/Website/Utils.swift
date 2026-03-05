import Foundation
import Saga
import PathKit
import Parsley

let docOrder = ["index", "Installation", "GettingStarted", "Architecture", "AdvancedUsage"]

func docSorting(_ a: Item<DocMetadata>, _ b: Item<DocMetadata>) -> Bool {
  let aIndex = docOrder.firstIndex(of: a.filenameWithoutExtension) ?? 999
  let bIndex = docOrder.firstIndex(of: b.filenameWithoutExtension) ?? 999
  return aIndex < bIndex
}

/// Bolds the first word in blockquotes that ends with a colon (e.g. "Note:", "Warning:").
func boldBlockquoteKeywords(_ html: String) -> String {
  html.replacingOccurrences(
    of: #"(<blockquote>\s*<p>)(\w+):\s*"#,
    with: "$1<em>$2</em> ",
    options: .regularExpression
  )
}

func rewriteMarkdownDocs(saga: Saga) throws {
  let docs = try (saga.inputPath + "docs").children()
  
  // Build a mapping of filename (without extension) → title from the first heading
  var docTitles: [String: String] = [:]
  for doc in docs {
    let markdown: String = try doc.read()
    let filename = doc.lastComponentWithoutExtension
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
    let rewritten = rewriteMarkdown(markdown: markdown, docTitles: docTitles)
    try doc.write(rewritten)
  }
}

/// We get Markdown with DocC syntax, that normal markdown parsers don't understand,
/// so we rewrite the markdown to normal syntax.
func rewriteMarkdown(markdown: String, docTitles: [String: String]) -> String {
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
      result.replaceSubrange(fullRange, with: "[\(title)](/docs/\(filename.lowercased())/)")
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
      result.replaceSubrange(outerRange, with: "(/docs/\(filename.lowercased())/)")
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
          let desc = String(paramLine[paramLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
          params.append((name, desc))
          i += 1
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
      output.append("<p>\(inlineMarkdown(desc))</p>")
      i += 1
      continue
    }

    output.append(lines[i])
    i += 1
  }
  result = output.joined(separator: "\n")

  return result
}

func inlineMarkdown(_ text: String) -> String {
  return (try? Parsley.html(text, options: [.unsafe], syntaxExtensions: [])) ?? text
}
