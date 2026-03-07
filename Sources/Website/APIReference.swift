import Foundation
import HTML
import Moon
import Parsley
import PathKit
import Saga
import SymbolKit

// MARK: - Symbol kind

enum SymbolKind: String, Codable, CaseIterable {
  case `class`
  case `protocol`
  case `struct`
  case `var`
  case `func`
  case `typealias`
  case `enum`
  case `extension`
  case typeMethod = "type.method"
  case `init`
  case typeProperty = "type.property"
  case property
  case method
  case enumCase = "enum.case"
  case typeSubscript = "type.subscript"
  case `subscript`
  case `associatedtype`

  var displayName: String {
    switch self {
      case .class: "Class"
      case .protocol: "Protocol"
      case .struct: "Structure"
      case .var: "Variable"
      case .func: "Function"
      case .typealias: "Type Alias"
      case .enum: "Enumeration"
      case .extension: "Extension"
      case .typeMethod: "Type Method"
      case .`init`: "Initializer"
      case .typeProperty: "Type Property"
      case .property: "Instance Property"
      case .method: "Instance Method"
      case .enumCase: "Enumeration Case"
      case .typeSubscript: "Type Subscript"
      case .subscript: "Subscript"
      case .associatedtype: "Associated Type"
    }
  }

  var pluralDisplayName: String {
    switch self {
      case .class: "Classes"
      case .protocol: "Protocols"
      case .struct: "Structures"
      case .var: "Variables"
      case .func: "Functions"
      case .typealias: "Type Aliases"
      case .enum: "Enumerations"
      case .extension: "Extensions"
      case .typeMethod: "Type Methods"
      case .`init`: "Initializers"
      case .typeProperty: "Type Properties"
      case .property: "Instance Properties"
      case .method: "Instance Methods"
      case .enumCase: "Enumeration Cases"
      case .typeSubscript: "Type Subscripts"
      case .subscript: "Subscripts"
      case .associatedtype: "Associated Types"
    }
  }

  var isTopLevel: Bool {
    switch self {
      case .class, .protocol, .struct, .var, .func, .typealias, .enum, .extension:
        true
      default:
        false
    }
  }

  var order: Int {
    Self.allCases.firstIndex(of: self)!
  }
}

// MARK: - Metadata

struct Conformance: Codable {
  let name: String
  let url: String?
}

struct DocMention: Codable {
  let title: String
  let url: String
}

struct APIMetadata: Metadata {
  let kind: SymbolKind
  let declaration: String
  let isDeprecated: Bool
  let deprecationMessage: String?
  let members: [APIMember]
  let conformances: [Conformance]
  let conformingTypes: [Conformance]
  let mentionedIn: [DocMention]
}

struct APIMember: Codable {
  let name: String
  let kind: SymbolKind
  let declaration: String
  let docComment: String?
  let isDeprecated: Bool
  let deprecationMessage: String?
}

// MARK: - Symbol graph helpers

/// Groups memberOf relationships by parent symbol ID.
func groupMembersByParent(graph: SymbolGraph) -> [String: [String]] {
  var result: [String: [String]] = [:]
  for rel in graph.relationships where rel.kind == .memberOf {
    result[rel.target, default: []].append(rel.source)
  }
  return result
}

/// Collects conformances from a symbol graph, keyed by source symbol ID.
func collectConformances(graph: SymbolGraph) -> [String: [Conformance]] {
  let symbols = graph.symbols
  var result: [String: [Conformance]] = [:]
  for rel in graph.relationships where rel.kind == .conformsTo {
    if let targetSymbol = symbols[rel.target] {
      let slug = targetSymbol.names.title.lowercased()
      result[rel.source, default: []].append(
        Conformance(name: targetSymbol.names.title, url: "/api/\(slug)/")
      )
    } else if let fallback = rel.targetFallback, !fallback.hasSuffix("Metatype") {
      result[rel.source, default: []].append(
        Conformance(name: fallback, url: nil)
      )
    }
  }
  return result
}

/// Converts member symbol IDs to sorted APIMember arrays.
func resolveMembers(ids: [String], symbols: [String: SymbolGraph.Symbol]) -> [APIMember] {
  ids.compactMap { memberID -> APIMember? in
    guard let symbol = symbols[memberID] else { return nil }
    guard symbol.accessLevel.rawValue == "public" else { return nil }
    guard let kind = SymbolKind(rawValue: symbol.kind.identifier.identifier) else { return nil }

    let (isDeprecated, deprecationMessage) = checkDeprecation(symbol: symbol)

    return APIMember(
      name: symbol.names.title,
      kind: kind,
      declaration: renderDeclaration(symbol: symbol),
      docComment: renderDocComment(symbol: symbol),
      isDeprecated: isDeprecated,
      deprecationMessage: deprecationMessage
    )
  }.sorted { a, b in
    if a.kind != b.kind { return a.kind.order < b.kind.order }
    return a.name < b.name
  }
}

// MARK: - Symbol graph loading

func loadSymbolGraph(rootPath: PathKit.Path) throws -> [Item<APIMetadata>] {
  let path = rootPath + ".build" + "symbolgraph" + "Saga.symbols.json"

  guard path.exists else {
    print("Warning: Symbol graph not found at \(path). Run `just symbol-graph` to generate it first.")
    return []
  }

  let data = try Data(contentsOf: URL(fileURLWithPath: path.string))
  let graph = try JSONDecoder().decode(SymbolGraph.self, from: data)

  let symbols = graph.symbols
  let membersByParent = groupMembersByParent(graph: graph)
  let conformancesBySymbol = collectConformances(graph: graph)

  // Find top-level symbols (public, not members of other symbols)
  let memberTargets = Set(
    graph.relationships
      .filter { $0.kind == .memberOf }
      .map { $0.source }
  )

  // Collect conforming types (reverse of conformances) for protocols
  var conformingTypesBySymbol: [String: [Conformance]] = [:]
  for rel in graph.relationships where rel.kind == .conformsTo {
    if let sourceSymbol = symbols[rel.source], symbols[rel.target] != nil {
      let slug = sourceSymbol.names.title.lowercased()
      conformingTypesBySymbol[rel.target, default: []].append(
        Conformance(name: sourceSymbol.names.title, url: "/api/\(slug)/")
      )
    }
  }

  var items: [Item<APIMetadata>] = []

  for (id, symbol) in symbols {
    guard symbol.accessLevel.rawValue == "public" else { continue }
    guard let kind = SymbolKind(rawValue: symbol.kind.identifier.identifier), kind.isTopLevel else { continue }

    // Skip symbols that are members of other types (but not members of the module itself)
    if memberTargets.contains(id) {
      let memberOfRelations = graph.relationships
        .filter { $0.source == id && $0.kind == .memberOf }
      let isModuleMember = memberOfRelations.allSatisfy { rel in
        symbols[rel.target] == nil
      }
      if !isModuleMember {
        continue
      }
    }

    let declaration = renderDeclaration(symbol: symbol)
    let docComment = renderDocComment(symbol: symbol)
    let (isDeprecated, deprecationMessage) = checkDeprecation(symbol: symbol)
    let members = resolveMembers(ids: membersByParent[id] ?? [], symbols: symbols)
    let conformances = (conformancesBySymbol[id] ?? []).sorted { $0.name < $1.name }
    let conformingTypes = (conformingTypesBySymbol[id] ?? []).sorted { $0.name < $1.name }

    let mentions = (symbolMentions[symbol.names.title] ?? [])
      .map { DocMention(title: $0.title, url: $0.url) }

    let metadata = APIMetadata(
      kind: kind,
      declaration: declaration,
      isDeprecated: isDeprecated,
      deprecationMessage: deprecationMessage,
      members: members,
      conformances: conformances,
      conformingTypes: conformingTypes,
      mentionedIn: mentions
    )

    let slug = symbol.names.title.lowercased()

    let item = Item<APIMetadata>(
      title: symbol.names.title,
      body: docComment ?? "",
      relativeDestination: PathKit.Path("api/\(slug)/index.html"),
      metadata: metadata
    )

    items.append(item)
  }

  // Load extension symbol graphs (Saga@Swift.symbols.json, Saga@PathKit.symbols.json, etc.)
  let extensionItems = try loadExtensionSymbolGraphs(rootPath: rootPath)
  items.append(contentsOf: extensionItems)

  return items.sorted { a, b in
    if a.metadata.kind != b.metadata.kind { return a.metadata.kind.order < b.metadata.kind.order }
    return a.title < b.title
  }
}

// MARK: - Extension symbol graph loading

func loadExtensionSymbolGraphs(rootPath: PathKit.Path) throws -> [Item<APIMetadata>] {
  let dir = rootPath + ".build" + "symbolgraph"
  guard dir.exists else { return [] }

  let extensionFiles = try dir.children().filter { $0.lastComponent.hasPrefix("Saga@") && $0.extension == "json" }
  guard !extensionFiles.isEmpty else { return [] }

  // Collect all extension members and conformances grouped by extended type name
  var membersByType: [String: [APIMember]] = [:]
  var declarationsByType: [String: String] = [:]
  var conformancesByType: [String: [Conformance]] = [:]

  for file in extensionFiles {
    let data = try Data(contentsOf: URL(fileURLWithPath: file.string))
    let graph = try JSONDecoder().decode(SymbolGraph.self, from: data)

    let symbols = graph.symbols
    let membersByParent = groupMembersByParent(graph: graph)
    let conformancesByBlock = collectConformances(graph: graph)

    for (id, symbol) in symbols {
      guard symbol.accessLevel.rawValue == "public" else { continue }
      guard SymbolKind(rawValue: symbol.kind.identifier.identifier) == .extension else { continue }

      let typeName = symbol.names.title
      declarationsByType[typeName] = renderDeclaration(symbol: symbol)
      membersByType[typeName, default: []].append(contentsOf: resolveMembers(ids: membersByParent[id] ?? [], symbols: symbols))
      conformancesByType[typeName, default: []].append(contentsOf: conformancesByBlock[id] ?? [])
    }
  }

  // Create one Item per extended type
  return membersByType.map { typeName, members in
    let sortedMembers = members.sorted { a, b in
      if a.kind != b.kind { return a.kind.order < b.kind.order }
      return a.name < b.name
    }

    // Deduplicate conformances by name
    let conformances = Array(Set((conformancesByType[typeName] ?? []).map(\.name)))
      .sorted()
      .map { Conformance(name: $0, url: nil) }

    let declaration = declarationsByType[typeName] ?? escapeHTML("extension \(typeName)")
    let slug = typeName.lowercased()

    let mentions = (symbolMentions[typeName] ?? [])
      .map { DocMention(title: $0.title, url: $0.url) }

    let metadata = APIMetadata(
      kind: .extension,
      declaration: declaration,
      isDeprecated: false,
      deprecationMessage: nil,
      members: sortedMembers,
      conformances: conformances,
      conformingTypes: [],
      mentionedIn: mentions
    )

    return Item<APIMetadata>(
      title: typeName,
      body: "",
      relativeDestination: PathKit.Path("api/\(slug)/index.html"),
      metadata: metadata
    )
  }
}

// MARK: - Declaration rendering

func renderFragment(_ fragment: SymbolGraph.Symbol.DeclarationFragments.Fragment) -> String {
  let text = escapeHTML(fragment.spelling)
  switch fragment.kind {
    case .keyword:
      return #"<span class="token keyword">\#(text)</span>"#
    case .attribute:
      return #"<span class="token attribute atrule">\#(text)</span>"#
    case .typeIdentifier, .genericParameter:
      return #"<span class="token class-name">\#(text)</span>"#
    case .identifier:
      return #"<span class="token function-definition function">\#(text)</span>"#
    default:
      return text
  }
}

func renderDeclaration(symbol: SymbolGraph.Symbol) -> String {
  guard let fragments = symbol.declarationFragments else {
    return escapeHTML(symbol.names.title)
  }

  // Separate declaration-level attributes (like @discardableResult) from the rest.
  // These always go on their own line for long declarations.
  var attrPrefix = ""
  var bodyFragments = fragments[...]
  while let first = bodyFragments.first, first.kind == .attribute || (first.kind == .text && first.spelling.trimmingCharacters(in: .whitespaces).isEmpty && attrPrefix.hasSuffix("\n")) {
    if first.kind == .attribute {
      attrPrefix += renderFragment(first) + "\n"
    }
    bodyFragments = bodyFragments.dropFirst()
  }

  let bodyPlainText = bodyFragments.map(\.spelling).joined()
  let bodyInline = bodyFragments.map { renderFragment($0) }.joined()

  // If the body (without attributes) fits on one line, just add attribute prefix
  guard bodyPlainText.count > 80 else { return attrPrefix + bodyInline }

  // Only format multi-line if there are actual parameters
  let hasParams = bodyFragments.contains {
    $0.kind == .externalParameter || $0.kind == .internalParameter
  }
  guard hasParams else { return attrPrefix + bodyInline }

  // Build formatted declaration with one parameter per line.
  // Walk through fragments, tracking paren depth to identify the main
  // parameter list, and insert line breaks at `(`, `,`, and `)`.
  let indent = "  "
  var result = attrPrefix
  var parenDepth = 0
  var paramDepth = -1 // set to the paren depth of the main param list
  var paramListClosed = false

  for fragment in bodyFragments {
    // Non-text fragments never contain structural chars — render directly
    guard fragment.kind == .text else {
      result += renderFragment(fragment)
      continue
    }

    // Text fragments may contain (, ), and , that define parameter boundaries.
    // Process char-by-char to insert line breaks at the right paren depth.
    let spelling = fragment.spelling
    var i = spelling.startIndex
    while i < spelling.endIndex {
      let char = spelling[i]

      if char == "(" {
        parenDepth += 1
        if paramDepth == -1 { paramDepth = parenDepth }
        result += "("
        if parenDepth == paramDepth && !paramListClosed {
          result += "\n" + indent
        }
      } else if char == ")" && parenDepth == paramDepth && !paramListClosed {
        result += "\n)"
        parenDepth -= 1
        paramListClosed = true
      } else if char == ")" {
        parenDepth -= 1
        result += ")"
      } else if char == "," && parenDepth == paramDepth && !paramListClosed {
        let next = spelling.index(after: i)
        if next < spelling.endIndex && spelling[next] == " " {
          result += ",\n" + indent
          i = spelling.index(after: next)
          continue
        }
        result += ","
      } else {
        result += escapeHTML(String(char))
      }

      i = spelling.index(after: i)
    }
  }

  return result
}

// MARK: - Doc comment rendering

func renderDocComment(symbol: SymbolGraph.Symbol) -> String? {
  guard let docComment = symbol.docComment, !docComment.lines.isEmpty else {
    return nil
  }

  var text = docComment.lines.map { $0.text }.joined(separator: "\n")
  guard !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
    return nil
  }

  text = rewriteMarkdown(markdown: text, docTitles: [:])

  guard let html = try? Parsley.html(text, options: [.unsafe, .smartQuotes]) else {
    return nil
  }

  let result = Moon.shared.highlightCodeBlocks(in: html)
  return boldBlockquoteKeywords(result)
}

// MARK: - Deprecation check

func checkDeprecation(symbol: SymbolGraph.Symbol) -> (Bool, String?) {
  guard let availability = symbol.availability else {
    return (false, nil)
  }

  for item in availability {
    if item.isUnconditionallyDeprecated {
      return (true, item.message)
    }
    if item.deprecatedVersion != nil {
      return (true, item.message)
    }
  }

  return (false, nil)
}
