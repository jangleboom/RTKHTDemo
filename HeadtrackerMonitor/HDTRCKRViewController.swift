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



class HDTRCKRViewController: UIViewController {
  
  //let headTrackerServiceCBUUID = CBUUID(string: "0xFFE0")
  //let headTrackerMeasurementCharacteristicCBUUID = CBUUID(string: "0xFFE1")
  let headTrackerServiceCBUUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
  let headTrackerMeasurementCharacteristicCBUUID = CBUUID(string: "713D0002-503E-4C75-BA94-3148F18D941E")
  let headtrackerDeviceName = "rwaht_rtk_01"

  var centralManager: CBCentralManager!
  var headTrackerPeripheral: CBPeripheral!
  
  @IBOutlet weak var headTrackerLabel: UILabel!
  @IBOutlet weak var additionalSensorDataLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
 
    centralManager = CBCentralManager(delegate: self, queue: nil)
    
    
    // Make the digits monospaces to avoid shifting when the numbers change
//    headTrackerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: headTrackerLabel.font!.pointSize, weight: .regular)
  }

  func onHeadtrackingReceived(_ orientation: String) {
    let delimiter = " "
    let token = orientation.components(separatedBy: delimiter)
    print(token.count)
    if  token.count == 3 {
      var yaw = String(token[0])
      var pitch = String(token[1])
      let linAccelZ = ((token[2] as NSString).floatValue < 0) ? String(token[2]) : (" " + String(token[2]))
     
//      var steps = String(token.last!)
//      headTrackerLabel.text = "yaw: \(yaw)°\npitch: \(pitch)°\nlinAccelZ: \(linAccelZ)\nsteps: \(steps)"
      
      switch yaw.count {
      case 0:
        yaw = "nil"
        break
      case 1:
        yaw = "  " + yaw
        break
      case 2:
        yaw = " " + yaw
        break
      case 3:
        break
        
      default:
         print("too many digits (yaw)")
      }
      
      switch pitch.count {
      case 0:
        pitch = "nil"
        break
      case 1:
        pitch = "   " + pitch
        break
      case 2:
        pitch = "  " + pitch
        break
      case 3:
        pitch = " " + pitch
        break
      case 4:
        break
      default:
        print("too many digits (pitch)")
      }
      

      
//      headTrackerLabel.text = "azimuth: \(yaw)°\nelevation: \(pitch)°"
      headTrackerLabel.text = "yaw: \(yaw)°\npitch: \(pitch)°\nlinAccelZ: \(linAccelZ)"
    }
      else if token.count == 1 {
      let data = String(token.first!)
        headTrackerLabel.text = "data: \(data)"
      }
    
    
    
    print(headTrackerLabel.text ?? "no data")
  }
}



extension HDTRCKRViewController: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
      
    case .unknown:
      print("central.state is .unknown")
      fallthrough
    case .resetting:
      print("central.state is .resetting")
      fallthrough
    case .unsupported:
      print("central.state is .unsupported")
      fallthrough
    case .unauthorized:
      print("central.state is .unauthorized")
      fallthrough
    case .poweredOff:
      print("central.state is .poweredOff")
      fallthrough
    case .poweredOn:
      print("central.state is .poweredOn")
      print("scanning for peripherals with service(s): \([headTrackerServiceCBUUID])")
      centralManager.scanForPeripherals(withServices: [headTrackerServiceCBUUID], options: nil)
    
    @unknown default:
      print("Action needed: Handle unknown default")
    }
  }
  

  
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    print(String("Peripheral discovered: \(peripheral.name ?? "unknown")"))
    // You can change this to check for UUID from security reasons
    
    let found: Bool = peripheral.name?.isEqualToString(find: headtrackerDeviceName) ?? false
    if (found) {
        headTrackerPeripheral = peripheral
        headTrackerPeripheral.delegate = self
        centralManager.stopScan()
        central.connect(headTrackerPeripheral)
        additionalSensorDataLabel.text = headtrackerDeviceName
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



extension HDTRCKRViewController: CBPeripheralDelegate {
  
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
    
//    let firstBitValue = byteArray[0] & 0x01
//    if firstBitValue == 0 {
//      // Heart Rate Value Format is in the 2nd byte
//      return Int(byteArray[1])
//    } else {
//      // Heart Rate Value Format is in the 2nd and 3rd bytes
      return  packetStr//(Int(byteArray[1]) << 8) + Int(byteArray[2])
//    }
  }
  
  
}





// Compare two Strings
extension String {
  
  func isEqualToString(find: String) -> Bool {
    return String(format: self) == find
  }
}
