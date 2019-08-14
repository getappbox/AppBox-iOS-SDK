# AppBox SDK for iOS

## Introduction
Add AppBox SDK in your development/adhoc/enterprises iOS apps to get automatic update for apps uploaded via [AppBox-iOSAppsWirelessInstallation](https://getappbox.com/).

## Prerequisites
Before you begin, please make sure that the following prerequisites are met:
* [AppBox for Mac](https://getappbox.com/download)
* An iOS project that is set up in Xcode 9.0 or later on macOS 10.13 or later.
* The minimum OS target supported by the AppBox SDK is iOS 10.0 or later.
* If you are using cocoapods, please use cocoapods 1.1.1 or later.
* This readme assumes that you are using Swift 4 syntax.

## Integrate the SDK (using Cocoapods)

[CocoaPods](http://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like AppBox in your projects. To learn how to setup CocoaPods for your project, visit [the official CocoaPods website](http://cocoapods.org/).

1. Add the following to your podfile to include all services into your app. This will pull in AppBox SDK.

    ```ruby
    platform :ios, '10.0'
    use_frameworks! 

    target '{Your Target Name}' do
      pod 'AppBoxSDK'
    end
    ```

1. Run `pod install` to install your newly defined pod, open your `<ProjectName>.xcworkspace` and it's time to start the SDK and make use of the AppBox SDK.

## Start the SDK

To start the AppBox SDK in your app, follow these steps:

### 1. Get App Update Key
*  In order to use AppBox auto update service, you need to get app update key. For app update key, you need to upload your app with [AppBox](http://getappbox.com) option [Keep same link url for all future build](https://docs.getappbox.com/Features/keepsamelink/)

* When upload is complete, you'll get the a short url like this `https://tiny.app.link/bISsMrIxSY`. Open this url in your macOS web browser. Here you will see a long url like this `https://web.getappbox.com/?url=%2Fs%2Foge15hcy8nhw9q3%2Fappinfo.json&_branch_match_id=670527565819258213`.

* In long url after `s%2F` and before `%2Fappinfo.json` is your app update key, i.e - `oge15hcy8nhw9q3` in this case. Use your's.

### 2. Add import statements

You need to add import statements for AppBox modules before starting the SDK. Open your `AppDelegate.swift` file and add the following line.

```swift
import AppBoxSDK
```

### 3. Start the SDK

In order to use AppBox auto update service, you need to insert the following line to start the SDK in your app's `AppDelegate.swift` class in the `application(_:didFinishLaunchingWithOptions:)` method.

```swift
AppBox.start(key: "{App Update Key}")
```

## Troubleshooting

**Q. Unable to find a specification for AppBox error when using CocoaPods in your app?**

If you are using Cocoapods to install AppBox SDK in your app and run into an error with the message - Unable to find a specification for AppBox, run `pod repo update` or `pod repo update master` in your terminal. It will sync the latest podspec files for you. Then try `pod install` which should install AppBox SDK in your app.

## Contributions ❤️
Any contribution is more than welcome! You can contribute through pull requests and [issues](https://github.com/getappbox/AppBox-iOS-SDK/issues) on [GitHub](https://github.com/getappbox/AppBox-iOS-SDK/)

## Bugs 💔 
Please post any bugs to the [issue tracker](https://github.com/getappbox/AppBox-iOS-SDK/issues) found on the project's GitHub page. Please include a description of what is not working right with your issue.

Thank you!
