//
//  AnyStuff.swift
//  NetworkingStuff
//
//  Created by Nico Ameghino on 7/18/17.
//  Copyright © 2017 Nico Ameghino. All rights reserved.
//

import Foundation

class AnyResponseWrapper<O: Resource & Codable>: ResponseWrapper {
    var contents: [O] = []

    required init() { }
}

class AnyService<O: Resource & Codable>: Service {
    var baseURL: URL
    typealias ObjectId = O.ObjectId
    typealias Value = O
    required init(url: URL) {
        baseURL = url
    }

    convenience init(url: String) {
        self.init(url: URL(string: url)!)
    }
}

class AnyManager<O: Resource & Codable>: Manager {
    var memo: [O.ObjectId : O] = [:]
    var service: AnyService<O>

    typealias Wrapper = AnyResponseWrapper<O>

    static func createManager(for type: O.Type, with baseURL: String) -> AnyManager<O> {
        return AnyManager(service: AnyService<O>(url: baseURL))
    }

    init(service: AnyService<O>) {
        self.service = service
    }
}
