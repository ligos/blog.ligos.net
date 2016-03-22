---
title: Removing Covernant Eyes Manually
date: 2016-03-22 14:00:00  
tags:
- Covernant Eyes
- Accountability Software
- Windows
- Uninstall
- Winsock 
- Layered Service Provider
- LSI
- Sysinternals
categories: Technical
---

How to remove the Covernant Eyes web accountability software manually.

<!-- more --> 

## Background

I've been upgrading various family and friend's computers to Windows 10 and came across one with [Covernant Eyes](http://www/covernanteyes.com) installed.
Which was a slight problem, because Covernant Eyes kept blocking network connections.

[Covernant Eyes](http://www/covernanteyes.com) is web accountability software which is reasonably popular amoungst members of my church and the wider Sydney evangelical community.
It is designed to keep Christian believers accountable to someone else when using the Internet.
Basically, this boils down to three things:

1. Requires a password when you want to use the Internet (presumably held by your spouse).
2. Blocks access to sites which might be pornographic (again, you need a password to access such sites).
3. Logs all sites accessed and sends them to an *accountability partner*.  

I realise many people would question the sanity of anyone voluntarily installing a web-filtering program, but us Christians do weird things to make sure we don't fall into sin 
(and pornography can be [extremely destructive](https://en.wikipedia.org/wiki/Pornography_addiction) whether you call it a *"sin"* or not). 

Unfortunately, Covernant Eyes requires a code to uninstall it, and otherwise blocks web connections.
Which makes upgrading to Windows 10 rather difficult.
(Not to mention that the version on this computer is not compatible with Windows 10 anyway).

## How it Works Technically

To do the web filtering and logging, I knew it would install some sort of network filter in the Windows network stack.
And a quick check using Sysinternals [autoruns](https://technet.microsoft.com/en-us/sysinternals/bb963902) confirmed some Covernant Eyes dlls are installed under WinSock in the registry.
The registry path identified by autoruns relates to the [Layered Service Provider](https://en.wikipedia.org/wiki/Layered_Service_Provider).
Which looks to be a way to hook into all WinSock related network calls.
It's also been deprecated starting from Windows 8, so this particular machine will need a new version of Covernant Eyes.  

<img src="/images/Removing-Covernant-Eyes-Manually/autoruns.png" class="" width=300 height=300 alt="Autoruns entries for Covernant Eyes" />

There are also a couple of user processes which run at startup (again, highlighted nicely by autoruns).
I presume these are the part which communicates with the SLP dlls and asks for a password when required.
Although my brief look at what they were up to in process explorer didn't reveal any obvious mechanism for cross process communication.

<img src="/images/Removing-Covernant-Eyes-Manually/procexp.png" class="" width=300 height=300 alt="User land processes" />

From a technical point of view, I like this setup, as there are no kernel level drivers; everything is in user mode.
However, if you muck the SLP dll up, you're still going to break TCP based networking ([which Wikipedia notes](https://en.wikipedia.org/wiki/Layered_Service_Provider)).
And your dll gets loaded into every process which uses TCP, so it needs tight quality control.

<img src="/images/Removing-Covernant-Eyes-Manually/cespy.dll.png" class="" width=300 height=300 alt="The SLP filter dll is loaded by all kinds of processes" />


## Steps to Remove It

OK, the part everyone wants to get to.

1. Be admin (either via a dedicated admin user, or an elevated command prompt).
2. Kill the user mode processes `CovernantEyes.exe` and `CovernantEyesHelper.exe`.
3. Using autoruns, remove the Covernant Eyes program launched at startup.
4. Run `netsh winsock reset` to reset the network stack ([MSDN ref](https://technet.microsoft.com/en-us/library/cc753591.aspx)).
5. Restart the computer.
6. Run `netsh int ip reset c:\logfile.txt` to really reset the network stack ([ref](https://support.microsoft.com/en-us/kb/299357))
7. Restart the computer.
8. I needed to repeat steps 4-7 twice for some reason.

These steps were based on my findings above and a [blog post by Jeremy Arnold](http://www.pcgenesis.com/KnowledgeContent/manuallyremovecovenanteyes).
His steps are for a newer version of the software and also list files and registry locations which can be removed.
Generally, a registry and file system search for *covernant* will locate these.

* `C:\program files\CE\`
* `C:\program files (x86)\CE\`
* `C:\users\username\AppData\LocalLow\CE`
* `HKLM\Software\Covenant Eyes\`
* `HKLM\Software\Wow6432Node\Covenant Eyes`
* `HKCU\Software\Covenant Eyes\`
* `HKCU\Software\Wow6432Node\Covenant Eyes`
* `HKLM\System\CurrentControlSet\Services\WinSock2\Parameters\Protocol_Catalog9\Catalog_Entries`


## Conclusion

Covernant Eyes blocks network activity and makes it hard to uninstall (by design).
But with a few [Sysinternals](https://technet.microsoft.com/en-us/sysinternals) tools and technical knowledge of Windows, you can manually uninstall it easily enough.