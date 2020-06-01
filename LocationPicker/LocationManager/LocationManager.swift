//
//  LoationManger.swift
//
//  Created by HB on 27/03/18.
//  Copyright © 2018 HB. All rights reserved.
//

import UIKit
import CoreLocation

let PIN_MAP_ICON_ONLINE = ""
let MAP_STATIC_IMAGE_SIZE = "320x320"
let MAP_STATIC_ZOOM_SIZE = "12"
let MAP_API_KEY = "AIzaSyDykdKL5I2LYqHuPVPI5w0bDeXA3NN9m-Q"

typealias LocaltionManagerStartCompletion = ((_ isLocationUpdateStated: Bool) -> Void)?
typealias LocaltionFeatchCompletion = ((_ isLocationUpdateStated: Bool) -> Void)?
class LocationManager: NSObject {

    //shared instance
    static let sharedInstance = LocationManager()
    
    //CLLocationManager instance
    var locationManager: CLLocationManager?
    
    //StartLocation CompletionHandler
    var startCompletionHandler: LocaltionManagerStartCompletion!
    
    //Fetch location CompletionHandler
    var locationFeatchCompletionHandler: LocaltionFeatchCompletion!
    
    //stores updated location
    var currentLocation: CLLocation?
    
    ///call this method to start location manager
    /// - parameters:
    ///     - success: True if location has been updated
    func startLocationManger(success:@escaping (_ isLocationUpdateStated: Bool) -> Void) {
        self.startCompletionHandler = success
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.requestWhenInUseAuthorization()
        self.locationManager?.startUpdatingLocation()
    }
    
    /// call this to fetch Lat Long for location
    func fetchCurrentLocationLatAndLong(completionHandler:@escaping (_ isLocationFeatched: Bool, _ latitude: Double, _ longitute: Double) -> Void) {
        if let currentLocation = self.currentLocation {
            completionHandler(true, currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
        } else {
            completionHandler(false, 0, 0)
        }
    }
    
    /// call this to fetch Lat Long for location
    func fetchCurrentLocation(completionHandler:@escaping (_ isLocationFeatched: Bool, _ latitude: Double, _ longitute: Double) -> Void) {
        if let currentLocation = self.currentLocation {
            completionHandler(true, currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
        } else {
            startLocationManger { (isUpdated) in
                if let currentLocation = self.currentLocation, isUpdated == true {
                    completionHandler(true, currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
                }
            }
        }
    }
    
    class func getGoogleSaticImage(_ latititue: Double, longitute: Double) ->  String {
        return "http://maps.googleapis.com/maps/api/staticmap?zoom=\(MAP_STATIC_ZOOM_SIZE)&size=\(MAP_STATIC_IMAGE_SIZE)&maptype=roadmap&markers=icon:\(PIN_MAP_ICON_ONLINE)|\(latititue),\(longitute)&key=\(MAP_API_KEY)"
    }
    
}

extension LocationManager : CLLocationManagerDelegate {
    
    /// Invoked when a new location is available. oldLocation may be nil if there is no previous location available.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations[0]
        if let handler = self.startCompletionHandler {
            handler?(true)
            self.startCompletionHandler =  nil
        }
    }
    
    ///Invoked when an error has occurred. Error types are defined in "CLError.h".
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let handler = self.startCompletionHandler {
            handler?(false)
            self.startCompletionHandler =  nil
        }
    }
    ///Invoked when the authorization status changes for this application.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied {
            
            print("authorizationStatus : User has explicitly denied authorization for this application, or location services are disabled in Settings")
        } else if status == .restricted {
            print("authorizationStatus: This application is not authorized to use location services.  Due to active restrictions on location services, the user cannot change this status, and may not have personally denied authorization")
        } else if status == .authorizedWhenInUse ||  status == .authorizedAlways {
            print("authorizationStatus: User has authorized this application to use location services")
        } else if status == .notDetermined {
            print("authorizationStatus: User has not yet made a choice with regards to this application")
        }
        
    }

}
