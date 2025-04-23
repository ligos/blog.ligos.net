---
title: A Heat Pump Hot Water System
date: 2025-04-23
tags:
- Electric
- IoT
- Home
- Hot-Water
- Unpaid-Review
categories: Technical
---

From gas to electric hot water.

<!-- more --> 

## Background

Back in January, my hot water heating system failed.

This was a gas powered system which was installed not long after we moved into our unit, perhaps 12 years ago.
I've been told the average age for hot water systems is 10 years, so this wasn't unexpected.

Although, it was rather inconvenient!

<img src="/images/A-Heat-Pump-Hot-Water-System/old-hot-water-system.jpg" class="" width=300 height=300 alt="The water is supposed to be on the inside 😥" />

The failure mode was some kind of water leak, rather than the heating itself.

But a failure is still a failure. 
So it was time to purchase a new hot water heating system!


## System Selection

I'm on the path to electrifying my home.

Part of the is environmental - with solar panels on the roof, and batteries for overnight, and a sunny day, I'm mostly independent from the NSW electricity grid. In 2025, we're still generating about half our electricity from coal, and that's bad for the environment. So I'm doing my little bit and removing a few kilowatt hours from the grid, and burning a tiny bit less coal.

Yay for me!

Another part is cost - with solar panels, electricity is somewhere between free (sunny day) to cheap (cloudy day) during the day. While the [price of gas has been creeping up](https://www.aer.gov.au/industry/registers/charts/gas-market-prices) in NSW. 

So, I had already decided the hot water system would be electric.
And the [most efficient way to heat water electrically](https://en.wikipedia.org/wiki/Water_heating) is a [heat pump](https://en.wikipedia.org/wiki/Heat_pump).

(Heating water using direct solar isn't an option for me, because my roof is already covered in PV panels. I believe direct solar heating is more efficient than a heat pump, but alas, I don't have that option).

So now it was a matter of choosing which heat pump hot water system would be best.

I got some quotes and recommendations from some local companies which do plumbing, hot water and electrical work.

The general recommendations were:
1. Chose a reputable brand. They may cost a bit more, but they are more reliable and easier to repair. The big brands in Australia are: [Rheem](https://www.rheem.com.au/), [Dux](https://www.dux.com.au/) and [Rinnai](https://www.rinnai.com.au/).
2. Chose a larger tank than with gas. Heat pumps are efficient, but they heat more slowly than gas.

I also wanted a system which gave control over what time of day it would heat. So probably some kind of IoT app.

In the end, [Australian Hot Water](https://australianhotwater.com.au/) quoted a [Dux Ecosmart 300DHA20 model with a 285L tank](https://www.dux.com.au/products/ecosmart-heat-pump-290/).
The cost to supply, install, and remove the old heater was $3,500.

I did my research and yes, the Dux Ecosmart heat pumps have an app which can schedule the heating times.
And control a bunch of other things.

So the Dux Ecosmart it is!


## Installation

When I [installed batteries](https://blog.ligos.net/2024-08-02/Installing-Home-Batteries-2.html), I asked the electrician to install a new circuit for an electric hot water heater. I figured my existing heater was getting close to the end of its service life, and doing some work in advance would be helpful.

This proved to be the case as every company that quoted was pleasantly surprised they wouldn't need to do any electrical work - it was just pull the old system out, and install the new one.

And that's what happened. 

Australian Hot Water came at 9am with the new DUX Ecosmart system. 
The old gas system was removed.
And new one was operational by midday; with actual hot water by around 4pm.

It was all very easy.

<img src="/images/A-Heat-Pump-Hot-Water-System/new-hot-water-system.jpg" class="" width=300 height=300 alt="DUX Ecosmart is installed and making water hot 🔥" />


## App

The DUX Ecosmart system has an [Android app](https://play.google.com/store/apps/details?id=net.linkio.dux&hl=en&gl=US&pli=1), which allows a degree of automation of the hot water system.

The app had under 1000 installations when I downloaded it, which I'm pretty sure is the least popular app on my phone!
I guess it's a bit of a niche market.

<img src="/images/A-Heat-Pump-Hot-Water-System/app-status-eco-mode.png" class="" width=300 height=300 alt="App Status Screen - Eco Mode" />

There's a status screen, which shows the current water temperature, and target temperature.
Along with the ability to change heating modes.

This seems a good point to introduce the three modes of heating:

1. **None** - labelled as "holiday mode" or "frost protect mode", the system aims for ~20°C water. While the temperature remains higher than that, no heating happens; the system consumes less than 5W.
2. **Heat Pump Only** - labelled as "eco" mode, the system uses the heat pump to heat water up to 60°C. The system consumes 600-700W in this mode.
3. **Heating Element** - labelled as "boost" mode, the system uses an electric heating element to either heat in conjunction with the heat pump (faster heating), or to heat over 60°C (71°C is the highest configurable). The element draws 1.2kW; when combined with the highest draw I've measured is a little under 1.9kW.
4. **Auto** - which isn't really a mode, but selects automatically between options 2 and 3. It allows both heat pump and element heating.

<img src="/images/A-Heat-Pump-Hot-Water-System/app-statistics.png" class="" width=300 height=300 alt="App Statistics Screen (not working for some reason)" />

There's some statistics which show power consumption over time, either via heat pump (eco mode) or heating element (boost mode).

For regular users, this is useful to see how much power system system draws at different times.
For me, who has a clamp meter in my distribution board hooked up to [Home Assistant](https://www.home-assistant.io/), it adds little value.

<img src="/images/A-Heat-Pump-Hot-Water-System/app-schedule.png" class="" width=300 height=300 alt="App Schedule Screen" />

There's a tab to control the time of day the system will heat.
Other times are considered to be in "holiday / frost protect mode".

As I am using [Amber as my power retailer](https://amber.com.au), I am subject to dynamic electricity pricing based on the wholesale rate. 
On a sunny weekend at midday, that can be 5-10c/kWh.
And on a hot, cloudy day during the evening peak, that can be 30-40c/kWh.
And, if the power grid is under stress, it can spike up to 3000c/kWh (seriously)!

So, its very important the system draws no power in the morning and evening peak.
I configured it to run from midnight to 5am, and from 9am to 4pm - when power prices are low.

<img src="/images/A-Heat-Pump-Hot-Water-System/app-settings.png" class="" width=300 height=300 alt="App Settings Screen" />

Finally, there is a general settings tab.
Which is largely undocumented by Dux, but is mostly intuitive or can be figured out with some trial and error.
(The one setting I've never figured out is "PV delay").

The most useful setting here is the "BOOST temperature".
This lets you heat hotter than the default maximum of 60°C.
Which became very important in my usage.


## Differences to Gas

When a new thing replaces an old thing, you're always comparing.
And so here's my comparison between the Dux heat pump and my old gas system.

### The Hot Water Isn't As Hot

I never knew what the water temperature was for my gas system, but it was hot enough to be (just) scalding when I washed dishes by hand.
That has never been the case with the heat pump system (even when I pushed the boost temperature to 65°C).

In Australia, the definition of [hot water](https://pureplumbingpros.com.au/hot-water/information/what-should-the-hot-water-temperature-be-in-my-home) is anything above 50°C.
My personal preference is that 60°C ± 5°C is OK, but below 55°C really isn't very hot.

This "cooler hot water" thing has a couple of consequences, which I'll discuss below.


### Really Good Insulation

The system has really good insulation.

That is, the hot water stays hot for a long time without any heating.
And the exterior of the tank is not obviously hotter than ambient.

When the system was first installed, it ran for several hours to heat 280L of water to 60°C.
I monitored it on Home Assistant, noting the ~1.9kW draw.

<img src="/images/A-Heat-Pump-Hot-Water-System/home-assistant-graph-from-50-degrees.png" class="" width=300 height=300 alt="This is heating from 50°C to 63°C. But is representative of the first run." />

And then it drew no power. For 36 hours!

And the temperature was still above 50°C!

I wonder if a good part of why the system is so efficient is the insulation.
By keeping the hot inside, and not losing temperature to the outside world, it simply doesn't need as much energy to heat.

I have no idea how good the insulation was on the gas system, but it did heat more frequently.


### Cost and Dynamic Electricity Pricing

The heat pump costs less to operate than gas.

As mentioned above, Amber charges based on the [NSW wholesale electricity rate](https://www.aemo.com.au/).
Also, I have solar panels on my roof.

So, if I heat water during a sunny day, it costs me nothing (because solar).
If I heat water on a cloudy day, it might cost 20c/kWh.
And when raining, cost is up to 35c/kWh.

But electricity is always cheapest during the middle of the day, because NSW has a [crazy high take up of rooftop solar](https://pv-map.apvi.org.au/historical).

Based on a home assistance graph of power consumption to heat from 50°C to 63°C, the system consumes around 3.5kWh (a slight over-estimate).
More commonly, it consumes 2-3kWh per day, because I don't let the temperature fall to 50°C.

<img src="/images/A-Heat-Pump-Hot-Water-System/home-assistance-graph-from-55-degrees.png" class="" width=300 height=300 alt="Heating from 55°C to 63°C." />


So, in the best case scenario (entirely powered via my solar), it costs nothing to heat water.
In worst case (35c/kWh), it might cost up to $1.20 per day.
And, on average, ~40-50c per day is a pretty good middle ground.

After getting my first gas bill after the heat pump, I'm estimating 90%+ of gas usage goes to heating water. 
Which means gas costs between $1.10 and $1.30 per day to heat water.

So, the regular average price for gas is about the worst case scenario for electricity.

Nice!

Now, this isn't an entirely fair comparison, because gas was heating to a higher temperature.
But my family has adjusted to slightly-less-hot-water easily enough.
And I'm happy for the better efficiency and lower cost.


## Annoyances

As with any system, it has annoyances and gotchas.

### No Temperature in App when in "Frost Protect" Mode

Whenever the system is configured for "holiday / frost protect" mode (that is, in the peak electricity demand windows each day), it does not show the current temperature.

<img src="/images/A-Heat-Pump-Hot-Water-System/app-frost-protect-mode.png" class="" width=300 height=300 alt="Why you not show temperature???!!?" />

This is quite annoying, because the system is still measuring the temperature.
Frost protect will heat to protect against frost! 
So its still measuring, just not displaying on the app.

And having to wait until the system is in "eco" mode before I can see the water temperature is just silly.

Dux, if you ever bother to make changes to your app, please replace the snowflake symbol with the temperature.

### Heating Logic

When in eco mode, the heat pump has very simple logic:

1. While hotter than 50°C, do not heat. Under 5W power draw.
2. When temperature falls below 50°C, run the heat pump until 60°C. Power draw is 600-700W.

The app provides enough information to figure that out.
And I find it a bit annoying.

Because I would like the heat pump to kick in from 55°C.
But there is no way to configure that.

The only way to force the system to heat is to trigger boost mode, which will always use the 1.2kW heating element in conjunction with the heat pump.

This logic doesn't play well with dynamic pricing.
Sometimes, the system will fall below 50°C overnight and the heat pump kicks in.

I'd rather the system heat every day, during the day, to make best use of NSW's abundant solar energy.

### Boost and 60°C

If the temperature is over 60°C, then boost mode simply isn't allowed.
The system just ignores requests to boost.

Again, this is a bit annoying.

If I want to pull 1.9kW to heat water, and have gone to the trouble of pressing "boost", then just heat the water, dagnamit!


## Gaming The System for Best Pricing

I uncovered the above limitations and gotchas over the first month of usage.

Once you know the rules of a system, it's time to game it to your advantage!

I worked out that with an above average number of showers per day (everyone showering; no one skipping a day), the system would drop around 5-7°C.
And with minimum usage, it dropped ~3°C.

In order to heat once per day during cheapest time of 10am-3pm, and keep the temperature at a comfortable ~60°C, I adopted the following strategy:

1. Configured the boost temperature to 63°C. This is hot enough to be comfortable, but also drop to 60°C (or cooler) over 24 hours.
2. Set an alarm on my phone for around 1pm. This gives time for my batteries to charge using solar in the morning, and then have head room for heating water in the afternoon.
3. Manually trigger boost in the afternoon. This lets me take advantage of either a) my own solar, or in the absence of that due to clouds, b) the cheapest prices of the day.

That's all a little annoying, but takes about 30 seconds during a lunch break.
And it can be triggered remotely.

I'm sure I could reverse engineer the app API and automate this, but I really can't be bothered.

<img src="/images/A-Heat-Pump-Hot-Water-System/app-status-boost-mode.png" class="" width=300 height=300 alt="Boost Mode - how I maximise solar usage heating water" />


## Conclusion

I'm very happy with the Dux ABC heat pump hot water system.

1. It provides hot water. And when your other option is cold showers - I'm sold!
2. Combined with rooftop solar, and dynamic electricity prices, its definitely cheaper than gas.
3. I can nerd out over more graphs to try and get the cheapest prices and most efficiency.

Even with the gotchas, I recommend the system.

Hopefully, this one will last longer than 10 years!
