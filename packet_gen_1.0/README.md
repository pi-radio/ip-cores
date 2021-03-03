# Packet Generator IP Core

This core generates packets in a OFDM-suitable format.

## Description

The core starts generating packets as soon as the user writes a non-zero value to the register at index 00h. It stops and resets when user writes zero to the same register.

The core assumes a fixed number of 1024 subcarriers, and 10 OFDM symbols packet length. The first symbol of each packet is occupied by a synchronization word, and the rest by a combination of a seed number and counters of the core, as the payload. Pilot subcarriers are added to every one in four symbols, at multiples of 5 subcarrier indexes. Also, it is assumed that only 800 subcarriers are active in each symbol, as the rest are filled with zeros by the modulator core. 
