//
//  ViewController.swift
//  LocationPicker
//
//  Created by hb on 26/05/20.
//  Copyright © 2020 hb. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var lblResponse: UILabel!
    @IBOutlet weak var option: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        lblResponse.numberOfLines = 0
    }

    @IBAction func showLocationPicker() {
        LocationShareManager.showLocationShareController(parentController: self) { (obj, isCurrentLocation, isCancel) in
            print(obj)
            self.lblResponse.text = "\(obj["name"] ?? "")\n\n\(obj["vicinity"] ?? "")\n\(obj["lat"] ?? ""), \(obj["lng"] ?? "")"
        }
    }
    
    @IBAction func getCurrentLocation() {
        LocationManager().fetchCurrentLocation { (success, lat, lng) in
            print(lat, lng)
            self.lblResponse.text = "\(lat), \(lng)"
            self.fetchAddress(location: CLLocation(latitude: lat, longitude: lng))
        }
    }
    
    func fetchAddress(location: CLLocation) {
        if option.selectedSegmentIndex == 0 {
            LocationShareManager.getReverceGeoCodeAddress(location: location) { (obj, msg) in
                if let obj = obj {
                    print(obj)
                    self.lblResponse.text = "\(obj["name"] ?? "")\n\n\(obj["vicinity"] ?? "")\n\(obj["lat"] ?? ""), \(obj["lng"] ?? "")"
                }
            }
        } else {
            LocationShareManager.performGoogleReverseGeocodeAPI(location: location) { (obj, msg) in
                if let obj = obj {
                    print(obj)
                    DispatchQueue.main.async {
                        self.lblResponse.text = "\(obj["name"] ?? "")\n\n\(obj["vicinity"] ?? "")\n\(obj["lat"] ?? ""), \(obj["lng"] ?? "")"
                    }
                }
            }
        }
    }

}

