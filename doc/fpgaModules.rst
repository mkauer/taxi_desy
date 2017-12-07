========
Icescint
========

FPGA modules
################

There are two main information path. A trigger path (output of the comparators) and a data path (output of the adc with wave form data from DRS4).
Boxes are vhdl modules, squared brackets are external hardware components eg. [ADC]

Trigger path
~~~~~~~~~~~~

    ┌────────┐      ┌───────────────┐
    │ serdes │──┬──>│ pixel counter │
    └────────┘  │   └───────────────┘
       ^        │
       │        │   ┌───────────────┐   ┌───────┐   ┌────────────────┐
[comparator]    ├──>│ trigger logic │──>│ delay │──>│ edge detection │──> FIFO
                │   └────────────┬──┘   └───────┘   └────────────────┘
                │                └──> event trigger         ^
                │   ┌───────┐                               │
                └──>│ delay │───────────────────────────────┘
                    └───────┘

Data path
~~~~~~~~~

            ┌────────┐
    [ADC]──>│ serdes │
            └────┬───┘
                 │
                 V
┌──────┐   ┌─────────┐
│ drs4 ├──>│ ltm9004 ├──┐
└──────┘   └─────────┘  │
   ^            ^       │
   │            │       │   ┌───────────┐
   V            V       ├──>│ wave form ├──> FIFO
 [DRS4]       [ADC]     │   └───────────┘
                        │
                        │   ┌────────┐
                        ├──>│ charge ├──> FIFO
                        │   └────────┘
                        │
                        │   ┌──────────┐
                        └──>│ baseline ├──> FIFO
                            └──────────┘

Other vhdl modules
~~~~~~~~~~~~~~~~~~

* Internal Timing
* GPS
* WR
* vcxo
* 










