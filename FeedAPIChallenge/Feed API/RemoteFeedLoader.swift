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
		client.get(from: url) { result in
			switch result {
			case let .success((data, response)):
				guard response.statusCode == RemoteFeedLoader.successStatusCode else {
					completion(.failure(Error.invalidData))
					return
				}
				guard let feed = try? JSONDecoder().decode(Feed.self, from: data) else {
					completion(.failure(Error.invalidData))
					return
				}
				if feed.items.isEmpty {
					completion(.success([]))
				}
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}

	private struct Feed: Decodable {
		let items: [FeedImageAPI]
	}

	private struct FeedImageAPI: Decodable {
		let id: UUID
		let description: String?
		let location: String?
		let urlString: String

		enum CodingKeys: String, CodingKey {
			case id = "iamge_id"
			case description = "iamge_desc"
			case location = "iamge_loc"
			case urlString = "image_url"
		}
	}
}
