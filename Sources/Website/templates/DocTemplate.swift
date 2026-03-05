import Foundation
import HTML
import PathKit
import Saga

// MARK: - Doc sidebar

func docSidebar(docs: [Item<DocMetadata>], currentUrl: String) -> Node {
  aside(class: "md:sticky md:top-20 md:self-start") {
    ul(class: "list-none flex flex-col gap-1 p-0") {
      docs.map { doc in
        li {
          a(class: "sidebar-link\(doc.url == currentUrl ? " sidebar-link-active" : "")", href: doc.url) { doc.title }
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
      main(class: "doc-content min-w-0") {
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
