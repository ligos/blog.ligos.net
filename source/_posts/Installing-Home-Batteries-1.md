---
title: Installing Home Batteries - Part 1
date: 2024-07-10
tags:
- Batteries
- Solar
- Electrical
- Home-Assistant
- Tuya
categories: Technical
---

First step to installing home batteries: gathering data.

<!-- more --> 

## Background

In Australia, it looks like the future is electric and powered by renewables like solar and wind, backed by storage (hydro and batteries), with a bit of gas in the mix as well. [Possibly even nuclear](https://www.abc.net.au/news/2024-06-20/nuclear-dutton-coalition-unanswered-questions-beak-rules/104000664), if the Liberal Party wins the next election.

In any case, [coal is on the way out](https://en.wikipedia.org/wiki/List_of_power_stations_in_New_South_Wales#Coal_fired). Gas and petrol are getting more expensive.
And electric vehicles are (slowly) gaining popularity.

I got PV solar installed on my roof top in January 2023, and would love to get some batteries to store that solar energy for use over night.
Alas, PV panels and an inverter are relatively cheap, but batteries are expensive.

But recently, something changed: the authority which manages most of the Australian energy market - [AEMO](https://aemo.com.au/) - has [hinted at supply shortages as coal power plans are phased out](https://www.abc.net.au/news/2024-05-26/nsw-market-meltdown-sparks-energy-transition-warning/103890282). As early as this coming summer (2024-2025).

We rarely have blackouts in Sydney, but on the odd occasion we do, its really inconvenient.
Pretty much everything (except for heating water) in my house depends on electricity!
(And water heating will be electrified when my current gas fired system fails).

When my mother-in-law generously gifted us a large sum of money, I thought now is the time to get started with some home backup batteries!

## Goal

Install some batteries as a partial backup system in the event of a power outage.
And, to be able to charge said batteries during the day when the sun is shining (effectively for free).
And, to consume that stored power over night, when I'd otherwise be paying for electricity.

Even with my mother-in-law's substantial gift, I can't afford full house backup (and there are other things we also need to use that money for aside from my pet projects).
I'd like to cover a number of important items:

* Lighting
* Fridge and freezer
* Router and servers

Other low draw appliances are nice to have (TV, charging laptops and phones), but not essential.

Out of scope are all high draw appliances:
* Air Conditioning
* Heating
* Cooking

These all require a substantially larger inverter and batteries than I can afford.

I don't want something I need to build myself, but I would like something I can maintain.
I'm not a licensed electrician, so don't want to be messing with 230V AC or large lithium battery cells - out of the box is quite important.

Having said that, I know I'll need to get an electrician involved, because the batteries need to be wired into existing circuits.

First up, I'm a nerd, so I need to gather data!


## Plugin and Clamp Meters

So I purchased some devices to log power usage.
Both were from Aliexpress: a [plug in meter](https://www.aliexpress.com/item/1005004457142294.html) and a [clamp meter](https://www.aliexpress.com/item/1005005985883926.html).
The former lets you plug in any appliance and measure power consumption, and the latter is a sensor which clamps around the active electrical wire in your switch board to do the same thing.

I used plugin meters to monitor things like my fridge, TV and servers.
While the clamp meters were for lighting, air conditioning and all my appliance circuits.

These are all WiFi enabled Internet of Things devices, which use the [Tuya backend](https://www.tuya.com/).
That is, they are relatively cheap devices based on a Chinese IoT platform with some standards for data gathering.

<img src="/images/Installing-Home-Batteries-1/plugin-meter.jpg" class="" width=300 height=300 alt="Plugin Meter" />
<img src="/images/Installing-Home-Batteries-1/clamp-meters.jpg" class="" width=300 height=300 alt="Clamp Meters in Switchboard" />

Aside: I created an [isolated IoT network](/2016-07-28/How-To-Make-An-Isolated-Network.html) on my Mikrotik AP.
Because the "s" in IoT stands for security, and I don't want cheap devices, which will almost certainly end up with security issues in their lifetime, sitting on my main network.

Fun fact: every single IoT device I've purchased (from the above devices, to my solar inverter, and even the battery I finally chose) only supports 2.4GHz WiFi.
I guess they don't need much bandwidth - but I'm glad every other device in my house is 5GHz.

## Home Assistant

Now, I initially purchased these devices knowing there a [C# library](https://github.com/ClusterM/tuyanet) out there which can link into the Tyua Internet of Things world.
But turns out I didn't have time to write a data logger application, keep it running 24/7, or visualise the results.

So I installed [Home Assistant](https://www.home-assistant.io/).

There are already [instructions out there for installing Home Assistant](https://www.home-assistant.io/installation/linux), so I won't bother doing a step by step here.
I chose the ["core" installation](https://www.home-assistant.io/installation/linux#install-home-assistant-core) for my Debian server without Docker - apparently this is advanced stuff, even if its what I've been doing for the last ~15 years.
The most annoying thing is it doesn't auto-update, so every month or two I need to [manually follow their update instructions](https://www.home-assistant.io/common-tasks/core/) - the hardest part is remembering.

I used the [LocalTuya](https://github.com/rospogrigio/localtuya) plugin to integrate with the Tuya devices.
And within an hour, I had some pretty graphs on screen!

<img src="/images/Installing-Home-Batteries-1/plugin-usage.png" class="" width=300 height=300 alt="Home Assistant Graph" />


## The Data!

Finally, some data!

I spent a good 6 months gathering data, so I could see any patterns in Summer vs Winter.
And here are some things I found.

### Solar Power is great in Summer, and sucks in Winter

<img src="/images/Installing-Home-Batteries-1/solar-generation-winter.png" class="" width=300 height=300 alt="Solar Generation in Winter" />
<img src="/images/Installing-Home-Batteries-1/solar-generation-summer.png" class="" width=300 height=300 alt="Solar Generation in Summer" />

(Note that Home Assistant deletes high precision data after ~14 days and replaces it with an hourly approximation, so the Summer data looks less detailed in these graphs).
In Summer, there are 3 more usable hours of sun as compared to Winter. 
And, that sun is more intense, give more usable kWHs of power and a higher, longer peak.
And, there is less shading over my panels (that big dip in the middle of Winter).

In Winter, I might generate 15kWH on a good day, while Summer can exceed 45kW.

In short, if I can charge batteries in Winter, then I should have no problems in Summer!

### Plugin Meters Show Low Draw Appliances

<img src="/images/Installing-Home-Batteries-1/plugin-usage.png" class="" width=300 height=300 alt="Plugin Meter Usage" />

This graph shows usage from a number of low draw (low wattage) devices including my fridge (orange), freezer and home office setup (cyan), servers (purple), and TV and network (blue).
These devices rarely exceed 100W individually, and total about 500W at their peak (around 6-7pm). 

They are my prime targets to power by batteries overnight, after said batteries are charged from solar during the day.

<img src="/images/Installing-Home-Batteries-1/lighting-usage.png" class="" width=300 height=300 alt="Lighting Usage" />

I'm going to lump lighting in under the _low draw_ banner as well, although it was measured via a clamp meter.

If we assume a conservative draw of 500W continually, and 16 hours in Winter when we need to run batteries, we get around 8kWH required each night.
This number will be important when choosing batteries.

### Clamp Meters Show High Draw Appliances

<img src="/images/Installing-Home-Batteries-1/appliance-usage.png" class="" width=300 height=300 alt="Appliance Usage" />
<img src="/images/Installing-Home-Batteries-1/ac-usage.png" class="" width=300 height=300 alt="Air Conditioner Usage" />

These graphs are for appliances (covering two 20A circuits for all plugin appliances), and air conditioning.
Unlike the low draw appliances, these have some very high peaks (over 4kW for appliances), and sometimes sustained high draw (air conditioning in reverse cycle runs at 1-2kW for several hours).

Note that the appliance graph actually covers all the plugin meters! But their usage is, essentially, base load
which peaks at 800W, and is more usually under 500W.

These appliances are mostly in our kitchen - the kettle, toaster, air fryer, microwave, and induction cooker.
They are used for short periods of time, but draw 1.5kW+ each.

These won't be targeted for batteries (at least not right now), because that will cost double what I'm prepared to spend now!

### Evening Peak

All these graphs show peak usage is between 4pm and 9pm.
When everyone is home after school & work, and cooking dinner, and relaxing before going to bed.

Unfortunately, this peak is just after the sun sets in Winter, and has only partial overlap in Summer.

<img src="/images/Installing-Home-Batteries-1/grid-demand-and-price.png" class="" width=300 height=300 alt="Grid Demand and Price" />

There's some great data from [AEMO and other sources](https://opennem.org.au/energy/nsw1/?range=3d&interval=30m&view=discrete-time), which show energy demand, and supply by source, and pricing.
This shows a common pattern in NSW: power is cheap during the day because solar is ridiculously cheap (sometimes the price even goes negative). 
But the sun goes down right when demand spikes in the evening, leading to high wholesale prices from 5pm-9pm.

**This is the prime use case for batteries - store power during the day when the sun delivers cheap energy during the day, and use that power in the evening.**


## Conclusion

So far, I've gathered data about the details of my power usage.
From this information, I have chosen the high value, low draw appliances which I'd like battery backup for: lighting, fridge & freezer, networking, and servers.
And, I know approximately how much battery capacity I need to run overnight: at least 8kWhs.

Next up: [choosing and purchasing batteries](/2024-08-02/Installing-Home-Batteries-2.html).


