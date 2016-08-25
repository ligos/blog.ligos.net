---
title: Troubleshooting Windows Blue Screen of Death
date: 2016-08-25
tags: 
 - Blue Screen
 - Bug Check
 - Crash
 - Bsod
 - Windows
 - Troubleshooting
 - Windbg
 - Driver Verifier
 - Autoruns
categories: Technical
---

How to make sense of those annoying blue screen crashes. And maybe even fix them.

<!-- more --> 

## Background

My dad had updated his Windows 7 computer to Windows 10.
But he said that he was getting frequent freezes and blue screens of death.
Frequent as in two or three each day.

So he asked me to take a look.


## Troubleshooting A Blue Screen of Death

My assumption with any blue screen of death is it was caused by either a) bad hardware or b) bad drivers.
As much as Windows gets a bad rap for the blue screen of death, it's very rare to get one on good hardware and a clean install.
Most likely, there's some misbehaving hardware or a buggy driver.

(Sure, there are bugs in the Microsoft drivers too, but troubleshooting is an [exercise in optimisim](https://blogs.msdn.microsoft.com/oldnewthing/20141024-00/?p=43773/).
Fixing Microsoft's mistakes isn't really in our power, so just hope your blue screen isn't a Microsoft bug. 
On the plus side, Microsoft is known to fix bugs every now and then, when you submit error reports and crash dumps).


### What is a Bug Check?

The technical name for a Blue Screen of Death is a **Bug Check**.
A [bug check](https://msdn.microsoft.com/en-us/library/windows/hardware/hh994433.aspx) is when Windows realises something has gone so horribly wrong on your computer that it can't keep running.
So, with as little fuss as it can manage, it kills itself and restarts.

This is actually a good thing.
Because if it blindly kept running, it might do something very unexpected (and also very stupid).
Unexpected like destroying the files on your disk.
Stupid like calculate your employees' pay cheque wrong.
Or both, like damaging the [million dollar industrial control equipment](https://www.wired.com/2011/07/how-digital-detectives-deciphered-stuxnet/all/1) attached to the computer. 

Rather than doing something really bad, Windows just stops.
Which is terribly inconvenient, but better than finding your family photos, financial records and university thesis are gone. 


### Get a Memory Dump

The first step in troubleshooting is to get a memory dump.

Windows will save a copy of what was in your computer's memory to disk as part of a bug check.
This may be a **minidump** or a full or partial **memory dump**.

Windows will tend to save a *minidump* the first time a bug check happens, and escalate to larger memory dumps if they keep happening.

Check for a file called `C:\Windows\memory.dmp` or files in `c:\Windows\minidumps`.
Work with whatever is newest.

The settings for crash dumps are set in *Control Panel -> System -> Advanced System Settings -> Startup And Recovery -> Write Debugging Information*.

My dad was saving each memory dump file he got, so I had plenty to work with here.  

<img src="/images/Troubleshooting-Windows-Blue-Screen-of-Death/memory-dumps.png" class="" width=300 height=300 alt="That's a lot of memory dumps for 6 days!" />


#### How to Get a Memory Dump if Your Computer is Frozen (Maybe) 

A bug check is really good from a troubleshooting point of view.
There's lots of details in it.
But a hard lock up or freeze is much more difficult to diagnose.

As it turns out, there is a way to bug check a Windows computer by a keyboard shortcut.
You have to opt-in by setting some registry entries though.

USB keyboard: 

`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\kbdhid\Parameters` 

PS/2 keyboard: 

`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters`

Add a value:

* Name: `CrashOnCtrlScroll`
* Data Type: `REG_DWORD`
* Value: `1`

`CTRL + SCRLK x 2`

This assumes your computer is "spinning" rather than really crashed.
It's entirely possible a frozen computer won't respond to this.
But, it's worth a shot!

http://superuser.com/questions/224496/how-do-i-create-a-memory-dump-of-my-computer-freeze-or-crash

### Load it Into Windbg

To make any sense of the crash dump you'll need to install the Windows Debugger or `windbg` (less affectionately known as *wind bag*).
Download it as part of the [Windows SDK](http://go.microsoft.com/fwlink/p?LinkID=271979), just choose *Debugging Tools for Windows*.

It's worth checking you have a recent version of the debugger, as newer versions of Windows have more bug check codes. 
And newer debuggers tend to have better analysis logic.
Every version of Windows released has a corresponding debugger, and Windows 10 releases are coming 2 or 3 times per year, so update regularly!

Start `windbg`.

Then, go to *File -> Open a Crash Dump*, and find your `memory.dmp` file.
Windbg will load it and spew out a bunch of messages as it loads the memory dump and loads symbols.

<img src="/images/Troubleshooting-Windows-Blue-Screen-of-Death/windbg-loaded.png" class="" width=300 height=300 alt="Memory dump loaded" />

### Fix Symbols

You'll probably see various messages about symbols not being loaded right.
To fix this type `.symfix` into the little `1: kd>` command prompt at the bottom.
And then `.reload`.

If you find yourself analysing memory dumps often (as in, more than once), it's worth creating a folder `c:\symbols` and setting an environment variable like so:

```
SET _NT_SYMBOL_PATH=SRV*c:\Symbols*http://msdl.microsoft.com/download/symbols
```

### Run !analyze -v 

Before I even look at what caused the bug check, I run `!analyze -v`.
This tells windbg to go analyse the crash and tell me what it think caused it.

There's even a handy blue link to click, so I don't even need to type anything!

<img src="/images/Troubleshooting-Windows-Blue-Screen-of-Death/windbg-bang-analyze.png" class="" width=300 height=300 alt="Click to Analyse" />

Often, this will immediately point a finger at a driver which you should try to remove or update.
(Frequently, your video or hard disk driver).

(This is, of course, terribly bad practice. 
You should always check what the bug check code is and what it means.
Because some codes mean `!analyze` will get things horribly wrong.  
But its such an easy thing to do, I'll do this without even thinking.) 

<img src="/images/Troubleshooting-Windows-Blue-Screen-of-Death/windbg-bang-analyze-mem-corruption.png" class="" width=300 height=300 alt="Memory Corruption Sounds Bad" />

Usually, you get a nice stack trace with `!analyze`, but this one had lots of noise about symbol errors.
So I did a manual `kb` to get a *Stack Backtrace*.

```
WARNING: Stack unwind information not available. Following frames may be wrong.
00 ce20f238 8201564d 0000001e c0000046 81ecf6d1 nt!KeBugCheckEx
01 ce20f254 81f55bd2 ce20f61c 8208b2e8 ce20f34c nt!RtlTraceDatabaseValidate+0x5a5
02 ce20f278 81f55ba4 ce20f61c 8208b2e8 ce20f34c nt!ExRaiseStatus+0xce
03 ce20f33c 81f55b4b ce20f61c ce20f34c 00010007 nt!ExRaiseStatus+0xa0
04 ce20f66c 81ecf6d1 c0000046 00000000 8ed22488 nt!ExRaiseStatus+0x47
05 ce20f6c0 81ecf284 8ed224d4 00000001 00000000 nt!KeReleaseMutant+0x231
06 ce20f6d8 92d4313c 8ed224d4 00000000 00000000 nt!KeReleaseMutex+0x14
07 ce20f6f8 92d40a7f 00fe1c48 81e6f293 8ed223d0 ULCDRHlp+0x313c
08 ce20f71c 87c8daac 8ececcb0 92447a50 ce20f7e8 ULCDRHlp+0xa7f
09 (Inline) -------- -------- -------- -------- Wdf01000!FxIoTarget::Send+0xe
0a ce20f778 87c8cc5a 92447a50 00000001 ce20f7c0 Wdf01000!FxIoTarget::SubmitSync+0x14c [d:\th\minkernel\wdf\framework\shared\targets\general\fxiotarget.cpp @ 1777]
0b ce20f7b8 878c10cb 00000020 92447a50 8ececcb0 Wdf01000!imp_WdfRequestSend+0x17a [d:\th\minkernel\wdf\framework\shared\core\fxrequestapi.cpp @ 1940]
0c ce20f800 878d1119 71313348 00000002 00000000 cdrom!RequestSend+0xbb
0d ce20f820 87cfdd28 8ecec3d0 71313db8 92447a50 cdrom!CreateQueueEvtIoDefault+0x109
0e ce20f838 87cc048f 71314fe8 6dbb85a8 92447a50 Wdf01000!FxIoQueueIoResume::Invoke+0x2b [d:\th\minkernel\wdf\framework\shared\inc\private\common\fxioqueuecallbacks.hpp @ 60]
0f ce20f87c 87c86143 6dbb85a8 92447a50 8eceb010 Wdf01000!FxIoQueue::DispatchRequestToDriver+0x3a0af [d:\th\minkernel\wdf\framework\shared\irphandlers\io\fxioqueue.cpp @ 3389]
10 ce20f8a8 87c93192 8ecea500 00000000 8ecea57c Wdf01000!FxIoQueue::DispatchEvents+0x213 [d:\th\minkernel\wdf\framework\shared\irphandlers\io\fxioqueue.cpp @ 3100]
11 ce20f8cc 87cb0218 92447a50 8ecea538 8dfd27e0 Wdf01000!FxIoQueue::QueueRequest+0x82 [d:\th\minkernel\wdf\framework\shared\irphandlers\io\fxioqueue.cpp @ 2346]
12 ce20f954 87c83bea ce20f9a8 00000000 8eceae88 Wdf01000!FxPkgGeneral::OnCreate+0x2e0f8 [d:\th\minkernel\wdf\framework\shared\irphandlers\general\fxpkggeneral.cpp @ 1277]
13 (Inline) -------- -------- -------- -------- Wdf01000!FxPkgGeneral::Dispatch+0x5f
14 (Inline) -------- -------- -------- -------- Wdf01000!DispatchWorker+0x5f1
15 (Inline) -------- -------- -------- -------- Wdf01000!FxDevice::Dispatch+0x5f7
16 ce20f9e0 81e6f293 00ceae88 d6fe1c48 e96c002d Wdf01000!FxDevice::DispatchWithLock+0x65a [d:\th\minkernel\wdf\framework\shared\core\fxdevice.cpp @ 1402]
17 ce20f9fc 820f7daa df9df10f 8c3c8018 8c3c8030 nt!IofCallDriver+0x43
18 ce20fb28 82101870 8c3c8030 869bca58 e96c4458 nt!NtReadFile+0xd0a
19 ce20fbf4 820fb200 820f7730 869bca58 f0051b01 nt!RtlEqualUnicodeString+0x2730
1a ce20fc70 821238e4 014bf774 869bca58 f0051b01 nt!ObOpenObjectByName+0x110
1b ce20fcf4 8212359c 014bf774 014bf78c 00000000 nt!NtCreateFile+0x334
1c ce20fd34 81f507db 014bf758 00100080 014bf774 nt!NtOpenFile+0x2a
1d ce20fd54 77474540 badb0d00 02000000 00000000 nt!ExfUnblockPushLock+0x14fb
1e ce20fd58 badb0d00 02000000 00000000 00000000 0x77474540
1f ce20fd5c 02000000 00000000 00000000 00000000 0xbadb0d00
20 ce20fd60 00000000 00000000 00000000 00000000 0x2000000

```

My dad's memory dump showed the `ULCDRHlp` driver near the top of the stack.
Which we found was an old ULead DVD driver (from a time when burning DVDs needed a special driver).

But the analysis said *memory corruption* was the cause of the crash, which means `ULCDRHlp` crashed the system, but probably didn't corrupt the memory in the first place.
Most likey, some other driver corrupted memory and poor old `ULCDRHlp` was an innocent bystander. 

But, given its an old driver and wasn't needed, we disabled it anyway.


### Disable a Driver Using Autoruns

[Autoruns](https://technet.microsoft.com/en-us/sysinternals/bb963902) is a [sysinternals](https://technet.microsoft.com/en-us/sysinternals/bb545021.aspx) tool that lists many common places where Windows will load things.
From the programs that appear in your task tray, to key background services.

It also provides a nice, one-click way to stop loading a Windows driver.

<img src="/images/Troubleshooting-Windows-Blue-Screen-of-Death/autoruns-driver.png" class="" width=300 height=300 alt="Untick the Checkbox to Remove the Driver" />

After you untick the checkbox, reboot your computer.

(And, if your computer doesn't restart, use *safe mode* to re-enable the driver).


### Look up the Bug Check Code in the Help File

The windbg help file is actually very detailed.
Every possible code is listed, along with a description of what it means, and some basic steps you can take to troubleshoot.

Seriously, it's one of the best help files I've read (and I've read plenty).

*Help -> Contents -> Bug Checks (blue screens) -> Bug Check Code Reference*

If you lost your bug check code in debug spew, or missed in on the blue screen, you can tell the debugger to show it to you by doing a `.bugcheck`.

The bug check code for my dad was `0x1E` or `KMODE_EXCEPTION_NOT_HANDLED`.

Unfortunately, the help file indicated *"this is a very common bug check"*. 
And listed a bunch of instructions which didn't match what I was seeing on the screen. 

I decided I was in over my head and tried a different avenue. 


### Driver Verifier

[Driver verifier](https://msdn.microsoft.com/en-us/library/windows/hardware/ff545448.aspx) is a program that comes with Windows to add additional sanity checks to drivers.
It slows your computer down, and uses more memory, but means a *memory corruption* style of crash can be noticed when the offending driver causes the corruption, rather than when some innocent driver actually crashes the computer.

Driver developers often use *Driver Verifer* to check their drivers are doing everything correctly.
And helps us track down problem drivers.

1. Search or Run `verifer`, and elevate to admin.
3. Choose *Create standard settings*
3. Choose *Automatically select drivers built for older versions of Windows* 
4. You'll get a list of older drivers - 4 on my dad's computer. 

<img src="/images/Troubleshooting-Windows-Blue-Screen-of-Death/driver-verifier.png" class="" width=300 height=300 alt="Driver Verifier (after dodgy drivers were removed)" />

I checked details of these, noted them down and I named two as suspect: `windrvr6` and `tviclpt`. 
Dad commented that `windrvr6` part of an old microcontroller programmer and he'd heard some bad things about its stability.

(Note, selecting *all drivers installed on this computer* caused a bug check on boot on my dad's computer, and I needed safe-mode to fix it. Be warned).

After selecting the 4 drivers and rebooting, I got a new bug check during the boot sequence: `0xC4` or `DRIVER_VERIFIER_DETECTED_VIOLATION`.
The help file said sub-code `0x83` meant: *The driver called MmMapIoSpace without having locked down the MDL pages*.
(And I won't pretend I know what that means, other than it doesn't sound much like *memory corruption*).

This was driver verifier in action: it trapped a problematic driver really quickly.
And meant we got better info to troubleshoot with!

```
BugCheck C4, {83, e0000, fffff, 100}

WARNING: Stack unwind information not available. Following frames may be wrong.
8a8875c8 823d736a 000000c4 00000083 000e0000 nt!KeBugCheckEx
8a8875ec 823ce1ca 000e0000 000fffff 00000100 nt!IoIsValidIrpStatus+0x76ba
8a887614 823e683c 000e0000 00000000 00000000 nt!MmIsDriverSuspectForVerifier+0x3332
8a887628 93986f05 000e0000 00000000 000fffff nt!IoIsValidIrpStatus+0x16b8c
8a88764c 939871c0 8a887674 000e0000 00000000 windrvr6+0x16f05
8a887680 9398fbb0 000e0000 00000000 000fffff windrvr6+0x171c0
8a8876bc 9398ff5b 000fffff 9179d2a8 939828ff windrvr6+0x1fbb0
8a8876d4 9397e089 9397e358 8a8876f0 9397e7e2 windrvr6+0x1ff5b
8a8876e0 9397e7e2 9179e000 895f16f8 8a8878d0 windrvr6+0xe089
8a8876f0 8220afa6 9179d2a8 9179e000 8a887a2c windrvr6+0xe7e2
8a8878d0 8220a481 00000000 8a8878f8 00000005 nt!ExIsManufacturingModeEnabled+0x656
8a88798c 8210e49a 00000016 8a887a2c 00000002 nt!IoRegisterPlugPlayNotification+0x14a9
8a8879b8 8219ba35 00000005 8a5706b0 80000238 nt!FsRtlQueryCachedVdl+0x52a
8a887aa0 8219b262 ffffffff 895f16f8 8fa2e7d8 nt!RtlDuplicateUnicodeString+0x2861
8a887c8c 822574d8 8a887cb8 00000000 00000000 nt!RtlDuplicateUnicodeString+0x208e
8a887cc0 81ea363e 820c0f00 8a56a5c0 820ed220 nt!SeRegisterLogonSessionTerminatedRoutineEx+0x142
8a887d20 81f7b125 00000000 00000000 8a56a5c0 nt!KeInitializeGuardedMutex+0x31a
8a887d70 81ea0003 820ed220 5e9db1ae 00000000 nt!PsGetProcessSignatureLevel+0xaa9b
8a887db0 81fb6281 81f7b050 820ed220 00000000 nt!PoSetUserPresent+0xfa3
8a887db4 81f7b050 820ed220 00000000 00000000 nt!KiDispatchInterrupt+0x7e1
8a887db8 820ed220 00000000 00000000 00000000 nt!PsGetProcessSignatureLevel+0xa9c6
8a887dbc 00000000 00000000 00000000 00000000 nt!PsJobType+0x9d4
```


The crash analysis clearly showed driver `windrvr6` on the stack as the likely culperate.
The error wasn't obviously related to *memory corruption*, so I wasn't confident that `windrvr6` was actually the root cause, but it certainly looked like a contibuting factor. 
So we used *autoruns* to disable `windrvr6`. 

I rebooted and disabled driver verifier.
Given that the crash only happened every 6-18 hours, I left dad with instructions to keep note of further crashes.
(At this point, I thought I'd need at least one more round of troubleshooting).

A week later, my dad reported no more blue screens!
So problem solved!

## Conclusion

Using `windbg`, `autoruns` and `driver verifier`, you can make a decent guess at what is causing your Windows computer to blue screen.

Once you identify a driver causing the problem, you can either a) uninstall it, b) disable it, or c) update it. 


### Additional Resources

I don't claim to be a kernel debugger (most of my development is in nice high level languages like C#).
The links below have additional resources you can use if you have a blue screen (which I used to prepare this post).

https://social.technet.microsoft.com/wiki/contents/articles/6302.windows-bugcheck-analysis.aspx

http://www.techrepublic.com/blog/windows-and-office/how-do-i-use-windbg-debugger-to-troubleshoot-a-blue-screen-of-death/

[MSDN Channel 9 - Defrag Tools](https://channel9.msdn.com/Shows/Defrag-Tools)