---
title: Building a CPRNG called Terninger - Part 4 Random Tests
date: 2017-06-02
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

Checking how random the core generator is.

<!-- more --> 

## Background

You can [read other Turninger posts](/tags/Terninger-Series/) which outline my progress building a the Fortuna CPRNG.

So far, we have the PRNG `BlockCypherCprngGenerator`, and a console app which outputs random data to file or stdout.


## Goal

Now we have a console app that can produce effectively unlimited (2<sup>63</sup> is plenty big enough for now) random bytes, we need to examine the output and check it really is random.

Note that we already know the output is *deterministic*, that is, the same seed will produce the same sequence of numbers.
But if you don't know the seed, every bit should have exactly 50% of being a 1 or 0.

To do this, we will use several external programs which will use [statistics](https://en.wikipedia.org/wiki/Statistics) to quantify how random the output really is.

I'm not going to pretend I understand the statistics used (I did one basic statistics course at university around 15 years ago, and nothing since), 
but I think they're looking for things like:

* Biases, eg: byte `0x01` is produced more than `0x02`.
* Obvious repeats: eg, `0101010101`.
* Less obvious repeats: eg, every 256th bit is always a zero.
* A bunch of things I don't understand ([TestU01](http://simul.iro.umontreal.ca/testu01/guideshorttestu01.pdf) has ~45 pages describing 13 different test algorithms).


### What Tests?

First question is, what programs should I use to analyse the results?

I've been talking a lot about [dieharder](http://www.phy.duke.edu/~rgb/General/dieharder.php) as a test suit.
But after a little research, I found several other [test suites on StackOverflow](http://stackoverflow.com/questions/778718/how-to-test-random-numbers).

* **Dieharder** - http://www.phy.duke.edu/~rgb/General/dieharder.php
* **TestU01** - http://simul.iro.umontreal.ca/testu01/tu01.html
* **RaBiGeTe** - http://cristianopi.altervista.org/RaBiGeTe_MT/
* **NIST STS** - http://csrc.nist.gov/groups/ST/toolkit/rng/documentation_software.html
* **PractRand** - http://pracrand.sourceforge.net/

Other than my requirement to analyse the data and give some sort of pass / fail result (or more likely a range of good-ness and bad-ness),
I want things that are easy to run in my Windows environment,
and, well, easy to make sense of for someone without a statistics degree.

*PractRand* was most recommended in the [StackOverflow answer](http://stackoverflow.com/a/27160683) (even if the recommendation from its own author) and also gave a few recommendations about other test suits.
It was quite against the *Diehard*, *Dieharder* and *NIST STS* suits, and quite positive about *TestU01* and *RaBiGeTe*.
It was also the simplest to build and use on Windows.

Other than *RaBiGeTe*, all other suites needed to be built from source in Linux.
Which is rather painful as I don't have a Linux box sitting around (virtual or otherwise).
Instead, I gave the [Windows Subsystem for Linux](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide) a go.

Which means, I'll use the top 3 recommended tests (*PractRand*, *TestU01* and *RaBiGeTe*), as well as *Dieharder* (just because I've mentioned it so much in previous posts).

(And yes, the rest of this post will be me installing, compiling and posting results from the above. 
Such is the nature of testing software).


### PractRand

http://pracrand.sourceforge.net/

PractRand was quite straight forward to build and use.
I needed to install the Visual Studio 2017 C++ compiler, download PractRand source and change the projects to target the latest Windows 10 SDK.
After that, everything built and ran OK.

PractRand accepts input from stdin, so I told Terninger to produce a lot of bytes and piped that to `RNG_test.exe`.

Then I let it run overnight to get results.

```
> Terninger.Console.exe -s 1 -c 9999999999999 -outstyle binary -outStdout -q | RNG_test.exe stdin                                                 
RNG_test using PractRand version 0.93                                          
RNG = RNG_stdin, seed = 0x70a52540                                             
test set = normal, folding = standard(unknown format)                          
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 16 megabytes (2^24 bytes), time= 3.7 seconds                           
  no anomalies in 119 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 32 megabytes (2^25 bytes), time= 10.0 seconds                          
  no anomalies in 130 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 64 megabytes (2^26 bytes), time= 19.1 seconds                          
  no anomalies in 139 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 128 megabytes (2^27 bytes), time= 34.8 seconds                         
  no anomalies in 151 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 256 megabytes (2^28 bytes), time= 66.2 seconds                         
  no anomalies in 162 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 512 megabytes (2^29 bytes), time= 121 seconds                          
  no anomalies in 171 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 1 gigabyte (2^30 bytes), time= 233 seconds                             
  no anomalies in 183 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 2 gigabytes (2^31 bytes), time= 437 seconds                            
  no anomalies in 194 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 4 gigabytes (2^32 bytes), time= 828 seconds                            
  no anomalies in 203 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 8 gigabytes (2^33 bytes), time= 1502 seconds                           
  no anomalies in 215 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 16 gigabytes (2^34 bytes), time= 2917 seconds                          
  no anomalies in 226 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 32 gigabytes (2^35 bytes), time= 5759 seconds                          
  no anomalies in 235 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 64 gigabytes (2^36 bytes), time= 11053 seconds                         
  no anomalies in 247 test result(s)                                           
                                                                               
rng=RNG_stdin, seed=0x70a52540                                                 
length= 128 gigabytes (2^37 bytes), time= 22686 seconds                        
  no anomalies in 258 test result(s)                                           
```

It's not very exciting to post a big list of *no anomalies found*, so I created a 256GB file (also for using with other tests) and [dumped all test results](/images/Building-A-CRNG-Terninger-4-Random-Tests/practrand-256GB.out.txt).

None of the tests were labelled as anomalies, but I noticed several with very small p values (less than 0.001).
P values are the statistical term which says how likely the test was to failing; extremely small or large values of p (eg, less than 0.001 or more than 0.999) indicate something might be wrong).

I'm not sure if that is normal, good or bad, but it strikes me as a warning.


### RaBiGeTe 

http://cristianopi.altervista.org/RaBiGeTe_MT

RaBiGeTe was a binary download, but needed several additional files for all tests to run.
It also has a whole stack of options (most of which I don't understand), so I chose the *default* preset and a sequence length of 32Mbit.

RaBiGeTe accepts input from a DLL with C style function exports, or a file.
So I used the 256GB file PractRand processed (presumably only the first 4MB are analysed though).

Unfortunately, I couldn't work out any way of saving the entire tables RaBiGeTe generated.
So we just have screenshots of the worst tests.

There are two results highlighted in red and twelve in orange (across the *Table* and *Pearson* tabs).
An no giant "fail" errors.

I'm not sure if this is normal, good or bad. 
Though several of the border-line results are for *short blk* tests, which sounds like some level of correlation over short distances (maybe).

<img src="/images/Building-A-CRNG-Terninger-4-Random-Tests/RaBiGeTe-table.png" class="" width=300 height=300 alt="The Table tab of RaBiGeTe" />

<img src="/images/Building-A-CRNG-Terninger-4-Random-Tests/RaBiGeTe-pearson.png" class="" width=300 height=300 alt="The Pearson tab of RaBiGeTe" />

<img src="/images/Building-A-CRNG-Terninger-4-Random-Tests/RaBiGeTe-graph.png" class="" width=300 height=300 alt="The Graph tab of RaBiGeTe" />

You can also [download the messages](/images/Building-A-CRNG-Terninger-4-Random-Tests/RaBiGeTe-messages.txt) RaBiGeTe produced as output (although there's no statistics in them).


### TestU01 

http://simul.iro.umontreal.ca/testu01/tu01.html

TestU01 had options for Windows binaries compiled against MinGW or Cygwin, otherwise its build from source in a Linux environment. So I decided to give the [Windows Subsystem for Linux](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide) a go.

You need to enable the *Windows Subsystem for Linux* feature in Windows, and reboot to install the kernel driver.
Then you can run `bash`, which downloads and installs the base system image.
Then set a username and password.
Then an `apt update` and `apt upgrade` to get things up to date.
And finally, [installing C compilers](https://help.ubuntu.com/community/InstallingCompilers) via the `build-essentials` package (and a few others).

From there, downloading and compiling TestU01 was easy:

```
$ ./configure --prefix=/usr/local
$ make
$ sudo make install
```

Running TestU01 was somewhat more difficult.

Unlike PractRand and Dieharder, which have a console apps that can accept input from stdio or a file, TestU01 is a C library with no console app out of the box.
It has some example files which illustrate basic use cases, and some standard "batteries" of tests that you call via a C function. 
Just no way to use it without an additional compilation step.

After reading the [doco](http://simul.iro.umontreal.ca/testu01/guideshorttestu01.pdf) and copying most of the `bat1.c` example, I created a few basic C programs which ran the *small crush*, *crush* and *big crush* test batteries, like so:

```c
int main (void)
{
   unif01_Gen *gen;
   gen = ufile_CreateReadBin ("/mnt/m/random.256G.bin", 16384);
   bbattery_Crush (gen);
   ufile_DeleteReadBin (gen);
   return 0;
}
```

A few more steps were needed to get that to compile:

```
$ export LD_LIBRARY_PATH=/usr/local/lib
$ export LIBRARY_PATH=/usr/local/lib
$ gcc crush.c -o crush -ltestu01 -lprobdist -lmylib -lm
```

And finally, you can run it like so:

```
$ ./crush > crush-output.txt
```

Several of the tests had borderline p values, and *LongestHeadRun* was flagged as a failure (p value lower than 0.001).

Here's the full output of the [small crush](/images/Building-A-CRNG-Terninger-4-Random-Tests/testu01-crush-small.out.txt) and [crush](/images/Building-A-CRNG-Terninger-4-Random-Tests/testu01-crush-normal.out.txt) tests. 
The big crush test had troubles running because 256GB (and even 384GB) wasn't enough randomness for all its tests in one go (the doco estimates around 1TB of random bytes are required), so its results are broken up into several parts: [part 1](/images/Building-A-CRNG-Terninger-4-Random-Tests/testu01-bigcrush.out.1.txt), [part 2](/images/Building-A-CRNG-Terninger-4-Random-Tests/testu01-bigcrush.out.2.txt), [part 3](/images/Building-A-CRNG-Terninger-4-Random-Tests/testu01-bigcrush.out.3.txt), [part 4](/images/Building-A-CRNG-Terninger-4-Random-Tests/testu01-bigcrush.out.4.txt), [part 5](/images/Building-A-CRNG-Terninger-4-Random-Tests/testu01-bigcrush.out.5.txt), [part 6](/images/Building-A-CRNG-Terninger-4-Random-Tests/testu01-bigcrush.out.6.txt), [part 7](/images/Building-A-CRNG-Terninger-4-Random-Tests/testu01-bigcrush.out.7.txt).


### Dieharder

http://www.phy.duke.edu/~rgb/General/dieharder.php

Dieharder is Linux only, and there were binaries available via `apt`.

```
$ sudo apt install dieharder
$ dieharder -a -f /mnt/m/random.256G.bin -g 201 > dieharder.256G.output.txt
```

Dieharder accepted a file as input, and [produced output](/images/Building-A-CRNG-Terninger-4-Random-Tests/dieharder.out.txt) showing p-values and a rating for each test run.
Several tests showed Turninger as *weak* with low p values, but none were labelled as a fail.

As with other tests, I'm not sure if this is normal, good or bad. 

One thing I noted with Dieharder was it used a lot of kernel CPU time.
Given that TestU01 could read files at 50MB/sec or faster, I suspect the issue lies with Dieharder rather than the Linux Subsystem for Windows.

<img src="/images/Building-A-CRNG-Terninger-4-Random-Tests/dieharder-cpu.png" class="" width=300 height=300 alt="Dieharder uses much more kernel CPU time than I'd expect" />


### How to Fix the Weak / Poor Tests

Given the PRNG is AES, there isn't much I can do about the test results that are marked as poor or weak.
I can't go and change the AES algorithm or implementation.
It's possible a different cypher will produce better results (I'll test other cyphers when I allow them to be configured).
It's much more likely that my implementation has a subtle flaw or bug.

It's also possible that the tests themselves are flawed (the author of PractRand has indicated this about some Dieharder tests). 
But I'm in no position to comment on that.

I probably should have thought more about this before starting this analysis; I was expecting AES in counter mode to pass with flying colours.


### Some Thoughts about WSL

The [Windows Subsystem for Linux](https://msdn.microsoft.com/en-us/commandline/wsl) was essential for me to complete these tests. Here are a few thoughts from my use of it:

* **It works!**: I really want to emphasise this: *it just worked*. Granted, compiling some programs, reading some large files and burning CPU time isn't very taxing, but it's a very functional Linux compatible command line within Windows itself!
* **It's light weight**: The initial download is ~250MB, disk footprint is ~1GB. Memory usage for the `bash` shell and other basic processes is under 50MB. This is much smaller than a comparable VM.
* **It's IO performance isn't great**: I guess that's to be expected though. Windows doesn't play as well with lots of small files, and Linux makes great use of many small files. There's layers of translation and mapping that has to happen for each IO call. And it is still labelled a *Beta*. Having said that, dieharder had the issue using [excessive kernal CPU time](/images/Building-A-CRNG-Terninger-4-Random-Tests/dieharder-cpu.png); TestU01 was reading at 50MB/sec or more with minimal kernel CPU impact - so it may depend on the program doing the IO.
* **You install it per-user**: After the system wide LXSS component is installed, everything else is user land. (Yes, I instinctively downloaded it for my admin user first, and then had to re-download it for my normal user).
* **Everything stops when you close bash**: Close the shell and everything else goes away. So it's not really suitable for servers just yet (although I understand that may change in the future).

My overall impression is: it's perfectly usable for filling a gap (I need these two Linux things, but I really don't care for a whole VM), but I wouldn't be running production workloads just yet.



## Next Up

We've demonstrated that the core Fortuna PRNG is indeed random (at least within a reasonable margin of randomness). Although there are some potential weaknesses that we can't do much about just yet.

The next step will be to allow customising the PRNG.
Some customisations will be to allow flexibility (different block cyphers), some for new functionality (adding small amounts of additional entropy), and some with performance in mind (larger buffer and block sizes).

However, there are a few other projects that need my attention, so I'll put Turninger on pause for a while.
