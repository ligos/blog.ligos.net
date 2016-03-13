---
title: Home Security With Raspberry Pi
date: 2016-03-13 22:30:00 
tags:
- Raspberry Pi
- Security
- Home Security
- Camera
- Video 
- Surveillance
categories: Technical
---

A quick guide to setting a Raspberry Pi as a home security camera.

<!-- more --> 

In our unit block, there are suspicions that someone is stealing mail from our mailboxes.
So I decided to move my [Raspberry Pi](https://www.raspberrypi.org/) home security camera to keep photos of that area.

## Requirements

* A Raspberry Pi (mine is the original version 1)
* Raspberry Pi [camera module](https://www.raspberrypi.org/products/camera-module/)
* MicroSD card
* Network and power cables (or WiFi adapter)
* Power supply
* Box to place Pi in
* Zip lock bag to keep water out (optional if your box is water resistant)

## Device Setup

[MotionEye](https://github.com/ccrisan/motioneyeos) is a brilliant all-in-one surveillance environment for the Pi.
It does all the low-level setup required during installation (operating system, packages, dependencies, etc), and only a small amount of extra config is required.

Download an [appropriate image](https://github.com/ccrisan/motioneyeos/wiki/Supported-Devices) for your Raspberry Pi (or alternate device), and flash it to your micro SD card. 
Boot your Pi and wait for about 5 minutes while all the initial setup is done.
([MotionEyeOS's own install notes](https://github.com/ccrisan/motioneyeos/wiki/Installation)).

Then you can browse to the IP address of your device and start configuring MotionEye.
There are ways to figure out your device's IP, but if worst comes to worst, you can just connect it to a screen, login and run `ifconfig`.


## MotionEye Setup

Most of this is quite streight forward.

### General Settings

* Set advanced settings on
* Set passwords for admin and user accounts
* Set your timezone

### Network Settings

* Configure wireless if you're going to use it
* Set a static IP if you'd like to use one rather than DHCP (I set my device via DHCP and fix the IP from the router)

### Expert Settings

I didn't need to change anything here, but it's always good to check things labelled as *expert* or *advanced*.
There are log files in here which may help if things go wrong.

### Video Device

* Set a name for your camera, this is watermarked on all images in the bottom left.
* Set **Contrast** to 75% and **Saturation** to 0%. This gives black and write images which look much better than the default colour ones.
* Set **Video Resolution** to *1280x960*. This is high enough for good quality images, but low enough for the Pi's CPU to cope.  
* Set **Frame Rate** to the minimum of 2. Again, to keep the CPU usage down.

### File Storage

I'm storing files on my Windows file server, so set this to a **Network Share** with an appropriate login details.

You can use a USB storage device if you prefer.

### Video Streaming

* Set **Frame Rate** to 1, and **Streaming Quality** to 50% to minimise CPU and network usage.

### Still Image

* Set **Image Quality** to 85%. This makes sure the logged images are high quality to make out facial features if required.  
* You can set **Preserve Pictures** to something other than *Forever* if you don't want to run out of disk space. 30 days is good.

### Movies

I turn them off. Stills give highest quality individual images.
Just one high quality image is enough to identify someone, which is our goal.

### Motion Detection

* Set **Show Frame Changes** on, so you can see where motion is detected on images.
* **Frame Change Threshold** is the tricky one. Set it high enough to ignore images when the wind makes the shadows dance. But low enough to notice actual relevent motion. Err on the side of a lower threshold, because it's better to have a few hundered extra images than miss the one which was needed. Mine is around 9%, but you'll need to experiment.  
* **Motion Gap** = 10 sec
* **Captured Before** = 3 frames
* **Captured After** = 6 frames
* **Minimum Motion Frames** = 1 frames 



## Physical Installation

This was the tricky part.

The camera needed to be placed so that it can see people clearly visiting mail boxes.
But reasonably concealed so passers-by don't obviously see it.

The best way is to place it above or below people's eye line.
Generally, people walk with the eyes down, so a higher vantage point is good to watch without being noticed. 
There was a bush about 2-3m high directly behind the mailboxes in our unit block, which worked as a great place to hide the camera.
It's not visible unless you go looking for it (and then it's quite visible, unfortunately).

Currently, its being held in place by gravity, though some cable ties would work a treat. 

I placed my Pi in a zip lock sandwich bag to keep the rain out ([IP level 1](https://en.wikipedia.org/wiki/IP_Code), I hope).
Running power and network was slightly difficult with the bag, but enough fiddling paid off.

It is important to keep the camera module fixed in place (at least as much as possible).
Mine is attached to a tree branch with blue-tack.
Which suites this temporary installation quite well.

## Problems

The biggest outstanding problem is how to run power (and network without WiFi) to the Pi when it is ~10m from the nearest building.
The device needs power, so there isn't really any way around that.
But I'd need an electrician to improve the 20m extension lead currently in use.

The other problem is night-time images: they are terrible.
Which isn't entirely unexpected, because the mailboxes are poorly lit.
Even with the [NoIR camera](https://www.raspberrypi.org/products/pi-noir-camera/), the images are a washed out mess and the camera continually detects motion during darkness.
Improvement on this front would likely need an array of IR LEDs to improve lighting.  

 
## End Result

During day time, the images are pretty good.
You can see people quite clearly when checking the mail.

<img src="/images/Home-Security-With-Raspberry-Pi/mailbox-view.jpg" class="" width=300 height=300 alt="Me Checking My Mail" />

  


## Conclusion

You can setup a surveillance camera with a Raspberry Pi quite easily.
Very little technical knowledge is needed (if you can use a Pi, you can turn it into a camera).

A more permanent solution would require more work, but this was completed in a few hours. 