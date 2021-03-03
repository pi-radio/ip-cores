# Modulator IP Core

This core performs BPSK modulation to the input data and adds null subcarriers at DC and at the first and last subcarriers.

## Description

The core accepts as input 32 bit wide samples from the packet generator block, adds zeros at the proper subcarrier indices and BPSK-modulates the data. It assumes FFT size of 1024. The user can reset the core by writing at any of the four registers available through the Slave AXI memory mapped interface.
