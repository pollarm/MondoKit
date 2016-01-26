# MondoKit

MondoKit is a Swift framework wrapping the Mondo API at https://getmondo.co.uk/docs/

## Getting started

In your applicationDidFinishLaunchingWithOptions

```swift
import MondoKit

MondoAPI.instance.initialiseWithClientId(mondoClientId, clientSecret : mondoClientSecret)
```

Then to allow the user to sign in request an auth view controller

```swift
let oauthViewController = MondoAPI.instance.newAuthViewController() { (success, error) in ... }
```

Present that as you see fit and await the callback to confirm the result.

You can then use the MondAPI singleton to retrive account and transaction information. eg.

```swift
MondoAPI.instance.listAccounts() { [weak self] (accounts, error) in ... }
```
