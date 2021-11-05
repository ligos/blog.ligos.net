---
title: Building a CPRNG called Terninger - Part 1 Introduction
date: 2017-05-08
tags:
- Dice
- Fortuna
- RNG
- CPRNG
- Crypto
- Terninger-Series
- Random
- C#
- .NET
categories: Coding
---

An implementation of Fortuna in c#, with added extras.

<!-- more --> 

## Background

I've been bitten by uninitialised or poor random number generators in the past.

It's never fun when you copy two public keys into your source code (one for staging, one for production) and notice they are identical.
Even less fun when you get an email late at night saying your [KeePass plugin for generating Readable Passphrases](https://github.com/ligos/readablepassphrasegenerator) is making the same passphrases on different computers.
And then staying up late to make "oh crap, update now" release.
And worst of all, telling people [all their passphrases from the last 4 years are potentially tainted](https://github.com/ligos/readablepassphrasegenerator/wiki/0.17.0-Fix-for-Non-Random-Passphrases).

I've also written my own random number generator for [makemeapassword.org](https://makemeapassword.org), which mixes random data from various sources (and was not affected by the KeePass bug, for that very reason).
But it's a home grown generator, and with all things cryptography, you should really leave it to the experts.

So, I thought I'd build a proper crypto strength random number generator because
a) because I've had a track record with them failing, b) to learn some new things and c) to show how a CPRNG works, as they are usually a very black box.


## Goal

I'm going to build a cryptographic pseudo random number generator (CPRNG).
It will be called **Terninger**, which means *dice* in Danish (according to Bing).

It will be based on the [Fortuna algorithm](https://www.schneier.com/academic/paperfiles/fortuna.pdf), as written by Bruce Schneier. 
So I have high confidence in the algorithms and theory behind it.

It will pass the [dieharder](http://www.phy.duke.edu/~rgb/General/dieharder.php) random tests, so consumers have confidence it really is random.

It will be target .NET and be written in C#, because that's what I'm most familiar with.

It will take a while, because I don't get a huge amount of free programming time.


## Cryptographic Pseudo Random Number Generator - CPRNG (what is it?)

First off, a bit of a diversion to work out what a CPRNG is.
And the problem we're trying to solve.


Computers are wonderfully deterministic.
That is, 1+1 is always 2.
So it's actually rather hard to get a computer to make truly random numbers.

There are various algorithms that take a *seed* value, and spit out what appears to be random numbers.
These are called *Pseudo Random Number Generators* ([PRNG](https://en.wikipedia.org/wiki/Pseudorandom_number_generator)), because they aren't really random, but close enough for most purposes.
They also aren't safe for *Cryptographic* operations because if anyone discovers the seed used, they can derive the exact same "random" numbers.

A *Cryptographic Pseudo Random Number Generator* (CPRNG) takes additional steps to make it at least very hard (if not impossible) to derive the same random numbers,
**even if** the seed value becomes known to the bad guys.
That can be a tough ask, because the bad guys can be very smart and very subtle, but this is what Fortuna promises.


Wikipedia has as good a definition of a [CPRNG](https://en.wikipedia.org/wiki/Cryptographically_secure_pseudorandom_number_generator) as any, which boils down to three points:

**One**

The numbers it produces are **random**. 

That is, if you look really carefully at the pattern of ones and zeros it produces, and try to guess the next bit (one or zero) you can't guess correctly any more than 50% of the time.
This needs to be true over a very long period of time and a lot of ones and zeros.
CPRNGs should be good for 2<sup>64</sup> bytes of randomness, and are often much better than that.

Incidently, this criteria applies to PRNGs as much as their crypto-safe big brothers.
[Dieharder](http://www.phy.duke.edu/~rgb/General/dieharder.php) is a bunch of statistical tests to work out if your random number generator is really random or not.

This assumes that any internal state, seed value, or secret key being used to generate random numbers remains secret and unknown to the outside observer.
That is, an attacker isn't looking inside the CPRNG, just at the values produced by it.

**Two**

If the internal state of the CPRNG becomes known to a bad guy, it can't be used to **rewind** to previously generated numbers.
That is, you can't work out previous random numbers generated based on the current "key" or internal "seed" of the CPRNG.

If you think about this, its really, really important for crypto work.
Because lots of cryptography is based on some really big and very secret random number.
And if you could "turn back time" to work out what those numbers were, then you could easily break all kinds of crypto stuff (anything from encrypted disks to HTTPS sessions).

**Three**

The CPRNG makes it somewhere between very hard and impossible to **fast forward** to numbers generated in the future, if the internal state becomes known.
That is, you shouldn't be able to work out the next random number (or the n-th next random number) even if you know what the internal "seed" or key is right now.

This is the really hard problem CPRNGs have to solve.
And by hard, I mean impossible (at least in all possible cases).

Because you never know exactly when an attacker works out the seed, or how much influence they might have over the CPRNG.

However, there are lots of things a CPRNG can do to make life much harder for any bad guy trying to do this.
And Fortuna does a bunch of these things.



### An Overview of Fortuna

So how does Fortuna address the above criteria?
What are the parts of it that make it such a good CPRNG?

The following diagram of the Fortunata algorithm was taken from [a paper by McEvey, Curran, Cotter and Murphy](http://www.academia.edu/410608/Fortuna_A_Cryptographically_Secure_Pseudo-Random_Number_Generation_In_Software_And_Hardware)

<img src="/images/Building-A-CRNG-Terninger-1-Introduction/fortuna-diagram.png" class="" width=300 height=300 alt="A Diagram of the Fortuna Algorithm - The Red is My Additon, Corresponding to the Numbers Below" />

There are four parts to Fortuna, corresponding to the sections labelled above:

**1: A PRNG**

It has a core PRNG which generates random numbers.
This is defined as a block cypher in counter mode.

That is, you get yourself a secret key or seed, and use it to encrypt the number 1, then 2, then 3, and so on.
And the encrypted output should be random (because the output of any cypher is effectively random).

Fortuna recommends [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) for this, but states you could use any [block cypher](https://en.wikipedia.org/wiki/Block_cipher).
I can't see why you couldn't use any keyed crypto strength [hash algorithm](https://en.wikipedia.org/wiki/Cryptographic_hash_functions) (eg: HMAC+SHA2) or even a [stream cypher](https://en.wikipedia.org/wiki/Stream_cipher).
But some very smart people have [gone over the use of block cyphers with a fine tooth comb](http://eprint.iacr.org/2013/338.pdf), so here be dragons if you don't follow their recommendations!

The random output will repeat when you go through all possible numbers in the cypher's *block size*.
Which for AES is 128 bits (which is a really big number).
However, after around 2<sup>64</sup> blocks are generated, the [birthday paradox](https://en.wikipedia.org/wiki/Birthday_problem) says there's a non-trivial chance of getting a duplicate block by random chance.

This addresses requirement **one** for a CPRNG.
(And, there's some detail in Fortuna which partially addresses requirement **two** as well).

**2: Sources of Entropy**

The PRNG in point one is good for 2<sup>64</sup> * 16 bytes worth of random numbers.
But you need a random key of minimum 128 bits to get started (and Fortuna recommends 256 bits).

That is, assuming you have 256 bits of randomness, part one will generate a really long sequence of random numbers.
But you need to get 256 random bits first.
Chicken, meet egg.

Fortunately, we don't really need 256 random bits, just any amount of data with 2<sup>256</sup> possible combinations (*entropy* is a fancy word which means "the total possible combinations").
If we can get a bunch of data with 256 bits of entropy, we can use a crypto hash algorithm (Fortuna recommends SHA2) to distill that data to our required 256 random bits.

The raw data can come from any source that is changing.
The most basic one is *high resolution timers*.

Although computers are very deterministic, a modern computer is also doing an awful lot of things at once.
If you set a timer for one second, it's highly unlikely it will actually be exactly one second, because of the 500 other things the computer is doing.
It might be 1.00003 seconds, or 0.999994 seconds, depending on lots of (rather unpredictable) factors.
If you measure one second over and over, and take that tiny fractional difference from one second, you'll eventually have that 256 bits of entropy.

Any source which changes over time can be used to derive entropy, eg: the static you get when recording silence, the changing content of a news website, the number of network packets received since the computer starts, a true hardware random number generator, etc.
The more different sources you use, the harder it will be for bad guys to guess your seed.

This addresses requirements **two** and, most importantly, **three** of the CPRNG requirements.


**3: A Way to Re-Key the PRNG Based on Pools of Entropy**

This is the part of Fortuna that sets it apart from other CPRNGs.
And is the key way it makes it really hard for bad guys to guess the internal seed of point 1.
It's also the most complex part of the algorithm, so the description which follows is quite high level.

Fortuna doesn't directly accept the entropy in point 1, it distributes it among 32 pools in a round-robin fashion.
Then, when it needs to re-key to PRNG, it takes the content of one or more pools to derive a new key.
Where first first pool is included most often, and the 32nd pool least often.

What this means is that entropy gathered very recently is combined with entropy gathered some time ago (in extreme cases, months or years ago) to produce a new key.
The assumption it is extraordinarily difficult for any bad guy to control enough entropy sources over such a long period of time to reliability predict the new key.
A bad guy may be able to predict, influence or observe some incoming entropy for a short period of time, but, after a few re-key events, that information will be lost in the noise of entropy from the past and other sources the attacker can't control. 

Fortuna also defines how to securely distribute entropy coming into the pools. 
And when to update the key for the PRNG based on those pools.

This addresses the most difficult CPRNG requirement **three**.


**4: A Way to Save and Load the CPRNG State**

Any CPRNG is vulnerable when a computer starts up, because there will be some time before it has accumulated enough entropy to safely seed the PRNG.
And the entropy gathered is highly predictable, because a computer does the same things every time it starts.

As a way to work around this, Fortuna says that the PRNG secret key from point 1 should be saved to disk when the computer stops and reloaded when the computer starts.
So Fortuna only ever starts truly "cold" once, when the computer is first installed.

(Of course, that doesn't help Fortuna on its very first start, but does from then on).

This improves CPRNG requirement **three**.


### How is Terninger Different?

Terninger will have the following features, some which differ from Fortuna:

* A *classic fortuna* implementation, for people who want Fortuna exactly as Bruce Schneier specifies.
* An *improved fortuna* implementation, which takes on board some [suggested improvements to Fortuna](http://eprint.iacr.org/2014/167.pdf) as well as my own improvements.
* A *short term* CPRNG, which is essentially the core PRNG of Fortuna without any re-keying.
* A *less secure short term* CPRNG implementation, which sacrifices some security to improve performance.
* A wide variety of *entropy sources*; my own creativity is the only limit here. 
* *Highly configurable*, if you want to experiment with all the knobs and dials (eg: number of pools, cypher, hash algorithm, etc).
* All the *helper methods* needed to generate arbitrary streams of random bytes, random integers, random doubles and so on.



### Alternatives

Turninger won't be ready for some time, so if you've arrived here and need a working Fortuna implementation or CPRNG, see below.

An existing [C# implementation of Fortuna](https://github.com/smithc/Fortuna).

Implementations of [Fortuna in Java and Python](http://www.seehuhn.de/pages/fortuna).

The C# [RngCryptoServiceProvider class](https://msdn.microsoft.com/en-us/library/system.security.cryptography.rngcryptoserviceprovider.aspx) is a CPRNG, which calls into [unmanaged code](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379942.aspx). 
Although we have no visibility into its implementation, [Niels Ferguson says](http://eprint.iacr.org/2014/167.pdf) it is (or was in 2013) based on Fortuna. And [Michael Howard](https://blogs.msdn.microsoft.com/michael_howard/2005/01/14/cryptographically-secure-random-number-on-windows-without-using-cryptoapi/) lists some of the entropy sources used (in 2005; Windows Vista timeframe).

[Wikipedia has a list of CPRNGs](https://en.wikipedia.org/wiki/Category:Cryptographically_secure_pseudorandom_number_generators).

[RFC 4186, appendix B](https://tools.ietf.org/html/rfc4186#appendix-B) has a basic PRNG.

And, on Linux based systems, you can make use of `/dev/random` or `/dev/urandom`.
I'm not sure if they use Fortuna or not in current kernels, but they are good for producing crypto-safe random numbers.


## Next Up

That's my introduction to CPRNGs, Fortuna and what I hope Turninger will be.
It should keep me busy making it all happen, with the degree of quality assurance I want.

The first step: building the PRNG based on AES - the core random number generator of Fortuna.




