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
        
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(createPublisher), userInfo: nil, repeats: true)
    }
    
    func addToCityArray(city: String) {
        
        cityArray.append(city)
    }
    
    @objc func createPublisher() {

        let newCityArray = ["Honolulu", "San Diego", "New Orleans", "Seattle", "LA"]

        let newCityPublisher = Publishers.Sequence<[String], Error>(sequence: [newCityArray[runCount]])
        
        let dallasPublisher = Publishers.Sequence<[[String]], Error>(sequence: [["Dallas"]])
        
        let bostonPublisher = Publishers.Sequence<[[String]], Error>(sequence: [["Boston"]])
        
        let jacksonvillePublisher = Publishers.Sequence<[[String]], Error>(sequence: [["Jacksonville"]])
        
        let mainPublisher = Publishers.Sequence<[[String]], Error>(sequence: [cityArray])
            .combineLatest(dallasPublisher) { (existingPub, newCityPub) in
                return existingPub + newCityPub
            }
            .combineLatest(jacksonvillePublisher, bostonPublisher, { (existingPub, newPub1, newPub2) in
                return existingPub + newPub1 + newPub2
            })
            .zip(newCityPublisher)
        
        mainPublisher.sink { (cities) in
            self.addToCityArray(city: cities.1)
            print(cities)
        }
        
        
        
        let mergePub2 = Publishers.Sequence<[String], Error>(sequence: ["Atlanta", "Columbus ", "DC Metro", "Philly", "Charlotte", "Denver", "Richmond"])
            .append("Miami")
            /*Atlanta
             Columbus
             DC Metro
             Philly
             Charlotte
             Denver
             Richmond
             Miami*/
            
            .contains("Miami")
            //true
        
//        mergePub2.sink { (cities) in
//            print(cities)
//        }
        
        checkTimer()
    }
    
    func checkTimer() {
        if runCount < 4 {
            runCount += 1
        } else {
            timer?.invalidate()
        }
    }
}

