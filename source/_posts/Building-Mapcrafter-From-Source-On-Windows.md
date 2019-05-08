---
title: Building Mapcrafter from Source on Windows
date: 2019-05-08 
tags:
- Mapcrafter
- WSL
- Windows
- Build
- Debian
categories: Technical
---

By cheating with WSL.

<!-- more --> 

## Background

I use [Mapcrafter](https://mapcrafter.org/) to generate detailed maps for my (and my kids) [Minecraft worlds](https://minecraft.ligos.net/).
Partly so I can navigate around in them, and partly to just look at whatever I've built in them, and partly to cheat and find neat things I can explore.


## The Problem

The [Mapcrafter author](https://github.com/m0r13) releases [binaries for various platforms](https://mapcrafter.org/downloads), including Windows.

When a new version of Minecraft is released, generally a new version of Mapcrafter is also required.
Which comes from a [fork in Github](https://github.com/mapcrafter/mapcrafter/tree/world113).
Which I have to build from source.

But I've never managed to build from source within Windows.


## Solution

So I cheat: I use [WSL](https://docs.microsoft.com/en-us/windows/wsl/about) to get a Linux environment on my Windows box, and then just follow the regular Linux instructions!


### Step 1: Install WSL

The [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about) is available on Windows 10 from version 1607 onwards.
Significant improvements have been made since the original release, so you'll get a better experience if you use the most recent version of Windows 10.
However, WSL is only available for Windows 10 and Server 2016, so if you're sticking with Windows 7 (or 8 for some reason), this won't help you.

Microsoft has [instructions for installing WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10).


These boil down to:

**1:** Install the Windows Component: either via "Turn Windows Features On or Off" control panel, or the Powershell command below.

```
PS> Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

<img src="/images/Building-Mapcrafter-From-Source-On-Windows/WSL-Windows-Features.png" class="" width=300 height=300 alt="Install WSL" />


**2:** Reboot. (WSL is a kernel level feature after all).


### Step 2: Install a Distribution from the Windows Store

Open up the Microsoft Store, search for *"Linux"*, and download your chosen distribution (I'm using Debian, but there are other available).

<img src="/images/Building-Mapcrafter-From-Source-On-Windows/Microsoft-Store-Ubuntu.png" class="" width=300 height=300 alt="I'm using Debian, but this is for downloading Ubuntu 18" />

### Step 3: Follow the Usual 'Build from Source' Instructions

Documentation for [building from source on Debian](https://docs.mapcrafter.org/builds/stable/installation.html#building-from-source) is available.

```
$ sudo apt update
$ sudo apt upgrade
$ sudo apt install git
$ sudo apt install libpng-dev libjpeg-dev libboost-iostreams-dev \
                   libboost-system-dev libboost-filesystem-dev \
                   libboost-program-options-dev build-essential \
                   cmake
$ mkdir mapcrafter
$ cd mapcrafter
$ git clone https://github.com/mapcrafter/mapcrafter.git .
$ git checkout world113
$ cmake .
$ make
```

At the end, you should have a executable Mapcrafter in `~/mapcrafter/src/mapcrafter`.

<img src="/images/Building-Mapcrafter-From-Source-On-Windows/Building-Mapcrafter.png" class="" width=300 height=300 alt="Building Mapcrafter in Debian in Windows" />


### Step 4: Create a Mapcrafter Configuration File

You can find [documentation about Mapcrafter Config Files](https://docs.mapcrafter.org/builds/world113/configuration.html), or [examples from my Minecraft Server](https://minecraft.ligos.net/worlds/index.html).

This is an exercise for the reader!


### Step 5: Run Mapcrafter from Windows

You can invoke Mapcrafter directly from a Windows `cmd` or `ps1` script, by using the `wsl.exe` command, or your distribution name.
Here's how I invoke it on my Windows computer:

```
PS> debian run /path/to/mapcrafter/src/mapcrafter -c /path/to/mapcrafter/src/config.txt
```

<img src="/images/Building-Mapcrafter-From-Source-On-Windows/Mapcrafter-WSL.png" class="" width=300 height=300 alt="Look! Mapcrafter in Debian in Windows!" />

You can hook that into other scripts, scheduled tasks, etc.
My full script invokes `mapcrafter`, `mapcrafter_markers` on each world I maintain, and then copies all the resulting files to my [hosting laptop... err... server](2019-03-09/Migrating-From-IIS-to-Nginx.html).

Mapcrafter is intelligent about updating the map: it will only update chunks which have been touched in Minecraft.
So create a regular scheduled task and it will just keep your map updated.

Here's the result for my [Creative Minecraft world](https://minecraft.ligos.net/worlds/Creative/index.html) (which my kids love playing in).


### Step 6 (optional): One Gotcha

There is one gotcha you may run into.
Linux (and Unix in general) is case-sensitive, while Windows is case-insensitive (but case preserving).
WSL, by default, behaves like Linux (case-sensitive) when working on automatically mounted Windows volumes.
However, this can cause problems in some cases (particularly if you're hosting on IIS).

To turn this behaviour off, you create a `wsl.conf` file in `/etc`, with the following content:

```
[automount]
options="case=off"
```

Here's some [references](https://docs.microsoft.com/en-us/windows/wsl/wsl-config#set-wsl-launch-settings) for the [wsl.conf](https://devblogs.microsoft.com/commandline/automatically-configuring-wsl/) file.


## Conclusion

Whenever I have trouble building or using Linux or Unix centric apps these days, I just reach for the Windows Subsystem for Linux.
It just works!

Building Mapcrafter goes from an impossible task, to just following the regular instructions.
(And I'm too old and busy to bother with caring about a "native" version).
