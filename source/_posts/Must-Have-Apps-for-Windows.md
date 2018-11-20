---
title: Must Have Apps for Windows
date: 2018-11-20
tags:
- Windows
- Basics
- Software
- Apps
- 3rd Party
- Installation
categories: Technical
---

The extra things I install on a Windows PC.

<!-- more --> 

## Background

I install Windows from scratch pretty regularly.
Either on new computers or re-installing on an older one.

And yes, I always re-install on a brand new computer - I don't want [OEM "extras"](https://arstechnica.com/gadgets/2015/02/save-yourself-from-your-oems-bad-decisions-with-a-clean-install-of-windows-8-1/), I just want the stock standard Windows (and even then I get [junk I don't want](https://superuser.com/questions/958562/how-do-i-remove-candy-crush-saga-from-windows-10)).

I had cause to re-install recently on a 2nd hand laptop for my kids.
So here's what I did.

<small>Yes, this is meant to be a very big list of links.</small>


## Windows Install

These days, Windows 10 just installs everything.
There was a time when you could pick and choose, which would save some disk space, but not any more.
And this makes installing pretty easy - there are no difficult choices to make.
Click *next* a few times, enter a product key (although even that is optional since Windows stores that on your motherboard now) and wait 10-30 minutes while the files copy.


OK, there is one choice: [which language should I install](https://support.microsoft.com/en-au/help/14236/language-packs)?

This isn't a serious choice, because you can always change or add or remove languages Windows uses.
But it's nice to get it correct out of the box by choosing the right [full localisation language](https://www.microsoft.com/en-au/windows/windows-10-specifications#primaryR5).

I live in Australia and speak English.
It's spelled *colour*, not *color*.
My printer has A4 paper, not US Letter.
And the 11th of December 2018 is correctly formatted as `12/11/2018`, not `11/12/2018`.
(Except when I'm a software developer, then dates may only be formatted as `2018-11-12`).

American English spelling and dates are wrong.
Which is what you get if you use the *English (United States)* or `en-US` installation media.

The alternative is *English (United Kingdom)* or `en-GB`, which at least gets the spelling, dates and paper correct.
But also defaults to a UK keyboard layout.
In Australia, we use a US keyboard layout (we use dollars, not pounds or Euros)

So, when I tell the [media creation tool](https://www.microsoft.com/en-au/software-download/windows10) what language, I choose `en-UK`.
And after installation I remove all traces of the UK keyboard layout.


## Universal Must Have Apps

These get installed on absolutely every Windows computer I work with.
No questions asked.

**Web Browsers**: [Chrome](https://www.google.com/chrome/) and [Firefox](https://www.mozilla.org/en-US/firefox/new/).
Most people I rub shoulders with don't see any difference between "Chrome" and "the Internet", so I figure I'll just get the inevitable out of the way.
The in-box [Edge](https://www.microsoft.com/en-au/windows/microsoft-edge) browser is more than capable these days, if anyone cares.
And putting Firefox on ensures all three major browsers are available.

**Zip App**: or *archive app* - [7-zip](https://www.7-zip.org/).
It's pretty ugly compared to alternatives these days, but very powerful for opening and creating ZIP files.
And the native 7-zip format gives better compression than ZIP (to be fair, that's true of every other alternative to ZIP as well).
Alternatives include: [WinRAR](https://www.win-rar.com), [IZArc](https://www.izarc.org/) and [WinZIP](https://www.winzip.com).

**Text Editor**: [Notepad++](https://notepad-plus-plus.org/).
There are stacks of text files you may need to view or edit (particularly as a developer), and [notepad](https://en.wikipedia.org/wiki/Microsoft_Notepad) isn't really up to the task.
Alternatives include: [Nodepad2](https://notepad2.com/) and [UltraEdit](https://www.ultraedit.com/).

**PDF Reader**: [Edge](https://www.microsoft.com/en-au/windows/microsoft-edge) / whatever web browser you prefer.
I haven't used Adobe's PDF viewer since I first used Windows 10 (and Edge said it could render PDFs).
And with Windows having a built in PDF printer, well, 3rd party software isn't even needed to create a PDF.
Alternatives include: [Adobe Reader](http://get.adobe.com/reader/), anything from [this list](https://www.lifewire.com/free-pdf-readers-1356652).
But I don't care very much.

**Image Editor**: [Paint.net](https://www.getpaint.net/index.html) - ([Windows Store Version](https://www.microsoft.com/en-au/p/paintnet/9nbhcs1lx4r0)).
This is what the built in [MS Paint](https://en.wikipedia.org/wiki/Microsoft_Paint) should be - simple, yet powerful.
Good enough for the occasions when I need to touch up photos or pretend I'm a graphic designer.
Alternatives include: [The Gimp](https://www.gimp.org/), [Adobe Photoshop](https://www.adobe.com/au/products/photoshop.html), [PaintShop Pro](https://www.paintshoppro.com/en/).

**Media Player**: [VLC Media Player](https://www.videolan.org/vlc/).
The built in Windows 10 *Films & TV* app works well enough, playing mp4s and most other videos.
But VLC plays everything you throw at it, and people want that-video-I-just-downloaded to Just Work™, so VLC is the best option (even if its UI comes out of the 90s).
Alternatives include: the built in [media player](https://www.microsoft.com/en-au/p/films-tv/9wzdncrfj3p2), [iTunes](https://www.apple.com/itunes/).

**[SysInternals Suite](https://docs.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite)**: *The* toolkit for digging into the inside of Windows systems.
Its like [Task Manager](https://en.wikipedia.org/wiki/Task_Manager_(Windows)), but way more powerful, and with a hundred more tools.
I download this and put it on the path, so I can run `procexp` from the start menu.
Alternatives include: [Process Hacker](https://processhacker.sourceforge.io/).


## Tier 2 Apps

These are must haves in my family.
And strongly recommended for everyone else.

**Password Manager**: [KeePass Password Safe](https://keepass.info/).
I have so many accounts and passwords (~450) that a password manager is essential.
KeePass was the one I chose years ago and is still going strong.
It's a little nerdy, but has versions for Windows, Linux, Android and iOS.
Alternatives include: [LastPass](https://www.lastpass.com/
), [1Password](https://1password.com/) and [Password Safe](https://www.pwsafe.org/).

**Internal File Sync**: [SyncThing](https://syncthing.net/).
I use it to synchronise files directly between my own devices (no "cloud" required).
It's a bit tricky to share data with other people, but within our household it's fantastic.
Alternatives include: [Resilio](https://www.resilio.com/) and [OwnCloud](https://owncloud.org/).

**External File Sync**: [Dropbox](https://www.dropbox.com/) and [OneDrive](https://onedrive.live.com/).
For files I need to share with people outside my household, Dropbox is the gold standard.
However, as I get boatloads of OneDrive storage with my Office365 subscription, I'm making more use of it.
Alternatives include: [Google Drive](https://drive.google.com/) and [Spideroak](https://spideroak.com/).

**Email Client**: [emClient](https://www.emclient.com/).
Chosen because of its [support for email encryption](/2017-01-02/Smime-Email-and-Yubikey.html), and ability to copy email between mail accounts.
For most people, the stock [Windows Mail](https://en.wikipedia.org/wiki/Mail_&#40;Windows&#41;) app works well enough.
Alternatives include: [Outlook](https://www.outlook.com/), [Thunderbird](https://www.thunderbird.net).

**Note Taking**: [OneNote](https://www.onenote.com).
For taking and keeping random notes, I've found OneNote works a treat.
I used the Office bundled version for some time, but switched over to the free Windows Store version a year or two ago, and found it works just as well (at least for my basic use).
Alternatives include: [Google Keep](http://www.google.com.au/keep/), [Evernote](https://evernote.com/).

**Office Suite**: [Office365](https://www.office.com/).
As much as paper-less offices are all the rage, Word documents are still rampant (and I do still print things from time to time).
And I'm in a secret love affair with Excel.
MS Office is the best here, and an Office365 subscription give me updates + storage as part of the deal (or you can stick with the one-time purchase [Office 2019](https://www.microsoft.com/en-au/p/office-professional-2019/cfq7ttc0k7c5)).
Alternatives include: [LibreOffice](https://www.libreoffice.org/), [WPS Office](http://kingsoftstore.com/).

**Where's-All-My-Disk-Space-Gone Tool**: [SpaceSniffer](http://www.uderzo.it/main_products/space_sniffer/).
Working out why I don't have much disk space left happens every 6-12 months, and SpaceSniffer does a fantastic job of a [Treemap](http://www.cs.umd.edu/hcil/treemap-history/) to answer that question.
I copy this into a Program Files folder and pin it to my start menu (as it doesn't have an installer).
Alternatives include: [WinDirStat](https://windirstat.net/).

**VoIP Softphone**: [MicroSip](https://www.microsip.org/).
This is more for work use than home, but I can use it to make and receive calls on my cheap VoIP number.
Ugly as any '90s Windows app, but plenty functional.

**[Winbox](https://mikrotik.com/download)**: because I'm a [Mikrotik tragic](/tags/Mikrotik/), and all my network devices have their brand name on them.
And their Webmin interface... well... not as good as Winbox.

**Remote Access**: [TightVNC](http://tightvnc.net/).
I prefer Remote Desktop when I can (and it's much better than VNC), but VNC is occasionally a life-saver if a laptop's screen dies.
For emergency use only.
Alternatives include: [Remote Desktop](https://www.bing.com/search?q=remote+desktop), [TeamViewer](https://www.teamviewer.com/en/).

**Facebook**: [Facebook (beta)](https://www.microsoft.com/en-au/p/facebook-beta/9nblggh6ct0l) & [Messenger (beta)](https://www.microsoft.com/en-au/p/messenger-beta/9nblggh2t5jk) from Windows Store.
I've removed Facebook from my phone (much to the delight of my additional spare time and phone battery life) but still use it to communicate with friends and family.
The Windows Store apps work quite nicely.
For some reason, the beta versions were much better than their non-beta counterparts - well, they were a few years ago, and I never bothered to un-beta myself.
Alternatives include: [facebook.com](https://www.facebook.com/).


## On Privacy, Updates and Classic Shell

Plenty of people are concerned (to put it mildly) about Windows 10 and their privacy.
Or dislike forced updates.
Or want their Windows 7 start menu back.

I'm not one of those people, but I understand the concern.
If you do want to disable Windows updates, or stop all telemetry going to Microsoft, or get something which looks more like a Windows 7 start menu, I suspect these would be on your new installation list:

* [Privacy options in Windows 10](https://www.maketecheasier.com/configure-privacy-options-windows-10/)
* [Turn of Windows 10 Updates](https://www.thewindowsclub.com/turn-off-windows-update-in-windows-10)
* [Classic Shell](http://classicshell.net/)


## User Accounts

I always run as a standard user, and so does everyone in my family.
There's very little reason to be an administrator user for day-to-day tasks (even as a developer, I can do 99% of my work as a standard user).
And it puts a password / PIN between any malware and real admin privileges.

So, I create two admin accounts: one is the standard Windows `administator` user, the other a dedicated admin Microsoft account.
The Microsoft account admin is added as the first user during installation.
And activate the `administrator` user like so:

```
PS> net user administator /active:yes
```

Just don't forget to give it a password.


## Conclusion

There's my list of must have Windows apps!
Plus a few other tips for a brand new installation.

May it improve your Windows experience, and maybe even make it more bearable.