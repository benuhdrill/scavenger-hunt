//
//  Task.swift
//  Scavenger-Hunt
//
//  Created by Charlie Hieger on 11/15/22.
//

import UIKit
import CoreLocation

class Task {
    let title: String
    let description: String
    var image: UIImage?
    var imageLocation: CLLocation?
    var isComplete: Bool {
        image != nil
    }

    init(title: String, description: String) {
        self.title = title
        self.description = description
    }

    func set(_ image: UIImage, with location: CLLocation) {
        self.image = image
        self.imageLocation = location
    }
}

extension Task {
    static var mockedTasks: [Task] {
        return [
            Task(title: "Your favorite local restaurant",
                 description: "Where is your favorite local restaurant located?"),
            Task(title: "Your favorite local cafe",
                 description: "Where do you drink coffee?"),
            Task(title: "Your go-to brunch place",
                 description: "Where is your favorite place to sit down and eat?"),
            Task(title: "Your favorite hiking spot",
                 description: "Where do you go to be one with nature?")
        ]
        
    }
}
