# MIDI Sound Mode Addon for FCEUX

How to enable:
* Make sure luamidi.dll is placed in the FCEUX or System32 directory (for 64-bit use luamidi64.dll renamed to luamidi.dll)
* Config > Sound > Sound enabled., turn off
* Config > Timing > Disable speed throttling used when sound is disabled., keep off if you want
* File > Lua > New Lua Script Window and open MIDISound.lua
* Enter optionally the below options in the arguments, run to enable the MIDI sound mode.

### Options:
* -l	List available MIDI devices
* -o	Use MIDI port # [0]
* -v	Note velocity [127]
* -e	Use expression instead of channel volume (overrides channel volume to specific value) [0]
* -d	Enable DMC DPCM channel to MIDI (channels 5 and 10)

	Needs comma-separated Address:Patch [0]:Key [24] and/or Address-0x4000:Drum - see below for examples [0]
* -0	Patch # for each duty cycle [7,81,80,87]
* -1	Patch # for triangle [39]
* -2	Patch # for noise [126]
* -3	Patch # for short noise [124]
* -9	Patch # for drums assigned to DPCM [-1]
* -g	Use Bank MSB # for each duty cycle (nil,1,1 recommended for GS devices) [0,0,0,0]
* -x	Use Bank LSB # for each duty cycle (nil,6,6 recommended for XG devices) [0,0,0,0]
* -n	Disable noise channel (MIDI channel 4)
* -b	Disable Pitch Bend (if your hardware tone generator doesn't support pitch bend, this may reduce buffer)
* -t	Disable Portamento Control (if your hardware tone generator doesn't support portamento control, this may reduce buffer)
* -s	Channel initialization type on start [1]

0. Don't sent Mono Operation, Reverb, and ADR off events
1. Use controllers 72, 73, and 75 for ADR off
2. Use NRPN for ADR off (if your MIDI tone generator doesn't support controllers 71-78 and instead has them in RRPN only)
* -h	Display help in console

## -d argument examples for specific game:
* Duck Hunt

**BB00:76 -956**
* Super Mario Bros. 3

**9800:47,9B80:62,A000:36,A080:38,A980:63,AA80:66,EE00:47:12,B280:60**
* Dr. Mario

**BD00:64,BD80:63**
* Journey to Silius

**C000:37:10,C400:37:12,C800:37:14,CC00:37:11,D000:37:13**
* Race America

**8040:36,81C0:38,8440:48,8789:43**
* U-four-ia: The Saga

**C000:37:12,C400:37:14,C800:37:11,CC00:37:13,D000:37:10,D400:118**
* Tetris 2 + BomBliss

**8000:75 -956** or **C000:127:0**
* Kira Kira Star Night

**8000:38,82C0:36**
* Dr. Garfield

**EAC0:39:12,EDC0:39:14**

More to come…