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

class AnyManager<O, S: Service>: Manager where O == S.Value {
    var memo: [O.ObjectId : O] = [:]
    var service: S

    typealias Wrapper = AnyResponseWrapper<O>

    static func createManager(for type: O.Type, with baseURL: String) -> AnyManager<O, AnyService<O>> {
        let s = AnyService<O>(url: baseURL)
        return AnyManager<O, AnyService<O>>(service: s)
    }

    init(service: S) {
        self.service = service
    }
}
