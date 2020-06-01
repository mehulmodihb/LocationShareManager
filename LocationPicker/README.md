# LocationShareManager

LocationShareManager is easy integrated library for sharing current location or selected location along with latitude, longitude, place name and address. You can easily get address from latitude and longitude using ```GoogleReverseGeoCode``` and ```AppleReverseGeoCode```.

## Installation

You just need to drag and drop ```LocationManager``` folder to your project.
In Info.plist file add permission for locations.

```
<key>NSLocationWhenInUseUsageDescription</key>
<string>$(PRODUCT_NAME) require your current location to share</string>
```

## Usage

### • Show Location Picker :

```swift
LocationShareManager.showLocationShareController(parentController: self) { (obj, isCurrentLocation, isCancel) in
    print(obj)
    print("\(obj["name"] ?? "")\n\n\(obj["vicinity"] ?? "")\n\(obj["lat"] ?? ""), \(obj["lng"] ?? "")")
}
```
### • Get Current Location :

```swift
LocationManager().fetchCurrentLocation { (success, lat, lng) in
    print(lat, lng)
    print("\(lat), \(lng)")
}
```

### • Apple Reverse GeoCode :

```swift
LocationShareManager.getReverceGeoCodeAddress(location: location) { (obj, msg) in
    if let obj = obj {
        print(obj)
        print("\(obj["name"] ?? "")\n\n\(obj["vicinity"] ?? "")\n\(obj["lat"] ?? ""), \(obj["lng"] ?? "")")
    }
}
```

### • Google Reverse GeoCode :

```swift
LocationShareManager.performGoogleReverseGeocodeAPI(location: location) { (obj, msg) in
    if let obj = obj {
        print(obj)
        print("\(obj["name"] ?? "")\n\n\(obj["vicinity"] ?? "")\n\(obj["lat"] ?? ""), \(obj["lng"] ?? "")")
    }
}
```

# License


```
Copyright 2020

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
