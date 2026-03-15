import HTML
import Saga

// MARK: - Breakable title

/// Inserts <wbr> at camelCase boundaries and after colons so long titles can wrap.
func breakableTitle(_ title: String) -> String {
  var result = ""
  let chars = Array(title)
  for (i, char) in chars.enumerated() {
    result.append(char)
    if char == ":" {
      result.append("<wbr>")
    } else if i + 1 < chars.count,
              char.isLowercase, chars[i + 1].isUppercase
    {
      result.append("<wbr>")
    }
  }
  return result
}

func conformanceList(_ conformances: [Conformance]) -> Node {
  Node.fragment(conformances.enumerated().map { index, conformance in
    let separator: Node = index > 0 ? Node.raw(", ") : Node.raw("")
    let item: Node = conformance.url.map { url in
      a(href: url) { code { conformance.name } }
    } ?? code { conformance.name }
    return Node.fragment([separator, item])
  })
}

// MARK: - API page templates

func renderAPIIndex(context: ItemsRenderingContext<APIMetadata>) -> Node {
  return layout(title: "API Reference", activePage: .api) {
    div(class: "mx-auto max-w-5xl px-8 pt-20 pb-16 grid grid-cols-1 md:grid-cols-[220px_1fr] gap-12") {
      apiSidebar(currentSlug: "/api/", allItems: context.allItems)

      main(class: "doc-content min-w-0") {
        h1 { "Saga \(sagaVersion) API Reference" }
        p(class: "mt-8") { "Complete reference for all public types, protocols, and functions in the Saga module. Browse the symbols using the sidebar." }
        a(class: "inline-flex items-center gap-2 rounded-lg bg-accent px-7 py-3 text-sm font-semibold text-white! transition-all hover:-translate-y-px hover:bg-accent-hover hover:shadow-lg", href: "/docs/releasenotes/") {
          "Releases notes"
        }
      }
    }
  }
}

func renderAPIPage(context: ItemRenderingContext<APIMetadata>) -> Node {
  let meta = context.item.metadata

  return layout(title: context.item.title, activePage: .api) {
    div(class: "mx-auto max-w-5xl px-8 pt-20 pb-16 grid grid-cols-1 md:grid-cols-[220px_1fr] gap-12") {
      apiSidebar(currentSlug: context.item.url, allItems: context.allItems)

      main(class: "doc-content min-w-0", customAttributes: ["data-pagefind-body": ""]) {
        p(class: "text-sm text-zinc-500 uppercase tracking-wide font-semibold mb-1", customAttributes: ["data-pagefind-meta": "kind", "data-pagefind-ignore": ""]) { meta.kind.displayName }

        h1 {
          Node.raw(breakableTitle(context.item.title))
        }

        if meta.isDeprecated {
          blockquote {
            p {
              em { "Deprecated" }
              if let message = meta.deprecationMessage {
                Node.raw(" ")
                message
              }
            }
          }
        }

        div(class: "mb-6", customAttributes: ["data-pagefind-ignore": ""]) {
          Node.raw(#"<pre class="top-declaration"><code class="language-swift" data-pagefind-meta="declaration">\#(meta.declaration)</code></pre>"#)
        }

        if !context.item.body.isEmpty {
          div(class: "mb-8") {
            Node.raw(context.item.body)
          }
        }

        if !meta.mentionedIn.isEmpty {
          h2 { "Mentioned In" }
          ul {
            meta.mentionedIn.map { mention in
              li {
                a(href: mention.url) { mention.title }
              }
            }
          }
        }

        renderMemberGroups(meta.members)

        if !meta.inheritsFrom.isEmpty || !meta.inheritedBy.isEmpty || !meta.conformances.isEmpty || !meta.conformingTypes.isEmpty {
          h2 { "Relationships" }
          if !meta.inheritsFrom.isEmpty {
            h3 { "Inherits From" }
            p { conformanceList(meta.inheritsFrom) }
          }
          if !meta.inheritedBy.isEmpty {
            h3 { "Inherited By" }
            p { conformanceList(meta.inheritedBy) }
          }
          if !meta.conformances.isEmpty {
            h3 { meta.kind == .protocol ? "Inherits From" : "Conforms To" }
            p { conformanceList(meta.conformances) }
          }
          if !meta.conformingTypes.isEmpty {
            h3 { "Conforming Types" }
            p { conformanceList(meta.conformingTypes) }
          }
        }
      }
    }
  }
}

// MARK: - Member rendering

func renderMemberGroups(_ members: [APIMember]) -> Node {
  let groups = Dictionary(grouping: members) { $0.kind }

  return Node.fragment(
    SymbolKind.allCases.filter { !$0.isTopLevel }.flatMap { kind -> [Node] in
      guard let groupMembers = groups[kind], !groupMembers.isEmpty else { return [] }
      var nodes: [Node] = [h2 { kind.pluralDisplayName }]

      for member in groupMembers {
        let anchor = member.name.lowercased()
        nodes.append(
          div(class: "member-item member-\(kind.rawValue)", id: anchor) {
            Node.raw(#"<pre class="member-declaration\#(member.isDeprecated ? " line-through" : "")" data-pagefind-ignore><code class="language-swift">\#(member.declaration)</code></pre>"#)
            if member.isDeprecated {
              if let message = member.deprecationMessage {
                blockquote(class: "mt-4") {
                  p {
                    em { "Deprecated" }
                    Node.raw(" ")
                    message
                  }
                }
              } else {
                blockquote(class: "mt-4") {
                  p { em { "Deprecated" } }
                }
              }
            }
            if let doc = member.docComment, member.deprecationMessage == nil {
              div(class: "member-doc") { Node.raw(doc) }
            }
          }
        )
      }
      return nodes
    }
  )
}

// MARK: - API sidebar

func apiSidebar(currentSlug: String, allItems: [AnyItem]) -> Node {
  let apiItems = allItems.compactMap { $0 as? Item<APIMetadata> }
  let grouped = Dictionary(grouping: apiItems) { $0.metadata.kind }

  return aside(class: "doc-sidebar") {
    SymbolKind.allCases.filter(\.isTopLevel).compactMap { kind -> [Node]? in
      guard let items = grouped[kind], !items.isEmpty else { return nil }
      let sorted = items.sorted { $0.title < $1.title }
      return [
        h4(class: "text-xs font-semibold uppercase tracking-wide text-zinc-500 mt-6 mb-2 first:mt-0") { kind.pluralDisplayName },
        ul(class: "list-none flex flex-col gap-1 p-0") {
          sorted.map { item in
            li {
              a(class: "sidebar-link\(currentSlug == item.url ? " sidebar-link-active" : "")", href: item.url) { item.title }
            }
          }
        },
      ]
    }.flatMap(\.self)
  }
}
