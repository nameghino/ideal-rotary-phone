//
//  ViewController.swift
//  NetworkingStuff
//
//  Created by Nico Ameghino on 7/17/17.
//  Copyright © 2017 Nico Ameghino. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    static let placeholderURL = "https://jsonplaceholder.typicode.com"
    static let moviesURL = "https://api.themoviedb.org/3/"

    let toDoManager = AnyManager(service: AnyService<ToDoItem>(url: ViewController.placeholderURL))
    let postsManager = AnyManager(service: AnyService<Post>(url: ViewController.placeholderURL))
    let moviesManager = TMDBManager()


    override func viewDidLoad() {
        super.viewDidLoad()

//        toDoManager.get(byId: 4) { result in
//            switch result {
//            case .success(let wrapper):
//                print(wrapper.contents.first!.title)
//            case .failure(let error):
//                print(error)
//            }
//        }
//
//        postsManager.get(byId: 7) { result in
//            switch result {
//            case .success(let wrapper):
//                print(wrapper.contents.first!.title)
//            case .failure(let error):
//                print(error)
//            }
//        }
//
//        toDoManager.getAll { result in
//            switch result {
//            case .success(let response):
//                print("got \(response.contents.count) items to do")
//            case .failure(let error):
//                print("error: \(error)")
//            }
//        }
//
//        moviesManager.get(byId: 76341, ignoreCache: true) { (result) in
//            switch result {
//            case .success(let w):
//                print("got \(w.contents.first!.title)")
//            case .failure(let e):
//                print("error: \(e)")
//            }
//        }
//
        moviesManager.search(for: "back to the future") { (result: Result<TMDBSearchResponseWrapper>) in
            switch result {
            case .success(let w):
                print(w)
            case .failure(let e):
                print(e)
            }
        }


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

