# MondoKit

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

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

Run `carthage update --platform iOS --no-use-binaries` to build the framework and it's dependencies and drag the built `Alamofire.framework, KeychainAccess.framework, SwiftyJSON.framework and MondoKit.framework` into your Xcode project.


## Getting started

### Initialization


I suggest storing your Mondo clientId and clientSecret in a property list file called MondoKeys.plist and .gitignore the file.
You can then initialise the MondoAPI as follows:

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    // Initialise MondoAPI with oauth2 id, secret

    guard let mondoKeysPath = NSBundle.mainBundle().pathForResource("MondoKeys", ofType: "plist"),
        mondoKeys = NSDictionary(contentsOfFile: mondoKeysPath),
        mondoClientId = mondoKeys["clientId"] as? String,
        mondoClientSecret = mondoKeys["clientSecret"] as? String else {

            assertionFailure("MondoKeys.plist containing 'clientId' and 'clientSecret' required but not found in main bundle")
            return false
        }

    MondoAPI.instance.initialiseWithClientId(mondoClientId, clientSecret : mondoClientSecret)

    return true
}
```

Then to allow the user to sign in request an auth view controller:

```swift
let oauthViewController = MondoAPI.instance.newAuthViewController() { (success, error) in ... }
```

Present that as you see fit and await the callback to confirm the result.

You can then use the MondAPI singleton to retrive account and transaction information. eg.

```swift
MondoAPI.instance.listAccounts() { (accounts, error) in ... }
```
