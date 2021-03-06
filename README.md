PingThing ![Icon](https://raw.githubusercontent.com/huwr/pingThing/master/PingThing/Images.xcassets/AppIcon.appiconset/icon_128x128.png "PingThign icon") 
=========

A little Mac app that sits in your menu bar and pings things.  It does not do very much else.  You get continuous feedback about the results.  The status icon changes depending on the results of the pings.

![Screenshot](screenshot.png "Screenshot")

Get it [here](https://github.com/huwr/pingThing/releases)!

The app is mostly written in Swift.  The ICMP SimplePing part is written in Objective-C and is a slightly modified version of the ADC sample code.  Icons are designed by Freepik, but the main app icon is by @yusf.

Known Issues
------------

* The 'Launch at Login' checkbox is not implemented - you will have to add it to your Login Items in System Preferences manually.
* Does not test connectivity correctly when connectivity is precluded by the network. That's difficult to control for; perhaps there could be a TCP ACK test.

Future Plans
------------

Here are the things I will be implementing next:

* Launch at Login
* Displaying the delay in the menu (and maybe even next to the icon)
* Suggestions of targets to Ping
* Multiple targets
* A cool graph of the delay over time
* Number of hops
