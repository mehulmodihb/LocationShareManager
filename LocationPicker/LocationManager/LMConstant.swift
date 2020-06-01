//
//  LMConstant.swift
//  LocationPicker
//
//  Created by hb on 26/05/20.
//  Copyright © 2020 hb. All rights reserved.
//

import UIKit

struct LMConstant {
     static let IS_IPHONE_X                                            = (UIScreen.main.bounds.size.height >= 812.0)
     static let kProfile                                        : String = "icon_user"//user_blank
     static let objAppDelegate                                  : AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
     static let API_KEY                                         : String = ""

     static let SEARCH_HISTORY                                  : String = "SEARCH_HISTORY"
     static let kRefreshMapViewNotification                     : String = "refreshMapView"
     static let kUpdateCurrentLocationNotification              : String = "updateCurrentLocation"
     static let kUpdateCurrentLocationStringNotification        : String = "updateCurrentLocationString"
     static let kFilterPlaceBySearchNotification                : String = "filterPlaceBySearch"
     static let kShareLocationNotification                      : String = "shareLocation"
     static let kOpenOrCloseSearchStatusNotification            : String = "openOrCloseSearchStatus"
     static let kMapDefault                                     : String = "ic_map_location"
     static let kMapPin                                         : String = "ic_img_map_pin_bg"
     static let kMapPin2                                        : String = "ic_map_pin"
     static let kMapDefault1                                    : String = "ic_location"
     static let kMapDefaultSelectedLoc                          : String = "btn_send_comment"
     static let kPlistFile                                      : String = "MapPully.plist"
     static let kLocationEnableMessage                          : String = "Turn On Location Services to get your current location may be used to search for nearby locations.";
     static let kSearching                                      : String = "Searching..."
     static let Cancel           = "Cancel"
     static let OK               = "OK"
     static let SendLocation             = "Send Location"
     static let GettingAddress           = "getting address..."
     static let NotNow           = "Not Now"
     static let Settings         = "Settings"

}
