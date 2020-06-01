//
//  PrimaryMapViewController.swift
//
//  Created by HB on 30/03/18.
//  Copyright © 2018 Hidden Brains. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GooglePlaces

let COLLAPSE_HEIGHT     : CGFloat = 106.0
let REVEAL_HEIGHT       : CGFloat = 265.0

class PrimaryMapViewController: UIViewController
{
    //MARK: - Outlets
    @IBOutlet private weak var mapView      : MKMapView!
    @IBOutlet private weak var tblListView  : UITableView!
    @IBOutlet private weak var controlView  : UIView!
    @IBOutlet private weak var btnCurrentLoc: UIButton!
    @IBOutlet public var searchBar          : UISearchBar!
    
    @IBOutlet private var viewMap           : UIView!
    @IBOutlet private var viewMapType       : UIView!
    @IBOutlet private var viewSearch        : UIView!
    @IBOutlet private var viewInner         : UIView!
    @IBOutlet private var btnClose          : UIButton!
    @IBOutlet private var segmentControl    : UISegmentedControl!
    
    @IBOutlet private var pinImageView      : UIImageView!
    
    //MARK: - Variables
    fileprivate var searchString            : String = "";
    fileprivate var listOfSearchedPlaces    : NSMutableArray!
    fileprivate var listOfPlaces            : NSMutableArray!
    fileprivate var placeDictionary         : NSDictionary!
    
    fileprivate var placesClient            : GMSPlacesClient!
    fileprivate var updatedLocation         : CLLocation!
    fileprivate var navigationHeight        : CGFloat = LMConstant.IS_IPHONE_X ? 88.0 : 64.0
    fileprivate var oldCollapseHieght       : CGFloat = COLLAPSE_HEIGHT;
    fileprivate var spinner                 : UIActivityIndicatorView?
    fileprivate var centerAnnotation        : PlaceAnnotation!;
    fileprivate var isPartiallyRevealed     : Bool = true;
    fileprivate var centerPin               :MKAnnotationView!;
    fileprivate var mapChangedFromUserInteraction:  Bool = false
    
    
    
    // MARK: ViewController LifeCycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setUpLayout();
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated);
        self.showMapCurrentLocation();
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.mapView.removeFromSuperview()
        self.mapView = nil
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    //MARK: - Setup layout
    private func setUpLayout()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshMapView(_:)), name: NSNotification.Name(rawValue: LMConstant.kRefreshMapViewNotification), object: nil)
        
        self.controlView.layer.cornerRadius = 10.0
        self.controlView.layer.masksToBounds = true;
        
        self.viewInner.layer.cornerRadius = 4.0
        self.viewInner.layer.masksToBounds = true;
        
        self.btnClose.layer.cornerRadius = self.btnClose.frame.size.width/2;
        self.btnClose.layer.masksToBounds = true;
        
        self.mapView.showsUserLocation = true
        self.mapView.mapType = MKMapType(rawValue: 1)!
        
        self.pinImageView.isHidden = true;
        self.listOfSearchedPlaces = NSMutableArray();
        self.listOfPlaces = NSMutableArray();
        self.placesClient = GMSPlacesClient.shared();
    }
    //MARK: - Show current location map
    ///Shows current location map
    private func showMapCurrentLocation()
    {
        LocationManager.sharedInstance.startLocationManger { (isEnabled) in
            LocationShareManager.isEnableServices = isEnabled;
            if isEnabled == false
            {
                self.showConfirmationAlert(title: LMConstant.kLocationEnableMessage, message: nil, cancelTitle: LMConstant.NotNow, okTitle: LMConstant.Settings, completion: { (buttonIndex) in
                    if(buttonIndex == 1) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                })
                if self.listOfPlaces.count != 0
                {
                    self.listOfPlaces = [];
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kFilterPlaceBySearchNotification), object: []);
                }else{}
            }
            else
            {
                LocationManager.sharedInstance.fetchCurrentLocationLatAndLong(completionHandler: { (isSuccess, lat, long) in
                    if isSuccess
                    {
                        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                        if CLLocationCoordinate2DIsValid(coordinate)
                        {
                            let userLocation = CLLocation(latitude: lat, longitude: long)
                            self.updateCoordinateRegion(location: userLocation);
                            self.fetchNearByLocation(location: userLocation)
                        }
                        else{}
                    }
                    else{}
                })
            }
        }
        
    }
    //MARK: - update coordnate region
    ///to change region according to the location provided
    /// - parameters:
    ///     - location: location to update coordinate region
    private func updateCoordinateRegion(location : CLLocation)
    {
        if self.mapView == nil{
            return
        }
        self.updatedLocation = location;
        self.mapView.centerCoordinate = location.coordinate
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kUpdateCurrentLocationNotification), object: location);
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000);
        DispatchQueue.main.async {
            self.mapView.showsUserLocation = true
            self.mapView.setRegion(region, animated: false);
        }
    }
    
    private var prevDrawPostion : PulleyPosition = .partiallyRevealed;
    
    //MARK: - Show search history view
    ///To show search history view
    private func showSearchHistoryView()
    {
        if let history = LocationShareManager.getSearchHistory(), history.count != 0
        {
            self.listOfSearchedPlaces = history
        }
        else{}
        self.tblListView.reloadData();
        if let locationShareVC = self.parent as? LocationShareViewController
        {
            self.prevDrawPostion = locationShareVC.drawerPosition;
            UIView.animate(withDuration: 0.3, animations: {
                self.viewSearch.alpha = 1.0;
            }, completion: { (finished) in
                locationShareVC.setDrawerPosition(position: .closed, animated: false);
            })
            
        }
        else{}
    }
    
    //MARK: - Close search history view
    ///To close search history view
    /// - parameters:
    ///     - isCollapsed: Whether to collapse historyview or not
    private func closeSearchHistoryView(isCollapsed : Bool = true)
    {
        self.view.endEditing(true);
        if let locationShareVC = self.parent as? LocationShareViewController
        {
            locationShareVC.setDrawerPosition(position: self.prevDrawPostion, animated: false);
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    self.viewSearch.alpha = 0.0;
                }, completion: { (finished) in
                    
                })
            }
        }
        else{}
    }
    
    //MARK: - Show map type view
    private func showMapTypeView()
    {
        self.updateSegmentControl(rawValue: Int(self.mapView.mapType.rawValue));
        if let locationShareVC = self.parent as? LocationShareViewController
        {
            self.prevDrawPostion = locationShareVC.drawerPosition;
            locationShareVC.setDrawerPosition(position: .closed, animated: true);
            UIView.animate(withDuration: 0.5) {
                self.viewMapType.alpha = 1.0;
                self.controlView.alpha = 0.0
            }
        }
        else{}
    }
    
    //MARK: - Close map type view
    private func closeMapTypeView()
    {
        if let locationShareVC = self.parent as? LocationShareViewController
        {
            locationShareVC.setDrawerPosition(position: self.prevDrawPostion, animated: true);
            UIView.animate(withDuration: 0.3) {
                self.viewMapType.alpha = 0.0;
                self.controlView.alpha = 1.0
            }
        }
        else{}
    }
    //MARK: - Update segment control
    ///To update segment control
    /// - parameters:
    ///     - rawValue: An integer value for selected segment
    private func updateSegmentControl(rawValue : Int)
    {
        self.segmentControl.selectedSegmentIndex = (rawValue == 0 ? 0 : (rawValue == 1 ? 2 : 1));
        self.mapView.mapType = MKMapType(rawValue: UInt(rawValue))!
    }
    //MARK: - Refresh mapview
    @objc private func refreshMapView(_ notification : Notification)
    {
        self.searchBar.text = "";
        self.searchString = "";
        self.showMapCurrentLocation();
    }
    
    // MARK: IBAction methods
    @IBAction private func btnLocationPressed(_ sender : UIButton)
    {
        self.btnCurrentLoc.tintColor = UIColor.blue
        self.searchBar.text = "";
        self.searchString = "";
        self.showMapCurrentLocation();
    }
    @IBAction private func btnInfoPressed(_ sender : UIButton)
    {
        self.showMapTypeView();
    }
    @IBAction private func btnClosePressed(_ sender : UIButton)
    {
        self.closeMapTypeView();
    }
    //MARK: - Segment value changed
    @IBAction private func segmentValueChanged(_ sender : UISegmentedControl)
    {
        let rawValue = (sender.selectedSegmentIndex == 0 ? 0 : (sender.selectedSegmentIndex == 1 ? 2 : 1))
        self.updateSegmentControl(rawValue: rawValue);
    }
    
    //MARK: Search-MapView methods
    private func updateCurrentPlaceByReverseGeoCode(location : CLLocation)
    {
        if self.centerAnnotation != nil
        {
            self.centerAnnotation.coordinate = self.mapView.centerCoordinate
            self.centerAnnotation.tag = 999;
            self.mapView.addAnnotation(self.centerAnnotation);
        }
        else
        {
            self.centerAnnotation = PlaceAnnotation(coordinate: self.mapView.centerCoordinate, title: LocationSend.SendThisLocation.rawValue, subtitle: LMConstant.GettingAddress)
            self.centerAnnotation.tag = 999;
            self.centerAnnotation.coordinate = self.mapView.centerCoordinate
            self.mapView.addAnnotation(self.centerAnnotation!)
        }
        self.pinImageView.isHidden = true
        self.mapView.selectAnnotation(self.centerAnnotation, animated: true);
        self.view.isUserInteractionEnabled = false
        
        LocationShareManager.performGoogleReverseGeocodeAPI(location: location, completion: { (placeDictionary, message) in
            if message == ""
            {
                print("FETCHED SELECTED LOCATION : \(placeDictionary!)");
                DispatchQueue.main.async {
                    if self.centerAnnotation != nil
                    {
                        self.centerAnnotation.coordinate = self.mapView.centerCoordinate
                        self.centerAnnotation.title = LocationSend.SendThisLocation.rawValue
                        self.centerAnnotation.subtitle = placeDictionary?.value(forKey: kPlaceFullAddress) as? String ?? ""
                        self.centerAnnotation.tag = 999;
                        self.centerPin?.rightCalloutAccessoryView = nil
                    }
                    else {
                        self.centerAnnotation = PlaceAnnotation(coordinate: self.mapView.centerCoordinate, title: LocationSend.SendThisLocation.rawValue, subtitle: placeDictionary?.value(forKey: kPlaceFullAddress) as? String ?? "")
                        self.centerAnnotation.tag = 999;
                        if !self.isPartiallyRevealed
                        {
                            self.mapView.addAnnotation(self.centerAnnotation);
                        }
                        else{}
                    }
                }

                self.placeDictionary = placeDictionary;
                if placeDictionary != nil
                {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kUpdateCurrentLocationStringNotification), object: placeDictionary);
                }
                else{}
            }
            else
            {
                print(message)
            }
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true
            }
        })
    }
    private func fetchNearByLocation(location : CLLocation) {
        self.updateSearchHistoryInBackground(location: location);//BACKGROUND UPDATING SEARCH HISTORY
        self.fetchPlaceFromLocation(coordinate: location.coordinate, completion: { (placesArray) in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kOpenOrCloseSearchStatusNotification), object: true);
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kFilterPlaceBySearchNotification), object: placesArray);
            DispatchQueue.main.async {
                self.updateMapWithAnnotations();
            }
        })
    }
    
    private func updateSearchHistoryInBackground(location : CLLocation)
    {
        if let history = LocationShareManager.getSearchHistory(), history.count != 0
        {
            self.listOfSearchedPlaces = history
            DispatchQueue.main.async {
                self.tblListView.reloadData();
            }
            return;
        }
        else
        {}
        
        if let placeName = self.placeDictionary?.value(forKey: kPlaceName) as? String, !placeName.isEmpty
        {
            LocationShareManager.autoCompleteSearch(searchText: placeName, completion: { (placesArray, message) in
                if placesArray.count != 0
                {
                    self.listOfSearchedPlaces = placesArray;
                }
                else
                {
                    self.listOfSearchedPlaces = NSMutableArray();
                }
                DispatchQueue.main.async {
                    self.tblListView.reloadData();
                }
            })
        }
        else
        {}
    }
    private func fetchPlaceFromLocation(coordinate : CLLocationCoordinate2D, completion : ((_ placesArray : NSMutableArray) -> Void)?)
    {
        LocationShareManager.performGooglePlacesAPI(coordinate: coordinate, searchText: "", completion: { (placesArray, message) in
            if placesArray.count == 0
            {
                print(message);
            }
            else{}
            self.listOfPlaces = placesArray;
            completion!(placesArray);
        })
    }
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view: UIView = self.mapView.subviews[0]
        for recognizer in view.gestureRecognizers! {
            if (recognizer.state == UIGestureRecognizer.State.began || recognizer.state == UIGestureRecognizer.State.ended) {
                return true
            }
        }
        return false
    }
}

//MARK: - MKMapview delegate methods
extension PrimaryMapViewController : MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation
        {
            return nil;
        }
        else
        {
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "iPinView")
            if annotation is PlaceAnnotation
            {
                let objAnnotation = annotation as! PlaceAnnotation
                let image = (objAnnotation.tag == 999 ? UIImage(named : LMConstant.kMapPin) : UIImage(named : LMConstant.kMapPin2));
                if pinView == nil
                {
                    pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: "iPinView");
                    pinView?.centerOffset = CGPoint(x: 0, y: -image!.size.height/2)
                    pinView?.canShowCallout = true;
                    pinView?.isDraggable = false;
                }
                if objAnnotation.tag == 999
                {
                    self.centerAnnotation = objAnnotation;
                    self.spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
                    self.spinner?.color = UIColor(red: 0, green: 159.0/255.0, blue: 218.0/255.0, alpha: 1.0)
                    pinView?.image = image
                    
                    pinView?.annotation = objAnnotation;
                    pinView?.centerOffset = CGPoint(x: 0, y: -image!.size.height/2)
                    if objAnnotation.subtitle != nil && objAnnotation.subtitle! == LMConstant.GettingAddress
                    {
                        pinView?.rightCalloutAccessoryView = self.spinner
                        self.spinner?.startAnimating()
                        self.spinner?.isHidden = false
                        print("spinner \(self.spinner!)")
                    }
                    else
                    {
                        pinView?.rightCalloutAccessoryView = nil
                    }
                    self.centerPin = pinView
                }
                else
                {
                    pinView?.image = image
                    pinView?.rightCalloutAccessoryView = nil
                    pinView?.isDraggable = false;
                    pinView?.annotation = objAnnotation;
                }
            }
            else{}
            return pinView!;
        }
    }
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let annotation = view.annotation as? PlaceAnnotation, annotation.tag == 999
        {
            view.rightCalloutAccessoryView = nil;
            self.mapView.selectAnnotation(view.annotation!, animated: false)
        }else{}
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? PlaceAnnotation, annotation.tag == 999
        {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapCallOut))
            view.addGestureRecognizer(tap)
        } else{}
    }
    @objc private func didTapCallOut()
    {
        if self.placeDictionary != nil {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kShareLocationNotification), object: self.placeDictionary!);
        }
    }
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.mapChangedFromUserInteraction = self.mapViewRegionDidChangeFromUserInteraction()
        print("self.isPartiallyRevealed==\(self.isPartiallyRevealed)")
        if self.isPartiallyRevealed == false {
            if self.centerAnnotation != nil
            {
                self.mapView.removeAnnotation(self.centerAnnotation!);
                self.centerAnnotation = nil
            }else{}
            self.spinner?.isHidden = false
            self.spinner?.startAnimating()
            self.pinImageView.isHidden = false;
            var frame = self.pinImageView.frame
            frame.origin.y -= 10
            UIView.animate(withDuration: 0.2) {
                self.pinImageView.frame = frame
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        if self.mapChangedFromUserInteraction {
            self.mapChangedFromUserInteraction = false
            self.btnCurrentLoc.tintColor = UIColor.darkGray
        } else {
            self.btnCurrentLoc.tintColor = UIColor.blue
        }
        if self.isPartiallyRevealed == false {
            let location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude);
            self.updatedLocation = location;
            
            if self.centerAnnotation != nil
            {
                self.centerAnnotation.coordinate = mapView.centerCoordinate;
                self.centerAnnotation.title = LocationSend.SendThisLocation.rawValue
                self.centerAnnotation.subtitle = LMConstant.GettingAddress
                self.centerAnnotation.tag = 999;
            }
            else
            {
                self.centerAnnotation = PlaceAnnotation(coordinate: mapView.centerCoordinate, title: LocationSend.SendThisLocation.rawValue, subtitle: LMConstant.GettingAddress)
                self.centerAnnotation.tag = 999;
            }
            
            var frame = self.pinImageView.frame
            frame.origin.y += 10
            
            UIView.animate(withDuration: 0.2, animations: {
                self.pinImageView.frame = frame
            }) { (finished) in
                if finished {
                    if !self.isPartiallyRevealed
                    {
                        self.updateCurrentPlaceByReverseGeoCode(location: location);
                    }
                    else{}
                }
            }
        }
        
    }
    
    fileprivate func updateMapWithAnnotations()
    {
        guard self.listOfPlaces.count != 0 else {
            return;
        }
        
        let annotations = self.mapView.annotations.filter { (annotation) -> Bool in
            !(annotation is MKUserLocation) && !((annotation as? PlaceAnnotation)?.tag == 999)
        }
        
        if annotations.count != 0
        {
            self.mapView.removeAnnotations(annotations);
        }else{}
        
        if let locationShareVC = self.parent as? LocationShareViewController
        {
            if locationShareVC.drawerPosition == .partiallyRevealed
            {
                return;
            }
            else
            {}
        }
        else{}
        
        var annotationsArray : [PlaceAnnotation] = [];
        for objPlace in self.listOfPlaces
        {
            let objDict = objPlace as! NSDictionary
            let coordinate = CLLocationCoordinate2D(latitude: objDict.value(forKey: kPlaceLatitude) as! CLLocationDegrees, longitude: objDict.value(forKey: kPlaceLongitude) as! CLLocationDegrees)
            let annotation = PlaceAnnotation(coordinate: coordinate, title: objDict.value(forKey: kPlaceName) as? String ?? "", subtitle: objDict.value(forKey: kPlaceAddress) as? String ?? "")
            annotationsArray.append(annotation);
        }
        DispatchQueue.main.async {
            self.mapView.addAnnotations(annotationsArray);
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
            self.showAllAnnotations(anmiated: true)
        }
    }
    
    fileprivate func showAllAnnotations(anmiated : Bool)
    {
        var zoomRect : MKMapRect = MKMapRect.null;
        for annotation in self.mapView.annotations
        {
            if annotation is MKUserLocation
            {
                continue;
            }
            let annotationPoint = MKMapPoint(annotation.coordinate);
            let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.1, height: 0.1);
            zoomRect = zoomRect.union(pointRect);
        }
        self.mapView.setVisibleMapRect(zoomRect, animated: anmiated);
       
    }
}

//MARK: - Tableview delegate methods
extension PrimaryMapViewController : UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension;
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listOfSearchedPlaces.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let objPlace = self.listOfSearchedPlaces[indexPath.row] as! NSDictionary
        var cell = tableView.dequeueReusableCell(withIdentifier: "iSearch");
        if cell == nil
        {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "iSearch");
            cell?.selectionStyle = .none;
            cell?.backgroundColor = .clear;
            cell?.contentView.backgroundColor = .clear;
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 14.0);
            cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: 10.0);
        }
        cell?.textLabel?.text = (objPlace.value(forKey: kPlaceName) as? String ?? "").capitalized;
        cell?.detailTextLabel?.text = (objPlace.value(forKey: kPlaceAddress) as? String ?? "").capitalized;
        return cell!;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        let objPlace = self.listOfSearchedPlaces[indexPath.row] as! NSDictionary
        LocationShareManager.saveSearchHistory(placeDict: self.listOfSearchedPlaces[indexPath.row] as! NSDictionary);
        
        GMSPlacesClient.shared().lookUpPlaceID(objPlace.value(forKey: kPlaceId) as! String) { (gmsplace, error) in
            if error == nil
            {
                self.fetchPlaceFromLocation(coordinate: (gmsplace?.coordinate)!) { (placesArray) in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kOpenOrCloseSearchStatusNotification), object: true);
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kFilterPlaceBySearchNotification), object: placesArray);
                    DispatchQueue.main.async {
                        self.updateMapWithAnnotations();
                        self.searchBar.text = objPlace.value(forKey: kPlaceName) as? String ?? "";
                        self.searchBar.showsCancelButton = false;
                        self.closeSearchHistoryView(isCollapsed: false);
                    }
                }
            }
            else
            {
                print("No place found: \(error?.localizedDescription ?? "")");
            }
        }
    }
}

//MARK: - Searchbar delegate methods
extension PrimaryMapViewController  : UISearchBarDelegate
{
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true;
        self.showSearchHistoryView();
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kOpenOrCloseSearchStatusNotification), object: false);
        return true;
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchString = searchText;
        LocationShareManager.autoCompleteSearch(searchText: searchText) { (placesArray, message) in
            if placesArray.count != 0
            {
                self.listOfSearchedPlaces = placesArray;
            }
            else
            {
                if let history = LocationShareManager.getSearchHistory(), history.count != 0
                {
                    self.listOfSearchedPlaces = history;
                }
                else
                {
                    self.listOfSearchedPlaces = NSMutableArray();
                }
            }
            DispatchQueue.main.async {
                self.tblListView.reloadData();
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false;
        searchBar.text = "";
        self.searchString = "";
        self.closeSearchHistoryView();
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kOpenOrCloseSearchStatusNotification), object: true);
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true);
    }
}
//MARK: - PulleyPrimaryContentControllerDelegate protocol methods
extension PrimaryMapViewController : PulleyPrimaryContentControllerDelegate
{
    func drawerPositionDidChange(drawer: LocationShareViewController)
    {
        print("PRIMARY : drawerPositionDidChange: \(self.view.bounds)")
        self.isPartiallyRevealed = (drawer.drawerPosition == .partiallyRevealed)
        
        if self.isPartiallyRevealed
        {
            if self.centerAnnotation != nil
            {
                self.mapView.removeAnnotation(self.centerAnnotation);
                self.mapView.setCenter(self.mapView.userLocation.coordinate, animated: true);
            }else{}
            self.pinImageView.isHidden = true;
        }
        else if self.prevDrawPostion == .partiallyRevealed && self.viewMapType.alpha == 1.0
        {
            if self.centerAnnotation != nil
            {
                self.mapView.removeAnnotation(self.centerAnnotation);
            }else{}
            self.pinImageView.isHidden = true;
        }
        else
        {
            if self.mapView.userLocation.location != nil && (self.viewMapType.alpha == 0.0 && self.viewSearch.alpha == 0.0)
            {
                self.mapView.setCenter(self.mapView.userLocation.location!.coordinate, animated: false)
                self.updateCurrentPlaceByReverseGeoCode(location: self.mapView.userLocation.location!)
            }
            self.pinImageView.isHidden = false;
        }
        
        if self.viewMapType.alpha == 0.0 && self.viewSearch.alpha == 0.0
        {
            self.updateMapWithAnnotations()
            var frame = pinImageView.frame;
            frame.origin.x = (self.mapView.bounds.size.width - frame.size.width)/2;
            frame.origin.y = (self.mapView.bounds.size.height - frame.size.height)/2 - frame.size.height/2;
            DispatchQueue.main.async {
                self.pinImageView.frame = frame;
            }
        }
        else
        {}
    }
    
    func makeUIAdjustmentsForFullscreen(progress: CGFloat)
    {
        
    }
    
    func drawerChangedDistanceFromBottom(drawer: LocationShareViewController, distance: CGFloat)
    {
        print("drawerChangedDistanceFromBottom: \(distance)")
    }
}

//MARK: - Place Annotation
class PlaceAnnotation: NSObject, MKAnnotation
{
    @objc dynamic var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @objc dynamic var title: String?
    @objc dynamic var url: URL?
    @objc dynamic var subtitle: String?
    @objc dynamic var tag : Int = 0;
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        super.init()
    }
}
