---
title: Internode HFC NBN on Mikrotik Router
date: 2019-07-05
tags:
- Mikrotik
- Internode
- NBN
- HFC
- VLAN
- Internet
categories: Technical
---

VLAN ID 2.

<!-- more --> 

## Background

I've been using [ADSL](https://en.wikipedia.org/wiki/Asymmetric_digital_subscriber_line) since... well... I got married and moved out of home.
That's ranged from ADSL1, which was 1.5Mbps downstream, up to ADSL2+, which can reach 20+Mbps downsteam.

Unfortunately, my current house is about 4KM from the phone exchange.
ADSL's performance is proportional to how much phone line is between you and the exchange.
I think there are three or four houses down the road from us which are further from the exchange, but I'm pretty close to as far away as you can be.

My ADSL is 4Mbps down, ~800kbps up (on a good day).

<img src="/images/Internode-HFC-NBN-With-Mikrotik/ADSL-Speed-Test.png" class="" width=300 height=300 alt="Its better than dialup. Just." />

So, when I found the [NBN](https://www.nbnco.com.au/) was available in my area, I called my [ISP](https://www.internode.on.net/) and arranged installation immediately!
In the NBN's wisdom, rather than using one technology across the board (fiber to the premesis), they've picked pretty much every possible last mile Internet tech available (from [FTTH](https://en.wikipedia.org/wiki/Fiber_to_the_x), to [HFC](https://en.wikipedia.org/wiki/Hybrid_fibre-coaxial), to variations of [very fast ADSL](https://en.wikipedia.org/wiki/VDSL), to fixed wireless).
My area got HFC, which is probably 2nd best (behind FTTH) .

After an NBN tech came out and drilled a hole in my wall, I have a shiny HFC modem connected to coaxial cable running from the street.

But I want to connect that to my Mikrotik router.
Internode's HFC requires VLAN tagging (for some reason), so not all routers are compatible.

Fortunately, Mikrotik is not "all routers"!


## Goal

Connect the Internode HFC service to my Mikrotik router (hEX S).

Enjoy Internet which can download faster than a [14.4kbps modem](https://en.wikipedia.org/wiki/Dial-up_Internet_access).


## Steps

I've already got my ADSL working with my Mikrotik router using PPPoE, I've got an [article about that](/2017-02-16/Use-A-Mikrotik-As-Your-Home-Router.html).
The trick with HFC is to add VLAN tagging.


### 0. Make Sure Your NBN HFC Modem is Working

Check the HFC modem is working.
Which means 4 lights on.
If not, you aren't going to have any luck with any router; and even Mikrotik routers aren't that magic.

<img src="/images/Internode-HFC-NBN-With-Mikrotik/NBN-HFC-Modem.jpg" class="" width=300 height=300 alt="The NBN HFC Modem. 4 lights is good." />

As part of my NBN bundle, I got some TP-Link router for free (postage $15).
I'm sure it's good enough for most residential users.
In my case, it was a test bed: I made sure the ISP supplied router worked first.

Internode also provides [generic configuration details](https://www.internode.on.net/support/guides/general_settings/).
They're happy for you to use your own equipment, they just aren't able to provide support if it breaks (another good reason to keep the their router handy).


### 1. Connect to Mikrotik

You'll need a spare Ethernet port on your Mikrotik router.
I had already reserved the [SFP port](https://en.wikipedia.org/wiki/Small_form-factor_pluggable_transceiver) for NBN, with a 1Gb copper Ethernet module (the odds of me installing any kind of fiber in my house is only slightly higher than hell freezing over).

Normally, eth1 is reserved for Internet access, so that's a better option if you're starting from scratch.
(You need to be sure whichever port you choose isn't part of your LAN bridge, delete it from `Bridge -> Ports` if it is).

<img src="/images/Internode-HFC-NBN-With-Mikrotik/Mikrotik-Cable.jpg" class="" width=300 height=300 alt="The black cable goes to the HFC Modem." />


### 2. Create VLAN Interface

This is the important part for Internode's HFC service: a VLAN interface tagged with Id 2.
Just add a new VLAN interface, assign it to your chosen physical port, and enter `2` in VLAN ID. 

<img src="/images/Internode-HFC-NBN-With-Mikrotik/Interfaces-VLAN.png" class="" width=300 height=300 alt="A VLAN interface under the Ethernet one, remember to use VLAN Id 2." />

```
[admin@MikroTik-bdr01] /interface vlan> print
Flags: X - disabled, R - running 
 #   NAME                   MTU ARP             VLAN-ID INTERFACE                
 2 R vlan-internode-nbn    1500 enabled               2 sfp1-nbn                 
```

### 3. Create PPPoE Client Interface

From here on, it's normal Mikrotik Internet configuration.
Create a PPPoE interface, and assign it to the VLAN you just created.
Enter your username and password, and you should be on the NBN!

<img src="/images/Internode-HFC-NBN-With-Mikrotik/Interfaces-PPPoE.png" class="" width=300 height=300 alt="A PPPoE interface attached to the VLAN." />

```
[admin@MikroTik-bdr01] /interface pppoe-client> print
Flags: X - disabled, I - invalid, R - running 
 1  R name="pppoe-internode-nbn" max-mtu=auto max-mru=auto mrru=disabled 
      interface=vlan-internode-nbn user="ligos.nbn@internode.on.net" 
      password="NotReallyMyPassword" profile=default keepalive-timeout=60 
      service-name="internode-nbn" ac-name="" add-default-route=yes 
      default-route-distance=1 dial-on-demand=no use-peer-dns=no 
      allow=pap,chap,mschap1,mschap2 
```

### 4. Add NAT Rule

Don't forget to add a *masquerade* NAT rule!
If you're starting from scratch, you probably already have one.
But it tripped me up, check in `IP -> Firewall -> NAT`.


### 5. Check Everything Else

I did a smooth cut over from ADSL to HFC.
So I had both Internet services running at once for a few days.
There were lots of places where I had the ADSL interface or my static IP or something else which needed changing over.

Do an `export` from the console, which will show you all your router config.
That's the easiest way to check everything.


## Conclusion

Internode's HFC service on the NBN needs the PPPoE connection to be tagged on VLAN Id 2.
Fortunately, Mikrotik routers can do pretty much anything!

And now I can move on from 4Mbps ADSL to 50/20Mbps HFC!

<img src="/images/Internode-HFC-NBN-With-Mikrotik/HFC-Speed-Test.png" class="" width=300 height=300 alt="Yes, its definitely faster than ADSL." />