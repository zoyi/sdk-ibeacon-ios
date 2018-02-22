# ZBeaconKit

## How to build?
### Cocoapods
In your Podfile, add

````
target 'Example' do
  use_frameworks!
  ... your pods
  # Pods for ZBeaconKitExample
  pod 'ZBeaconKit', :path => '../..'
end
````

and run `pod repo update` then `pod install`

### Carthage
This project could simply be built with [Carthage](https://github.com/Carthage/Carthage).

In case you are first get to know carthage, here is a brief description of how to build carthage.

1. install carthage.(better to use homebrew)
2. open project root folder.
3. Modify Manager.currentPackageVersion if needed
4. build ZBeaconKit with command:

`carthage build --no-skip-current`


5. the `ZBeaconKit.framework` could be found in `$(PROJECT_ROOT)/Carthage/Build/iOS`.
