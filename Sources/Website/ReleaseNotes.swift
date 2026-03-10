import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import Parsley
import PathKit
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
  let cachePath = Path(".build/releases-cache.json")

  // Use cached data if available
  if cachePath.exists,
     let attributes = try? FileManager.default.attributesOfItem(atPath: cachePath.string),
     let modified = attributes[.modificationDate] as? Date
  {
    let data: Data = try cachePath.read()
    let items = try JSONDecoder().decode([CachedRelease].self, from: data)
    return items.map(\.toItem)
  }

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

  let items: [Item<ReleaseMetadata>] = allReleases
    .filter { !$0.draft }
    .compactMap { release in
      let version = release.tag_name
      let components = version.split(separator: ".")
      guard let major = Int(components.first ?? "") else { return nil }

      let publishedAt = dateFormatter.date(from: release.published_at) ?? Date()
      let title = release.name ?? version

      let markdownBody = release.body ?? ""
      let htmlBody = (try? Parsley.html(markdownBody, options: [.unsafe, .smartQuotes])) ?? markdownBody

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

  // Cache the results
  try? FileManager.default.createDirectory(atPath: Path(".build").string, withIntermediateDirectories: true)
  let cached = items.map { CachedRelease(from: $0) }
  let cacheData = try JSONEncoder().encode(cached)
  try? cachePath.write(cacheData)

  return items
}

// MARK: - Cache serialization

private struct CachedRelease: Codable {
  let title: String
  let tagName: String
  let major: Int
  let htmlBody: String
  let publishedAt: Date
  let htmlUrl: String

  init(from item: Item<ReleaseMetadata>) {
    title = item.title
    tagName = item.metadata.tagName
    major = item.metadata.major
    htmlBody = item.body
    publishedAt = item.metadata.publishedAt
    htmlUrl = item.metadata.htmlUrl
  }

  var toItem: Item<ReleaseMetadata> {
    let metadata = ReleaseMetadata(
      tagName: tagName,
      major: major,
      publishedAt: publishedAt,
      htmlUrl: htmlUrl
    )
    return Item<ReleaseMetadata>(
      title: title,
      body: htmlBody,
      date: publishedAt,
      metadata: metadata
    )
  }
}
