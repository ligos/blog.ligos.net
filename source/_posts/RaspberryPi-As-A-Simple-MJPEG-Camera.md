---
title: Raspberry Pi As A Simple MJPEG Camera
date: 2016-04-17 22:30:00
tags:
- Raspberry Pi
- Security
- Home Security
- Camera
- Video 
- Surveillance
- MotionEye
categories: Technical
---

How to use MotionEye with a network MJPEG Raspberry Pi camera.

<!-- more --> 

Previously, I had [set up a Raspberry Pi as a home security camera](/2016-03-13/Home-Security-With-Raspberry-Pi.html).
It did a reasonable job monitoring the few square metres outside our mailbox.

## A Problem

But there was one sizable problem: my poor little mk 1 Pi just couldn't cope with the CPU demanding task of motion detection.

As long as there was no motion and no images to save, it sat at around 60-70% CPU.
But when it detected motion, it went to 100% CPU.
For about 20 seconds (so, 200% CPU is probably more accurate).

This meant, even after reducing resolution and frame rate to absolute minimum, it was still dropping frames.

Dropped frames are, simply, unacceptable.

## Fast Network Camera

During my original setup, I'd noticed the option to configure [MotionEyeOS](https://github.com/ccrisan/motioneyeos) as a *Fast Network Camera*.

*Fast* sounded good. 
But fast came at the expense of all other features: motion detection, saving images and "advanced features".

So, I decided to fire up a new instance of [MotionEye](https://github.com/ccrisan/motioneye) to consume the MJPEG stream produced by the PI.
 
## Ubuntu 16.04 in Hyper-V

First up, was to get an environment I could run another instance of MotionEye.
My Windows 10 computer isn't compatible and the recently released [Windows Subsystem for Linux](https://blogs.msdn.microsoft.com/commandline/2016/04/06/bash-on-ubuntu-on-windows-download-now-3/) thing won't be ready for prime time for months.
So Hyper-V and [Ubuntu](http://www.ubuntu.com/download/server) was the way to go.

Ubuntu 16.04 LTS was three weeks from completion, but apparently you can `apt upgrade` to the final release. 
So I decided to take a plunge with the server release candidate. 

The Hyper-V side was pretty easy.
Point it at the downloaded ISO, create a new vhdx (128GB; thin provisioned), generation 1, single CPU, and use dynamic memory (512MB-2048MB).
Click Start.

<img src="/images/RaspberryPi-As-A-Simple-MJPEG-Camera/Hyper-V-Settings.png" class="" width=300 height=300 alt="Hyper-V Settings" />

Ubuntu setup was equally easy (at least for someone who works professionally with similar servers).
Just remember to enable the option for installing an SSH Server and Samba. 
I assigned an static IP via DHCP from my router.
And decided to name my new server **Spyglass**.

And [installing MotionEye](https://github.com/ccrisan/motioneye/wiki/Installation) was, again, quite streight forward.
Install the packages required by MotionEye, as well as python 2.

Though the `pip install motioneye` didn't pick up all the dependencies, so I had to manually install a few.

But other than that, it all just worked!

## Lighting Up MJPEG

I saved a backup of the original settings on the Pi, and hit the switch.
 
<img src="/images/RaspberryPi-As-A-Simple-MJPEG-Camera/Enable-MJPEG.png" class="" width=300 height=300 alt="That Switch" />

And there were a whole bunch of new camera settings available.

<img src="/images/RaspberryPi-As-A-Simple-MJPEG-Camera/New-Camera-Settings.png" class="" width=300 height=300 alt="I Love More Settings!" />

I'm running with the settings in the image above:

* Resolution: 1280x1024
* Frames per Second: 4
* ISO: 800
* Video Stabilization: On
* Saturation: 0
* Slight boost to Brightness and Contrast

On Spyglass' MotionEye, the settings mostly consisted of copying the old settings from the Pi.
Things like File Storage on an SMB share, saving Still Images, and Motion Detection.

Adding the MJPEG camera just involved giving it a name and copying the *Streaming URL* from the Pi.

<img src="/images/RaspberryPi-As-A-Simple-MJPEG-Camera/Spyglass-Camera.png" class="" width=300 height=300 alt="The Same Picture I Has Before, But Via Spyglass" />


## Benefits

The first thing I checked on the Pi was CPU usage.
Which was greatly reduced, even with a higher resolution and frame rate. 

<img src="/images/RaspberryPi-As-A-Simple-MJPEG-Camera/Top-After-MJPEG.png" class="" width=300 height=300 alt="50% CPU, for Better Results" />
   
I had to tweak the Motion Detection settings on Spyglass because of the higher frame rate.
(I was getting perhaps 10x as many images saved)!

The second thing to check was CPU usage on Spyglass itself: about 30%.
Sometimes up to 60% when I was tweaking settings and there were lots of camera activity.

Interestingly, Hyper-V reported much lower CPU usage: 10-15%.
Which was born out by my server's actual CPU usage.

In short, the Pi's poor little CPU was maxed out processing half the load.
And it was almost a rounding error on my main server. 

<img src="/images/RaspberryPi-As-A-Simple-MJPEG-Camera/Hyper-V-Activity.png" class="" width=300 height=300 alt="10% CPU, Under 1GB RAM" />

I also checked my router to see if any there was any additional network load.
Afterall, rather than saving a 100kB image every few minutes, we're streaming larger images at a higher frame rate. 

<img src="/images/RaspberryPi-As-A-Simple-MJPEG-Camera/Network-Usage.png" class="" width=300 height=300 alt="15Mbps Network Usage" />

Fortunately, 15Mbps is trivial on a gigabit network.


## Conclusion

Running a Rasberry Pi as a surveillance camera gives much better results when using it as a *Fast Network Camera* and letting a more powerful computer do the motion detection.

And, while there's a little a more to setup, it is not too much harder.
 