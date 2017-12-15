========
Icescint
========

Main Data Format
################

The basic structure of all data coming out of the FPGA fifo is organized in packets of 9 words. One word is 2 byte. The first word always contains a type. The following 8 words mostly contain data related to a specific channel. The type also contains a counter (bit 9..0) to identify consecutive packets of the same type inside one event / message. 

+--------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| type   | channel 0 | channel 1 | channel 2 | channel 3 | channel 4 | channel 5 | channel 6 | channel 7 |
| 2 Byte | 2 Byte    | 2 Byte    | 2 Byte    | 2 Byte    | 2 Byte    | 2 Byte    | 2 byte    | 2 Byte    |
+--------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+

Event Based Packets
####################

An event in this sense is generated from the trigger system. The source can be a real signal from the detector or an artificially generated trigger (soft trigger). The data of one event consist of several packets. The first packet will be a header describing the following event. The packets following the header are optional. They can be enabled and disabled through configuration. The presence of the header itself can not be configured manually, it will be controlled automatically. If all event based packets are disabled the header will also be disabled.

Header
~~~~~~

+--------+---------------+---------------+--------------+-------------------+-------------------+-------------------+-------------------+----------+
| Header | event counter | event counter | event length | real time counter | real time counter | real time counter | real time counter | DRS4 ROI |
| 0x1000 | [31..16]      | [15..0]       | [63..48]     | [63..48]          | [47..32]          | [31..16]          | [15..0]           | 2 Byte   |
+--------+---------------+---------------+--------------+-------------------+-------------------+-------------------+-------------------+----------+

* Word 0: type 0x1000
* Word 1..2: event counter (32 bit)
* Word 3: event length in packets including the header
* Word 4..7: real time counter (64 bit)
* Word 8: DRS4 region of interest pointer

DRS4 Sampling
~~~~~~~~~~~~~

If the number of samples to read is configured to 200 (which is 0xc8) than there will be 200 packets. The types will be from 0x4000 to 0x40c7. The maximum useful number of samples to read is 1024. The real ADC resolution per sample is 14 bit. 

+----------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| DRS4 Sampling  | channel 0 | channel 1 | channel 2 | channel 3 | channel 4 | channel 5 | channel 6 | channel 7 |
| 0x4000..0x43ff | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   |
+----------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+

* Word 0: type 0x4000 .. 0x43ff
* Word 1..8: one sample per channel

DRS4 Charge
~~~~~~~~~~~

The DRS4 charge is the sum of all samples of one channel per event. The resulting value has 24 bit and is split between two packets.

+-----------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| DRS4 Charge MSB | channel 0 | channel 1 | channel 2 | channel 3 | channel 4 | channel 5 | channel 6 | channel 7 |
| 0x6000          | [23..16]  | [23..16]  | [23..16]  | [23..16]  | [23..16]  | [23..16]  | [23..16]  | [23..16]  |
+-----------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| DRS4 Charge LSB | channel 0 | channel 1 | channel 2 | channel 3 | channel 4 | channel 5 | channel 6 | channel 7 |
| 0x6001          | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   |
+-----------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+

* Word : type 0x6000 .. 0x6001
* Word 1..8: one part of the charge per channel

DRS4 Baseline
~~~~~~~~~~~~~

The DRS4 Baseline works similar to the charge. It is the sum of samples in a configured region in the wave form. If the region is set to a pre trigger position in the wave form it will contain the baseline. The value has 24 bit and is split between two packets.

+-------------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| DRS4 Baseline MSB | channel 0 | channel 1 | channel 2 | channel 3 | channel 4 | channel 5 | channel 6 | channel 7 |
| 0x5000            | [23..16]  | [23..16]  | [23..16]  | [23..16]  | [23..16]  | [23..16]  | [23..16]  | [23..16]  |
+-------------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| DRS4 Baseline LSB | channel 0 | channel 1 | channel 2 | channel 3 | channel 4 | channel 5 | channel 6 | channel 7 |
| 0x5001            | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   |
+-------------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+

* Word 0: type 0x5000 .. 0x5001
* Word 1..8: one part of the charge per channel

Non Event Based Packets
#######################

Some packets do not correspond to a event. These packets do not use the header and can, if configured, occur at any time. But they will never occur inside / during a event based packet.   

GPS
~~~

The real time counter and the GPS PPS are latched at the same time.

+--------+---------+-------------------+-------------------+------------------------------------+-------------------+-------------------+-------------------+-------------------+
| GPS    | week    | time of week [ms] | time of week [ms] | tick difference GPS to local clock | real time counter | real time counter | real time counter | real time counter |
| 0x9000 | [15..0] | [31..16]          | [15..0]           | [15..0]                            | [63..48]          | [47..32]          | [31..16]          | [15..0]           |
+--------+---------+-------------------+-------------------+------------------------------------+-------------------+-------------------+-------------------+-------------------+

* Word 0: type 0x9000
* Word 1: GPS week number
* Word 2..3: time of week in milli secunds (GPS weeks start at Sunday morning)
* Word 4: clock tick difference based on PPS input (value is signed) 
* Word 5..8: latched local real time counter 

White Rabbit
~~~~~~~~~~~~

The White Rabbit counter and the real time counter are latched at the same time.

+--------------+----------+----------+----------+---------+-------------------+-------------------+-------------------+-------------------+
| White Rabbit | WR time  | WR time  | WR time  | WR time | real time counter | real time counter | real time counter | real time counter |
| 0x8000       | [63..48] | [47..32] | [31..16] | [15..0] | [63..48]          | [47..32]          | [31..16]          | [15..0]           |
+--------------+----------+----------+----------+---------+-------------------+-------------------+-------------------+-------------------+

* Word 0: type 0x8000
* Word 1..4: latched White Rabbit counter 
* Word 5..8: latched local real time counter

Pixel Rate Counter
~~~~~~~~~~~~~~~~~~

The Pixel Rate Counter will show the last complete period.

+--------------------+-------------------+-------------------+-------------------+-------------------+----------------+----------------+----------------+----------------+
| Pixel Rate Counter | channel 0         | channel 1         | channel 2         | channel 3         | channel 4      | channel 5      | channel 6      | channel 7      |
| 0x2000             | [15..0]           | [15..0]           | [15..0]           | [15..0]           | [15..0]        | [15..0]        | [15..0]        | [15..0]        |
+--------------------+-------------------+-------------------+-------------------+-------------------+----------------+----------------+----------------+----------------+
| Pixel Rate Counter | channel 0         | channel 1         | channel 2         | channel 3         | channel 4      | channel 5      | channel 6      | channel 7      |
| 0x2001             | [15..0]           | [15..0]           | [15..0]           | [15..0]           | [15..0]        | [15..0]        | [15..0]        | [15..0]        |
+--------------------+-------------------+-------------------+-------------------+-------------------+----------------+----------------+----------------+----------------+
| Pixel Rate Counter | real time counter | real time counter | real time counter | real time counter | counter period | counter period | counter period | counter period |
| 0x2002             | [63..48]          | [47..32]          | [31..16]          | [15..0]           | [63..48]       | [47..32]       | [31..16]       | [15..0]        |
+--------------------+-------------------+-------------------+-------------------+-------------------+----------------+----------------+----------------+----------------+

* Word 0: type 0x2000 .. 0x2001
* Word 1..8: number of counted events per channel. The period for the counter to reset.

* Word 0: type 0x2002
* Word 1..4: latched local real time counter
* Word 5..8: the period the counter was active  





