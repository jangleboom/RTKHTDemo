/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

// TODO: distinguish between multiple devices: nehotspotconfigurationmanager could check the wifi client hostname of the connected device "rtkrover123456" and connect the to same device over BLE. The nehotspotconfigurationmanager is available with paid apple devoloper license only.

import UIKit
import CoreBluetooth
import MapKit
import CoreLocation
import os


@available(iOS 14.0, *)
class MainViewController: UIViewController
{
 

  @IBOutlet weak var distanceLabel: UILabel! 
  @IBOutlet weak var deviceNameLabelValue: UILabel!
  @IBOutlet weak var deviceNameLabel: UILabel!
  @IBOutlet weak var yawLabelValue: UILabel!
  @IBOutlet weak var pitchLabelValue: UILabel!
  @IBOutlet weak var yawLabel: UILabel!
  @IBOutlet weak var pitchLabel: UILabel!
  @IBOutlet weak var linAccelZLabel: UILabel!
  @IBOutlet weak var linAccelZLabelValue: UILabel!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var distanceLabelValue: UILabel!
  
  var locationManager: CLLocationManager!
  let headTrackerServiceCBUUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
  let headTrackerCharacteristicCBUUID = CBUUID(string: "713D0002-503E-4C75-BA94-3148F18D941E")
  let realTimeKinematicsCharacteristicCBUUID = CBUUID(string: "713D0004-503E-4C75-BA94-3148F18D941E")
  let rtkAccuracyCharacteristicCBUUID = CBUUID(string: "713D0006-503E-4C75-BA94-3148F18D941E")
  let deviceNamePrefix = "rtkrover"
  var centralManager: CBCentralManager!
  var headTrackerPeripheral: CBPeripheral!
  var headtrackerDeviceName = ""
  var rtkPositionAnnotation = MKPointAnnotation()
  let regionRadius: CLLocationDistance = 25
  let delimiter = ","
  let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "RTKHTDemo", category: "testing")
  var firstRunnedFlag: Bool = false

/**
 Do NOT delete!
 For later: Function to get the IP address of devices in  lan
 */
//  func getIPAddress() -> String {
//      var address: String?
//      var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
//      if getifaddrs(&ifaddr) == 0 {
//          var ptr = ifaddr
//          while ptr != nil {
//              defer { ptr = ptr?.pointee.ifa_next }
//
//              guard let interface = ptr?.pointee else { return "" }
//              let addrFamily = interface.ifa_addr.pointee.sa_family
//              if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
//
//                  // wifi = ["en0"]
//                  // wired = ["en2", "en3", "en4"]
//                  // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
//
//                  let name: String = String(cString: (interface.ifa_name))
//                  if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
//                      var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
//                      getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
//                      address = String(cString: hostname)
//                    print("hostname", hostname)
//                  }
//              }
//          }
//          freeifaddrs(ifaddr)
//      }
//      return address ?? ""
//  }
  
  @objc func didTapMapView(_ sender: UITapGestureRecognizer)
  {
    self.view.endEditing(true) // If the keyboard is popped up, dismiss it
    
    if locationManager.location != nil
    {
      centerMapOnLocation(location: locationManager.location!)
    }
  }
  
  func setupUI()
  {
    navigationController?.navigationBar.barTintColor = UIColor.green
    yawLabelValue.backgroundColor = UIColor.white
    yawLabelValue.textColor = UIColor.blue
    pitchLabelValue.backgroundColor = UIColor.white
    pitchLabelValue.textColor = UIColor.blue
    linAccelZLabelValue.backgroundColor = UIColor.white
    linAccelZLabelValue.textColor = UIColor.blue
    deviceNameLabel.textColor = UIColor.black
    yawLabel.textColor = UIColor.black
    pitchLabel.textColor = UIColor.black
    linAccelZLabel.textColor = UIColor.black
    distanceLabel.textColor = UIColor.black
    distanceLabelValue.backgroundColor = UIColor.white
    distanceLabelValue.textColor = UIColor.blue
  }
  
  func setUIDefaultValues()
  {
    yawLabelValue.text = "---"
    deviceNameLabelValue.text = "Disconnected"
    pitchLabelValue.text = "---"
    linAccelZLabelValue.text = "---"
    distanceLabelValue.text = "---"
    deviceNameLabel.text = "Device"
    yawLabel.text = "Yaw"
    pitchLabel.text = "Pitch"
    linAccelZLabel.text = "LinAccelZ"
    distanceLabel.text = "∆s RTK, iOS"
    rtkPositionAnnotation.title = "RTK"
    rtkPositionAnnotation.subtitle = ""
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    setupUI()
    setUIDefaultValues()
    
    locationManager = CLLocationManager()
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.requestWhenInUseAuthorization()
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.startUpdatingLocation()
    locationManager.startUpdatingHeading()
    /* this option will use the most power from your device, kCLLocationAccuracyBestForNavigation is intended to be used for automobile navigation, not our use case */
      
    mapView.mapType = MKMapType.satellite//Flyover
    mapView.isRotateEnabled = false
    //mapView.setUserTrackingMode(.followWithHeading, animated: false)
    mapView.showsUserLocation = true
    // Initialize Tap Gesture Recognizer
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapMapView(_:)))
    mapView.addGestureRecognizer(tapGestureRecognizer)
    

    centralManager = CBCentralManager(delegate: self, queue: nil)
    deviceNameLabelValue.backgroundColor = UIColor.white
    deviceNameLabelValue.textColor = UIColor.blue
//    deviceNameLabelValue.borderStyle = .none
//    print("wifi: \(String(describing: getIPAddress()))") // Do NOT delete
  }
 
  func centerMapOnLocation(location: CLLocation)
  {
    let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                              latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
      mapView.setRegion(coordinateRegion, animated: false)
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation] )
  {
    if let location = locations.first
    {
      let latitude = location.coordinate.latitude
      let longitude = location.coordinate.longitude
      
      // Handle location update
      var message: String = "accuracyAuthorization: "
      switch locationManager!.accuracyAuthorization
      {
      case .fullAccuracy:
        message = "Full Accuracy"
        
      case .reducedAccuracy:
        message = "Reduced Accuracy"
        
      @unknown default:
        message = "Unknown Precise Location..."
      }
      
      message += String(format: ", User location Lat: %.9f, Lon: %.9f", latitude, longitude)
      logger.log("iOS location %{public}@ \(#function), desiredAccuracy: \(String(describing: self.locationManager.desiredAccuracy)), \(message)")
      
      if  self.firstRunnedFlag == false
      {
        centerMapOnLocation(location: location) // Zoom to user location
        self.firstRunnedFlag = true
      }
    }
  }

  func onHeadtrackingReceived(_ orientation: String)
  {
    let token = orientation.components(separatedBy: delimiter)
    if  token.count == 3
    {
      let yaw = String(token[0])
      let pitch = String(token[1])
      let linAccelZ = ((token[2] as NSString).floatValue < 0) ? String(token[2]) : (" " + String(token[2]))
      
      
      yawLabelValue.text = "\(yaw)°"
      pitchLabelValue.text = "\(pitch)°"
      linAccelZLabelValue.text = "\(linAccelZ) mg"
      logger.log("yaw: \(yaw), pitch: \(pitch), \(linAccelZ)")
    }
    else
    {
      print("onHeadtrackingReceived: Data format does not fit (\(token.count)!=3)")
    }
  }

override func didReceiveMemoryWarning()
  {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
    print("didReceiveMemoryWarning")
  }
  
func onRealtimeKinematicsReceived(_ location: String)
  {
    let token = location.components(separatedBy: delimiter)
    
    if  token.count == 4
    { // Sending high precision values (1/mm)
      let lat = (token[0] as NSString).doubleValue * pow(10, -7)
      let latHp = (token[1] as NSString).doubleValue * pow(10, -9)
      let latitude = lat + latHp
      let lon = (token[2] as NSString).doubleValue * pow(10, -7)
      let lonHp = (token[3] as NSString).doubleValue * pow(10, -9)
      let longitude = lon + lonHp
      let locationCoord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      let location = CLLocation(latitude: locationCoord.latitude, longitude: locationCoord.longitude)
      rtkPositionAnnotation.coordinate = CLLocationCoordinate2D(latitude: locationCoord.latitude, longitude: locationCoord.longitude)
      mapView.addAnnotation(rtkPositionAnnotation)
      
      if locationManager.location != nil
      {
        let distance = location.distance(from: locationManager.location!)
        self.distanceLabelValue.text = String(format: "%.3f m", distance)
//        logger.log("Distance iOS location to rtk location %{public}@ \(#function), \(String(format: "%.3f m", distance))")
      }
      
//      let message = String(format: "User location Lat.: %.9f, Lon.: %.9f", latitude, longitude)
//      logger.log("RTK location %{public}@ \(#function), \(message)")
    }
    else
    {
      mapView.removeAnnotation(rtkPositionAnnotation)
      print("onRealtimeKinematicsReceived: Data format does not fit (\(token.count)!=4)")
    }
  }

func onRTKAccuracyReceived(_ accuracy: String)
  {
    let rtkHAccuracy = (accuracy as NSString).integerValue
//    logger.log("\(#function) %{public}@ RTK accuracy: \(rtkHAccuracy) mm")
    rtkPositionAnnotation.subtitle = "hAccuracy: " + String(rtkHAccuracy) + " mm"
  }

}

@available(iOS 14.0, *)
extension MainViewController: CBCentralManagerDelegate
{
  func centralManagerDidUpdateState(_ central: CBCentralManager)
  {
    switch central.state
    {
      case .unknown:
      print("central.state is .unknown")
      setUIDefaultValues()
      deviceNameLabelValue.text = "BLE unknown"
      mapView.removeAnnotation(rtkPositionAnnotation)
      break
      
    case .resetting:
      print("central.state is .resetting")
      setUIDefaultValues()
      deviceNameLabelValue.text = "BLE resetting"
      mapView.removeAnnotation(rtkPositionAnnotation)
      break
      
    case .unsupported:
      print("central.state is .unsupported")
      deviceNameLabelValue.text = "BLE unsupported"
      setUIDefaultValues()
      break
      
    case .unauthorized:
      print("central.state is .unauthorized")
      setUIDefaultValues()
      deviceNameLabelValue.text = "BLE unauthorized"
      break
      
    case .poweredOff:
      print("central.state is .poweredOff")
      setUIDefaultValues()
      deviceNameLabelValue.text = "BLE powered off"
      mapView.removeAnnotation(rtkPositionAnnotation)
      break
      
    case .poweredOn:
      print("central.state is .poweredOn")
      print("scanning for peripherals with service(s): \([headTrackerServiceCBUUID])")
      centralManager.scanForPeripherals(withServices: [headTrackerServiceCBUUID], options: nil)
      break
      
    @unknown default:
      print("centralManagerDidUpdateState - Action needed: Handle unknown default")
      setUIDefaultValues()
      deviceNameLabelValue.text = "BLE unknown default"
      break
    }
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
  {
    print(String("Peripheral discovered: \(peripheral.name ?? "unknown")"))
    // You can change this to check for UUID from security reasons
    let deviceFound: Bool = peripheral.name?.starts(with: deviceNamePrefix) ?? false
    if (deviceFound)
    {
      headTrackerPeripheral = peripheral
      headTrackerPeripheral.delegate = self
      centralManager.stopScan()
      central.connect(headTrackerPeripheral)
      headtrackerDeviceName = peripheral.name!
      deviceNameLabelValue.text = headtrackerDeviceName
    }
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
  {
    print("Connected!")
    headTrackerPeripheral.discoverServices([headTrackerServiceCBUUID])
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
  {
    setUIDefaultValues()
    print("Disconnected! Start scanning again...")
    mapView.removeAnnotation(rtkPositionAnnotation)
    centralManager.scanForPeripherals(withServices: [headTrackerServiceCBUUID], options: nil)
  }
}


@available(iOS 14.0, *)
extension MainViewController: CBPeripheralDelegate
{
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
  {
    guard let services = peripheral.services else { return }
    
    for service in services
    {
      print(service)
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                  error: Error?)
  {
    guard let characteristics = service.characteristics else { return }
    
    for characteristic in characteristics
    {
      if characteristic.properties.contains(.read)
      {
        print("\(characteristic.uuid): properties contains .read")
      }
      
      if characteristic.properties.contains(.notify)
      {
        print("\(characteristic.uuid): properties contains .notify")
        peripheral.setNotifyValue(true, for: characteristic)
      }
      
      if characteristic.properties.contains(.write)
      {
        print("\(characteristic.uuid): properties contains .write")
      }
      
      peripheral.readValue(for: characteristic)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                  error: Error?)
  {
    switch characteristic.uuid
    {
      case headTrackerCharacteristicCBUUID:
        let orientationString = orientationData(from: characteristic)
        onHeadtrackingReceived(orientationString)
      
      case realTimeKinematicsCharacteristicCBUUID:
        let positionString = locationData(from: characteristic)
        onRealtimeKinematicsReceived(positionString)
      
      case rtkAccuracyCharacteristicCBUUID:
        let accuracyString = locationAccuracy(from: characteristic)
        onRTKAccuracyReceived(accuracyString)
          
      default:
        print("Unhandled Characteristic UUID: \(characteristic.uuid)")
    }
  }
  
  private func locationData(from characteristic: CBCharacteristic) -> String
  {
    guard let characteristicData = characteristic.value else { return "" }
    let byteArray = [UInt8](characteristicData)
    var packetStr = ""
    for u in byteArray
    {
      let char = Character(UnicodeScalar(u))
      packetStr.append(char)
    }
      return  packetStr
  }
  
  private func orientationData(from characteristic: CBCharacteristic) -> String
  {
    guard let characteristicData = characteristic.value else { return "" }
    let byteArray = [UInt8](characteristicData)
    var packetStr = ""
    for u in byteArray
    {
      let char = Character(UnicodeScalar(u))
      packetStr.append(char)
    }
      return  packetStr
  }
  
  private func locationAccuracy(from characteristic: CBCharacteristic) -> String
  {
    guard let characteristicData = characteristic.value else { return "" }
    let byteArray = [UInt8](characteristicData)
    var packetStr = ""
    for u in byteArray
    {
      let char = Character(UnicodeScalar(u))
      packetStr.append(char)
    }
      return  packetStr
  }
}

// Mark:- String extension(s)

// Compare two Strings
extension String {
  
  func isEqualToString(find: String) -> Bool
  {
    return String(format: self) == find
  }
}


@available(iOS 14.0, *)
extension MainViewController: CLLocationManagerDelegate
{
    // iOS 14
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager)
  {
    print("Location Manager Authorization: ")
    
    switch manager.authorizationStatus
    {
    case .notDetermined:
          print("Not determined")
      
    case .restricted:
        print("Restricted")
      
    case .denied:
        print("Denied")
      
    case .authorizedAlways:
        print("Authorized Always")
      
    case .authorizedWhenInUse:
        print("Authorized When in Use")
      
    @unknown default:
        print("Unknown status")
    }
    
  }
    
    // iOS 13 and below
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
  {
    switch status
    {
    case .notDetermined:
        print("Not determined")
        manager.requestAlwaysAuthorization()
        manager.requestWhenInUseAuthorization()
        
    case .restricted:
        print("Restricted")
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
      
    case .denied:
        print("Denied")
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
      
    case .authorizedAlways:
        print("Authorized Always")
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
      
    case .authorizedWhenInUse:
        print("Authorized When in Use")
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
      
    @unknown default:
        print("Unknown status")
        manager.requestAlwaysAuthorization()
        manager.requestWhenInUseAuthorization()
    }
  }
}
