import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import Parsley
import Saga

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

      let markdownBody = release.body ?? ""
      var htmlBody = (try? Parsley.html(markdownBody, options: [.unsafe, .smartQuotes])) ?? markdownBody
      htmlBody = wrapBreakingChanges(htmlBody)

      let metadata = ReleaseMetadata(
        tagName: version,
        major: major,
        publishedAt: publishedAt,
        htmlUrl: release.html_url
      )

      return Item<ReleaseMetadata>(
        title: title,
        body: htmlBody,
        date: publishedAt,
        metadata: metadata
      )
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
