---
title: Installing Home Batteries - Part 3
date: 2024-08-27
tags:
- Batteries
- UPS
- Solar
- Electrical
- Bluetti
- Home-Assistant
- Tuya
- Amber
categories: Technical
---

Running on battery power in my home.

<!-- more --> 

## Background

I have [installed batteries in my house](/2024-08-02/Installing-Home-Batteries-2.html), which will run low power devices overnight: fridge, freezer, networking gear, the server hosting this blog.

I've been running them for a month, so lets see how well it works (or doesn't)!

## Does it Work?

**TL;DR:** Yes it does!

I am able to run lighting, fridge, freezer, networking gear, servers, phone & laptop chargers, and a few other devices.
During the day, the [AC200L and B300](https://www.bluettipower.com.au/products/ac200l-portable-power-station) units charge when the sun is shining.
And, at night, all the above run on battery, making my overnight consumption practically zero!

<img src="/images/Installing-Home-Batteries-3/full-battery-setup.jpg" class="" width=300 height=300 alt="Full Battery Setup in my Garage." />

<img src="/images/Installing-Home-Batteries-3/24-hours-running-on-batteries.png" class="" width=300 height=300 alt="Home Assistant Graph: 24 Hours Running on Batteries. Pink is total consumption, blue is solar production, and cyan is net consumption / export to grid." />

<img src="/images/Installing-Home-Batteries-3/power-consumption-overnight.png" class="" width=300 height=300 alt="That 14W is what I draw overnight! The two UPS loads are what I would be drawing without batteries." />

## Gotchas

Of course, there are a few gotchas and teething problems I needed to solve along the way.

### Washing Machine

Our washing machine only accepts cold water, and has an internal heating element for heating water.
I've always used cold cycles for washing clothes (with the exception of cloth nappies from when our children were young). 
I had measured consumption of a washing cycle and found it was quite low (~0.2kWH).
So, I had thoughts of running the washing machine on battery.

Alas, there were two problems.

First, even on a cold cycle the machine runs the heating element for a minute or two when the cycle starts.
And this manages to pull very close to 10A.
With only a few other appliances on battery, this is enough to trip breakers and overload the AC200L's inverter.

Second, my original measurements didn't take [power factor](https://en.wikipedia.org/wiki/Power_factor) into account.
Turns out a washing machine is mostly a big inductive motor.
And that makes for a poor power factor - so 0.2kWH is actually more like 0.5kWH.

So, washing machine stays grid powered.
Oh well.

### Timing Charging

While the AC200L accepts DC input from photovoltaic sources, my solar panels remain connected to the GoodWe inverter installed with the panels.
This means I'm not charging from solar as optimally as I could.
Instead, I need to time when the sun is up and I can charge, vs when the sun goes down and I run on battery.

<img src="/images/Installing-Home-Batteries-3/bluetti-app-schedule.png" class="" width=300 height=300 alt="App schedule, timed to charge when the sun shines." />

Fortunately, sunrise and sunset are quite predictable, so timing is pretty easy.
Either based on some [moderately complex maths](/2016-04-18/Day-Night-Cycle-For-MotionEye.html), or simply looking at the graphs from Home Assistant each week and adjusting as required.

Note that Bluetti has a [whole house system](https://www.bluettipower.com.au/pages/ep760) which is a proper hybrid inverter, able to balance solar input, batteries and the grid.
Alas, such a system is more expensive than what I just bought - and these batteries were expensive enough!

### Sunny vs cloudy days

While sunrise and sunset are easy to predict, cloudy or raining days are much harder.

Well, its easy to check the weather each morning, but the effort required to modify schedules each day (and the risk I'll mess something up) means I don't bother.
I just accept that a cloudy or rainy day is more expensive than a sunny one.

<img src="/images/Installing-Home-Batteries-3/solar-on-sunny-day.png" class="" width=300 height=300 alt="Typical solar output on a sunny day in Winter." />

The more annoying thing is the way some light cloud cover can actually raise my solar output during the middle of the day.
This is because of shading which lasts a few hours.

In full sun, the output drops to ~500W.
But in light overcast, the output actually increases to ~1200W!

<img src="/images/Installing-Home-Batteries-3/solar-on-cloudy-day.png" class="" width=300 height=300 alt="Typical solar output on a cloudy day in Winter - compare the output from 12noon to 2pm with the sunny day." />

I suspect solar panels perform best when there is uniform solar radiation across the whole panel.
Full sun makes for harsh shadows.
While light overcast acts as a giant diffuser, and shadows become less pronounced.

Note that rain is terrible for solar - output is as little as 20% when its raining all day.

<img src="/images/Installing-Home-Batteries-3/solar-on-rainy-day.png" class="" width=300 height=300 alt="Typical solar output on a rainy day in Winter - it sucks!" />

### Death By 1000 Conversions

There are a lot of losses in my current setup:
* Solar power is DC
* Which is converted by the inverter to 230V AC, to integrate with the grid
* Which is converted back to DC to charge batteries
* Which is converted back to AC when batteries discharge
* Which is converted back to DC for many appliances (servers, routers, TV, etc)

The saving grace is, once you pay to install solar, energy is effectively free.
So, even if I can only use half the photons which hit my roof, that half is cheaper than buying from the grid!

Another part to inefficiencies is [power factor](https://en.wikipedia.org/wiki/Power_factor).
The clamp meters I used to estimate usage do measure power factor, but they didn't include it in the power consumed (their Watts measurement).
On the other hand, the clamp meters do (they match the data from my smart meter).

DC devices like routers, computers and TVs have quite poor power factors (well, at least mine do).
Often around 50%!
Which means yet more power isn't used to its full effectiveness, and the batteries discharge faster than I thought.

### Clamp Gotchas

A few days after the original installation, I installed all the clamp meters.
This let me monitor pretty much every circuit in the house, so I have an excellent idea of where power is being consumed.
Wonderful!

<img src="/images/Installing-Home-Batteries-3/clamp-meters.jpg" class="" width=300 height=300 alt="Those black blobs hanging off red wires are clamp meters." />

I thought it would be best to plug all 6 clamps into one of the batteries, so that, if there was a power outage, they would continue to run.

Only problem is, I got some really strange measurements:

<img src="/images/Installing-Home-Batteries-3/clamp-meter-graph-overall-power.png" class="" width=300 height=300 alt="What's with the strange 'scribble' which averages out to zero??!?" />

While I was running on battery, the clamps measuring total consumption and solar generation went crazy!
Showing negative and positive wattage.

It got stranger!
One of the clamps measures a sine wave on a 2 hour period:

<img src="/images/Installing-Home-Batteries-3/clamp-meter-graph-all-clamps.png" class="" width=300 height=300 alt="Drilling into individual clamps, its just as strange. Wait, is that a sine wave??!?" />

<img src="/images/Installing-Home-Batteries-3/clamp-meter-graph-sine-wave.png" class="" width=300 height=300 alt="Yes, that's a sine wave with a 2 hour period!! What the??!?" />

According to that, the bedroom and living circuit oscillated between positive and negative 400W over a two  hour period!
That just shouldn't be possible!

Turns out I didn't understand how AC power works.

<img src="/images/Installing-Home-Batteries-3/clamp-meter.jpg" class="" width=300 height=300 alt="Clamp meter. Input on left is AC for voltage. Inputs on right are DC for clamps." />

The clamp meters have 3 inputs.
Two are the physical clamps themselves.
the other is AC 230V, which is used to supply power for the clamp firmware and WiFi, and also to measure voltage.

> Power = Current x Voltage

That's easy for DC circuits.
But more complex for AC power, because the voltage of AC is varying from positive to negative 230V fifty times per second (50Hz).

The clamp measures voltage to calculate power.
But the voltage of the grid is not exactly 50Hz, it varies by a fraction over time.
And when the battery inverter is running, it is generating its own 50Hz waveform, slightly different to the grid.
So, if the clamp is measuring voltage based on an inverter, and current going to the grid, these will be out of phase.
So, sometimes the clamp thinks the voltage is negative when it is really positive, and thus thinks power is flowing in reverse.

The sine wave is when a clamp is using voltage from one battery to measure power from a second battery.
Although identical models, the inverters are very slightly out of phase.
Based on the 2 hour sine wave, they differ by ~0.000003Hz.
Which I think is pretty impressive - but still enough to mess with my clamp meters!

The fix is easy: power clamp meters from the same circuit they are measuring.
Then I get nice clean measurements:

<img src="/images/Installing-Home-Batteries-3/24-hours-running-on-batteries.png" class="" width=300 height=300 alt="This is what a power graph should look like!" />

### Leaking Power

I originally configured batteries to run on a schedule within their own app.
For the duration when I know my solar is producing power, they are configured as "off peak" and will charge from the grid (which is really my solar).
When my solar is not producing power, they are configured as "peak" and will run on battery only.
So the "peak" time is shortly before sunset until a little after sunrise.

<img src="/images/Installing-Home-Batteries-3/bluetti-app-schedule.png" class="" width=300 height=300 alt="AC200L schedule configuration, which matches my solar generation." />

My clamps (after I fixed the out-of-phase problem) showed a small, but consistent, export of power overnight - around 90W.
And this was confirmed via my utility company smart meter data.

<img src="/images/Installing-Home-Batteries-3/smart-meter-overnight-export.png" class="" width=300 height=300 alt="The sun is not shining at 10pm, but I'm exporting electricity somehow." />

Exporting overnight is nice, if you have the capacity.
Unfortunately, my little 5kWH batteries don't have enough capacity to last overnight with my internal load.
So, adding an extra 90W makes a significant impact overnight.

I'm told by others who have batteries, this is normal.
Even when batteries are "off", they aren't really off.

However, if you physically disconnect my batteries from the grid, they will operate as a UPS.
When there is no physical connection to the grid, they cannot export anything!

My solution was to use two of my plugin meters as timed switches.
They can act as a "smart switch", which is a fancy label for an on/off switch controlled by an app.
Just so happens you can configure the switch on a schedule.

<img src="/images/Installing-Home-Batteries-3/export-when-on-peak-setting.png" class="" width=300 height=300 alt="Usage is zero when running as a UPS, but exporting about 90W when using 'peak'." />

My actual schedule is a combination of Bluetti and Tuya configuration
The batteries never operate in "peak" mode, only "UPS" or "off-peak" modes.
And the Tuya schedule controls when the grid is on or off.
So the three states are:

* **Grid Off**: overnight when grid power is expensive and my solar isn't running, so run on batteries.
* **UPS**: early morning and late afternoon where I consume my solar, but there isn't enough power to charge batteries.
* **Off Peak**: during the day when solar is producing and power is cheap, this is when I charge batteries.

<img src="/images/Installing-Home-Batteries-3/bluetti-app-schedule-final.png" class="" width=300 height=300 alt="Config for Bluetti schedule - charge when the sun is shining or in the dead of night." />

<img src="/images/Installing-Home-Batteries-3/tuya-app-schedule.png" class="" width=300 height=300 alt="Config for Tyua schedule - switch on to charge from grid, or off to prevent power export." />

### Not Enough Energy

My bedroom and living room circuit powers my network gear, servers, a bunch of phone chargers, a desktop PC and our TV.
All together, these might draw up to 400W, and has base load of ~220W overnight.
I don't want to run the batteries down to zero; 20% is what I'd like to keep them above.
And that load is too much to run from ~4pm until 8am.
The maths says just the base load would use ~65% of battery capacity, and reality says it will be worse.

My preferred solution would be to purchase another 3kWH B300 expansion battery.
Unfortunately, my budget has already been spent, so I'm stuck with what I've got.

Instead, I will charge overnight for an hour, when prices are cheapest (around 2am).
That is enough to keep the battery above 20% charge, still makes good use of day time solar, and avoids drawing from the grid in peak times (just before sunrise, just after sunset).

<img src="/images/Installing-Home-Batteries-3/over-night-charging.png" class="" width=300 height=300 alt="An hour of charging at night time, when grid load (and prices) are low." />

### Servers

I have a number of servers which run 24/7 and contribute to the 220W base load on the bedroom and living circuit.
Some are quite low power - they are actually laptops!
Others are more powerful desktop PCs - they include a [Minecraft](https://www.minecraft.net/) server, and a [TrueNAS](https://www.truenas.com/) box.

<img src="/images/Installing-Home-Batteries-3/servers.jpg" class="" width=300 height=300 alt="~8 year old laptops are surprisingly effective servers." />

The TrueNAS, in particular, draws ~80W on its own (about one third of the base load).

I tried to re-arrange background tasks to run during the day, automatically shut the server down at night, and automatically restart it in the morning.

However, for some reason, the BIOS power-on timer never worked reliably.
And I ended up with a server which was drawing 80W, and yet wasn't running - the worst of both worlds!

It just runs 24/7 now.

### Limited High Draw Appliances

While my primary use case is running low draw appliances, I have experimented with a few high draw ones.

I already mentioned the washing machine, which was a fail.

But my laser printer (which is usually a big no-no for powering off a UPS) works very nicely on 100% battery power.
It does dim the lights for a moment when printing starts, but everything works fine after that.

Many kitchen appliances can also run off the batteries.
_But only one at a time._
Things like the kettle, air fryer, induction cook top, and sandwich press have all been tested OK.
They draw up to 1800W, for up to 15 minutes.
That does hit the state of charge a little, but not enough to impact operation over night!

<img src="/images/Installing-Home-Batteries-3/battery-kettle.jpg" class="" width=300 height=300 alt="Electric kettle drawing ~1.8kW from battery." />

I've run an extension lead into the kitchen so we can use appliances in a blackout or when power prices are high in the evening.

### Micromanagement

My biggest problem is the urge to micromanage everything!

I'm a programmer and computer nerd, so optimising is second nature.
When I can tweak settings and schedules and appliance usage to save a few Watt-Hours, its very tempting!

I. Must. Resist.

Until the day I get a hybrid inverter which dynamically controls grid, batteries and solar, I will never have a perfectly optimised system.
I need to accept that better isn't perfect.
But its still better.

 
## Do They Save Me Money?

Maybe. 

If they do, it isn't all that much using a regular energy company which charges a flat rate for consumption & export.
That is around $100 per month, in Winter (and a bit less in summer).

July was my lowest consumption ever, according to my smart meter data.
(Even if my usage is regularly low anyway).

<img src="/images/Installing-Home-Batteries-3/usage-from-electricity-provider.png" class="" width=300 height=300 alt="July was the lowest consumption. Just." />

I'm definitely being friendlier to the grid.
Because I'm not drawing as much power during the dawn and dusk peak periods.
And I'm drawing practically nothing over night (with the exception of ~1.2kWH to partially charge one battery).

To try and save a bit more, I have switched to [Amber Electric](https://www.amber.com.au/), which passes wholesale prices onto consumers.
In theory, that means charging during the day is dirt cheap (prices are low), and discharging overnight is also cheap (because batteries).
We'll see if that helps or not over the next few months.

Of course, on the day I changed to Amber, the wholesale price jumped to scary levels!!

<img src="/images/Installing-Home-Batteries-3/nsw-price-spike-7-aug.png" class="" width=300 height=300 alt="High prices are ~$300/MWh (~$0.40/kWh). This spike was 50x the normal definition of 'high'!" />

So, my regular energy company would cost a few dollars per day.
But the first day on Amber cost $34!
On the other hand, Amber usually costs less on other days.

I know Amber is best for people who export power during the peak periods.
I'm not really trying to do that, and my batteries only export by accident.

We'll see how it all averages out.


## Conclusion

I've purchased and installed batteries which run my low power, but long running appliances.
The installation is done, it looks great, and I can run my chosen circuits on batteries alone.
I've even switched over to a different power company.

I seem to use less power. I might even be spending less money.

I'm definitely being friendlier to the grid - avoiding using power in peak periods when prices are high.

It might also be because I'm thinking more about power and so micromanage and optimise. But I guess that's a good thing!