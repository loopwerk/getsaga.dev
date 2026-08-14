import Foundation
import Moon
import Saga
import SagaPathKit
import SagaUtils
import SwiftSoup

struct DocMetadata: Metadata {
  var toc: String?
  var summary: String?
}

func processDocItem(item: Item<DocMetadata>) {
  // Replace titles like ``Saga`` with just Saga
  item.title = item.title.replacingOccurrences(of: "`", with: "")
}

func boldBlockquoteKeywords<M>(item: Item<M>) {
  item.body = boldBlockquoteKeywords(item.body)
}

func syntaxHighlight<M>(item: Item<M>) {
  item.body = Moon.shared.highlightCodeBlocks(in: item.body)
}

func renderToc(_ doc: Document, item: Item<DocMetadata>) throws {
  item.metadata.toc = try buildTOCList(doc)
}

/// Store the DocC abstract (the intro paragraph right below the title) as the item's summary,
/// so index pages can show it alongside the title.
func extractSummary(_ doc: Document, item: Item<DocMetadata>) throws {
  guard let first = doc.body()?.children().array().first, first.tagName() == "p" else { return }
  let text = try first.text().trimmingCharacters(in: .whitespacesAndNewlines)
  item.metadata.summary = text.isEmpty ? nil : text
}

/// Insert `<wbr>` after each `:` inside inline `<code>` elements so long Swift-style
/// identifiers like `atomFeed(title:author:baseURL:)` can wrap on narrow viewports.
func addCodeWordBreaks<M>(_ doc: Document, item: Item<M>) throws {
  let inlineCodes = try doc.select("code").array().filter { $0.parent()?.tagName() != "pre" }
  for code in inlineCodes {
    let html = try code.html()
    guard html.contains(":") else { continue }
    try code.html(html.replacingOccurrences(of: ":", with: ":<wbr>"))
  }
}
