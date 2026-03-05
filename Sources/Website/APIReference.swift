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
      case .class, .protocol, .struct, .var, .func, .typealias, .enum:
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

struct APIMetadata: Metadata {
  let kind: SymbolKind
  let declaration: String
  let isDeprecated: Bool
  let deprecationMessage: String?
  let members: [APIMember]
  let conformances: [Conformance]
  let conformingTypes: [Conformance]
}

struct APIMember: Codable {
  let name: String
  let kind: SymbolKind
  let declaration: String
  let docComment: String?
  let isDeprecated: Bool
  let deprecationMessage: String?
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

  // Find top-level symbols (public, not members of other symbols)
  let memberTargets = Set(
    graph.relationships
      .filter { $0.kind == .memberOf }
      .map { $0.source }
  )

  // Group members by their parent
  var membersByParent: [String: [String]] = [:]
  for rel in graph.relationships where rel.kind == .memberOf {
    membersByParent[rel.target, default: []].append(rel.source)
  }

  // Collect conformances by source symbol
  var conformancesBySymbol: [String: [Conformance]] = [:]
  for rel in graph.relationships where rel.kind == .conformsTo {
    if let targetSymbol = symbols[rel.target] {
      let slug = targetSymbol.names.title.lowercased()
      conformancesBySymbol[rel.source, default: []].append(
        Conformance(name: targetSymbol.names.title, url: "/api/\(slug)/")
      )
    } else if let fallback = rel.targetFallback, !fallback.hasSuffix("Metatype") {
      conformancesBySymbol[rel.source, default: []].append(
        Conformance(name: fallback, url: nil)
      )
    }
  }

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

    let memberIDs = membersByParent[id] ?? []
    let members = memberIDs.compactMap { memberID -> APIMember? in
      guard let memberSymbol = symbols[memberID] else { return nil }
      guard memberSymbol.accessLevel.rawValue == "public" else { return nil }

      let (memberDeprecated, memberDeprecMsg) = checkDeprecation(symbol: memberSymbol)

      guard let memberKind = SymbolKind(rawValue: memberSymbol.kind.identifier.identifier) else { return nil }

      return APIMember(
        name: memberSymbol.names.title,
        kind: memberKind,
        declaration: renderDeclaration(symbol: memberSymbol),
        docComment: renderDocComment(symbol: memberSymbol),
        isDeprecated: memberDeprecated,
        deprecationMessage: memberDeprecMsg
      )
    }.sorted { a, b in
      if a.kind != b.kind { return a.kind.order < b.kind.order }
      return a.name < b.name
    }

    let conformances = (conformancesBySymbol[id] ?? []).sorted { $0.name < $1.name }
    let conformingTypes = (conformingTypesBySymbol[id] ?? []).sorted { $0.name < $1.name }

    let metadata = APIMetadata(
      kind: kind,
      declaration: declaration,
      isDeprecated: isDeprecated,
      deprecationMessage: deprecationMessage,
      members: members,
      conformances: conformances,
      conformingTypes: conformingTypes
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

  return items.sorted { a, b in
    if a.metadata.kind != b.metadata.kind { return a.metadata.kind.order < b.metadata.kind.order }
    return a.title < b.title
  }
}

// MARK: - Declaration rendering

func renderDeclaration(symbol: SymbolGraph.Symbol) -> String {
  guard let fragments = symbol.declarationFragments else {
    return escapeHTML(symbol.names.title)
  }

  return fragments.map { fragment in
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
      case .externalParameter, .internalParameter:
        return text
      case .text:
        return text
      default:
        return text
    }
  }.joined()
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
