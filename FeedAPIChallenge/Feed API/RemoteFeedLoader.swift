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
		client.get(from: url) { [weak self] result in
			guard let _ = self else { return }
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
				completion(.success(feed.feedImages))
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}

	private struct Feed: Decodable {
		let items: [FeedImageAPI]

		var feedImages: [FeedImage] {
			items.compactMap { $0.feedImage }
		}
	}

	private struct FeedImageAPI: Decodable {
		let id: UUID
		let description: String?
		let location: String?
		let urlString: String

		enum CodingKeys: String, CodingKey {
			case id = "image_id"
			case description = "image_desc"
			case location = "image_loc"
			case urlString = "image_url"
		}
		
		var url: URL? { URL(string: urlString) }
		
		var feedImage: FeedImage? {
			url != nil ? FeedImage(id: id, description: description, location: location, url: url!) : nil
		}
	}
}
