import Foundation
import HTML
import SagaPathKit
import Saga

// MARK: - Doc sidebar

func docSidebar(docs: [Item<DocMetadata>], currentUrl: String) -> Node {
  let topics = docs.filter { !$0.url.contains("/guides/") }
  let guides = docs.filter { $0.url.contains("/guides/") }

  return aside(class: "doc-sidebar") {
    h4(class: "text-xs font-semibold uppercase tracking-wide text-zinc-500 mb-2") { "TOPICS" }
    ul(class: "list-none flex flex-col gap-1 p-0") {
      topics.map { doc in
        li {
          a(class: "sidebar-link\(doc.url == currentUrl ? " sidebar-link-active" : "")", href: doc.url) { doc.title }
        }
      }
      li {
        a(class: "sidebar-link\(currentUrl == "/docs/releasenotes/" ? " sidebar-link-active" : "")", href: "/docs/releasenotes/") { "Release Notes" }
      }
    }
    if !guides.isEmpty {
      h4(class: "text-xs font-semibold uppercase tracking-wide text-zinc-500 mb-2 mt-6") { "GUIDES" }
      ul(class: "list-none flex flex-col gap-1 p-0") {
        guides.map { doc in
          li {
            a(class: "sidebar-link\(doc.url == currentUrl ? " sidebar-link-active" : "")", href: doc.url) { doc.title }
          }
        }
      }
    }
  }
}

// MARK: - Guides index

func renderGuidesIndex(context: PageRenderingContext) -> Node {
  let docs = context.allItems.compactMap { $0 as? Item<DocMetadata> }.filter { $0.url.contains("/guides/") }
  let guides = docs.filter { $0.url.contains("/guides/") }

  return layout(title: "Documentation - Guides", activePage: .docs) {
    div(class: "mx-auto max-w-5xl px-8 pt-20 pb-16 grid grid-cols-1 md:grid-cols-[220px_1fr] gap-12") {
      docSidebar(docs: docs, currentUrl: "/docs/guides/")
      main(class: "doc-content min-w-0") {
        h1 { "Guides" }
        ul(class: "mt-8") {
          guides.map { guide in
            li {
              a(href: guide.url) { guide.title }
            }
          }
        }
      }
    }
  }
}

// MARK: - Doc page templates

func renderDocPage(context: ItemRenderingContext<DocMetadata>) -> Node {
  let hasToc = context.item.metadata.toc != nil
  return layout(title: "Documentation - \(context.item.title)", activePage: .docs) {
    div(class: "mx-auto max-w-5xl px-8 pt-20 pb-16 grid grid-cols-1 md:grid-cols-[220px_1fr] \(hasToc ? "lg:grid-cols-[220px_1fr_180px]" : "") gap-12") {
      docSidebar(docs: context.items, currentUrl: context.item.url)
      main(class: "doc-content min-w-0", customAttributes: ["data-pagefind-body": ""]) {
        Node.raw(#"<span data-pagefind-meta="kind" style="display:none">Topic</span>"#)
        h1 { context.item.title }
        Node.raw(context.item.body)
      }
      if let toc = context.item.metadata.toc {
        nav(class: "hidden md:block md:sticky md:top-20 md:self-start") {
          p(class: "text-xs font-semibold uppercase tracking-wide text-zinc-500 mb-3") { "On this page" }
          Node.raw(toc)
        }
      }
    }
  }
}
