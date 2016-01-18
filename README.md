# ZBeaconKit

## Prerequisites

- `Location Always Usage` permission should be enabled(*For iBeacon Region monitoring*).
- Device Bluetooth Service should always be active(*iBeacon is one of BLE Beacon specs, it needs Bluetooth to work properly*).

## Integrating ZBeaconKit to your iOS App.

### Adding `Location Always Usage` permission.

Add `NSLocationAlwaysUsageDescription` key into your project `info.plist`.

![](http://wifi-zoyi-jp.s3.amazonaws.com/wudi/Screen Shot 2016-01-12 at 12.52.15 PM.png)

### [Download](http://wifi-zoyi-jp.s3.amazonaws.com/wudi/ZBeaconKit.framework.zip) `ZBeaconKit.framework`, and copy to your project root folder.

![](http://wifi-zoyi-jp.s3.amazonaws.com/wudi/Screen Shot 2016-01-12 at 2.34.58 PM.png)

### [Install](https://github.com/Carthage/Carthage/releases) `carthage`.

![](http://wifi-zoyi-jp.s3.amazonaws.com/wudi/Screen Shot 2016-01-12 at 2.48.12 PM.png)

### Adding copy file run script.

- On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script with the following contents:
```
/usr/local/bin/carthage copy-frameworks
```
and add the paths to the frameworks you want to use under “Input Files”, e.g.:
```
$(SRCROOT)/ZBeaconKit.framework
```

![](http://wifi-zoyi-jp.s3.amazonaws.com/wudi/Screen Shot 2016-01-12 at 2.38.32 PM.png)

### The last step, configure your App specific info.

#### If you are building with Swift
- Import `ZBeaconKit`, configure your App authentication information.

![](http://wifi-zoyi-jp.s3.amazonaws.com/wudi/Screen Shot 2016-01-15 at 2.45.49 PM.png)

#### If you are building with Objective-C

- Enable `Embedded Content Contains Swift Code` flag in `Build Settings`.

![](http://wifi-zoyi-jp.s3.amazonaws.com/wudi/Screen Shot 2016-01-12 at 3.02.36 PM.png)

- Import `<ZBeaconKit/ZBeaconKit.h>`, configure your App authentication information.

![](http://wifi-zoyi-jp.s3.amazonaws.com/wudi/Screen Shot 2016-01-15 at 2.50.39 PM.png)
