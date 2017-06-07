# ZBeaconKit

## Prerequisites

- `Location Always Usage` permission should be enabled(*For iBeacon Region monitoring*).
- Device Bluetooth Service should always be active(*iBeacon is one of BLE Beacon specs, it needs Bluetooth to work properly*).

## Integrating ZBeaconKit to your iOS App.

### Adding `Location Always Usage` permission.

Add `NSLocationAlwaysUsageDescription` key into your project `info.plist`.

![](http://s3.ap-northeast-2.amazonaws.com/zoyi-github-assets/wiki/ZBeacon/add-location-always-usage-permission.png)

### [Download](http://wifi-zoyi-jp.s3.amazonaws.com/wudi/ZBeaconKit.framework.zip) `ZBeaconKit.framework`, and copy to your project root folder.

![](http://s3.ap-northeast-2.amazonaws.com/zoyi-github-assets/wiki/ZBeacon/download-zbeaconkit-framework.png)
![](https://s3.ap-northeast-2.amazonaws.com/zoyi-github-assets/wiki/ZBeacon/locate-file-in-project-root.png)

### Drag the `ZBeaconKit.framework` to your Xcode project path.

![](https://s3.ap-northeast-2.amazonaws.com/zoyi-github-assets/wiki/ZBeacon/drag-and-drop-to-xcode-project-path.png)

### [Install](https://github.com/Carthage/Carthage/releases) `carthage`.

![](http://s3.ap-northeast-2.amazonaws.com/zoyi-github-assets/wiki/ZBeacon/install-carthage.png)

### Adding copy file run script.

- On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script with the following contents:
```
/usr/local/bin/carthage copy-frameworks
```
and add the paths to the frameworks you want to use under “Input Files”, e.g.:
```
$(SRCROOT)/ZBeaconKit.framework
```

![](http://s3.ap-northeast-2.amazonaws.com/zoyi-github-assets/wiki/ZBeacon/add-copy-file-run-script.png)

### The last step, configure your App specific info.

#### If you are building with Swift
- Import `ZBeaconKit`, configure your App authentication information.

![](http://s3.ap-northeast-2.amazonaws.com/zoyi-github-assets/wiki/ZBeacon/import-zbeaconkit-in-swift.png)

#### If you are building with Objective-C

- Enable `Embedded Content Contains Swift Code` flag in `Build Settings`.

![](https://s3.ap-northeast-2.amazonaws.com/zoyi-github-assets/wiki/ZBeacon/enable-embedded-content-contains-swift-code.png)

- Import `<ZBeaconKit/ZBeaconKit.h>`, configure your App authentication information.

![](https://s3.ap-northeast-2.amazonaws.com/zoyi-github-assets/wiki/ZBeacon/import-zbeaconkit-in-objc.png)
