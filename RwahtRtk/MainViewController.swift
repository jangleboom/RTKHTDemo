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

import UIKit
import CoreBluetooth
import MapKit
import CoreLocation



class MainViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
 
  @IBOutlet weak var deviceNameTextField: UITextField!
  @IBOutlet weak var yawTextField: UITextField!
  @IBOutlet weak var pitchTextField: UITextField!
  @IBOutlet weak var linAccelZTextField: UITextField!
  @IBOutlet weak var deviceNameLabel: UILabel!
  @IBOutlet weak var yawLabel: UILabel!
  @IBOutlet weak var pitchLabel: UILabel!
  @IBOutlet weak var linAccelZLabel: UILabel!
  @IBOutlet weak var mapView: MKMapView!
  
  var locationManager: CLLocationManager!
  let headTrackerServiceCBUUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
  let headTrackerMeasurementCharacteristicCBUUID = CBUUID(string: "713D0002-503E-4C75-BA94-3148F18D941E")
  let deviceNamePrefix = "HTRTK_"
  var centralManager: CBCentralManager!
  var headTrackerPeripheral: CBPeripheral!
  var headtrackerDeviceName = "---"
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    locationManager = CLLocationManager()
    locationManager.requestWhenInUseAuthorization()
 
    centralManager = CBCentralManager(delegate: self, queue: nil)
    deviceNameTextField.backgroundColor = UIColor.white
    deviceNameTextField.textColor = UIColor.blue
    deviceNameTextField.borderStyle = .none
    deviceNameTextField.text = "not connected"
    yawTextField.backgroundColor = UIColor.white
    yawTextField.textColor = UIColor.blue
    yawTextField.borderStyle = .none
    yawTextField.text = "---"
    pitchTextField.backgroundColor = UIColor.white
    pitchTextField.textColor = UIColor.blue
    pitchTextField.borderStyle = .none
    pitchTextField.text = "---"
    linAccelZTextField.backgroundColor = UIColor.white
    linAccelZTextField.textColor = UIColor.blue
    linAccelZTextField.borderStyle = .none
    linAccelZTextField.text = "---"
    
    deviceNameLabel.textColor = UIColor.black
    deviceNameLabel.text = "Device"
    yawLabel.textColor = UIColor.black
    yawLabel.text = "Yaw"
    pitchLabel.textColor = UIColor.black
    pitchLabel.text = "Pitch"
    linAccelZLabel.textColor = UIColor.black
    linAccelZLabel.text = "Lin. Accel. Z"
  }
 
  
  func onHeadtrackingReceived(_ orientation: String) {
    let delimiter = " "
    let token = orientation.components(separatedBy: delimiter)
    if  token.count == 3 {
      let yaw = String(token[0])
      let pitch = String(token[1])
      let linAccelZ = ((token[2] as NSString).floatValue < 0) ? String(token[2]) : (" " + String(token[2]))

      yawTextField.text = "\(yaw)°"
      pitchTextField.text = "\(pitch)°"
      linAccelZTextField.text = "\(linAccelZ)"
    } else {
      print("onHeadtrackingReceived: Data format does not fit (\(token.count)!=3)")
    }
  }
}



extension MainViewController: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
      
    case .unknown:
      print("central.state is .unknown")
      break
    case .resetting:
      print("central.state is .resetting")
      break
    case .unsupported:
      print("central.state is .unsupported")
      break
    case .unauthorized:
      print("central.state is .unauthorized")
      break
    case .poweredOff:
      print("central.state is .poweredOff")
      break
    case .poweredOn:
      print("central.state is .poweredOn")
      print("scanning for peripherals with service(s): \([headTrackerServiceCBUUID])")
      centralManager.scanForPeripherals(withServices: [headTrackerServiceCBUUID], options: nil)
      break
    
    @unknown default:
      print("centralManagerDidUpdateState - Action needed: Handle unknown default")
      break
    }
  }
  

  
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    print(String("Peripheral discovered: \(peripheral.name ?? "unknown")"))
    // You can change this to check for UUID from security reasons
    // TODO: No hard coded device name here
    //let found: Bool = peripheral.name?.isEqualToString(find: headtrackerDeviceName) ?? false
    let found: Bool = peripheral.name?.starts(with: deviceNamePrefix) ?? false
    if (found) {
      headTrackerPeripheral = peripheral
      headTrackerPeripheral.delegate = self
      centralManager.stopScan()
      central.connect(headTrackerPeripheral)
      headtrackerDeviceName = peripheral.name!
      deviceNameTextField.text = headtrackerDeviceName
    }
    
  }

  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected!")
    headTrackerPeripheral.discoverServices([headTrackerServiceCBUUID])

  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    print("Disconneced! Start scanning again...")
    centralManager.scanForPeripherals(withServices: [headTrackerServiceCBUUID], options: nil)
  }
  
}



extension MainViewController: CBPeripheralDelegate {
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let services = peripheral.services else { return }
    
    for service in services {
      print(service)
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                  error: Error?) {
    guard let characteristics = service.characteristics else { return }
    
    for characteristic in characteristics {
      print(characteristic)
      
      if characteristic.properties.contains(.read) {
        print("\(characteristic.uuid): properties contains .read")
      }
      if characteristic.properties.contains(.notify) {
        print("\(characteristic.uuid): properties contains .notify")
        peripheral.setNotifyValue(true, for: characteristic)
      }
      if characteristic.properties.contains(.write) {
        print("\(characteristic.uuid): properties contains .write")
      }
      
      peripheral.readValue(for: characteristic)
      
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                  error: Error?) {
    switch characteristic.uuid {
      
      case headTrackerMeasurementCharacteristicCBUUID:
        let orientationString = orientationData(from: characteristic)
        onHeadtrackingReceived(orientationString)
        
      default:
        print("Unhandled Characteristic UUID: \(characteristic.uuid)")
      }
  }
  
  
  private func orientationData(from characteristic: CBCharacteristic) -> String {
    guard let characteristicData = characteristic.value else { return "" }
    let byteArray = [UInt8](characteristicData)
//    print("byteArray: \(byteArray)")
    var packetStr = ""
    for u in byteArray {
      let char = Character(UnicodeScalar(u))
      packetStr.append(char)
    }
//    print(packetStr)
      return  packetStr
  }
  
  
}



// Mark:- String extension(s)

// Compare two Strings
extension String {
  
  func isEqualToString(find: String) -> Bool {
    return String(format: self) == find
  }
}
