# Capture System IP core

This testing module interfaces with the rest of the cores through the AXI Stream interface. For configuration purposes there is also one AXI-Lite Slave interface

## Usage

The core accepts AXI stream data from its slave interface. When it is triggered, it passes through the indicated amount of data to the master AXI stream interface. The AXI-Lite interface is used for configuration and trigger. The amount of data the user wants to be passed through is indicated by a write operation to the register at the address "0h" of the AXI-Lite memory-mapped interface. This serves also as the trigger for the passthrough. Note that the number of data the user provides corresponds not to bytes but to samples, as they have been configured by the customization GUI (default is 32 bits == 4 bytes).
