//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	private static let successStatusCode = 200

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] clientResult in
			guard self != nil else { return }
			switch clientResult {
			case let .success((data, response)):
				let feedLoaderResult = RemoteFeedLoader.getFeedLoaderResult(data, response)
				completion(feedLoaderResult)
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}

	// MARK: - Helpers

	private static func getFeedLoaderResult(_ data: Data, _ response: HTTPURLResponse) -> FeedLoader.Result {
		guard response.statusCode == successStatusCode,
		      let feed = try? JSONDecoder().decode(Feed.self, from: data) else {
			return .failure(Error.invalidData)
		}
		return .success(feed.feedImages)
	}

	private struct Feed: Decodable {
		let items: [FeedImageAPI]

		var feedImages: [FeedImage] {
			items.map { $0.feedImage }
		}
	}

	private struct FeedImageAPI: Decodable {
		let id: UUID
		let description: String?
		let location: String?
		let url: URL

		enum CodingKeys: String, CodingKey {
			case id = "image_id"
			case description = "image_desc"
			case location = "image_loc"
			case url = "image_url"
		}

		var feedImage: FeedImage {
			FeedImage(id: id, description: description, location: location, url: url)
		}
	}
}
