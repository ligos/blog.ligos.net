---
title: Tear Down - Acer Spin 15
date: 2017-09-21
tags:
- Tear Down
- Disassemble
- Internals
- Repair
- Laptop
- Model N15W1
- Spin 5 SP513
categories: Technical
---

How to pull it apart (with pictures!)

<!-- more --> 

## Background

We recently purchased a new laptop for my wife.
An [Acer Spin 5](https://www.acer.com/ac/en/US/content/series/spin5).
Nice and shiny and new.
Touch screen, laptop or tent or tablet form factor, 8GB RAM, 128GB SSD, Win 10.

She was very happy with it.
As it meant she can browse the web, read email, and watch Netflix.
Without fighting our kids for a computer.

And then it had an accident.

My eldest managed to knock it off the table onto our tiled floor.
This floor has claimed many victims over the years: phones, glasses, plates, cuts and bruises on small children.
In this case the damage appeared superficial - just a scratch on one corner.

But there was tiny internal breakage: the charging socket snapped off.
So the laptop couldn't be charged any longer.

Fast forward a few hours and we were in the possession of a rather expensive paper weight.


## Tear Down

I searched the Internet for service manuals or tear downs for this model, and found nothing.
So, I decided to have a go myself.

My aim was to a) see if the charging socket was electrically intact and b) to fix it mechanically.

I've been pulling all manner of computers apart since at least age 10, so this wasn't particularly daunting.
Though I do prefer to have someone else's instructions to follow for laptops, as each make and model has its own procedures and gotchas (and to reduce the risk of me doing something dumb).

This won't be a complete tear down, just enough for me to repair the charging socket.
But I will show photos of the insides of the laptop, for reference.


### Step 1 - Unscrew All the Screws

There are 13 screws to remove on the bottom of the laptop.
You'll need a smallish philips head screwdriver for this.

There are no hidden screws under stickers or rubber feet; just the ones visible!
And no special or non-standard screwdrivers are required!

Note that the two screws in the back corners of the laptop are longer than the others.

<img src="/images/Tear-Down-Acer-Spin-15/laptop-bottom-screws.jpg" class="" width=300 height=300 alt="Location of screws - red are small, blue are large." />



### Step 2 - Pry the Bottom Section Apart

You can get special [pry tools](https://www.bing.com/images/search?q=pry+tool&qpvt=pry+tool) to help open the laptop base.
I don't have any, so I used my fingernails.

Place the laptop on your lap such that its screen is toward you, and the base / keyboard is away, and is open slightly.
And jam your pry tool / fingernails into the tiny gap that separates the base plate with the keyboard section.
I found I could get it started pretty easily at the corners, and then slide my fingernails across the long edge, hearing satisfying "snap" noises as I went.
Then firmly but cauciously, pry the sides apart and finally the back edge (where the battery is).
The base plate will fall away.

<img src="/images/Tear-Down-Acer-Spin-15/laptop-pry-open.jpg" class="" width=300 height=300 alt="The front edge seems to be easiest to pry open." />


### Step 3 - Fix the Broken Charging Socket

At this point we have access to most of the laptop's internals.
You can see the battery and circuit boards.

<img src="/images/Tear-Down-Acer-Spin-15/internal-labelled.jpg" class="" width=300 height=300 alt="The internals of the Acer Spin 5." />

I quickly established the charging socket was electrically OK; the laptop would still charge without a problem.
But a few millimeters of plastic had been snapped off, so it was no longer secured mechanically in the laptop.

Solution: great gobs of glue.
Under the socket, and on the side where the plastic snapped off, and behind it.

I'm sure epoxy would be better, but the [cheap stuff I got from Officeworks](https://www.officeworks.com.au/shop/officeworks/p/uhu-contact-liquid-glue-33ml-uh3337625) did a fine job.

<img src="/images/Tear-Down-Acer-Spin-15/repaired-charging-socket.jpg" class="" width=300 height=300 alt="My repaired charging socket. Glue slightly visible." />


### Picture and Comments on Internals

For people interested in what the inside of an Acer Spin 5 SP513 looks like, click the links below for full res images.

Notable user servicable components include:

* **M2 SSD** - [Hynix HFS128G39TND](http://www.memory4less.com/hynix-128gb-sata-6-0-gbps-ssd-hfs128g39tnd-n210a), 128GB, SATA interface, B and M keyed. Acer sells 256GB models, so this should be easily upgraded or replaced.
* **RAM** - 1 DIMM socket located under the large silver box. 8GB on my model. Acer's models only go up to 8GB, but [the CPU](https://ark.intel.com/products/88193/Intel-Core-i5-6200U-Processor-3M-Cache-up-to-2_80-GHz) supports up to 32GB, so there's a reasonable chance you could replace the 8GB DIMM with a 16GB module (totally untested of course).
* **Main battery** - secured by 2 screws. 15.2V, 3220mAh, 48Wh. Should be pretty easy to replace.
* **WiFI / Bluetooth** - in a small M2 socket. Again, easy to replace if you wanted to.
* **Lithium coin cell** - keeping the clock running if the main battery goes flat.

<img src="/images/Tear-Down-Acer-Spin-15/internal-1.jpg" class="" width=300 height=300 alt="Internals. Full size image below." />

[Full size image](/images/Tear-Down-Acer-Spin-15/internal-fullsize-1.jpg)

<img src="/images/Tear-Down-Acer-Spin-15/internal-2.jpg" class="" width=300 height=300 alt="More internals. Full size image below." />

[Full size image](/images/Tear-Down-Acer-Spin-15/internal-fullsize-2.jpg)


### Reassembly

Reassembly is even easier.

Simply put the plastic case back on the laptop, as it came off.
Press firmly around the outer edge so all the clips snap back into place.
And replace the screws (remembering the longer ones go in the rear corners).

And you're done!


## Conclusion

That's a basic tear down of the Acer Spin 5 SP513 (model number N15W1).
I even managed to repair the broken charging socket!

It's surprisingly easy to do and gives you access to three upgradable or replaceable components: RAM, SSD and the battery. 
