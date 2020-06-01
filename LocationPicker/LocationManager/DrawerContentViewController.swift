//
//  DrawerContentViewController.swift
//
//  Created by HB on 30/03/18.
//  Copyright © 2018 Hidden Brains. All rights reserved.
//

import UIKit
import GooglePlaces
import Kingfisher
import CoreLocation


public enum LocationSend : String {
    case SendThisLocation       =   "Send This Location"
    case SendCurrentLocation    =   "Send Your Current Location"
    case NoNearByPlaces         =   "No nearby places found"
}

class DrawerContentViewController: UIViewController
{
    
    @IBOutlet private weak var  tblListView     : UITableView!
    @IBOutlet private weak var viewGripper      : UIView!
    
    fileprivate var placesClient                : GMSPlacesClient!
    fileprivate var listOfPlaces                : NSMutableArray!
    fileprivate var currentLocation             : CLLocation!
    fileprivate var defaultMessage              : String = LocationSend.SendCurrentLocation.rawValue
    fileprivate var currentLocationTitle        : String = ""
    fileprivate var selectedLocationTitle       : String = ""
    fileprivate var currentLocationDict         : NSDictionary?
    fileprivate var selectedLocationDict        : NSDictionary?
    public var isCurrentLocation                : Bool = false;
    
    // MARK: ViewController LifeCycle methods
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setUpLayout();
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated);
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - Initial layout setup
    private func setUpLayout()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(self.filterPlaceBySearch(_:)), name: NSNotification.Name(rawValue: LMConstant.kFilterPlaceBySearchNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateCurrentLocation(_:)), name: NSNotification.Name(rawValue: LMConstant.kUpdateCurrentLocationNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateCurrentLocationString(_:)), name: NSNotification.Name(rawValue: LMConstant.kUpdateCurrentLocationStringNotification), object: nil)
        self.viewGripper.layer.cornerRadius = 2.5
        self.placesClient = GMSPlacesClient.shared();
        self.listOfPlaces = NSMutableArray();
        self.tblListView.rowHeight = UITableView.automaticDimension
        self.tblListView.estimatedRowHeight = 60
        self.tblListView.reloadData();
    }
    
    //MARK: - Filter place by search
    @objc private func filterPlaceBySearch(_ notification : NSNotification)
    {
        if let arr = notification.object as? NSMutableArray {
            self.listOfPlaces = arr
            DispatchQueue.main.async {
                self.tblListView.reloadData();
            }
        }
    }
    
    //MARK: - Update current location
    @objc private func updateCurrentLocation(_ notification : NSNotification)
    {
        if let localCurrentLocation = notification.object as? CLLocation {
            self.currentLocation = localCurrentLocation
        }
        LocationShareManager.performGoogleReverseGeocodeAPI(location: self.currentLocation!, completion: { (placeDictionary, message) in
            if message == ""
            {
                self.currentLocationTitle = placeDictionary?.value(forKey: kPlaceFullAddress) as? String ?? ""
            }
            else
            {
                print(message);
                self.currentLocationTitle = ""
            }
            self.currentLocationDict  = placeDictionary
            
            DispatchQueue.main.async {
                self.tblListView.setContentOffset(CGPoint.zero, animated: false);
                self.tblListView.reloadData()
            }
        })
    }
    
    /// Updates current location String
    @objc private func updateCurrentLocationString(_ notification : NSNotification)
    {
        self.selectedLocationDict  = notification.object as? NSDictionary
        if self.selectedLocationDict != nil
        {
            self.selectedLocationTitle = self.selectedLocationDict?.value(forKey: kPlaceFullAddress) as? String ?? ""
        }
        else
        {
            self.selectedLocationTitle = ""
        }
        
        DispatchQueue.main.async {
            self.tblListView.setContentOffset(CGPoint.zero, animated: false);
            self.tblListView.reloadData()
        }
    }
}

//MARK: - Pulley Drawer delegate methods
extension DrawerContentViewController : PulleyDrawerViewControllerDelegate
{
    func drawerPositionDidChange(drawer: LocationShareViewController) {
         if drawer.drawerPosition == .collapsed
         {
            self.defaultMessage = LocationSend.SendThisLocation.rawValue
            self.tblListView.isScrollEnabled = false;
         }
         else
         {
            self.defaultMessage = LocationSend.SendCurrentLocation.rawValue
            self.tblListView.isScrollEnabled = true;
         }
        self.tblListView.reloadData()
        self.tblListView.setContentOffset(CGPoint.zero, animated: true);        
    }
    func collapsedDrawerHeight() -> CGFloat
    {
        return COLLAPSE_HEIGHT
    }
    
    func partialRevealDrawerHeight() -> CGFloat
    {
        return REVEAL_HEIGHT
    }
    
    func supportedDrawerPositions() -> [PulleyPosition]
    {
        return [.collapsed, .partiallyRevealed, .closed]
    }
}

//MARK: - Tableview Delegate methods
extension DrawerContentViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0 ? 20.0 : 1);
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0
        {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width , height: 20.0));
            view.backgroundColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0);
            
            let label = UILabel(frame: CGRect(x: 15, y: 0, width: view.bounds.size.width - 15, height: view.bounds.size.height));
            label.backgroundColor = .clear;
            label.font = UIFont.systemFont(ofSize: 10.0) //UIFont(name: FontName.NunitoSansRegular, size: 10.0);
            label.textColor = .black;
            label.text = "NEARYBY PLACES"
            
            view.addSubview(label);
            return view;
        }
        else
        {
            return UIView();
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0
        {
            return 1;
        }
        else
        {
            return (self.listOfPlaces.count == 0 ? 1 : self.listOfPlaces.count);
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "drawerContentCell")
            if let imgv: UIImageView = cell?.viewWithTag(10001) as? UIImageView {
                if self.defaultMessage == LocationSend.SendThisLocation.rawValue
                {
                    imgv.image = UIImage(named: LMConstant.kMapDefaultSelectedLoc)
                }
                else if self.defaultMessage == LocationSend.SendCurrentLocation.rawValue
                {
                    imgv.image = UIImage(named: LMConstant.kMapDefault1)
                }
                else{}
            }
            else{}
            
            if let lblTitle: UILabel = cell?.viewWithTag(10002) as? UILabel {
                lblTitle.text = "\(self.defaultMessage.capitalized)"
            }
            else{}
            
            if let lblDesc: UILabel = cell?.viewWithTag(10003) as? UILabel {
                if self.defaultMessage == LocationSend.SendThisLocation.rawValue
                {
                    lblDesc.text = "\(self.selectedLocationTitle)"
                }
                else if self.defaultMessage == LocationSend.SendCurrentLocation.rawValue
                {
                    lblDesc.text = "\(self.currentLocationTitle)"
                }
                else{}
            }
            else{}
            
            return cell!;
        }
        else
        {
            if self.listOfPlaces.count == 0
            {
                var cell = tableView.dequeueReusableCell(withIdentifier: "progressIdentifier")
                if cell == nil
                {
                    cell = UITableViewCell(style: .default, reuseIdentifier: "progressIdentifier");
                    cell?.backgroundColor = .clear;
                    cell?.contentView.backgroundColor = .clear;
                    cell?.textLabel?.font = UIFont.systemFont(ofSize: 14.0)
                }
                if LocationShareManager.isEnableServices
                {
                    let indicatorView = UIActivityIndicatorView(style: .medium);
                    indicatorView.hidesWhenStopped = true;
                    cell?.accessoryView = indicatorView;
                    indicatorView.startAnimating();
                    cell?.textLabel?.textAlignment = .left;
                    cell?.textLabel?.text = LMConstant.kSearching.capitalized
                }
                else
                {
                    cell?.textLabel?.textAlignment = .center;
                    cell?.textLabel?.text = LocationSend.NoNearByPlaces.rawValue
                    cell?.accessoryView = nil;
                }
                return cell!;
            }
            else
            {
                let objPlace = self.listOfPlaces[indexPath.row] as! NSDictionary
                let cell = tableView.dequeueReusableCell(withIdentifier: "placeIdentifer")
                
                if let imgv: UIImageView = cell?.viewWithTag(10001) as? UIImageView {
                    imgv.image = UIImage(named: LMConstant.kMapDefault);
                    imgv.layer.cornerRadius = 20.0
                }
                else{}
                
                if let lblTitle: UILabel = cell?.viewWithTag(10002) as? UILabel {
                    lblTitle.text = (objPlace.value(forKey: kPlaceName) as? String ?? "").capitalized;
                }
                else{}
                
                if let lblDesc: UILabel = cell?.viewWithTag(10003) as? UILabel {
                    lblDesc.text = (objPlace.value(forKey: kPlaceAddress) as? String ?? "").capitalized;
                }
                else{}
                
                return cell!;
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        if indexPath.section == 0
        {
            if self.defaultMessage == LocationSend.SendThisLocation.rawValue
            {
                self.isCurrentLocation = false;
                if self.selectedLocationDict != nil
                {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kShareLocationNotification), object: self.selectedLocationDict);
                }
                else{}
            }
            else if self.defaultMessage == LocationSend.SendCurrentLocation.rawValue
            {
                self.isCurrentLocation = true;
                if self.currentLocationDict != nil
                {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kShareLocationNotification), object: self.currentLocationDict);
                }
                else{}
            }
            else{}
        }
        else
        {
            self.isCurrentLocation = false;
            let objPlace = self.listOfPlaces[indexPath.row] as! NSDictionary
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: LMConstant.kShareLocationNotification), object: objPlace);
        }
    }
}


