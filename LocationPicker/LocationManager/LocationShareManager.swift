//
//  LocationShareManager.swift
//  LocationShareDemo
//
//  Created by HB on 30/03/18.
//  Copyright © 2018 Hidden Brains. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import GooglePlaces

let kPlaceId                    : String = "place_id"
let kPlaceAddress               : String = "vicinity"
let kPlaceFullAddress           : String = "formattedAddress"
let kPlaceFormattedAddress      : String = "formatted_address"
let kPlaceName                  : String = "name"
let kPlaceLatitude              : String = "lat";
let kPlaceLongitude             : String = "lng";
let kPlaceSataticImage          : String = "static_image";
let kPlaceIcon                  : String = "icon";

typealias ShareLocationFetchCompletion = ((_ location : NSDictionary,_ isCurrentLocation : Bool,_ isCancel : Bool) -> Void)?

class LocationShareManager
{
    public static var shareLocationCompletionHandler        : ShareLocationFetchCompletion?
    public static var isEnableServices                      : Bool = false;
    
    /// Show location share controller
    /// - parameters:
    ///     - parentController: Parent controller of LocationShareController
    ///     - completionHandler: completion block
    ///     - location: Location dictionary
    ///     - isCurrentLocation: Is Location current location?
    class func showLocationShareController(parentController : UIViewController, completionHandler: @escaping (_ location : NSDictionary,_ isCurrentLocation : Bool,_ isCancel : Bool) -> Void)
    {
        GMSPlacesClient.provideAPIKey(LMConstant.API_KEY);
        self.shareLocationCompletionHandler = completionHandler;
        let storyboard = UIStoryboard(name: "Location", bundle: nil);
        let viewController = storyboard.instantiateViewController(withIdentifier: "iLocationController") as! LocationShareViewController;
        viewController.initialDrawerPosition = .partiallyRevealed
        let navigationController = UINavigationController(rootViewController: viewController);
        navigationController.navigationBar.isTranslucent = false;
        parentController.present(navigationController, animated: true, completion: nil);
    }
    
    //MARK: - Save Search History
    ///Saves search history
    
    ///- parameters:
    ///     - placeDict: Dictionary of places searched
    class func saveSearchHistory(placeDict : NSDictionary)
    {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
        let plistPath = documentPath.appending("/\(LMConstant.kPlistFile)");
        
        if var history = NSMutableArray(contentsOfFile: plistPath) as? [NSDictionary], history.count != 0
        {
            if let index = history.firstIndex(where: { (dictPlace) -> Bool in
                ((dictPlace.value(forKey: kPlaceName) as! String).lowercased() == (placeDict.value(forKey: kPlaceName) as! String).lowercased())
            })
            {
                print("Already in History : \(history[index])");
                return;
            }
            else
            {
                history.append(placeDict);
                let arraryOfHistory : NSMutableArray = (history as NSArray).mutableCopy() as! NSMutableArray
                arraryOfHistory.write(toFile: plistPath, atomically: false);
            }
        }
        else
        {
            let array = NSMutableArray();
            array.add(placeDict);
            array.write(toFile: plistPath, atomically: false);
        }
    }
    
    //MARK: - get search history
    ///To get search history
    class func getSearchHistory() -> NSMutableArray?
    {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
        let plistPath = documentPath.appending("/\(LMConstant.kPlistFile)");
        if let history = NSMutableArray(contentsOfFile: plistPath)
        {
            print("Reversed : \(history.reversed())");
            return (history.reversed() as NSArray).mutableCopy() as? NSMutableArray
        }
        return NSMutableArray();
    }
    //MARK: - Google Place API
    ///Performs google place API to search for places
    class func performGooglePlacesAPI(coordinate : CLLocationCoordinate2D?, searchText : String? = "", completion : ((_ placesArray : NSMutableArray, _ message : String) -> Void)?)
    {
        let latitude = String(coordinate?.latitude ?? 0.0);
        let longitude = String(coordinate?.longitude ?? 0.0);
        let url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=500&type=establishment,point_of_interest&keyword=\(searchText!)&key=\(LMConstant.API_KEY)";
        print(url);
        var request = URLRequest(url: URL(string: url)!);
        request.httpMethod = "GET";
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let session = URLSession.shared;
        let task = session.dataTask(with: request) { (data, response, error) in
            let arrayOfPlaces = NSMutableArray();
            if error == nil
            {
                do
                {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary
                    {
                        if let results = jsonObject["results"] as? NSArray
                        {
                            for object in results
                            {
                                let objPlace = object as! NSDictionary
                                let placeDict = NSMutableDictionary();
                                
                                if let geometry = objPlace.value(forKey: "geometry") as? NSDictionary
                                {
                                    if let loc = geometry.value(forKey: "location") as? NSDictionary
                                    {
                                        placeDict.setValue(loc[kPlaceLatitude], forKey: kPlaceLatitude)
                                        placeDict.setValue(loc[kPlaceLongitude], forKey: kPlaceLongitude)
                                    }
                                    else
                                    {
                                        placeDict.setValue(0.0, forKey: kPlaceLatitude)
                                        placeDict.setValue(0.0, forKey: kPlaceLongitude)
                                    }
                                }
                                else
                                {
                                    placeDict.setValue(0.0, forKey: kPlaceLatitude)
                                    placeDict.setValue(0.0, forKey: kPlaceLongitude)
                                }
                                placeDict.setValue(objPlace[kPlaceId], forKey: kPlaceId);
                                placeDict.setValue(objPlace[kPlaceIcon], forKey: kPlaceIcon);
                                placeDict.setValue(objPlace[kPlaceName], forKey: kPlaceName);
                                placeDict.setValue(objPlace[kPlaceAddress], forKey: kPlaceAddress);
                                arrayOfPlaces.add(placeDict);
                            }
                            completion!(arrayOfPlaces, "success");
                        }
                        else
                        {
                            completion!(arrayOfPlaces, "No Places found");
                        }
                    }
                    else
                    {
                        print("CANNOT PARSE RESULTS");
                    }
                }
                catch let expError
                {
                    print("PARSING ERROR : \(expError.localizedDescription)");
                    completion!(arrayOfPlaces, expError.localizedDescription)
                }
            }
            else
            {
                completion!(arrayOfPlaces, (error?.localizedDescription)!)
            }
        }
        task.resume();
    }
    
    //MARK: - Autocomplete search
    class func autoCompleteSearch(searchText : String, completion : ((_ placesArray : NSMutableArray, _ message : String) -> Void)?)
    {
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        GMSPlacesClient.shared().findAutocompletePredictions(fromQuery: searchText, filter: filter, sessionToken: nil) { (predictionResults, error) in
            let listOfLocations = NSMutableArray();
            if error != nil
            {
                completion!(listOfLocations, (error?.localizedDescription)!);
            }
            else if let predictions = predictionResults, predictions.count != 0
            {
                for result in predictions
                {
                    let placeDict = NSMutableDictionary();
                    placeDict.setValue(result.attributedPrimaryText.string, forKey: kPlaceName);
                    placeDict.setValue(result.attributedSecondaryText?.string ?? "", forKey: kPlaceAddress);
                    placeDict.setValue(result.placeID, forKey: kPlaceId)
                    listOfLocations.add(placeDict);
                }
                completion!(listOfLocations, "success");
            }
            else
            {
                completion!(listOfLocations, "No results found");
            }
        }
    }
    //MARK: - Google Geocode API
    class func performGoogleReverseGeocodeAPI(location : CLLocation?, completion : ((_ placeDictionary : NSDictionary?, _ message : String) -> Void)?)
    {
        let latitude = String(location?.coordinate.latitude ?? 0.0);
        let longitude = String(location?.coordinate.longitude ?? 0.0);
        let url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&key=\(LMConstant.API_KEY)";//&location_type=ROOFTOP
        print(url);
        var request = URLRequest(url: URL(string: url)!);
        request.httpMethod = "GET";
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let session = URLSession.shared;
        let task = session.dataTask(with: request) { (data, response, error) in
            if error == nil
            {
                do
                {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary
                    {
                        if let results = jsonObject["results"] as? NSArray, results.count != 0
                        {
                            let objPlace = results[0] as! NSDictionary
                            
                            let dictPlaceInfo = NSMutableDictionary();
                            if let geometry = objPlace.value(forKey: "geometry") as? NSDictionary
                            {
                                if let loc = geometry.value(forKey: "location") as? NSDictionary
                                {
                                    dictPlaceInfo.setValue(loc[kPlaceLatitude], forKey: kPlaceLatitude)
                                    dictPlaceInfo.setValue(loc[kPlaceLongitude], forKey: kPlaceLongitude)
                                }
                                else
                                {
                                    dictPlaceInfo.setValue(0.0, forKey: kPlaceLatitude)
                                    dictPlaceInfo.setValue(0.0, forKey: kPlaceLongitude)
                                }
                            }
                            else
                            {
                                dictPlaceInfo.setValue(0.0, forKey: kPlaceLatitude)
                                dictPlaceInfo.setValue(0.0, forKey: kPlaceLongitude)
                            }
                            var formatAddress = objPlace[kPlaceFormattedAddress] as! String
                            let name = formatAddress.components(separatedBy: ", ").first
                            let address = (formatAddress.components(separatedBy: ", ").dropFirst()).joined(separator: ", ");
                            if name?.lowercased() == "unnamed road" {
                                formatAddress = address;
                            }
                            dictPlaceInfo.setValue(name, forKey: kPlaceName);//IMPORTANT
                            dictPlaceInfo.setValue(address, forKey: kPlaceAddress);
                            dictPlaceInfo.setValue(formatAddress, forKey: kPlaceFullAddress);
                            dictPlaceInfo.setValue(objPlace[kPlaceId], forKey: kPlaceId);
                            completion!(dictPlaceInfo, "");
                            
                        }
                        else
                        {
                            completion!(nil, "No Places found");
                        }
                    }
                    else
                    {
                        print("CANNOT PARSE RESULTS");
                    }
                }
                catch let expError
                {
                    print("PARSING ERROR : \(expError.localizedDescription)");
                    completion!(nil, expError.localizedDescription)
                }
            }
            else
            {
                completion!(nil, (error?.localizedDescription)!)
            }
        }
        task.resume();
    }
    
    //MARK: - Get Reverse Geocode Address
    class func getReverceGeoCodeAddress(location : CLLocation, completion : ((_ placeDictionary : NSDictionary?, _ message : String) -> Void)?)
    {
        let geoCoder = CLGeocoder();
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placeMarks, error) in
            if error == nil
            {
                if let marks = placeMarks, marks.count != 0
                {
                    let placemark = marks[0];
                    if let formattedAddressArray = placemark.addressDictionary!["FormattedAddressLines"] as? [String], formattedAddressArray.count != 0
                    {
                        let name = formattedAddressArray[0];
                        let address = (formattedAddressArray.dropFirst()).joined(separator: ", ");
                        
                        let dictPlace = NSMutableDictionary();
                        dictPlace.setValue(name, forKey: kPlaceName);
                        dictPlace.setValue(address, forKey: kPlaceAddress);
                        dictPlace.setValue(formattedAddressArray.joined(separator: ", "), forKey: kPlaceFullAddress);
                        dictPlace.setValue(location.coordinate.latitude, forKey: kPlaceLatitude)
                        dictPlace.setValue(location.coordinate.longitude, forKey: kPlaceLongitude)
                        completion!(dictPlace, "");
                    }
                    else
                    {
                        print("No record found");
                        completion!(nil, "No record found")
                    }
                }
                else
                {
                    print("No record found");
                    completion!(nil, "No record found")
                }
            }
            else
            {
                print("Error while reverseGeocodeLocation: \(error?.localizedDescription ?? "No record found")");
                completion!(nil, error?.localizedDescription ?? "No record found")
            }
        })
    }
}
