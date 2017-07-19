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

protocol Request {
    var body: Data? { get set }
}

extension URLRequest: Request {
    var body: Data? {
        get {
            guard let data = httpBody else { return nil }
            return data
        }

        set {
            guard let data = try? JSONSerialization.data(withJSONObject: body as Any, options: []) else { fatalError() }
            httpBody = data
        }
    }
}

protocol Resource {
    associatedtype ObjectId: Hashable

    static var Path: String { get }
    var id: ObjectId { get }
    var path: String { get }
}

extension Resource {
    var path: String {
        return "\(Self.Path)/\(id)"
    }
}

enum ServiceError: Error {
    case noDataReceived
}

protocol Service {
    associatedtype ObjectId where ObjectId == Value.ObjectId
    associatedtype Value where Value: Codable, Value: Resource

    var baseURL: URL { get set }

    func getAll() -> URLRequest
    func get(id: ObjectId) -> URLRequest
    func put(object: Value) -> URLRequest
    func delete(object: Value) -> URLRequest
    func delete(id: ObjectId) -> URLRequest
    func post(object: Value) -> URLRequest

    func sendRequest(request: URLRequest, callback: @escaping (Result<Value>) -> Void)
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
        return request(withMethod: method, path: value.path, body: try? encoder.encode(value))
    }

    private func request(withMethod method: String, path appendedPath: String, body: Data? = nil) -> URLRequest {
        let url = baseURL.appendingPathComponent(appendedPath)
        var request = URLRequest(url: url)
        request.httpMethod = method
        return request
    }

    func getAll() -> URLRequest {
        return request(withMethod: "GET", path: Value.Path)
    }

    func get(id: ObjectId) -> URLRequest {
        return request(withMethod: "GET", path: Value.Path + "/\(id)")
    }

    func put(object: Value) -> URLRequest {
        return request(withMethod: "PUT", for: object)
    }

    func delete(object: Value) -> URLRequest {
        return delete(id: object.id)
    }

    func delete(id: ObjectId) -> URLRequest {
        return request(withMethod: "DELETE", path: Value.Path + "/\(id)")
    }

    func post(object: Value) -> URLRequest {
        return request(withMethod: "POST", for: object)
    }

    func sendRequest(request: URLRequest, callback: @escaping (Result<Value>) -> Void) {
        print("[outbound] \(request.url!)")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
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
                let object = try decoder.decode(Value.self, from: data)
                callback(.success(object))
            } catch (let error) {
                callback(.failure(error))
            }
        }
        task.resume()
    }
}

protocol Manager {
    associatedtype ServiceOfValue: Service
    associatedtype ObjectId where ObjectId == ServiceOfValue.ObjectId
    associatedtype Value where Value == ServiceOfValue.Value

    var service: ServiceOfValue { get set }

    var memo: [ObjectId : Value] { get set }
    func create(object: Value, callback: @escaping(Result<Value>) -> Void)
    func get(byId id: ObjectId, ignoreCache: Bool, callback: @escaping(Result<Value>) -> Void)
    func update(object: Value, callback: @escaping(Result<Bool>) -> Void)
    func delete(byId id: ObjectId, callback: @escaping(Result<Bool>) -> Void)
}

extension Manager {
    func create(object: Value, callback: @escaping(Result<Value>) -> Void) {
        let r = service.post(object: object)
        service.sendRequest(request: r, callback: callback)
    }
    
    func get(byId id: ObjectId, ignoreCache: Bool = false, callback: @escaping(Result<Value>) -> Void) {

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

    func update(object: Value, callback: @escaping(Result<Bool>) -> Void) {
    }

    func delete(byId id: ObjectId, callback: @escaping(Result<Bool>) -> Void) {
    }
}
