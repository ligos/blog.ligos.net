---
title: Moving to Linux Mint - BluRay Burner
date: 2025-05-02
tags:
- Linux
- Mint
- BluRay
- Backups
- VNC
- Wine
- VirtualBox
categories: Technical
---

Because Windows 10 is going out of support.

<!-- more --> 

## Background

Microsoft is [ending Windows 10 support on 14th October 2025](https://www.microsoft.com/en-us/windows/end-of-support). 

That is rather annoying, because I have a number of older PCs which cannot upgrade to Windows 11, and I don't want to spend money to replace them.

So time to figure out a replacement!

## Goal

My chosen alternative operating system is [Linux Mint](https://www.linuxmint.com/).

Linux Mint is based on Debian, so uses the familiar `apt` packaging system, and I'm generally familiar with it because its used for [my servers](https://blog.ligos.net/2018-12-16/Debian-9.5-Stretch-Basic-Installation.html).

I'll be upgrading various PCs over the next few months.
First on my list is the backup BluRay burning machine.
This was once my youngest son's gaming computer and the last desktop PC left standing in our household.

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/bluray-burner-pc.jpg" class="" width=300 height=300 alt="BluRay Burner PC - network name: GonkDroid" />

I've removed the expensive graphics card, but the main feature of this PC is the BluRay burner, which is essential for my [backups](https://blog.ligos.net/2022-04-02/The-Reliability-Of-Optical-Disks.html).

## Installation

The instructions for [installing Linux Mint](https://linuxmint-installation-guide.readthedocs.io/en/latest/) are online. 
And they're pretty straight forward.

I downloaded the [ISO for Mint 22.1 Cinnamon Edition](https://www.linuxmint.com/download.php), and used [Rufus](https://rufus.ie/en/) to write it to a USB thumb drive.
Then used F12 on the PC to boot the USB instead of the main SSD.
And stepped through the instructions.

After it repartitioned the 120GB SSD, and copied files, and rebooted, I had a band new Linux Mint desktop computer. 🎉

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/linux-mint-login.png" class="" width=300 height=300 alt="Installation: successful!" /> 

### Extra Packages and Config

Out of the box, Linux Mint is functional as a client OS.
However, I wanted to access the machine remotely, with no screen, keyboard or mouse.
After all, I just need to stick disks in, and hit the burn button.

But first things first, the out-of-the-box experience told me to configure and run updates, check for proprietary firmware / drivers, configure snapshots, and enable the firewall.

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/mint-welcome-screen.png" class="" width=300 height=300 alt="But still a few steps to complete" /> 

I then installed `openssh-server` so I could get remote command line access.
Which is what I am used to for other Debian based servers I use.

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/install-openssh-server-via-software-manager.png" class="" width=300 height=300 alt="Openssh Server for remote access" /> 

After that, I installed `x11vnc` to get graphical remote access.
The [instructions](https://tecadmin.net/setup-x11vnc-server-on-ubuntu-linuxmint/) included manually creating a `systemd` service to start it on boot.
And saving the password (I ended up moving it from a `/home` folder to `/etc/x11vnc`, given I'm treating it as a system level service).

Don't forget to allow ssh and vnc though the firewall:

```
$ sudo ufw allow ssh
$ sudo ufw allow from 192.168.1.0/24 to any proto tcp port 5900
```

And then we have remote access!

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/ssh-to-linux-mint.png" class="" width=300 height=300 alt="Remote Access via SSH" /> 

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/vnc-remote-access.png" class="" width=300 height=300 alt="Remote Access via VNC" /> 

I quickly found that `x11vnc` doesn't work well if there is [no monitor plugged in](https://askubuntu.com/questions/1033436/how-to-use-ubuntu-18-04-on-vnc-without-display-attached).
I think this is because the graphical system on Mint assumes a monitor, and without one it gets all confused.
While there were some software / config solutions, I ended up purchasing a few [dummy HDMI monitor plugs](https://www.aliexpress.com/item/1005007299151261.html), which create a fake screen in hardware.

Finally, I also installed `htop`, which is my preferred console mode process monitor.


## Network Share / Mount

Backup disks are just a bunch of files.
I stage them on my TrueNAS server via SMB network share.
So Linux Mint needs to read and write via SMB.

The file manager supports SMB out of the box, which works well enough.

But, I also created [permanent mount points](https://documentation.ubuntu.com/server/how-to/samba/mount-cifs-shares-permanently/index.html) in `/etc/fstab`, which proved useful when working with Wine and VirtualBox later. 

```
$ cat /etc/fstab
# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/sda2 during installation
UUID=e2f0956c-0304-4ac6-9460-e91c2abc075f /               ext4    errors=remount-ro 0       1
# /boot/efi was on /dev/sda1 during installation
UUID=C8EA-C347  /boot/efi       vfat    umask=0077      0       1
/swapfile                                 none            swap    sw              0       0

# Countdooku SMB mounts
//countdooku.ligos.local/Catalog       /mnt/countdooku_catalog       cifs  credentials=/etc/samba/countdooku.credentials
//countdooku.ligos.local/Scratch       /mnt/countdooku_scratch       cifs  credentials=/etc/samba/countdooku.credentials
//countdooku.ligos.local/Torrents      /mnt/countdooku_torrents      cifs  credentials=/etc/samba/countdooku.credentials
```


## Linux CD Burning Software

As this PC is all about burning BluRay disks, I went exploring the world of Linux burning software.

There are three main options: [K3b](https://apps.kde.org/k3b/), [Xfburn](https://docs.xfce.org/apps/xfburn/start), and [Brasero](https://wiki.gnome.org/Apps/Brasero/).

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/disk-burning-tools-on-linux.png" class="" width=300 height=300 alt="K3b, Xfburn and Brasero - graphical disk burning tools on Linux" /> 

While they all looked usable (and do work - I burned a test disk using Xfburn), they missed a few key features.
None had the ability to verify a disk by just reading all sectors (which I do to confirm disks are still usable each year), and none could write multiple copies of a disk (I burn everything in triplicate).

So, while I could get by using any of these, I was missing the depth of features in [ImgBurn](https://www.imgburn.com/).

## ImgBurn and Wine

I decided to try out [Wine](https://www.winehq.org/) as a way to run ImgBurn from Linux.

Mint has a special [meta-package to install Wine](https://forums.linuxmint.com/viewtopic.php?t=442279), which boils down to doing `apt install wine-installer`.

I gave that a go and ended up with a slightly older version of Wine (9, when current is version 10).

So I [worked through the official instructions](https://gitlab.winehq.org/wine/wine/-/wikis/Debian-Ubuntu) from Wine to install on Ubuntu / Mint.
And got a working version 10 of Wine.

I then ran the ImgBurn installer via Wine, and got a new ImgBurn icon!

```
$ wine SetupImgBurn_2.5.8.0.exe
```

However, ImgBurn didn't work immediately.
I needed to use `winecfg` to use Windows XP mode, rather than Windows 7.

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/winecfg-imgburn-windows-xp.png" class="" width=300 height=300 alt="winecfg lets you configure the version of Windows to present to each program" /> 

And then ImgBurn started!

I needed to configure it to use the **SPTI** interface, and then it was able to see the BluRay burner.

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/imgburn-on-linux.png" class="" width=300 height=300 alt="ImgBurn running on Linux via Wine!" /> 

Finally, I burned some disks successfully 🙂

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/imgburn-burning-disk.png" class="" width=300 height=300 alt="ImgBurn burning a disk on Linux via Wine!" /> 

## WinCatalog and VirtualBox

The second half of backups is to catalog them.
Because having hundreds of backup disks is useless if you cannot find what you want to restore.

I use [WinCatalog](https://www.wincatalog.com/) for that.
Unsuprisingly, it is Windows software.
And it needs direct access to the BluRay burner to read back the data for cataloging.

Again, I used Wine to install WinCatalog, and it seemed to work well enough.

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/wincatalog-on-linux.png" class="" width=300 height=300 alt="WinCatalog on Linux via Wine" /> 

However, I was not able to import a disk into the catalog.
Eventually, I determined this was because I had not installed the .NET Framework in Wine.

Big hint: if you run into problems with a Wine application, try running the app from a console (eg: `wine WinCatalog.exe`) and you will see all kinds of debug spew which might hint at the problem.

So I downloaded Wine's version of Mono, which is a non-Microsoft implementation of .NET.
Plus the Gecko support for a web browser.
And installed using the rather unintuitive `wine uninstaller` [Wine command](https://gitlab.winehq.org/wine/wine/-/wikis/Commands).

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/wine-uninstaller.png" class="" width=300 height=300 alt="You can install apps via the uninstaller 🙃" /> 

WinCatalog got slightly further importing, but still failed with an error.

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/wincatalog-error-importing-disk.png" class="" width=300 height=300 alt="WinCatalog error when importing a BluRay disk via Wine" /> 

It's possible a newer version of Wine might work better, but I was stuck for now.

Instead, I turned to [VirtualBox](https://www.virtualbox.org/) and [Tiny10](https://ntdev.blog/2024/01/08/the-complete-tiny10-and-tiny11-list/).

VirtualBox is a virtual machine software, which allows you to install and run Linux under Windows, or Windows under Linux.
I had used it in the past for various purposes, so again, I was reasonably familiar with it.

I didn't want to install a full version of Windows 10 just to run one piece of software.
So I found a cut down version of Windows 10 called [Tiny10](https://ntdev.blog/2024/01/08/the-complete-tiny10-and-tiny11-list/), which removes a lot of bits of Windows that I didn't need.
I was able to [download the ISO for Tiny10 from the internet archive](https://archive.org/details/tiny-10-23-h2).

A recent version of VirtualBox is available via `apt install virtualbox`.
And I then created a Windows virtual machine, installed Tiny10 and WinCatalog.

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/virtualbox-with-tiny10.png" class="" width=300 height=300 alt="VirtualBox with Tiny10. 1.5GB is pretty small for a base install!" /> 

I ended up configuring the network as `bridged`, so Windows could connect directly to my TrueNAS.

WinCatalog installed successfully, and was able to import a burned backup disk!

<img src="/images/Moving-To-Linux-Mint-BluRay-Burner/virtualbox-wincatalog-importing-disk.png" class="" width=300 height=300 alt="WinCatalog importing a disk in VirtualBox" /> 

Note that the Windows VM is unactivated.
Although I have a retail licence for Windows 10 Home (which was installed on the same hardware) I have not tried to move the license to the VM (yet).


## Conclusion

[Linux Mint](https://www.linuxmint.com/) is a viable alternative to Windows.

And I was able to successfully migrate my BluRay burning PC to Mint, as a machine I control remotely.

Even Windows software (ImgBurn and WinCatalog) was usable on it.

And I am able to continue burning backup disks after October 2025.
