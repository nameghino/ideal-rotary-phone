//
//  BaseManager.swift
//  NetworkingStuff
//
//  Created by Nico Ameghino on 7/17/17.
//  Copyright © 2017 Nico Ameghino. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)

    var isError: Bool {
        switch self {
        case .success(_): return false
        case .failure(_): return true
        }
    }
}

protocol Resource {
    associatedtype ObjectId: Hashable

    static var path: String { get }
    var id: ObjectId { get }
    var resourcePath: String { get }
}

extension Resource {
    var resourcePath: String {
        return "\(Self.path)/\(id)"
    }
}

protocol ResponseWrapper: Codable {
    associatedtype Value where Value: Codable & Resource
    var contents: [Value] { get set }

    init()
    init(_ contents: [Value])
    init(_ value: Value)
}

extension ResponseWrapper {
    init(_ contents: [Value]) {
        self.init()
        self.contents = contents
    }

    init(_ value: Value) {
        self.init()
        self.contents = [value]
    }
}

enum ServiceError: Error {
    case noDataReceived
}

protocol Service {
    associatedtype ObjectId where ObjectId == Value.ObjectId
    associatedtype Value where Value: Codable & Resource

    var baseURL: URL { get set }

    // Convenience methods for automatically querying a REST api
    func getAll() -> URLRequest
    func get(id: ObjectId) -> URLRequest
    func put(object: Value) -> URLRequest
    func delete(object: Value) -> URLRequest
    func delete(id: ObjectId) -> URLRequest
    func post(object: Value) -> URLRequest

    // If more customization is required
    func get(endpoint: String, headers: [String : String]?, query: [String : String]?) -> URLRequest
    func delete(endpoint: String, headers: [String : String]?, query: [String : String]?) -> URLRequest
    func post(endpoint: String, data: Data?, headers: [String : String]?, query: [String : String]?) -> URLRequest
    func put(endpoint: String, data: Data?, headers: [String : String]?, query: [String : String]?) -> URLRequest

    func configure(request: inout URLRequest)

    func sendRequest<R: ResponseWrapper>(request: URLRequest, callback: @escaping (Result<R>) -> Void)
}

extension Service {

    //    init(url: String) {
    //        self.init(url: URL(string: url)!)
    //    }
    //
    //    init(url: URL) {
    //        self.init(url: url)
    //        self.baseURL = url
    //    }

    private func request(withMethod method: String, for value: Value) -> URLRequest {
        let encoder = JSONEncoder()
        return request(withMethod: method, path: value.resourcePath, body: try? encoder.encode(value))
    }

    private func request(withMethod method: String, path appendedPath: String, body: Data? = nil, headers: [String : String]? = nil, query: [String : String]? = nil) -> URLRequest {

        guard var components = URLComponents(url: baseURL.appendingPathComponent(appendedPath), resolvingAgainstBaseURL: false) else { fatalError() }
        if let query = query {
            components.queryItems = query.map { t in return URLQueryItem(name: t.key, value: t.value) }
        }

        guard let url = components.url else { fatalError() }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        if let headers = headers {
            for (field, value) in headers {
                request.addValue(value, forHTTPHeaderField: field)
            }
        }
        return request
    }

    func getAll() -> URLRequest {
        return request(withMethod: "GET", path: Value.path)
    }

    func get(id: ObjectId) -> URLRequest {
        return request(withMethod: "GET", path: Value.path + "/\(id)")
    }

    func put(object: Value) -> URLRequest {
        return request(withMethod: "PUT", for: object)
    }

    func delete(object: Value) -> URLRequest {
        return delete(id: object.id)
    }

    func delete(id: ObjectId) -> URLRequest {
        return request(withMethod: "DELETE", path: Value.path + "/\(id)")
    }

    func post(object: Value) -> URLRequest {
        return request(withMethod: "POST", for: object)
    }

    // Methods for custom service calls
    func get(endpoint: String, headers: [String : String]? = nil, query: [String : String]? = nil) -> URLRequest {
        return request(withMethod: "GET", path: endpoint, body: nil, headers: headers, query: query)
    }

    func delete(endpoint: String, headers: [String : String]? = nil, query: [String : String]? = nil) -> URLRequest {
        return request(withMethod: "DELETE", path: endpoint, body: nil, headers: headers, query: query)
    }

    func post(endpoint: String, data: Data? = nil, headers: [String : String]? = nil, query: [String : String]? = nil) -> URLRequest {
        return request(withMethod: "POST", path: endpoint, body: data, headers: headers, query: query)
    }

    func put(endpoint: String, data: Data? = nil, headers: [String : String]? = nil, query: [String : String]? = nil)-> URLRequest {
        return request(withMethod: "PUT", path: endpoint, body: data, headers: headers, query: query)
    }

    func configure(request: inout URLRequest) { }

    func sendRequest<R: ResponseWrapper>(request: URLRequest, callback: @escaping (Result<R>) -> Void) {
        var configuredRequest = request
        configure(request: &configuredRequest)
        print("[outbound] \(configuredRequest.url!)")
        let task = URLSession.shared.dataTask(with: configuredRequest) { (data, response, error) in
            guard error == nil else {
                callback(.failure(error!))
                return
            }
            guard let data = data else {
                callback(.failure(ServiceError.noDataReceived))
                return
            }

            do {
                let decoder = JSONDecoder()

                // base object is either:
                // - a dictionary, but that holds an R
                // If that fails spectacularly, then we're left with either:
                // -- a dictionary, perform decoding using R.Value
                // -- an array, perform decoding using an array of R.Value instead

                callback(.success(try decoder.decode(R.self, from: data)))
                return
            } catch {
                do {
                    let decoder = JSONDecoder()
                    var contents: [R.Value] = []
                    if let _ = try JSONSerialization.jsonObject(with: data, options: []) as? Array<Any> {
                        contents = try decoder.decode(Array<R.Value>.self, from: data)
                    } else {
                        let object = try decoder.decode(R.Value.self, from: data)
                        contents.append(object)
                    }

                    let wrapper = R(contents)
                    callback(.success(wrapper))
                } catch (let error) {
                    callback(.failure(error))
                }
            }
        }
        task.resume()
    }
}

protocol Manager {
    associatedtype ServiceOfValue: Service
    associatedtype ObjectId where ObjectId == ServiceOfValue.ObjectId
    associatedtype Value where Value == ServiceOfValue.Value
    associatedtype Wrapper where Wrapper: ResponseWrapper, Wrapper.Value == ServiceOfValue.Value

    var service: ServiceOfValue { get set }

    var memo: [ObjectId : Value] { get set }
    func create(object: Value, callback: @escaping(Result<Wrapper>) -> Void)
    func get(byId id: ObjectId, ignoreCache: Bool, callback: @escaping(Result<Wrapper>) -> Void)
    func getAll(ignoreCache: Bool, callback: @escaping(Result<Wrapper>) -> Void)
    func update(object: Value, callback: @escaping(Result<Wrapper>) -> Void)
    func delete(byId id: ObjectId, callback: @escaping(Result<Wrapper>) -> Void)
}

extension Manager {
    func create(object: Value, callback: @escaping(Result<Wrapper>) -> Void) {
        let r = service.post(object: object)
        service.sendRequest(request: r, callback: callback)
    }
    
    func get(byId id: ObjectId, ignoreCache: Bool = false, callback: @escaping(Result<Wrapper>) -> Void) {

        // get caching right here. -n
        /*
         if !ignoreCache, let o = memo[id] {
         callback(.success(o))
         return
         }
         */

        let r = service.get(id: id)
        service.sendRequest(request: r, callback: callback)
    }

    func getAll(ignoreCache: Bool = false, callback: @escaping(Result<Wrapper>) -> Void) {
        let r = service.getAll()
        service.sendRequest(request: r, callback: callback)
    }

    func update(object: Value, callback: @escaping(Result<Wrapper>) -> Void) {
    }

    func delete(byId id: ObjectId, callback: @escaping(Result<Wrapper>) -> Void) {
    }
}
