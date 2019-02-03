---
title: Installing LineageOS on your Android Phone
date: 2019-02-03
tags:
- Android
- LineageOS
- Custom ROM
- Fastboot
- CyanogenMod
- adb
categories: Technical
---

Refresh your phone with a custom ROM - LineageOS.

<!-- more --> 

**Background**

My Nexus 5X phone has been going strong for several years. 
But it's starting to fall out of support, software updates are becoming rarer, and even security updates aren't happen any more.

So, I decided that, now it's out of warranty and support, I have little to lose by wiping it and starting again - but plenty to gain.

[LineageOS](https://lineageos.org/) (a fork from [CyanogenMod](https://en.wikipedia.org/wiki/CyanogenMod)) is a [custom Android ROM](https://en.wikipedia.org/wiki/List_of_custom_Android_distributions), which are a tweaked version of the Android operating system on your phone.
It has extra features like security updates after your phone isn't supported, additional security options, the ability to choose what Google apps you use, and more customisable settings.

Basically, [LineageOS](https://en.wikipedia.org/wiki/LineageOS) is just like Android which came loaded on your phone, but with more features.
Particularly ones which appeal to the security conscious (or any nerd really).

In this post, I'll walk through the installation process on my Nexus 5X.

**IMPORTANT, ATTENTION, WARNING**

The process of loading a custom ROM on your Android phone **will** wipe all your data.
There's a possibility of **damaging** your phone such that it doesn't start up any more - known as **"bricking"** your phone.
If your phone has a warranty, this process will **void it**.

You have been warned!

**IMPORTANT, ATTENTION, WARNING**


## Is Your Phone Supported?

Before even contemplating LineageOS, check if your device is supported on the [LineageOS downloads](https://download.lineageos.org/) page. 
You can check the exact model for your phone in *Settings -> System -> About Phone*.
If its not on the LineageOS download page, you're out of luck - try a different [custom Android ROM](https://en.wikipedia.org/wiki/List_of_custom_Android_distributions).

LineageOS has information about each device it supports - check the details match your phone, because loading the wrong ROM on your phone will probably brick it.
Here's the [information about my Nexux 5X](https://wiki.lineageos.org/devices/bullhead).


## Installation Steps

How to install a custom Android ROM - LineageOS.


## 0. Backup first

Loading a custom ROM on your phone will wipe everything.
Apps, data, photos, everything.
So make sure you have a backup of everything before starting.

And then double check, because there's no going back!

Remember to:

* Check every app you have installed.
* Make sure any Authenticator codes are saved somewhere.
* All your photos, videos, etc are downloaded.
* Load a file manager on your device and check all your files.

I just copy individual files across to my computer.
But you could also use the [command line `adb` tool for a backup](https://stackoverflow.com/questions/19225467/backing-up-android-device-using-adb) (which you usually need at some point in the install process anyway).
Or, there's plenty of apps to accomplish the same thing.


## 1. Read the Instructions

Read all the instructions in full *before* you start.
You might not understand everything, but at least you are forewarned.
Maybe look for a blog post or YouTube video for your device, so you can see what you need to do in advance.

For me, here are the instructions for [Installing LineageOS on bullhead](https://wiki.lineageos.org/devices/bullhead/install) (the codename for my device).



## 1a. Download All the Things

You need to download a bunch of things, as listed on the install instructions.
Do that before you start.

* `adb`, the Android Debug Bridge (~10MB) - https://wiki.lineageos.org/adb_fastboot_guide.html
* `UniversalAdbDriver`, a Windows driver for ADB (~17MB) - https://adb.clockworkmod.com/
* `TWRP`, a recovery mode which lets you load the new ROM (~16MB) - https://twrp.me/Devices/
* `OpenGApps`, if you want to use the Google Play Store (make sure you use the link from install instructions to get the the right version) (~90MB - ~900MB)- https://wiki.lineageos.org/gapps.html
* `LineageOS`, err... the thing we came to install (~450MB) - https://download.lineageos.org/

[OpenGApps has a comparison page](https://github.com/opengapps/opengapps/wiki/Package-Comparison), which details what each package contains.
I've chosen the *Micro* version, which gets me GMail, Google Calendar and the Play Store - I don't use many other Google apps

## 2. Setup ADB

[Install and make sure ADB can see your device](https://wiki.lineageos.org/adb_fastboot_guide.html).

You'll need to install the `UniversalAdbDriver` and then unzip `adb` itself.

Enable developer mode on your phone by going to *Settings* -> *About*.
Then tap the *Build Number* 7 times.

Then you can go to *Settings* -> *Developer Options* -> and enable *USB Debugging*.

Connect your device to your computer and open a command prompt / Powershell window where you unzipped `adb`.

```
PS> ./adb devices
List of devices attached
* daemon not running; starting now at tcp:5037
* daemon started successfully
01e5bfbd1cc7ac10        unauthorized
```

When you first run `adb`, you'll need to authorise your computer from your phone.
After that, you should see something like this:

```
PS> ./adb devices -l
List of devices attached
01e5bfbd1cc7ac10       device product:bullhead model:Nexus_5X device:bullhead transport_id:1
```

You should confirm the device name & codename match the LineageOS and GApps you downloaded.


## 3. Unlock Your Bootloader

By default, your device won't let you load any old ROM onto it.
That's a security feature so random bad guys (or silly users) can't wipe your phone with a hacked Android which sends all your personal details to the highest bidder.

**IMPORTANT:** this is when you lose all your data. There's no going back after this step!

Go to *Settings* -> *System* -> *Developer Options* -> and enable *OEM Unlocking*.

Reboot your device into the OEM fastboot mode with `adb reboot bootloader`.

Then check the device is visible, and unlock your boot loader.

```
PS> ./fastboot devices
01e5bfbd1cc7ac10        fastboot
PS> ./fastboot flashing unlock
OKAY [142.588s]
Finished. Total time: 142.594s
```

You'll probably see a great big warning / disclaimer on your phone at this point. 
Including the part about *deleting all your personal data from your phone*.

**IMPORTANT:** this is when you lose all your data. There's no going back after this!

Use the volume up / down buttons to choose **yes**, and then the power button to confirm.
There will be a short delay while your phone is erased.

Reboot your device into the bootloader for the next step.
(You may need to re-enable USB debugging).


## 4. Install Custom Recovery

TWRP is a more user friendly recovery.
It has a pretty basic GUI which lets you navigate by tapping your phone screen rather than the volume up / down buttons (or issuing commands via `adb` or `fastboot`).
Of particular interest to us, it can erase partitions and load the custom ROM onto your device.

Reboot your device into the OEM fastboot mode with `adb reboot bootloader`.

Then check the device is visible, and upload the TWRP recovery image.

```
PS> ./fastboot devices
01e5bfbd1cc7ac10        fastboot
PS> ./fastboot flash recovery twrp-3.2.3-0-bullhead.img
Sending 'recovery' (16289 KB)                      OKAY [  0.535s]
Writing 'recovery'                                 OKAY [  0.158s]
Finished. Total time: 0.727s
```

Shutdown your device.

Then boot into our brand new TWRP recovery mode by powering on by holding down `Power` + `Volume Down`.
And chose *Recovery Mode*.


## 5. Install LineageOS from Recovery

Finally, we're up to the part we set out to do!

You should have the *LineageOS install package* ready (mine was ~420MB), and a Google Apps package (I chose the *micro* version, around ~170MB).

I found that my device wanted to reboot into the main system.
It took me a few times to force it into the bootloader so I could choose recovery.
Don't worry it you don't get into TWRP first time around; your phone is still OK!

My device was encrypted, so the first thing TWRP did was ask for the encryption password.
You can *cancel* out of that - we don't need to access your existing data.

Then, you get a warning: *Keep System Read only?*
We would like to make changes, so swipe to enable modifications.

The install instructions recommend a **backup** at this point, but my data partition is encrypted so I couldn't save my backup anywhere.
You actually need to do the next step first: that is, *Wipe* -> *Format Data* (and confirm).
Then you can **Backup**.

Unfortunately, I couldn't get the backup off my device. 
As I couldn't work out the right incantation for `adb` to transfer files off my device, and Google doesn't support SD cards on my Nexus 5X (or any Nexus or Pixel device, to my knowledge).
If your device has an SD card, that would work well to get your backup off your device.
I'm just going to not re-format my `/data` partition and hope I can get at the backup later, if I really need it (FYI, it got wiped at some point during the install; after LineageOS was going, I couldn't find any backup files).

Go to Wipe -> Advanced Wipe.
Then select `System`, `Dalvik / ART Cache`, and `Cache`.
And swipe to confirm.

**IMPORTANT:** your system won't boot until you load LineageOS (or some other ROM) - although you can get back into TWRP / recovery mode.

Now, we need to load the LineageOS (and GApps) packages.
On your device, tap `Advanced` -> `ADB Sideload` and then swipe.
On your computer run the following (which will take a while):

```
PS> ./adb devices
01e5bfbd1cc7ac10        sideload
PS> ./adb sideload lineage-15.1-20190127-nightly-bullhead-signed.zip
serving: '..\lineage-15.1-20190127-nightly-bullhead-signed.zip'  (~19%)
Total xfer: 1.01x
```

Then repeat the process for the Google Apps package:

```
PS> ./adb sideload open_gapps-arm64-8.1-micro-20190127.zip
serving: '..\open_gapps-arm64-8.1-micro-20190127.zip'  (~4%)
```

If you want to "root" your phone and have "SU" or full access to the device, you can load an [SU package](https://download.lineageos.org/extras) at this point.
I've done this in the past (for a different phone), but decided not to this time.

Now for the moment of truth!
Tap *Reboot* and choose *System* and swipe to confirm.

If all has gone well, you should see a different loading icon (for LineageOS instead of Google).
The first boot takes a few minutes (including an encryption phase and another reboot), and you don't really get any indication of where things are up to.


If anything goes wrong, reboot into the TWRP recovery mode (with `Power` + `Volume Down`) and repeat step 5.


## 6. Setup Your Phone

At this point, you'll be in the normal *Out of the Box Experience*.
From here on, it's like a fresh install on your phone - go through the usual process of entering your language, WiFi passwords and account details.


## Conclusion

Its a bit involved, but you can load a custom ROM onto your phone.
This is particularly useful if a) you want to keep getting security updates after your OEM stops updating your phone, b) you want extra features, or c) you want nerd credit.

[LineageOS](https://lineageos.org/) is now keeping my Nexus 5X secure, updated and happy!