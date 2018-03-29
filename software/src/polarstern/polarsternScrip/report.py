#!/usr/bin/python

import sys
import os
from operator import add

clockRate = 118750000
summationTime = 60*60*clockRate # 1h

def printStats(h, date):
    #print("pixel trigger rates:")
    #print(pixelTriggerSum)
    #print("sector trigger rates:")
    #print(clusterTriggerRateSum)
    #print("sector pattern rates: (1:1,1:2,1:3,1:4,2:1, ... ,4:4)")
    #print(clusterTriggerPatternSum)
    print(h,pixelTriggerSum, clusterTriggerRateSum, clusterTriggerPatternSum)

def clearStats():
    global pixelTriggerSum
    global clusterTriggerRateSum
    global clusterTriggerPatternSum
    pixelTriggerSum = [0]*16
    clusterTriggerRateSum = [0]*8
    clusterTriggerPatternSum = [0]*17

def getSec(clock):
    c = clock.split("-")
    h = int(c[0])
    m = int(c[1])
    s = int(c[2])
    a = s + m*60 + h*3600
    b = s + m*60
    return h,b

def getEventStats(e):
    global eventTime  
    global eventTimeEnd
    global verbose
    
    
    pixel = [0]*16    
    clusterTrigger = [0]*8
    clusterTriggerPattern = [0]*17

    for t in range(7,23):
        if(e[t] != 0x8080):
            pixel[t-7] = 1
    
    for t in range(8):
        if((pixel[t*2] == 1) and (pixel[t*2+1] == 1)):
            clusterTrigger[t] = 1  
    
    for m in range(0,4):
        for n in range(0,4):
            if((clusterTrigger[m] == 1) and (clusterTrigger[n+4] == 1)):
                clusterTriggerPattern[m*4+n] = 1

    if(clusterTrigger == [1]*8):
        clusterTriggerPattern[16] = clusterTriggerPattern[16] + 1

    return (pixel,clusterTrigger,clusterTriggerPattern)

def getTime(e):
    return  0 + e[3]*2**48 + e[4]*2**32 + e[5]*2**16 + e[6]

def getEvent(rawFile):
    e = []
    for u in range(23):
        lo = rawFile.read(1)
        hi = rawFile.read(1)
        if((lo == None) or (hi == None) or (lo == "") or (hi == "")):
            return False 
        e.append((ord(hi)*0x100+ord(lo))) 
    return e

def getNextTriggerEvent(rawFile):
    while True:
        e = getEvent(rawFile)
        if(e == False):
            return False
        if(e[0] == 0x1000):
            return e

def dropEventUntil(rawFile, time):
    e = getNextTriggerEvent(rawFile)
    if(e == False):
        return False

    while(getTime(e) < time):
        e = getNextTriggerEvent(rawFile)
    return e

def addToStats(s):
    global pixelTriggerSum
    global clusterTriggerRateSum
    global clusterTriggerPatternSum
        
    pixelTriggerSum = map(add, pixelTriggerSum, s[0])
    clusterTriggerRateSum = map(add, clusterTriggerRateSum, s[1])
    clusterTriggerPatternSum = map(add, clusterTriggerPatternSum, s[2])

def cleanupString(l):
    msg = ""
    msg = msg.join(l)
    msg = msg.replace(",","")
    msg = msg.replace("[","")
    msg = msg.replace("]","")
    return msg

def scanFile(rawFile, reportFile, time, date):
    global pixelTriggerRate 
    e = getNextTriggerEvent(rawFile)
    if(e == False):
        return False
    h,b = getSec(time)
    timeStart = getTime(e)
    timeEnd = timeStart + (60*60-b)*clockRate 
    if(b>100):
        dropEventUntil(rawFile, timeEnd)
        timeEnd = timeEnd + summationTime 
        h = h + 1

    while True:
        #e = getNextTriggerEvent(rawFile)
        #if(e == False):
        #    return x
        e = getEvent(rawFile)
        if(e == False):
            return False
        if(e[0] == 0x1000):
            s = getEventStats(e)
            addToStats(s)
            if(getTime(e) > timeEnd):
                printStats(h, date)
                m = "" + date + " " + time + " " + str(h) + " " + str(pixelTriggerSum) + " " + str (clusterTriggerRateSum) + " " + str(clusterTriggerPatternSum) + "\n"
                reportFile.write(cleanupString(m))
                clearStats()
                h = h + 1
                timeEnd = timeEnd + summationTime 
        elif(e[0] == 0x2000):
            #gps
            pass
        elif(e[0] == 0x5000):
            #pixel trigger before trigger logic
            for i in range(16):
                pixelTriggerRate[i] = pixelTriggerRate[i] + e[7+i]
            pixelTriggerRate[16] = pixelTriggerRate[16] + e[1]
            #print("0x5000: ", e[1] ,e[7:23])
        elif(e[0] == 0x6000):
            #sector Trigger rate
            #print("0x6000: ", e[7:23])
            pass

    return True

#rawPath = "/data/raw/"
#reportPath = "/data/report/"
rawPath = "/c/Users/kossatz/Desktop/mt/test/"
reportPath = "/c/Users/kossatz/Desktop/mt/test/"

la = os.listdir(rawPath)
l2 = [a for a in la if '.bin' in a]
l3 = [a for a in la if '.done' in a]
lb = os.listdir(reportPath)
l4 = [a for a in lb if '.report' in a]
l5 = [a for a in lb if '.send' in a]

for i in l2:
    #print(i)
    doneFileName = i[:-4]+".done"
    reportFileName = i[:-4]+".report"
    if reportFileName in l4:
        continue
    else:
        if doneFileName in l3:
            clearStats()
            eventTime = 0;
            eventTimeEnd = 0
            
            reportFile = open(reportPath+reportFileName, "w")

            with open(rawPath+i, "rb") as rawFile:
                pixelTriggerRate = [0.0]*17 
                name = i.split("_")
                date = name[2]
                time = name[3][:-4]
                print("")
                print(rawPath+i+":")
                print("" + date + " " + time + ":")
                print("------------------------------------------")
                #reportFile.write(date + " " + time)
                scanFile(rawFile, reportFile, time, date)
                
                for i in range(16): pixelTriggerRate[i] = pixelTriggerRate[i] / pixelTriggerRate[16]
                #print(pixelTriggerRate)
                reportFile.write(cleanupString("#rawPixelRates: " + str(pixelTriggerRate[:-1])))
                
                reportFile.close()
            rawFile.close()
        else:
            print("file " + i + " is not done")

#TODO: send all *.report files per mail and generate *.send files
#for i in l4:
#   ...



