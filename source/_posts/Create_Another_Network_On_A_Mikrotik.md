---
title: Create Another WiFi Network on a Mikrotik Router
date: 2016-10-04
tags:
- Mikrotik
- Network
- Guest
- Firewall
- WiFi
categories: Technical
---

Steps to create a second (or third) network on a Mikrotik router, perhaps for a guest network.

<!-- more --> 

## Background

I like to separate different WiFi on my network.
So my friends use a guest network, the kids are on their own network, etc. 

Many home routers have a "tick the box" style of guest WiFi network,
you tick the "guest network" box and out pops a virtual guest access point.

[Mikrotik](http://www.mikrotik.com/) routers can do exactly the same thing, except you can have effectively unlimited access points and you need to build the network piece by piece.

## Steps

In this guide, I create a separate WiFi interface for phones and tablets.

Phones rarely need full network access to other local devices.
And they have a nasty habit of getting lost, stolen or otherwise broken, so having a separate WiFi access point (and password) means you don't accidentally disclose your main WiFi password.

I'll be using WinBox, but I'll also list the console details via a print command.

### 1. Create an Interface

First thing to do is create yourself a passphrase for your AP.
I generate one from [makemeapassword.org](https://makemeapassword.org) and save it in my [KeePass](https://keepass.info) database. 

Then create a new *security profile*:
Goto **Wireless** -> **Security Profiles** and add a new profile.

Give it an appropriate name (`wpa2-phones` in my case).
I disable *WPA* and only use *WPA2*, as I have no legacy devices and it improves security slightly.
Finally, don't forget to enter your passphrase.

<img src="/images/Create-Another-Network-On-A-Mikrotik/wireless-security-profile.png" class="" width=300 height=300 alt="Wireless Security Profile" />

```
[admin@Mikrotik-gateway] /interface wireless security-profiles> print

 4   name="wpa2-phones" mode=dynamic-keys authentication-types=wpa2-psk unicast-ciphers=aes-ccm 
     group-ciphers=aes-ccm wpa-pre-shared-key="" 
     wpa2-pre-shared-key="NotMyRealPassphrase" supplicant-identity="" 
     eap-methods="" tls-mode=no-certificates tls-certificate=none mschapv2-username="" 
     mschapv2-password="" static-algo-0=none static-key-0="" static-algo-1=none static-key-1="" 
     static-algo-2=none static-key-2="" static-algo-3=none static-key-3="" 
     static-transmit-key=key-0 static-sta-private-algo=none static-sta-private-key="" 
     radius-mac-authentication=no radius-mac-accounting=no radius-eap-accounting=no 
     interim-update=0s radius-mac-format=XX:XX:XX:XX:XX:XX radius-mac-mode=as-username 
     radius-mac-caching=disabled group-key-update=5m management-protection=allowed 
     management-protection-key="" 
```

Then create a virtual access point:
Goto **Wireless** -> **Interfaces** and then add a *Virtual AP*.

On the *General* tab, enter a name for the network interface (which will be used internally on your Mikrotik).
Mine is `wlan-phones`.

On the *Wireless* tab, enter an SSID to identify your network: `ligos-phones` for me, 
then select your newly created security profile

<img src="/images/Create-Another-Network-On-A-Mikrotik/wireless-interface.png" class="" width=300 height=300 alt="Wireless Virtual AP" />

```
[admin@Mikrotik-gateway] /interface wireless> print

 3    name="wlan-phones" mtu=1500 l2mtu=1600 mac-address=4C:5E:0C:01:02:03 arp=enabl
      interface-type=virtual-AP master-interface=wlan ssid="ligos-phones" vlan-mode=
      vlan-id=1 wds-mode=disabled wds-default-bridge=none wds-ignore-ssid=no bridge-
      default-authentication=yes default-forwarding=yes default-ap-tx-limit=0 
      default-client-tx-limit=0 hide-ssid=no security-profile=wpa2-phones 

```


### 2. Assign an IP Pool and Address

A network interface isn't much use without an IP address.

Goto **IP** -> **Address** and then add a new address.

Choose an appropriate IP address for your new network (I'm using `10.46.2.xxx`) and assign it to your new interface.

<img src="/images/Create-Another-Network-On-A-Mikrotik/ip-address.png" class="" width=300 height=300 alt="Add an IP Address" />

```
[admin@Mikrotik-gateway] /ip address> print
Flags: X - disabled, I - invalid, D - dynamic 
 #   ADDRESS            NETWORK         INTERFACE                              
 5   ;;; Phone WiFi
     10.46.2.1/24       10.46.2.0       wlan-phones     
```

On many other routers, you assign an IP address range against the DHCP server.
On a Mikrotik you create an IP Pool, which is then used by DHCP (and other things too, I guess, though I have no idea what).
So we need a pool before we can configure DHCP.

Goto **IP** -> **Pool** and then add a new pool.

I tend to reserve the bottom ~60 address (from `x.1` to `x.63`) for static allocations, and `x.255` is the broadcast address.
Which means a range like `10.46.2.64 - 10.46.2.254` is my pool.

<img src="/images/Create-Another-Network-On-A-Mikrotik/ip-pool.png" class="" width=300 height=300 alt="The Dynamic Pool" />

```
[admin@Mikrotik-gateway] /ip pool> print
 # NAME                         RANGES                        
 4 dhcp-phones                  10.46.2.63-10.46.2.254      
```

### 4. Create a DHCP Server

DHCP is used to assign addresses to devices as they connect to the WiFi network.
They will use the pool we just created.
And also assign a few other special addresses.

Goto **IP** -> **DHCP Server** -> *DHCP* Tab and add a new DCHP Server.  

Give it a name (I named mine after the `wlan-phones` interface).
Select the interface you created.
Extend the lease time to something reasonably long (I use 1 day).
And select the address pool you created in the last step. 

<img src="/images/Create-Another-Network-On-A-Mikrotik/dhcp-server.png" class="" width=300 height=300 alt="DHCP Server" />

```
[admin@Mikrotik-gateway] /ip dhcp-server> print
Flags: X - disabled, I - invalid 
 #   NAME         INTERFACE         ADDRESS-POOL       LEASE-TIME
 4   wlan-phones  wlan-phones       dhcp-phones        1d       
```

Now, jump over to the *Networks* tab and add new configuration.

The **Address** field is what ties the *Address Pool*, *DHCP Server* and *Network Configuration* all together.
It should be the same as the IP address you chose, but with a zero at the end, and the netmask afterwards.
`10.46.2.0/24` fits my example so far. 
The Netmask should be `255.255.255.0` or `24`, unless you know much more about subnets than I do.

I also set the router to be the DNS server and NTP server.
And the domain to `ligos.local`.

<img src="/images/Create-Another-Network-On-A-Mikrotik/dhcp-config.png" class="" width=300 height=300 alt="DHCP Config" />

```
[admin@Mikrotik-gateway] /ip dhcp-server network> print
 # ADDRESS          GATEWAY      DNS-SERVER   WINS-SERVER   DOMAIN                        
 0 ;;; Phone WiFi
   10.46.2.0/24     10.46.2.1    10.46.2.1                  ligos.local                   

```

### 5. Assign an IPv6 Pool and Address

I also have a public IPv6 range assigned by my ISP, so I add an IPv6 address as well.
You need to create an IPv6 pool first, based on your public address assignment, before you can advertise it on an interface or assign an address.
Also, because there's much more auto discovery built into IPv6, config is much less complicated.

Goto **IPv6** -> **Pool** and then add a new pool.

I'm simply assigning `/64` subnets (from my `/56` public allocation) to each network.
This gives me 255 subnets for 255 networks (which is plenty, given I don't event have 255 devices!) 
There's no static assignments, so no address range exclusions like for IPv4.

<img src="/images/Create-Another-Network-On-A-Mikrotik/ipv6-pool.png" class="" width=300 height=300 alt="The IPv6 Pool" />

```
[admin@Mikrotik-gateway] /ipv6 pool> print
Flags: D - dynamic 
 #   NAME                         PREFIX                           
 3   phones-ipv6-pool             2001:44b8:3168:9b03::/64  
```

Now, goto **IPv6** -> **Address**.
You'll note that link local addresses (starting with `fe80`) have been dynamically created for your new interface.
This is totally normal. 

Now, add a new address.
I use the same address for the router as for the pool.
And set the correct pool and interface.

<img src="/images/Create-Another-Network-On-A-Mikrotik/ipv6-address.png" class="" width=300 height=300 alt="The IPv6 Address" />

```
[admin@Mikrotik-gateway] /ipv6 address> print
Flags: X - disabled, I - invalid, D - dynamic, G - global, L - link-local 
 #    ADDRESS                        FROM-POOL INTERFACE     ADVERTISE
 8 DL fe80::4c5e:cff:feb8:d8d1/64              wlan-phones   no       
 9  G 2001:44b8:3168:9b03::/64       phones... wlan-phones   yes      
```

### 6. Add Firewall Rules

Before everything will work, you'll need a few firewall rules.

I've created a defacto routing policy based on *Address Lists*.
By adding the new network masks to existing *Address Lists*, everything just works without any further changes to firewall rules.
Though I'll list the firewall rules as well, for your reference.

There are 4 categories I have at the moment:

1. **all_internal** - a list of all my internal networks. I need to add my new `10.46.2.0/24` network here.  
2. **internal_trusted** - networks which may access LAN resources. As my new phones network doesn't need blanket local access, I don't add it.  
3. **internal_restricted** - networks which cannot access LAN resources (unless I add explicit rules). I add `10.46.2.0/24` here.
4. **named_blah** - specific named devices. Because you can't use DNS names in firewall rules. 

Note the `10.46.1.0/26` network in **internal_trusted**.
Although `10.46.1.0/24` is restricted by default, I trust a small part of that network (this lets my kids' devices access printers and SMB shares). 

```
[admin@Mikrotik-gateway] /ip firewall address-list> print
Flags: X - disabled, D - dynamic 
 #   LIST                       ADDRESS                        
30   all_internal               192.168.1.0/24    
31   all_internal               10.46.1.0/24      
32   all_internal               10.46.2.0/24      
12   internal_trusted           192.168.1.0/24    
14   internal_trusted           10.46.1.0/26      
19   internal_restricted        10.46.1.0/24      
20   internal_restricted        10.46.2.0/24      
23   named_loki                 loki.ligos.local  
24   named_printer              printer.ligos.local
```

The most important firewall rule is the NAT rule, which translates public IP addresses to private ones.
Without this, no Internet connectivity is possible.

```
[admin@Mikrotik-gateway] /ip firewall nat> print
Flags: X - disabled, I - invalid, D - dynamic 

10    ;;; Main NAT rule
      chain=srcnat action=masquerade src-address-list=all_internal out-interface=pppoe-internode log=no 
      log-prefix=""
```

The **filters** tab are where the firewall rules actually live.
They enforce whatever policies I have, that is, what may access what. 
There are three categories of rules I have:

* Stats rules - these are just to track GBs and number of packets.
* Allow rules - to allow particular connections.  
* Deny rules - the Mikrotik firewall allows everything by default, so you need some rules to reverse that behaviour.   

Note that most rules are applied to the `forward` chain.
This is the one used when forwarding packets between networks (as opposed to packets within the same networks).

```
[admin@Mikrotik-gateway] /ip firewall filter> print
Flags: X - disabled, I - invalid, D - dynamic 
 1    ;;; Incoming Stats
      chain=forward action=passthrough in-interface=pppoe-internode log=no log-prefix="" 
 3    chain=forward action=passthrough in-interface=pppoe-internode out-interface=bridge-local log=no log-prefix="" 
 6    chain=forward action=passthrough in-interface=pppoe-internode out-interface=wlan-phones log=no log-prefix="" 

 8    ;;; Outgoing Stats
      chain=forward action=passthrough out-interface=pppoe-internode log=no log-prefix="" 
 9    chain=forward action=passthrough in-interface=bridge-local out-interface=pppoe-internode log=no log-prefix="" 
12    chain=forward action=passthrough in-interface=wlan-phones out-interface=pppoe-internode log=no log-prefix="" 


29    ;;; Allow restricted networks to access http(s) on Loki only
      chain=forward action=accept protocol=tcp src-address-list=internal_restricted dst-address-list=named_loki 
      dst-port=80,443 log=no log-prefix="" 

30    ;;; Allow DNS access for all internal
      chain=input action=accept protocol=udp src-address-list=all_internal dst-port=53 log=no log-prefix="" 

31    ;;; Allow NTP access for all internal
      chain=input action=accept protocol=udp src-address-list=all_internal dst-port=123 log=no log-prefix="" 

32    ;;; Allow SMB / CIFS access to Loki from trusted addresses (particularly kids network)
      chain=forward action=accept protocol=tcp src-address-list=internal_trusted dst-address-list=named_loki 
      dst-port=445 log=no log-prefix="" 

33    ;;; Allow restricted networks to access http(s) and SSH on Loki only
      chain=forward action=accept protocol=tcp src-address-list=internal_restricted dst-address-list=named_loki 
      dst-port=80,443,22 log=no log-prefix="" 

34    ;;; Allow printer access from trusted networks
      chain=forward action=accept src-address-list=internal_trusted dst-address-list=named_printer log=no 
      log-prefix="" 

43    ;;; Full access to INTERNAL trusted address list
      chain=input action=accept src-address-list=internal_trusted log=no log-prefix="" 


44    ;;; Drop access to LAN from restricted networks
      chain=forward action=reject reject-with=icmp-net-prohibited src-address-list=internal_restricted 
      dst-address-list=internal_trusted log=no log-prefix="" 

49    ;;; Drop external access by default
      chain=input action=drop protocol=tcp in-interface=pppoe-internode log=no log-prefix="" 

50    ;;; drop external access by default
      chain=input action=drop protocol=udp in-interface=pppoe-internode log=no log-prefix="" 
```


IPv6 firewall is considerably simpler: just the accounting rules.
Although that's probably more due to my laziness than best practise.

```
[admin@Mikrotik-gateway] /ipv6 firewall filter> print
Flags: X - disabled, I - invalid, D - dynamic 
 1    ;;; Incoming Stats
      chain=forward action=passthrough in-interface=pppoe-internode log=no log-prefix="" 
 3    chain=forward action=passthrough in-interface=pppoe-internode out-interface=bridge-local log=no log-prefix="" 
 6    chain=forward action=passthrough in-interface=pppoe-internode out-interface=wlan-phones log=no log-prefix="" 

 8    ;;; Outgoing Stats
      chain=forward action=passthrough out-interface=pppoe-internode log=no log-prefix="" 
 9    chain=forward action=passthrough in-interface=bridge-local out-interface=pppoe-internode log=no log-prefix="" 
12    chain=forward action=passthrough in-interface=wlan-phones out-interface=pppoe-internode log=no log-prefix="" 

```

### 7. Testing

Once configured, you should be able to ping the new IP addresses you just created.

And the final test is to connect a phone to the new WiFi network.
Make sure it gets an IP address (if not, the WiFi interface itself or the DHCP server is mis-configured).
And try to access the Internet (if you can't, the NAT rule or another firewall rule is probably broken).

It's also useful to keep an eye on the **Log**, as errors may appear in there to help you track down problems.
And look against firewall rules to see when packet counts increase, that is a hint where things might be getting blocked. 

<img src="/images/Create-Another-Network-On-A-Mikrotik/wireless-registration.png" class="" width=300 height=300 alt="Phones Connected to the Phone WiFi!" />


## Conclusion

You can create many new WiFi networks on a Mikrotik router to segregate and restrict devices.

The process is more involved than on most home routers, but considerably more flexible.