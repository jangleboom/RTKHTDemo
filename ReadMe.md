
<!--![alt-text-1](./Screenshots/rtkhtdemo.png "CoreLocation user position & realtime-kinematics rover position.")-->

<img align="right" src="./Screenshots/rtkhtdemo.png" width="240"/> 

### Real Time Kinematics & Head Tracking Monitor

This project belongs to the [RTKBaseStation](https://github.com/audio-communication-group/RTKBaseStation) and [RTKRover](https://github.com/audio-communication-group/RTKRover) projects and monitors the rover data. The iOS demonstrator receives location- (ZED-F9P) and orientation (BNO080) data via BLE from an ESP32 (RTKRover). The iOS device location and the RTKRover location are logged to console and the distance between both coordinates is displayed. 

Tested on an iPhone 7 (iOS 15.6.) and iPhone 12 mini (iOS 16.1.2).


