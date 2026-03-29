import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import Parsley
import Saga
import SwiftSoup

struct ReleaseMetadata: Metadata {
  let tagName: String
  let major: Int
  let publishedAt: Date
  let htmlUrl: String
}

private struct GitHubRelease: Decodable {
  let tag_name: String
  let name: String?
  let body: String?
  let html_url: String
  let published_at: String
  let draft: Bool
  let prerelease: Bool
}

func fetchReleases() async throws -> [Item<ReleaseMetadata>] {
  var allReleases: [GitHubRelease] = []
  var page = 1

  while true {
    var request = URLRequest(url: URL(string: "https://api.github.com/repos/loopwerk/Saga/releases?per_page=100&page=\(page)")!)
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

    let (data, _) = try await URLSession.shared.data(for: request)
    let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
    if releases.isEmpty { break }
    allReleases.append(contentsOf: releases)
    if releases.count < 100 { break }
    page += 1
  }

  let dateFormatter = ISO8601DateFormatter()
  dateFormatter.formatOptions = [.withInternetDateTime]

  return allReleases
    .filter { !$0.draft }
    .compactMap { release in
      let version = release.tag_name
      let components = version.split(separator: ".")
      guard let major = Int(components.first ?? "") else { return nil }

      let publishedAt = dateFormatter.date(from: release.published_at) ?? Date()
      let title = release.name ?? version

      let metadata = ReleaseMetadata(
        tagName: version,
        major: major,
        publishedAt: publishedAt,
        htmlUrl: release.html_url
      )

      return Item<ReleaseMetadata>(
        title: title,
        body: release.body ?? "",
        date: publishedAt,
        metadata: metadata
      )
    }
}

func processReleaseNotes(item: Item<ReleaseMetadata>) {
  var html = (try? Parsley.html(item.body, options: [.unsafe, .smartQuotes, .hardBreaks])) ?? item.body
  html = wrapBreakingChanges(html)
  item.body = html
}

/// Splits list items on `<br>`, keeping the first part as-is
/// and wrapping the remaining parts in a styled div.
func wrapListItemDescriptions(_ doc: SwiftSoup.Document, item: Item<ReleaseMetadata>) throws {
  let lis = try doc.select("li")

  for li in lis {
    let innerHtml = try li.html()
    let parts = innerHtml.components(separatedBy: "<br />")
    guard parts.count > 1 else { continue }
    let first = parts[0]
    let rest = parts.dropFirst().joined(separator: "<br />")
    try li.html(first + #"<div class="text-zinc-400 mt-2">"# + rest + "</div>")
  }
}

/// Wraps "BREAKING CHANGES" sections in a styled container.
func wrapBreakingChanges(_ html: String) -> String {
  guard let regex = try? NSRegularExpression(
    pattern: #"(<h2>BREAKING CHANGES</h2>)([\s\S]*?)(?=<h2>|$)"#,
    options: []
  ) else { return html }

  let range = NSRange(html.startIndex..., in: html)
  return regex.stringByReplacingMatches(
    in: html,
    range: range,
    withTemplate: #"<div class="breaking-changes">$1$2</div>"#
  )
}
