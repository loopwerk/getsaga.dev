import Foundation
import HTML
import Saga

private let displayDateFormatter: DateFormatter = {
  let f = DateFormatter()
  f.dateStyle = .long
  f.timeStyle = .none
  return f
}()

private func versionSidebar(currentMajor: Int, maxMajor: Int) -> Node {
  nav(class: "hidden md:block md:sticky md:top-20 md:self-start") {
    p(class: "text-xs font-semibold uppercase tracking-wide text-zinc-500 mb-3") { "SERIES" }
    ul(class: "list-none flex flex-col gap-1 p-0") {
      (0 ... maxMajor).reversed().map { major in
        let label = "\(major).x"
        let url = "/docs/releasenotes/\(major).x/"
        return li {
          a(class: "sidebar-link\(major == currentMajor ? " sidebar-link-active" : "")", href: url) { label }
        }
      }
    }
  }
}

func renderReleaseNotes(context: PartitionedRenderingContext<Int, ReleaseMetadata>) -> Node {
  let major = context.key
  let releases = context.items.sorted { $0.date > $1.date }
  let docs = context.allItems.compactMap { $0 as? Item<DocMetadata> }.sorted(by: docSorting)
  let maxMajor = context.allItems.compactMap { ($0 as? Item<ReleaseMetadata>)?.metadata.major }.max() ?? major

  return layout(title: "Release Notes - \(major).x", activePage: .docs) {
    div(class: "mx-auto max-w-5xl px-8 pt-20 pb-16 grid grid-cols-1 md:grid-cols-[220px_1fr] lg:grid-cols-[220px_1fr_180px] gap-12") {
      docSidebar(docs: docs, currentUrl: "/docs/releasenotes/", maxMajor: maxMajor)

      main(class: "doc-content min-w-0") {
        h1 { "Release Notes" }

        releases.map { release in
          article(class: "mb-12") {
            h2(id: release.metadata.tagName) {
              a(href: release.metadata.htmlUrl, target: "_blank") { release.title }
            }
            p(class: "text-sm text-zinc-500 -mt-2 mb-4") {
              displayDateFormatter.string(from: release.date)
            }
            div(class: "release-notes") {
              Node.raw(release.body)
            }
          }
        }
      }

      versionSidebar(currentMajor: major, maxMajor: maxMajor)
    }
  }
}
