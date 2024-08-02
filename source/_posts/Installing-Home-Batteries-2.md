---
title: Installing Home Batteries - Part 2
date: 2024-08-02
tags:
- Batteries
- UPS
- Solar
- Electrical
- Bluetti
categories: Technical
---

Second step to installing batteries in my home: buying batteries.

<!-- more --> 

## Background

I want to install batteries in my house. 

In the [previous article](/2024-07-10/Installing-Home-Batteries-1.html), I described how I used Home Assistant and energy meters to gather data about my energy usage.
This has given me the information to chose the right batteries, which give the capacity required for my needs.

Just a reminder, I want to power low power devices overnight.
Things like fridge, freezer, networking gear, and server hosting this blog.

## Choosing Batteries

The maximum load of the devices I'd like to power is 500W, and overnight is about 14 hours in winter time, which is ~6kWh.
That means I need a small inverter and large batteries, because that 500W load adds up over 14 hours.

I have been researching the idea of batteries for over 18 months, coming at it from several perspectives.

The most obvious option is the **"whole house" batteries**.
This is your [Tesla Powerwall](https://www.tesla.com/en_AU/powerwall), or [Sungrow Batteries](https://aus.sungrowpower.com/productDetail/2116/battery-sbr064-096-128-160-192-224-256), or [others](https://www.choice.com.au/home-improvement/energy-saving/solar/articles/solar-battery-trial).
When I got solar panels installed, my utility company quoted about $10,000 for a 9.6kWh Sungrow battery.

The big problem I have with these is they are big and expensive and aren't always upgradable.
This means big capital purchases for physically large batteries which are difficult for me to find a home for.

So, I tried approaching the problem as an IT nerd: **I already have battery backups, they're called [a UPS](https://en.wikipedia.org/wiki/Uninterruptible_power_supply)**.
The $150 UPSs I've bought to protect my networking gear and severs have cheap [sealed lead acid (SLA)](https://en.wikipedia.org/wiki/VRLA_battery) batteries.
But, because the load is so low, they often last ~2 hours in a blackout.

Maybe I can scale up to a big UPS?

Turns out this isn't a great idea.
The SLA batteries have a lifetime of ~3-5 years before they basically don't work at all.
While they are [pretty cheap to replace](https://www.altronics.com.au/p/s4542-12v-9ah-sealed-lead-acid-sla-gel-battery/), I'd need to replace them more often than I'd like.
There were a handful of lithium based UPSs, and they had a 2-3x price premium over their SLA counterparts.

I did some research and found some [large UPS systems](https://upssolutions.com.au/products/ups-solutions-xrt6-online-ups-10kva-w-long-life-battery-230v-rack-tower-6u).
They were still expensive, big, tricky to install, and they didn't even look like they had enough capacity to last overnight.

Finally, large scale UPS systems are designed to run on batteries for a short period of time (a brownout or 15 minute blackout) before a generator kicks in.
And they charge slowly - so slowly I wasn't convinced they would recharge during the day after discharging overnight.

My final, and most crazy idea was: **built it myself**!

That lasted for about 30 minutes.
I'm no electrical engineer, and the idea of working with large lithium ion batteries, busbars carrying 50A+, hooking up charging circuitry, connecting an inverter, and dealing with 230V outputs was just too scary.

I didn't have the time, and also didn't have the expertise.

Eventually, I found a curious product: the **portable power station**.

[Portable power stations](https://outbax.com.au/collections/camping/power-stations) are pitched at camping, worksites and off-grid living.
They have inverters ranging from ~1kW to up 5kWs.
They use lithium chemestries.
They are designed for running long periods on batteries alone.
And they don't cost as much as "professional" UPSs.

Essentially, they're a big lithium based UPS, which seem perfectly designed for my use case!

This eventually lead me to [Bluetti](https://www.bluettipower.com.au/), which had a great combination of price, features and upgrades.

## Bluetti AC200L + B300

I chose the [Bluetti AC200L](https://www.bluettipower.com.au/products/ac200l-portable-power-station) plus a [B300 expansion battery](https://www.bluettipower.com.au/products/bluetti-b300-expansion-battery).
On paper, this gives me ~5kWhs of [lithium iron phosphate (LiFePO)](https://en.wikipedia.org/wiki/Lithium_iron_phosphate_battery) battery capacity, a 2.4kW inverter, USB and DC outputs, all the charging smarts from AC or DC inputs, and an app to control it all.

There are a [bunch of videos about the AC200L](https://www.youtube.com/results?search_query=bluetti+ac200l) out there.
The [best one](https://www.youtube.com/watch?v=AZZpUBdbSJw) goes into considerable detail about all capabilities, specs, benchmarks and gotchas. 
Just a note: that's a 90 minute video!

Here are some unboxing pictures:

<img src="/images/Installing-Home-Batteries-2/boxed-ac200l-and-b300.jpg" class="" width=300 height=300 alt="The B300 is in the front, AC200L at back. And that's my garage door in the background - those are some big boxes!" />

<img src="/images/Installing-Home-Batteries-2/B300-on-a-pallet.jpg" class="" width=300 height=300 alt="The other B300 arrived on a pallet!" />

<img src="/images/Installing-Home-Batteries-2/b300-box-open.jpg" class="" width=300 height=300 alt="Both units come double boxed! And have cables - this is the B300." />

<img src="/images/Installing-Home-Batteries-2/cables-from-AC200L-and-B300.jpg" class="" width=300 height=300 alt="Cables from AC200L and B300. Plus some manuals and a bag." />

<img src="/images/Installing-Home-Batteries-2/AC200L-B300-stacked.jpg" class="" width=300 height=300 alt="AC200L and B300 stacked on top of each other. As yet, unpowered." />

And how the unit looks, when I was testing it (before any electrical work).

<img src="/images/Installing-Home-Batteries-2/AC200L-B300-powered-on-and-under-test.jpg" class="" width=300 height=300 alt="AC200L and B300 stacked on top of each other, powered on, charging and under test." />

Oh... and I decided I'd need two to safely cover my needs!

The AC200L cost $2,400, and the B300 cost $2,500, with some end of financial year discounts. 
Two of each total to $9,800 for ~10kWh of nameplate capacity, or a little under $1 per Wh, which is slightly better than average in Australia.

### Specs and Capabilities

Let's walk through what the power station can do!

#### AC and DC Outputs

The core of any portable power station or UPS is AC outputs.
The AC200L has 4 x 230V, 50Hz AU plug outputs, and can supply up to 2400W in total.
My needs are usually in the 200-400W range, but there are occasional spikes (eg: using a laser printer).

On the DC side, there are 2 USB-A outputs rated at ~30W between them and a USB-C output which can supply up to 100W.
These are nice to charge phones and tablets overnight.
And, I've run my son's laptop off the USB-C output while playing some games.

<img src="/images/Installing-Home-Batteries-2/AC200L-B300-outputs.jpg" class="" width=300 height=300 alt="AC, USB and DC outputs" />

Both the AC and DC outputs have an "eco mode".
Which is a timer to turn the outputs off after a few hours when the output falls below a configured level.
This is because there is some overhead running the AC inverter & DC circitry, even if nothing is plugged in.
As I'm running these overnight to replace the grid, the AC eco mode got disabled.
But DC is set to an hour, which lets me charge devices without the risk of over charging.

There is a 12V DC output, which I'm unlikely to use.
And a magic 48V DC output, which is very tempting to run to my appliances, as about half of what I'm powering would prefer DC over AC (think computers, smart TV, and network gear), and I'm sure there are significant losses converting between AC and DC several times over.
Alas, it requires a proprietary Bluetti dongle thing, which isn't available in Australia.

#### AC and DC Inputs

On the input side, you can connect various DC sources - 12V batteries or solar panels via an MPPT controller.
I'm not likely to ever use those though.
You can also connect to the grid using an AC cable (not a standard IEC cable - I suspect this is so Bluetti can charge at up to 15A on 110V grids).

One tiny gotcha I found was turning the device off: you must switch off the grid input and disconnect before the AC200L will power off.

#### Status Screen

You can see status via a nice bright LCD.
This isn't a full graphical LCD like a phone, but fixed function - like what you'd see on a microwave.
But it is clear, bright, colourful, and more than functional.
Current level of charge, time to full charge (when charging) or zero charge (when discharging), and current AC and DC input and output (in Watts) are all clearly visible.

There are three simple buttons to control the AC inverter, DC, and USB outputs.
Press any button once and the display lights up, and a second time to turn it on / off.

<img src="/images/Installing-Home-Batteries-2/AC200L-status-screen.jpg" class="" width=300 height=300 alt="Status screen" />


#### B300 Expansion

The B300 can be used as a stand alone DC battery, with USB and 12V outputs, plus an MPPT controller for charging.
However, I've always connected the B300 as an expansion battery, and the main AC200L controls it automatically.

The AC200L can use 2 x B300 expansions.
[Other Bluetti units](https://www.bluettipower.com.au/products/bluetti-ac300-b300-home-battery-backup) can link with up to 4 x B300s, or use different expansion units.
I may take advantage of an extra B300 in the future, but for now, I'm running one AC200L and one B300 together.

<img src="/images/Installing-Home-Batteries-2/AC200-with-B300-stacked.jpg" class="" width=300 height=300 alt="AC200L and B300 expansion" />

#### Weight and Size

The units are heavy, and just barely portable by one person around my house (~15m).
[Exact weight specs are on Bluetti's website](https://www.bluettipower.com.au/products/ac200l-portable-power-station).
If I was taking these camping or moving them around, I'd want two people to lift them, or even a trolley ([Bluetti actually sell a trolley](https://www.bluettipower.com.au/products/bluetti-folding-trolley)!)

The size is just about perfect to fit under some steel shelves in my garage, near my switch board.
The B300 is wider and flatter, while the AC200L is a bit taller and narrower.
[Exact size specs are on Bluetti's website](https://www.bluettipower.com.au/products/ac200l-portable-power-station).


#### App

The AC200L has app connectivity.
This is via BlueTooth, which is entirely offline (essential if you're taking the unit camping), or via WiFi, which hooks in to Bluetti's cloud service and requires an Internet connection.

Many other sources have the basic app operation, so I won't repeat many details here.
Suffice it to say, pretty much all the on-screen data and on / off buttons are duplicated in the app.

<img src="/images/Installing-Home-Batteries-2/app-main-screen.png" class="" width=300 height=300 alt="App Main Screen" />

One gotcha: you can only update device firmware via BlueTooth.
I only connected via WiFi for the first few weeks, only to find there were a bunch of updates when I first checked via BlueTooth.

My usage is geared toward controlling how and when the units charge and discharge, so here's more detail about that.

<img src="/images/Installing-Home-Batteries-2/app-settings.png" class="" width=300 height=300 alt="App Settings - These bits interest me" />

#### App - Charging Mode

_Charging Mode_ has three options - `Standard`, `Turbo`, and `Silent`. `Turbo` tries to charge as quickly as possible, even if this might reduce battery life - I'd rather protect my expensive batteries so haven't tried this mode. `Silent` restricts charging to ~600W; it isn't entirely silent, but definitely runs fans less often. `Standard` is what I settled on: it charges at ~1200W from the grid. I may change over to `Silent` in Summer when there are more hours of sun in the day.

#### App - Working Mode

This is where all the action is.
There are a few options, but I chose `Custom` because it enables all the possible settings.

<img src="/images/Installing-Home-Batteries-2/app-working-mode.png" class="" width=300 height=300 alt="App Working Mode" />

The `SOC Setting` controls what percentage the battery will charge and discharge to.

The `Time of Use` slider enables the _Schedule_, which (as far as I'm concerned) is the most interesting part of the app.

`Schedule` lets you add 6 scheduled daily durations. Each of those durations can be either `Off-Peak`, or `Peak`. Any remaining time is blank, but I'll refer to it as `UPS`. Here's what they do (assuming plugged in to grid):

* `Off-Peak` = the unit will charge as fast as other settings allow (_Charging Mode_ and _Max Charging Current of Grid_ are the relevant settings).
* `Peak` = the unit will run on battery, not attempting to charge at all.
* `UPS` = the unit will pass power from the grid, but not attempt to charge. Essentially, it will be a UPS.

There is a [YouTube video](https://www.youtube.com/watch?v=lENGwfq-MIA) which details all possible combinations of _Working Mode_ with AC & DC charging, if you're interested.
Note: 50 minute video.

<img src="/images/Installing-Home-Batteries-2/app-schedule.png" class="" width=300 height=300 alt="App Schedule" />

#### App - Advanced Settings > Max Charging Current of Grid

This has been detailed on [YouTube videos](https://www.youtube.com/watch?v=lENGwfq-MIA), and is essentially a way to restrict (or increase) the maximum current the device will pull from the grid. In Australia, we can safely pull 10A from standard power outlets, but you can ask Bluetti Support for a magic code to increase that to 12A (I don't have a need to charge that fast, so haven't bothered). 

I experimented with reducing the maximum current for a few weeks, but have ended up putting it back to the default 10A.

#### App - Data Logging

Not long after I purchased the devices (and perhaps coinciding with firmware updates), several time-series graphs appeared:

* **Daily Power Profile**: this measures Watts for AC & DC inputs, plus AC & DC outputs.
* **Energy Statistics**: this measures kWhs for AC & DC inputs, plus AC & DC outputs.
* **SOC Trend**: this measures the percentage of charge.

I tend to keep an eye on SOC Trend, and ignore the others, because Home Assistant gives me that data. 

<img src="/images/Installing-Home-Batteries-2/app-soc-trend-graph.png" class="" width=300 height=300 alt="App SOC Trend" />

#### Tear Down

I'm not about to void warranties or destroy my brand new batteries. [But someone else has](https://www.youtube.com/watch?v=vfDSTvmsAbk) - yay for YouTube!

## Electrical Work

It's all good to have batteries.
But I need to connect them into my home circuits for them to be used.
While its possible to run various appliances from the power stations directly, that gets pretty tedious.
It also means I cannot run important things on batteries like lighting.

So, I engaged an electrician to replace the switch board, add a change over switch between mains and batteries, and add outlets to charge and connect the power stations to some circuits.

A big shout out to [Daniel from Lighting Electrical and Communications](https://leac.com.au), who did this work very professionally and to a very high quality.
And put up with my nerd-ness doing work which was a bit unusual!

There are three circuits which can be powered from batteries, and one last area which runs directly from the power station via extension lead:
* Lighting (UPS 1)
* Fridge (UPS 1)
* Freezer and home office (aka, the garage, powered directly from UPS 1)
* Living room and bed room (UPS 2)

The main switch board was upgraded to be twice the size, allowing me to add clamp meters on almost all circuits.
The only thing I couldn't clamp was the wire coming from the grid - I might have another go at that in the future.

<img src="/images/Installing-Home-Batteries-2/old-switchboard.jpg" class="" width=300 height=300 alt="Old Switchboard - its tight in there!" />
<img src="/images/Installing-Home-Batteries-2/new-switchboard.jpg" class="" width=300 height=300 alt="New Switchboard - so much room, even with extra clamps" />

The change over switch allows switching between mains and the batteries for the above three circuits.
This is a manual switch, and I've operated it exactly once - its now permanently set to "UPS".
Although I plan to always be running from batteries, it is important to have a bypass switch, in cast maintenance needs to happen (and I'm sure it will be needed at some point).

<img src="/images/Installing-Home-Batteries-2/UPS-change-over-switch.jpg" class="" width=300 height=300 alt="UPS Manual Change Over Switch - Up is Mains, Down is UPS, Middle is Off" />

Finally, there's a dedicated 20A circuit going to a power outlet to supply the power stations.
And two sockets which run back up to the switchboard.
The supplied cables are used for grid charging, and some short extension leads run from one of the AC outlets back to the switchboard.

<img src="/images/Installing-Home-Batteries-2/UPS-feeds.jpg" class="" width=300 height=300 alt="Feed to Circuits (left), and UPS supply (right)" />

## Installed Batteries

Here is a picture of the whole setup.

<img src="/images/Installing-Home-Batteries-2/full-battery-setup.jpg" class="" width=300 height=300 alt="Full Battery Setup" />

Although the power stations think they are always charging from grid, I use the schedule feature charge when the solar panels are generating.
This is entirely based on timing, but the sun rises and sets on a pretty reliable cycle, and all I need to do is check every week or two and adjust as required.

And the boring part is: **it Just Works™**.

Through the day, the batteries charge.
In the evening, they power our lights, fridge, freezer, servers, network gear, and phone chargers.

OK... there were some gotchas and glitches, but I'll address those in the next article.

## Conclusion

I've purchased and installed batteries which run my low power, but long running appliances.
The installation is done, it looks great, and I can run my chosen circuits on batteries alone.

So far, so good!

The real question is: does my setup actually save power and money?

I'll answer that in the next post!
