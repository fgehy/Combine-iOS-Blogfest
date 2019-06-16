//
//  ViewController.swift
//  Combine Framework - iOS Blogfest
//
//  Created by Fabrice Gehy on 6/15/19.
//  Copyright © 2019 Fabrice Gehy. All rights reserved.
//

import UIKit
import Combine

class ViewController: UIViewController {

    var timer: Timer?
    var runCount = 0
    var cityArray = ["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver", "Richmond"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(createPublisherOne), userInfo: nil, repeats: true)
    }
    
    @objc func createPublisherOne() {

        let newCityArray = ["Honolulu", "San Diego", "New Orleans", "Seattle", "LA"]

        let newCityPublisher = Publishers.Sequence<[String], Error>(sequence: [newCityArray[runCount]])
        
        let dallasPublisher = Publishers.Sequence<[[String]], Error>(sequence: [["Dallas"]])
        
        let bostonPublisher = Publishers.Sequence<[[String]], Error>(sequence: [["Boston"]])
        
        let jacksonvillePublisher = Publishers.Sequence<[[String]], Error>(sequence: [["Jacksonville"]])
        
        let allPublishers = Publishers.Sequence<[[String]], Error>(sequence: [cityArray])
            .combineLatest(dallasPublisher) { (existingPub, newCityPub) in
                return existingPub + newCityPub
            }
            .combineLatest(jacksonvillePublisher, bostonPublisher, { (existingPub, newPub1, newPub2) in
                return existingPub + newPub1 + newPub2
            })
            .zip(newCityPublisher)
        
        allPublishers.sink { (cities) in
            self.addToCityArray(city: cities.1)
            print(cities)
        }
        
        
        checkTimer()
    }
    
    func createPublisherTwo() {
        
            let mergePub = Publishers.Sequence<[String], Error>(sequence: ["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver", "Richmond"])
            .append("Miami")
                
            /* Output:
             Atlanta
             Columbus
             DC Metro
             Philly
             Charlotte
             Denver
             Richmond
             Miami
            */
            
            .contains("Miami")
            /* Output:
            true
            */
        
        mergePub.sink { (cities) in
            print(cities)
        }
    }
    
    func addToCityArray(city: String) {
        
        cityArray.append(city)
    }
    
    func checkTimer() {
        if runCount < 4 {
            runCount += 1
        } else {
            timer?.invalidate()
        }
    }
}

