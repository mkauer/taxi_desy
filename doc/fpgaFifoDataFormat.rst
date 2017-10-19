========
Icescint
========

Main Data Format
################

The basic structure of all data coming out of the FPGA fifo is organized in packets of 9 words. One word is 2 byte. The first word always contains a type. The following 8 words mostly contain data related to a specific channel. The type also contains a counter (bit 9..0) to identify consecutive packets of the same type inside one event.

+--------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| type   | channel 0 | channel 1 | channel 2 | channel 3 | channel 4 | channel 5 | channel 6 | channel 7 |
| 2 Byte | 2 Byte    | 2 Byte    | 2 Byte    | 2 Byte    | 2 Byte    | 2 Byte    | 2 byte    | 2 Byte    |
+--------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+

The data of one event consist of several packets. The first packet will be a header describing the following event. The packets following the header are optional. They can be enabled and disabled through configuration.

Header
~~~~~~

+--------+---------------+---------------+--------------+-------------------+-------------------+-------------------+-----------------+----------+
| Header | event counter | event counter | event length | real time counter | real time counter | real time counter | realtim counter | DRS4 ROI |
| 0x1000 | [31..16]      | [15..0]       | [63..48]     | [63..48]          | [47..32]          | [31..16]          | [15..0]         | 2 Byte   |
+--------+---------------+---------------+--------------+-------------------+-------------------+-------------------+-----------------+----------+

* Word 0: type 0x1000
* Word 1..2: event counter (32 bit)
* Word 3: event length in packets including the header
* Word 4..7: real time counter (64 bit)

DRS4 Sampling
~~~~~~~~~~~~~

If the number of samples to read is configured to 200 (which is 0xc8) than there will be 200 packets. The types will be from 0x4000 to 0x40c7. The maximum useful number of samples to read is 1024. The real ADC resolution per sample is 14 bit. 

+----------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| DRS4 Sampling  | channel 0 | channel 1 | channel 2 | channel 3 | channel 4 | channel 5 | channel 6 | channel 7 |
| 0x4000..0x43ff | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   | [15..0]   |
+----------------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+

* Word 0: type 0x4000 .. 0x43ff
* Word 1..7: one sample per channel

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
* Word 1..7: one part of the charge per channel

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
* Word 1..7: one part of the charge per channel








