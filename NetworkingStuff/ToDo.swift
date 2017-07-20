//
//  ToDoManager.swift
//  NetworkingStuff
//
//  Created by Nico Ameghino on 7/18/17.
//  Copyright © 2017 Nico Ameghino. All rights reserved.
//

import Foundation

/*
 {
 "userId": 1,
 "id": 1,
 "title": "delectus aut autem",
 "completed": false
 }
*/

struct ToDoItem: Codable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

extension ToDoItem: Resource {

    static var path: String = "todos"

    var resourcePath: String {
        return "\(path)/\(id)"
    }
}
