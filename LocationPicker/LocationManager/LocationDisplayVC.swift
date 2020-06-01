//
//  LoationDisplayVC.swift
//
//  Created by HB on 31/03/18.
//  Copyright © 2018 HB. All rights reserved.
//

import UIKit
import MapKit

let CAR_IAMGE = "car"

class LocationDisplayVC: UIViewController {

    private enum LocationDisplay : String{
        case OpenInMaps         =   "Open in Maps"
        case OpenInGoogleMaps   =   "Open in Google Maps"
        case ChooseApplication  =   "Choose aplication"
        case Map                =   "Maps"
        case GoogleMap          =   "Google Maps"
        case TurnOnLocation     =   "Turn On Location"
    }
    
    var userLatitude: Double = 17.387140
    var userLongitude: Double = 78.491684
    var userName: String = ""
    var userId: String = ""
    var userLocationDescription: String = ""
    var isShowingCurrentUserLocation = true
    
    
    @IBOutlet var mapView: MKMapView?
    
    //MARK: - ViewController LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showDistanceFromCurrentLocation()
        
        self.title = self.userLocationDescription;
        let  cancelBtn = UIBarButtonItem.init(barButtonSystemItem: .cancel, target: self, action: #selector(canelClicked))
        self.navigationItem.leftBarButtonItem = cancelBtn
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    ///Dismiss ViewController
    @objc func canelClicked() {
        self.dismiss(animated: true, completion: nil)
    }
    //MARK: - set location
    ///sets location from give Latitude & Longitude
    func setLocation(latitude: Double, longitude long: Double, userName name: String, locationDescription locationDes: String) {
        self.userLatitude = latitude
        self.userLongitude = long
        self.userName = name
        self.userLocationDescription = locationDes
    }
    
    ///Map type selection [Standard, Hybrid, Satellite]
    @IBAction func mapTypeSegmentClicked(_ segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            self.mapView?.mapType = .standard
        } else if segment.selectedSegmentIndex == 1 {
            self.mapView?.mapType = .hybrid
        } else if segment.selectedSegmentIndex == 2 {
            self.mapView?.mapType = .satellite
        }
    }
    
    //MARK: - Open location BarButton clicked
    ///Open location in map on click
    @IBAction func openLocationClick(_ sender: UIBarButtonItem) {
        
        let locationActionSheet = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        //apple maps
        locationActionSheet.addAction(UIAlertAction.init(title: LocationDisplay.OpenInMaps.rawValue, style: .default, handler: { (alertAction) in
            if let url = URL(string: "maps://") {
                if (UIApplication.shared.canOpenURL(url)) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    print("Can't use maps://");
                }
            }
            
        }))
        
        //google maps
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
            locationActionSheet.addAction(UIAlertAction.init(title: LocationDisplay.OpenInGoogleMaps.rawValue, style: .default, handler: { (alertAction) in
                if let url = URL(string:
                    "comgooglemaps://?q=\(self.userLatitude),\(self.userLongitude)&center=\(self.userLatitude),\(self.userLongitude)&zoom=14") {
                    if (UIApplication.shared.canOpenURL(url)) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        print("Can't use maps://");
                    }
                }
            }))
        }
        
        
        //cancel
        locationActionSheet.addAction(UIAlertAction.init(title: LMConstant.Cancel, style: .cancel, handler: { (alertAction) in
            
        }))
        self.present(locationActionSheet, animated: true, completion: nil)
        
    }
   
    //MARK: - Direction button clicked
    ///Shows direction when clicked
     @objc func directionButtonClick() {
        
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
            let locationActionSheet = UIAlertController.init(title: LocationDisplay.ChooseApplication.rawValue, message: nil, preferredStyle: .actionSheet)
            //apple maps
            locationActionSheet.addAction(UIAlertAction.init(title: LocationDisplay.Map.rawValue, style: .default, handler: { (alertAction) in
                if let url = URL(string: "maps://") {
                    if (UIApplication.shared.canOpenURL(url)) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        print("Can't use maps://");
                    }
                }
            }))
            
            //google maps
            locationActionSheet.addAction(UIAlertAction.init(title: LocationDisplay.GoogleMap.rawValue, style: .default, handler: { (alertAction) in
                if let url = URL(string: "https://www.google.com/maps?daddr=\(self.userLatitude),\(self.userLongitude)&directionsmode=driving") {
                    if (UIApplication.shared.canOpenURL(url)) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        print("Can't use maps://");
                    }
                }
            }))
            
            //cancel
            locationActionSheet.addAction(UIAlertAction.init(title: LMConstant.Cancel, style: .cancel, handler: { (alertAction) in
                
            }))
            self.present(locationActionSheet, animated: true, completion: nil)
        } else {
            if let url = URL(string: "http://maps.apple.com/?daddr=\(self.userLatitude),\(self.userLongitude)&dirflg=d") {
                if (UIApplication.shared.canOpenURL(url)) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    print("Can't use maps://");
                }
            }
        }
        
    }
    //MARK: - Distance from current location
    ///shows distance of place from current location
    func showDistanceFromCurrentLocation() {
        LocationManager.sharedInstance.startLocationManger { (isEnabled) in
            LocationManager.sharedInstance.fetchCurrentLocationLatAndLong(completionHandler: { (isFecthed, currentLat, currentLong) in
                if isEnabled {
                    if self.isShowingCurrentUserLocation {
                        let sourceLocation = CLLocation.init(latitude: currentLat, longitude: currentLong)
                        let destinationLocation = CLLocation.init(latitude: Double(self.userLatitude), longitude: Double(self.userLongitude))
                        let distance = sourceLocation.distance(from: destinationLocation) / 1000
                        self.addAnnotaion(title: self.userName, subTitle: "\(self.getDistanceInProperFormat(distance: Int(distance))) km away")
                    } else {
                        self.addAnnotaion(title: self.userName, subTitle: "")
                    }
                } else {
                    self.addAnnotaion(title: self.userName, subTitle: "")
                    let alertView = UIAlertController.init(title: self.getLocationString(), message: nil, preferredStyle: .alert)
                    alertView.addAction(UIAlertAction.init(title: LMConstant.OK, style: .cancel, handler: nil))
                    self.present(alertView, animated: true, completion: nil)
                }
            })
            
        }
        
    }
    
    //MARK: - Get location string
    ///To get location in String format
    func getLocationString() -> String{
        var str = LocationDisplay.TurnOnLocation.rawValue
        str = str.replacingOccurrences(of: "%@", with: "APP_NAME", options: .literal, range: nil)
        return str
    }
    
    //MARK: - Get distance in proper format
    ///To get distance in String format
    func getDistanceInProperFormat(distance: Int) -> String {
        let numberformatter = NumberFormatter()
        numberformatter.alwaysShowsDecimalSeparator = false
        numberformatter.numberStyle = .decimal
        numberformatter.currencySymbol = ""
        numberformatter.locale = Locale.current
        return numberformatter.string(from: NSNumber(value: distance))!
    }

}

//MARK: - MKMapview delegate methods
extension LocationDisplayVC : MKMapViewDelegate {
    func addAnnotaion(title:  String = "", subTitle: String = "") {
        let coordination = CLLocationCoordinate2D(latitude: userLatitude,
                                                  longitude: userLongitude);
        let userAnnotation = PlaceAnnotation.init(coordinate: coordination, title: title, subtitle: subTitle)

        self.mapView?.addAnnotation(userAnnotation)
        self.mapView?.selectAnnotation(userAnnotation, animated: true)
        
        
        let region = MKCoordinateRegion(center: coordination, latitudinalMeters: 100, longitudinalMeters: 100)
        let adjustedRegion = self.mapView?.regionThatFits(region)
        self.mapView?.setRegion(adjustedRegion!, animated: false)
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil;
        }
        let identifier = "UserAnnotation"
        if annotation is PlaceAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
                
                let infoBtn = UIButton(type: .detailDisclosure)
                annotationView!.rightCalloutAccessoryView = infoBtn
                
                let directionButton = UIButton.init(frame: CGRect(x:-10, y:-12, width: 50, height:(annotationView?.frame.size.height)! + 12))
                directionButton.backgroundColor = UIColor.blue
                directionButton.setImage(UIImage.init(named: CAR_IAMGE), for: .normal)
                directionButton.addTarget(self, action:  #selector(directionButtonClick), for: .touchUpInside)
                annotationView!.leftCalloutAccessoryView = directionButton
                
            } else {
                annotationView!.annotation = annotation
            }
            return annotationView
        }
        return MKAnnotationView()
    }
}


