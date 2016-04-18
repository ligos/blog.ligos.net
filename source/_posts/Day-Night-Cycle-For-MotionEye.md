---
title: Day / Night Cycle for MotionEye
date: 2016-04-18 22:00:00
tags:
- Raspberry Pi
- Security
- Home Security
- Camera
- Video 
- Surveillance
- MotionEye
- Python
- Configuration
- Day Night Cycle
categories: Technical
---

A simple script to configure [MotionEye](https://github.com/ccrisan/motioneye) to change configuration based on a day / night cycle.

<!-- more --> 

<div class="highlight"> 
[**Download sunriseset.py**](/images/Day-Night-Cycle-For-MotionEye/sunriseset.py)
</div>

## Background 

After [setting up my Raspberry Pi to run as a fast network camera with an MJPEG stream](/2016-04-17/RaspberryPi-As-A-Simple-MJPEG-Camera.html), I found that the configuration needed to be slightly different between day time and night time. 

Mostly, the ISO sensitivity needed to be pushed as far as it would go at night, and the brightness increased.
While in the day time, ISO can be relaxed and brightness set back to default. 

Otherwise, day time images were too noisy (which means falsely detecting motion) and night time was totally black:

<img src="/images/Day-Night-Cycle-For-MotionEye/night.jpg" class="" width=300 height=300 alt="Not going to detect much motion" />

My two options were:

1. Check the images for an average level of blackness / brightness and change config files.
2. Check the current time relative to sunset / sunrise and change config files.

Number 1 was too CPU intensive to run on a Raspberry Pi, so I went with number 2.

## Calculating Sunset and Sunrise With Python

Calculating sunrise and sunset is a known thing, but still pretty complicated for my math-poor brain.
[Wikipedia has the actual formulas](https://en.wikipedia.org/wiki/Sunrise_equation).
And Michel Anders [implemented them in python](http://michelanders.blogspot.com.au/2010/12/calulating-sunrise-and-sunset-in-python.html), which my script is heavily based on.

I uploaded the script to my Pi in `/data/storage`, as that was writable on [MotionEyeOS](https://github.com/ccrisan/motioneyeos).

## Script Configuration

The script itself requires minimal configuration:

* Your timezone
* Your location (latitude and longitude)
* An optional fudge factor to make the day / night transition happen slightly earlier or later

The fudge factor deserves a little more explanation.
I found that, because of the location of trees, buildings, hills, etc that it would get dark a little earlier than the calculated time allows for.
So, you can fudge your own local *sunrise* or *sunset* time to be slightly different, depending on local conditions. 

``` python

# Varient of time zone available on MotionEyeOS
localTimezone = timezone('Australia/Sydney')

# Location of here in lat / long (consult your favourite maps app to determine this)
localLat = -33.8
localLong = 151.0

# Sunrise and sunset fudge factor (in minutes)
# Positive minutes is later, negative minutes is earlier.
sunriseFudgeMinutes = 10
sunsetFudgeMinutes = -10

# Current state of day / night is stored in this file.
dayAndNightStateFile = '/var/spool/dayornight'

```

## MotionEye Configuration

As MotionEye is a front-end to several other programs, most of its work is updating various configuration files. 

To support new configurations, I configured things as I'd like in MotionEye.
Then copied the resulting configuration files to have `.day` or `.night` after them.

The script will copy the `.day` or `.night` config file to the real file to adopt that configuration. 

<img src="/images/Day-Night-Cycle-For-MotionEye/config.png" class="" width=300 height=300 alt="Day / Night configuration files" />

Incidentally, you can get a good idea of the files MotionEye uses by doing a backup and then opening the `tar.gz` file.

## Algorithm

This is quite simple.

The script loads the last day / night state (which will be empty on first run, or saved from last run).
Then calculates the current state based on current time of day.
If they are different, it updates the configuration files and restarts MotionEye. 
Then, saves the new state to file.

``` python
 # Track day / night state in file.
 fileDayOrNight = readLineOfFile(dayAndNightStateFile)
 print('previous day/night state: ' + fileDayOrNight)
 
 # Determine current day / night state based on current time of day.
 s=sun(lat=localLat,long=localLong)
 currentDayOrNight = s.dayornight(sunriseFudge=sunriseFudgeMinutes,sunsetFudge=sunsetFudgeMinutes)
 print('current day/night state: ' + currentDayOrNight)
 
 if fileDayOrNight != currentDayOrNight:
  print('File and current day/night state are different. Changing to "' + currentDayOrNight + '" config.')
  
  # On transition between day / night, copy config files and restart motioneye processes.
  copyConfigFiles(currentDayOrNight)
  print('Updated config files, restarting motioneye...')
  restartMotionEye()
  print('Motioneye resetarted.')
  
  # Update the file day / night state.
  updateContentsOfFile(dayAndNightStateFile, currentDayOrNight)
```

## Cron Job

Finally, I added a cron job which executed the script every 5 minutes.

```
02,07,12,17,22,27,32,37,42,47,52,57 * * * * /usr/bin/python /data/sunriseset.py >> /var/log/daynight.log
```

Yes, it would be better to run the script less often. 
But this arrangement a) works and b) doesn't involved modifying crontab from a cron job - which I'd need to do as sunset / sunrise changes throughout the year.

## Conclusion

This script allows for a basic day / night cycle to be used on my Raspberry Pi based MotionEye camera.
I can use slightly different settings day or night, so the camera is best at detecting motion. 

<div class="highlight"> 
[**Download sunriseset.py**](/images/Day-Night-Cycle-For-MotionEye/sunriseset.py)
</div>
 