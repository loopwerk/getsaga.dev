import Moon
import SagaPathKit
import Saga
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
