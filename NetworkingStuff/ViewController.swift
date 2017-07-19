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

    let toDoManager = AnyManager(service: AnyService<ToDoItem>(url: ViewController.placeholderURL))
    let postsManager = AnyManager(service: AnyService<Post>(url: ViewController.placeholderURL))



    override func viewDidLoad() {
        super.viewDidLoad()

        toDoManager.get(byId: 4) { result in
            switch result {
            case .success(let wrapper):
                print(wrapper.contents.first!.title)
            case .failure(let error):
                print(error)
            }
        }

        postsManager.get(byId: 7) { result in
            switch result {
            case .success(let wrapper):
                print(wrapper.contents.first!.title)
            case .failure(let error):
                print(error)
            }
        }


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

