import Moon
import Saga
import SagaPathKit
import SagaUtils
import SwiftSoup

struct DocMetadata: Metadata {
  var toc: String?
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
