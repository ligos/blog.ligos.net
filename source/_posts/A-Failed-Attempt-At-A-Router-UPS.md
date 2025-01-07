---
title: A Failed Attempt at a Router UPS
date: 2025-01-07
tags:
- UPS
- Powerbank
- USB-C
- Router
categories: Technical
---

A USB power bank is not a UPS.

<!-- more --> 

## Background

I love batteries.
I [spent a lot of money on batteries](/2024-08-27/Installing-Home-Batteries-3.html) to run a good chunk of my house.

But I want more!!

Even though my NBN modem is protected by the Bluetti UPS, those batteries require maintenance every now and then. 
Annoying things like firmware updates and so forth.

And when they are undergoing maintenance, the router will reboot (at least once).
There is a change over switch, which is supposed to switch from UPS to mains power, but last time I used it, the earth leakage switch tripped.
And so the modem went off.
And my family was sad.

(Note that all the other networking gear in my house is protected by a real UPS.
And yes, I have a UPS behind a UPS.
Did I mention I love batteries?)

## Goal

I'd like a small UPS, which can power the NBN modem (or other small network devices like a router) when doing maintenance to the big batteries.

* Should run for 30-60 minutes.
* DC only; 12V at 2A.
* Cheap enough I can purchase it without raising my wife's eyebrows.


## Power Bank Plus USB-C Power Delivery

You can get a power bank which supplies [USB-C power delivery](https://en.wikipedia.org/wiki/USB_hardware#USB_Power_Delivery).
This allows up to 20V output, and said power banks usually have capacity of 30 Watt Hours or higher.
More than large enough for running a router or modem for an hour.

Neither my modem or router are powered by USB-C.
However, you can [purchase USB-C cables](https://www.aliexpress.com/w/wholesale-usb%252525252dc-to-dc-12v.html), which advertise a particular voltage, and have a DC plug suitable for powering various electronic equipment.
This would request the power bank supply 12V (in my case), and power my router or modem.

Then you just need a power bank which can charge and discharge at the same time.
That is, one with two USB-C ports.

After a bit of shopping around, I found the items I needed:
* [Laser 100W 20AH Power Bank](https://www.mwave.com.au/product/laser-100w-20000mah-power-bank-with-led-display-screen-ac77352) - $99, on sale.
* [Power Delivery to DC Cable; 5V to 20V Selectable; With Assorted DC plugs](https://www.aliexpress.com/item/1005006506713488.html) - approx $15
* 33W USB charger - came with my last phone; unused in the cupboard; $0
* USB charging cable - found in cupboard; unknown providence; $0

And arranged for them to be purchased as Christmas gifts (or found them in my tech cupboard).

Here they all are:

<img src="/images/A-Failed-Attempt-At-A-Router-UPS/all-the-parts.jpg" class="" width=300 height=300 alt="All the parts for my UPS" />

The power delivery cable has a button which lets you select between 5V, 9V, 12V, 15V and 20V.
In my case, 12V is what I need.
There are cheaper cables with a fixed voltage, but I wanted something flexible.

<img src="/images/A-Failed-Attempt-At-A-Router-UPS/power-deliver-cable.jpg" class="" width=300 height=300 alt="Power delivery cable" />

The power delivery cable also comes with a variety of DC plugs.
The Lenovo one on the left is compatible with my ageing laptop.

<img src="/images/A-Failed-Attempt-At-A-Router-UPS/DC-plugs.jpg" class="" width=300 height=300 alt="A variety of DC plugs" />

The power bank has two USB-C connectors, each power delivery compatible, and capable of charging and discharging.
It also has two USB-A connectors, which aren't so interesting to me.

<img src="/images/A-Failed-Attempt-At-A-Router-UPS/power-bank-front.jpg" class="" width=300 height=300 alt="Power bank - front" />

The back of the power bank has all the technical details of charging and discharging parameters.
Of interest to me is that it can supply 12V at at least 3A. 

<img src="/images/A-Failed-Attempt-At-A-Router-UPS/power-bank-back.jpg" class="" width=300 height=300 alt="Power bank - back" />

Here we have the power bank charging at 12V 1.5A, and also powering the power delivery cable at 12V (albeit, with no load):

<img src="/images/A-Failed-Attempt-At-A-Router-UPS/power-bank-charging-and-discharging.jpg" class="" width=300 height=300 alt="Power bank charging and discharging at the same time" />

Finally, here we have the power bank charging and powering my NBN modem (sorry about the mess of cables)!
Turns out the modem only draws ~0.6A, so the power bank has plenty of head room.

<img src="/images/A-Failed-Attempt-At-A-Router-UPS/power-bank-powering-the-modem.jpg" class="" width=300 height=300 alt="NBN modem, powered by power bank as a UPS" />


## Failure - A Power Bank is not a UPS

I ran the router for a few minutes from the power bank and all worked well.
And then I decided to pull the USB charger, to test the cut over from mains to battery.

This failed.
The router powered down, and then powered back up again.

Turns out that when the charger is disconnected, the power bank does some kind of reset.
The output stops for a few seconds, and is then restored.

Two seconds is ~1.99 seconds too long to be a UPS.

(A similar thing happens when the charger is re-connected; everything powers down for a moment before coming back up again).

Here's a video of what happens (for a router not connected to the internet rather than my modem; I decided not to repeatedly disconnect my family from the internet):

<video controls preload="metadata">
  <source src="/images/A-Failed-Attempt-At-A-Router-UPS/demo-power-outage-on-power-bank.webm" type="video/webm">
</video>

## Conclusion

It turns out that if you want a UPS, you should purchase a UPS.
And a power bank is not a UPS.

Seems that [AliExpress has pretty cheap DC UPS devices](https://www.aliexpress.com/w/wholesale-DC-UPS-Battery-Backup-.html?spm=a2g0o.detail.search.0), exactly for the purpose of powering a 12V router or modem.
Perhaps, instead of looking for a fancy power banks and USB power delivery cables, I should have looked for the actual thing I wanted.

Oh well.

The power bank is pretty nice on its own.
And being able to supply 12V for some electronics or 20V to charge an old laptop is useful as well.
