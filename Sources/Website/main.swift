import Bonsai
import Foundation
import Saga
import SagaParsleyMarkdownReader
import SagaSwimRenderer
import SagaUtils
import SwiftTailwind

let saga = try Saga(input: "content", output: "deploy")
let tailwind = SwiftTailwind(version: "4.2.1")

// Read the markdown files in content/docs/, and overwrite the content
// with a rewritten, improved version.
try rewriteMarkdownDocs(inputPath: saga.inputPath)

try await saga
  .ignoreChanges("output.css")
  .ignoreChanges("content/docs/*")

  // Compile Tailwind CSS
  .beforeRead { _ in
    try await tailwind.run(
      input: "content/static/input.css",
      output: "content/static/output.css",
      options: .minify
    )
  }

  // Guide documentation (from DocC markdown files)
  .register(
    folder: "docs",
    metadata: DocMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: sequence(
      processDocItem,
      boldBlockquoteKeywords,
      swiftSoupProcessor(processExternalLinks, renderToc, addCodeWordBreaks),
      syntaxHighlight
    ),
    sorting: docSorting,
    writers: [
      .itemWriter(swim(renderDocPage)),
    ]
  )

  // API Reference (from symbol graph)
  .register(
    metadata: APIMetadata.self,
    fetch: { try loadSymbolGraph(rootPath: saga.rootPath) },
    itemProcessor: boldBlockquoteKeywords,
    writers: [
      .itemWriter(swim(renderAPIPage)),
      .listWriter(swim(renderAPIIndex), output: "api/index.html"),
    ]
  )

  // Release notes
  .register(
    metadata: ReleaseMetadata.self,
    fetch: { try await fetchReleases() },
    itemProcessor: sequence(processReleaseNotes, swiftSoupProcessor(wrapListItemDescriptions, processExternalLinks)),
    writers: [
      .groupedWriter(swim(renderReleaseNotes), by: \.metadata.major, output: "docs/releasenotes/[key].x/index.html"),
    ]
  )

  .createPage("index.html", using: swim(renderHomePage))
  .createPage("404.html", using: swim(render404Page))
  .createPage("search/index.html", using: swim(renderSearch))
  .createPage("docs/guides/index.html", using: swim(renderGuidesIndex))
  .createPage("docs/releasenotes/index.html", using: renderReleaseNotesRedirect)

  // Minify all HTML output (prod only)
  .postProcess { html, _ in
    guard !Saga.isDev else { return html }
    return Bonsai.minifyHTML(html)
  }

  // Index the site with Pagefind
  .afterWrite { _ in
    let pagefind = Process()
    pagefind.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    pagefind.arguments = ["pnpm", "pagefind", "--site", "deploy"]
    pagefind.currentDirectoryURL = URL(fileURLWithPath: saga.rootPath.string)
    try pagefind.run()
    pagefind.waitUntilExit()
    if pagefind.terminationStatus != 0 {
      print("pagefind failed with exit code \(pagefind.terminationStatus)")
    }
  }

  // Run everything!
  .run()
