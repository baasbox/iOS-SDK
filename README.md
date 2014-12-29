BaasBox iOS SDK
=======

This is the official iOS SDK for [BaasBox](http://www.baasbox.com)

#Installation

## Cocoapods

Add the following to your Podfile

``pod 'BaasBoxSDK', '~> 0.9.0'``

## Good old way

Download this repo and drag the `BaasBox-iOS-SDK` folder on your Xcode project. 

#Importing

Add `#import "BAAClient.h"` to the .pch file of your project and you are good to go.

For Swift projects import all the .h and .m files. Xcode will ask you to create a bridging header. Say yes.
Then add the following to the bridging header file `#import "BAAClient.h"`. Tested with Xcode6 beta6.

#Documentation
Read documentation here: [http://www.baasbox.com/documentation](http://www.baasbox.com/documentation)

#License

This SDK is released under the Apache 2 license. See the LICENSE file for more details.

We are gonna write a tutorial soon. Check out [our blog](http://www.baasbox.com/blog/)
