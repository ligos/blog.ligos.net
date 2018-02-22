---
title: Making Mikrotik Safe
date: 2018-02-22
tags:
- Mikrotik
- Safe Mode
- Networking
- User Interface
- Idiot Poof
categories: Technical
---

Un-nuking it from orbit.

<!-- more --> 

## Background

I posted a [feature request on the Mikrotik forums](https://forum.mikrotik.com/viewtopic.php?f=1&t=131042) to validate the *remove* button after I [managed to delete my network](/2018-02-18/Mikrotik-Routers-and-the-Remove-Button.html).

And I learned there was already a way to save me from my own stupidity: **safe mode**.


## Safe Mode

[Safe Mode](https://wiki.mikrotik.com/wiki/Manual:Console#Safe_Mode) is a feature of [WinBox](https://wiki.mikrotik.com/wiki/Manual:Winbox), Webmin, [TikApp](https://play.google.com/store/apps/details?id=com.mikrotik.android.tikapp&hl=en) and the Mikrotik [console](https://wiki.mikrotik.com/wiki/Manual:Console).

<img src="/images/Making-Mikrotik-Safe/safe-mode.png" class="" width=300 height=300 alt="The Anti-Stupid Button" />

It provides an undo stack of changes you've made on your router.
And if your changes involve... errr... nuking your router from orbit, they'll automatically roll back after 9 minutes.
Or, you exit without confirming your changes, you are given the option to undo them
Or, you can hit the undo button to undo something bad.

To be clear, this isn't queuing up changes ready to be applied; all your changes are made as normal.
All it does is allow you to hit `CTRL+Z` if you mucked something up really badly.
(Impressively, "something" also includes "removing all router connectivity").

<img src="/images/Making-Mikrotik-Safe/undo-redo.png" class="" width=300 height=300 alt="Undo and Redo" />

When you're all done making changes, click **Safe Mode** again so they won't be done when you exit.


## Limitations

The manual says the router will only store the **last 100 actions**.
I'm not exactly sure what *one action* may encompass (my guess is each action is one console command), but you could configure quite a bit in 100 actions.
Also, this should encourage you to make small changes and then test they are working.

Safe mode is a **global router setting**.
If multiple users are logged onto the router, they fight to hold safe mode.
Given I'm a home user, if more than one people is connected to my router, I've probably been hacked.

The **9 minute timeout** relates to TCP timeouts (apparently).
That is, you need to confirm your changes for them to take effect.
If you don't, it takes the router 9 minutes to notice your connection wasn't closed cleanly and roll the changes you made back.
9 minutes is rather a long time in my book, but better than nothing. 
(As a reference, I managed to repair my router's deleted bridge interface in around 15 minutes, which included time to panic and troubleshoot).

The documentation doesn't mention any actions which **aren't supported** by safe mode.
But it's a pretty safe bet that commands like *restart* or *shutdown* can't be undone.


## Default to Safe Mode

There was [some](https://forum.mikrotik.com/viewtopic.php?f=1&t=131042#p643479) [talk](https://forum.mikrotik.com/viewtopic.php?f=1&t=131042#p643430) of making a Winbox option for safe mode to be on by default.
And I [amended my feature request](https://forum.mikrotik.com/viewtopic.php?f=1&t=131042#p643541) to allow individual connections to save if safe mode is on or not.

However, it appears you need to opt into safe mode every time you connect.

Sadly, that means 90% of the time, I'll forget.


## Conclusion

Mikrotik lets you do almost everything.
Including using *Safe Mode* to un-nuke your router.

Turn it on today!
And keep turning it on tomorrow!