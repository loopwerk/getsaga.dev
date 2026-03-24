import Foundation
import HTML
import Moon
import Parsley
import Saga
import SagaPathKit
import Sigil
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
  case `init`
  case property
  case method
  case typeProperty = "type.property"
  case typeMethod = "type.method"
  case enumCase = "enum.case"
  case `subscript`
  case typeSubscript = "type.subscript"
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
  let inheritsFrom: [Conformance]
  let inheritedBy: [Conformance]
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

/// Collects inheritance relationships from a symbol graph, keyed by source symbol ID.
func collectInheritance(graph: SymbolGraph) -> [String: [Conformance]] {
  let symbols = graph.symbols
  var result: [String: [Conformance]] = [:]
  for rel in graph.relationships where rel.kind == .inheritsFrom {
    if let targetSymbol = symbols[rel.target] {
      let slug = targetSymbol.names.title.lowercased()
      result[rel.source, default: []].append(
        Conformance(name: targetSymbol.names.title, url: "/api/\(slug)/")
      )
    } else if let fallback = rel.targetFallback {
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
      declaration: Sigil.renderDeclaration(symbol: symbol),
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

func loadSymbolGraph(rootPath: Path) throws -> [Item<APIMetadata>] {
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
  let inheritanceBySymbol = collectInheritance(graph: graph)

  // Find top-level symbols (public, not members of other symbols)
  let memberTargets = Set(
    graph.relationships
      .filter { $0.kind == .memberOf }
      .map(\.source)
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

  // Collect inherited-by types (reverse of inheritsFrom) for classes
  var inheritedBySymbol: [String: [Conformance]] = [:]
  for rel in graph.relationships where rel.kind == .inheritsFrom {
    if let sourceSymbol = symbols[rel.source], symbols[rel.target] != nil {
      let slug = sourceSymbol.names.title.lowercased()
      inheritedBySymbol[rel.target, default: []].append(
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

    let declaration = Sigil.renderDeclaration(symbol: symbol)
    let docComment = renderDocComment(symbol: symbol)
    let (isDeprecated, deprecationMessage) = checkDeprecation(symbol: symbol)
    let members = resolveMembers(ids: membersByParent[id] ?? [], symbols: symbols)
    let inheritsFrom = (inheritanceBySymbol[id] ?? []).sorted { $0.name < $1.name }
    let inheritedBy = (inheritedBySymbol[id] ?? []).sorted { $0.name < $1.name }
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
      inheritsFrom: inheritsFrom,
      inheritedBy: inheritedBy,
      conformances: conformances,
      conformingTypes: conformingTypes,
      mentionedIn: mentions
    )

    let slug = symbol.names.title.lowercased()

    let item = Item<APIMetadata>(
      title: symbol.names.title,
      body: docComment ?? "",
      relativeDestination: Path("api/\(slug)/index.html"),
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

func loadExtensionSymbolGraphs(rootPath: Path) throws -> [Item<APIMetadata>] {
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
      declarationsByType[typeName] = Sigil.renderDeclaration(symbol: symbol)
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

    let declaration = declarationsByType[typeName] ?? Sigil.escapeHTML("extension \(typeName)")
    let slug = typeName.lowercased()

    let mentions = (symbolMentions[typeName] ?? [])
      .map { DocMention(title: $0.title, url: $0.url) }

    let metadata = APIMetadata(
      kind: .extension,
      declaration: declaration,
      isDeprecated: false,
      deprecationMessage: nil,
      members: sortedMembers,
      inheritsFrom: [],
      inheritedBy: [],
      conformances: conformances,
      conformingTypes: [],
      mentionedIn: mentions
    )

    return Item<APIMetadata>(
      title: typeName,
      body: "",
      relativeDestination: Path("api/\(slug)/index.html"),
      metadata: metadata
    )
  }
}

// MARK: - Doc comment rendering

func renderDocComment(symbol: SymbolGraph.Symbol) -> String? {
  guard let docComment = symbol.docComment, !docComment.lines.isEmpty else {
    return nil
  }

  var text = docComment.lines.map(\.text).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
  guard !text.isEmpty else {
    return nil
  }

  text = rewriteMarkdown(markdown: text, docTitles: [:], docUrls: [:])

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
