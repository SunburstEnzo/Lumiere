# Lumiere (iOS)

<p align="center">
<img src="Lumiere/Resources/LumiereAppIconRounded.png">
</p>

> An iOS app with share extension for saving Instagram post media. 

Tap the share button when viewing an Instagram post in the app or in Safari on iOS, and select “Lumiere” to view the share sheet in app. 

![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)


## Requirements 
* Xcode 11
* iOS 14+


## How To Install
1. Use your own Apple Developer account to sign the app and its share extension (note: uses Keychain sharing).
1. Open the main Lumiere app and sign into Instagram with your personal account.
1. Visit an Instagram link and tap the share button, or copy and paste a link into the app.


## Dependencies
* [Swiftagram](https://github.com/sbertix/Swiftagram) (SPM)
* [SDWebImage](https://github.com/SDWebImage/SDWebImage) (SPM)


## Future Plans
* Support for more than just posts (e.g. user profile browsing, stories)
* Full iPad support
* History
* Bulk downloads
* Save to a “Lumiere” photo album
* SwiftUI rewrite


## Privacy
[Privacy Policy](https://github.com/SunburstEnzo/Privacy-Policy)

No analytics whatsoever, I literally could not care less about what you look at. 


## Notes
I had to rewrite the app around Swiftagram instead of SwiftInsta due its media limitations. 

Intended for personal use only; please don’t use this for bad stuff like stealing content and reposting. I built this so it would be easier to reference things, a bit like Pinterest boards, instead of just screenshotting posts. Please don’t try to upload this to the App Store as it won’t get approved, and even if it slipped through it will get rejected as it uses some private Apple APIs. 

Feel free to open issues, though no support is provided. 
