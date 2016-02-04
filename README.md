# MondoKit

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/MondoKit.svg)](https://img.shields.io/cocoapods/v/MondoKit.svg)
[![License](https://img.shields.io/cocoapods/l/MondoKit.svg?style=flat)](http://cocoapods.org/pods/MondoKit)
[![Platform](https://img.shields.io/cocoapods/p/MondoKit.svg?style=flat)](http://cocoapods.org/pods/MondoKit)

MondoKit is a Swift framework wrapping the Mondo API at https://getmondo.co.uk/docs/

## Requirements

- iOS 9.0+
- Xcode 7.2+

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

To integrate MondoKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "pollarm/MondoKit"
```

Run `carthage update --platform iOS --no-use-binaries` to build the framework and it's dependencies and drag the built `Alamofire.framework, KeychainAccess.framework, SwiftyJSONDecodable.framework, SwiftyJSON.framework and MondoKit.framework` into your Xcode project.

### CocoaPods

> CocoaPods 0.39.0+ is required to build MondoKit.

To integrate MondoKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '9.0'
use_frameworks!

pod 'MondoKit'
```

Then, run the following command:

```bash
$ pod install
```

## Getting started

### Initialization

Initialising the MondAPI is achieved as follows and should be done before you do anything else with the MondoAPI class, so probably in `applicationDidFinishLaunchingWithOptions`.

```swift
MondoAPI.instance.initialiseWithClientId(mondoClientId, clientSecret : mondoClientSecret)
```

One option is to store your Mondo clientId and clientSecret in a property list file called MondoKeys.plist (don't forget to .gitignore this file).
You can then initialise the MondoAPI as follows:

```swift
guard let mondoKeysPath = NSBundle.mainBundle().pathForResource("MondoKeys", ofType: "plist"),
    mondoKeys = NSDictionary(contentsOfFile: mondoKeysPath),
    mondoClientId = mondoKeys["clientId"] as? String,
    mondoClientSecret = mondoKeys["clientSecret"] as? String else {

        assertionFailure("MondoKeys.plist containing 'clientId' and 'clientSecret' required but not found in main bundle")
        return false
    }

MondoAPI.instance.initialiseWithClientId(mondoClientId, clientSecret : mondoClientSecret)
```

### Authentication

MondoAPI provides a ViewController implemetation to manage 3-legged authorization with the API. It also stores authorization details (accessToken, expiresIn etc.) securely in the KeyChain in the event of a successful authorization so you don't need to login every time you run your app.

To check if MondoAPI is already authorized for a user:

```swift
if MondoAPI.instance.isAuthorized { ... proceed ... }
```

If not then request an auth ViewController specifiying the callback closure to deal with the result and present it:

```swift
else {
    let oauthViewController = MondoAPI.instance.newAuthViewController() { (success, error) in
        if success {
            self.dismissViewControllerAnimated(true) {
            // proceed now we're logged in
        }
        else {
            // present error to user
        }
    }
    presentViewController(oauthViewController, animated: true, completion: nil)
}
```

### listAccounts

```swift
MondoAPI.instance.listAccounts() { (accounts, error) in ... }
```

### getBalanceForAccount

```swift
MondoAPI.instance.getBalanceForAccount(account) { (balance, error) in ... }
```

### listTransactions

```swift
MondoAPI.instance.listTransactionsForAccount(account) { (transactions, error) in ... }
```

eg. using Optional `expand` parameter

```swift
MondoAPI.instance.listTransactionsForAccount(account, expand: "merchant") { (transactions, error) in ... }
```

eg. using Optional `pagination` parameter

```swift
MondoAPI.instance.listTransactionsForAccount(account, pagination: MondoAPI.Pagination(limit: 50, since: .Date(NSDate()), before: NSDate())) { (transactions, error) in ... }
```

### getTransactionForId

```swift
MondoAPI.instance.getTransactionForId(id, expand: "merchant") { (transaction, error) in ... }
```

### annotateTransaction

```swift
MondoAPI.instance.annotateTransaction(transaction, withKey "aKey", value: "aValue") { (transaction, error) in ... }
```

### listFeedForAccount

```swift
MondoAPI.instance.listFeedForAccount(account) { (feedItems, error) in ... }
```
