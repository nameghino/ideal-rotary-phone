//
//  Movie.swift
//  NetworkingStuff
//
//  Created by Nico Ameghino on 7/20/17.
//  Copyright © 2017 Nico Ameghino. All rights reserved.
//

import Foundation

private extension String {
    static let TMDBAPIKey = "1f54bd990f1cdfb230adb312546d765d"
}

struct Genre: Codable {
    let id: Int
    let name: String
}

struct Movie: Codable {
//    private enum CodingKeys: String, CodingKey {
//        case releaseDate = "release_date"
//        case id
//        case title
//    }

    let id: UInt64
    let title: String
//    let releaseDate: Date
//    let posterPath: String?
//    let overview: String
//    let backdropPath: String?
//    let genres: [Genre]
}

extension Movie: Resource {
    static var path: String { return "movie" }
    var resourcePath: String { return "" }
}

class TMDBService: Service {
    var baseURL: URL = URL(string: "https://api.themoviedb.org/3/")!
    typealias ObjectId = Movie.ObjectId
    typealias Value = Movie

    func configure(request: inout URLRequest) {
        guard
            let url = request.url,
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return }

        let authenticationToken = URLQueryItem(name: "api_key", value: String.TMDBAPIKey)

        if var existingQueryItems = components.queryItems {
            existingQueryItems.append(authenticationToken)
            components.queryItems = existingQueryItems
        } else {
            components.queryItems = [authenticationToken]
        }

        request.url = components.url
    }
}

struct TMDBSearchResponseWrapper: ResponseWrapper, Codable {
    typealias Value = Movie
    var contents: [Movie] = []

    init() {
        page = Int.min
        totalPages = Int.min
        resultCount = Int.min
    }

    init(currentPage: Int, totalPages: Int, results: [Movie]) {
        self.contents = results
        page = currentPage
        self.totalPages = totalPages
        resultCount = results.count
    }

    let page: Int
    let totalPages: Int
    let resultCount: Int

    private enum CodingKeys: String, CodingKey {
        case contents = "results"
        case page
        case totalPages = "total_pages"
        case resultCount = "total_results"
    }
}

class TMDBManager: Manager {
    var service: TMDBService = TMDBService()
    var memo: [Movie.ObjectId : Movie] = [:]
    typealias Value = Movie
    typealias Wrapper = AnyResponseWrapper<Movie>

    func search(for query: String, in page: Int = 1, callback: @escaping(Result<TMDBSearchResponseWrapper>) -> Void) {

        let parameters: [String : String] = [
            "page": "\(page)",
            "query": query,
            "include_adult": "false"
        ]

        let r = service.get(endpoint: "search/movie", query: parameters)
        service.sendRequest(request: r, callback: callback)
    }
    
}
