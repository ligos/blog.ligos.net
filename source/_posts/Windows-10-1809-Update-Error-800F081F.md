---
title: Windows 10 1809 Update Error 0x800F081F
date: 2018-11-24
tags:
- Microsoft
- Windows
- Install
- Update
- 1809
- October Update
categories: Technical
---

Remove "*Windows Developer Mode*" first.

<!-- more --> 

## Background

I'm upgrading all my Windows computers to the latest major Windows build 1809 (october update).
3 upgraded OK, but my laptop didn't.

I used the [media creation tool](https://www.microsoft.com/en-au/software-download/windows10) to create a USB, which I've used to upgrade each of them.

## The Error

The installer went through its normal process OK, and started the actual upgrade.
I walked away at this point, because I had better things to do than watch the line go across the screen.

When it restarted, I had this error: 

```
0x800F081F - 0x20003
The installation failed in the SAFE_OS phase with an error during INSTALL_UPDATES operation
```

<img src="/images/Windows-10-1809-Update-Error-0x800F081F/windows-upgrade-error-800f081f.png" class="" width=300 height=300 alt="We couldn't install Windows 10 - 0x800F081F " />

At this point, I rebooted my computer and tried again - with the same result.

As an aside, as much as Microsoft can produce some [pretty poor software](https://arstechnica.com/GADGETS/2018/10/MICROSOFTS-PROBLEM-ISNT-SHIPPING-WINDOWS-UPDATES-ITS-DEVELOPING-THEM/) at times, my experiences with the Windows updater have been very good.
OK, it hasn't always worked, which isn't fantastic.
But even if terrible and horrible errors occur (and I've seen a few doosies), it managed to put things back the way they were and leave you with a usable system, albeit unupgraded.

The place to look for reasons why the update failed are: `c:\windows\panther\setuperr.log` and `c:\windows\panther\setupact.log`.
You might need a bit of technical knowledge (or a friend who can decypher the programmer jargon), but there's a stack of information in there.

But I couldn't see anything which stuck out at me.
Which left me a bit stuck.

## The Solution

So I tried [searching the error code](http://lmgtfy.com/?s=b&q=windows+10+upgrade+1809+0x800f081f) `0x800F081F`.

And someone's [YouTube video](https://www.youtube.com/watch?v=nVlDpC_6NBg) appeared.

Normally I avoid videos like the plague (it takes 15 minutes watching them to get the same information I could read in 2).
But this one was titled with the exact error I was trying to fix, and it only went for 2 minutes.

Turns out you cannot upgrade with the optional feature *Windows Developer Mode* installed.

So, **Start** -> search for *Manage Optional Features* -> remove *Windows Developer Mode*.

And this time the upgrade worked fine!

Thanks [Gone](https://www.youtube.com/channel/UC1dccqr7hgUjMp48OHbpV2A)!



## Conclusion

No idea why, but you can't upgrade to Windows 10 October update (1809) with *Windows Developer Mode* installed.
Remove it first and you should be OK.