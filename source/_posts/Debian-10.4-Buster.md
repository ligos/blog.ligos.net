---
title: Debian 10 Buster
date: 2020-06-27
tags:
- Debian
- Basics
- setterm
- consoleblank
categories: Technical
---

Hey, they moved my cheese! Oh there it is.

<!-- more --> 

## Background

[Debian 10 "Buster" is available](https://www.debian.org/News/2020/20200509).

Actually, it's been available for ages. But I was very slack publishing this article.

## Differences from Debian 9

Here are my notes compared to [Debian 9](/2018-12-16/Debian-9.5-Stretch-Basic-Installation.html).

### sudo

As in Debian 9, `sudo` isn't installed by default.
However, the group to be a "sudoer" is now *sudo* instead of *sudoers*.

```
$ su
$ apt install sudo
$ adduser myuser sudo
```

### Screen Blanking

The biggest challenge was the laptop I installed Debian 10 on wasn't blanking the screen any more.

It used to do that in Debian 9 automagically.
And I was a bit disappointed Debian 10 wasn't co-operating.

My first attempt was to use [setterm](https://unix.stackexchange.com/questions/421779/how-to-disable-tty1-and-backlight-using-arch-linux).
It lets you configure a timeout to blank the laptop screen.

```
$ su
$ setterm --blank 5 --term linux > /dev/tty1
```

This worked OK when I had used `su` to become root.
It didn't work via `sudo` (which was rather surprising), and I couldn't make it work as a `systemd` service either (despite running as root).

A solution that involves me manually running a command isn't going to work.
So I looked for other options.

The other approach is to tell the [kernel to blank the screen](https://unix.stackexchange.com/questions/8056/disable-screen-blanking-on-text-console/24412#24412).
There is a [Linux kernel option](https://www.kernel.org/doc/html/v4.14/admin-guide/kernel-parameters.html) called `consoleblank`, which does what I want.
It blanks the console after N seconds (default = 600, or 10 minutes).

Seems the out-of-the-box Debian kernel sets this to 0, which disables console blanking.

I've never set a kernel option.
Heck, I never knew you could pass options to the kernel - although I should have known better, the kernel at least needs to know what device to boot from.
So, StackOverflow, [how do you set a kernel boot parameter](https://askubuntu.com/questions/19486/how-do-i-add-a-kernel-boot-parameter)?

Apparently, you need to modify the `grub` configuration, update the bootloader and then reboot.

```
$ cat /etc/default/grub
...
GRUB_CMDLINE_LINUX_DEFAULT="quiet consoleblank=600"
...
$ grub-update
$ shutdown -r now
```

After the reboot, you can verify the kernel parameters via `/proc/cmdline`:

```
$ cat /proc/cmdline
BOOT_IMAGE=/boot/vmlinuz-4.19.0-8-amd64 root=UUID=71c98b73-cd73-492a-8874-8723756a919d ro quiet consoleblank=600
```

And lo! There's `consoleblank`, configured for 10 minutes.

Finally, wait for 10 minutes and the screen does indeed go blank. Success!


## Conclusion

There's not much difference between Debian 9 and 10.
I consider that a feature.

Thanks for not moving much of my cheese, Debian developers :-)
