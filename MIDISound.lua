midi=require"luamidi"
assert(midi.getoutportcount()>0,"No MIDI output devices detected!")
function round(num)return math.floor(num+.5)end
portID,noiseEnable,bend,portamentoControl,init,velocity,volume,dutyPatches,dutyBankMSB,dutyBankLSB,trianglePatch,noisePatch,noiseShortPatch,lastVolume,lastTriangleOn,lastVolumeNoise,lastNote,retrigger,lastNoteTriangle,lastNoteNoise,lastPitch,lastPitchTriangle,lastDuty,bankMSB,bankLSB,paused=0,true,true,true,1,127,0,{7,81,80,87},{0,0,0,0},{0,0,0,0},39,126,124,{0,0},false,0,{0,0},{false,false},0,0,{8192,8192},8192,{},{0,0,0,0},{0,0,0,0},false
if arg then
for x in arg:gmatch"%S+"do
if x:sub(1,2)=="-h"or x=="--help"then
print("MIDI Sound Mode Addon for FCEUX"..(string.char(13)..string.char(10)):rep(2).."Options:"..string.char(13)..string.char(10),"-l	List available MIDI devices"..string.char(13)..string.char(10),"-o	Use MIDI port # [0]"..string.char(13)..string.char(10),"-v	Note velocity [127]"..string.char(13)..string.char(10),"-e	Use expression instead of channel volume (overrides channel volume to specific value) [0]"..string.char(13)..string.char(10),"-d	Enable DMC DPCM channel to MIDI"..string.char(13)..string.char(10).."	Needs comma-separated Address:Patch [0]:Key [24] and/or Address-0x4000:Drum [0]"..string.char(13)..string.char(10),"-0	Patch # for each duty cycle [7,81,80,87]"..string.char(13)..string.char(10),"-1	Patch # for triangle [39]"..string.char(13)..string.char(10),"-2	Patch # for noise [126]"..string.char(13)..string.char(10),"-3	Patch # for short noise [124]"..string.char(13)..string.char(10),"-9	Patch # for drums assigned to DPCM [-1]"..string.char(13)..string.char(10),"-g	Use Bank MSB # for each duty cycle (nil,1,1 recommended for GS devices) [0,0,0,0]"..string.char(13)..string.char(10),"-x	Use Bank LSB # for each duty cycle (nil,6,6 recommended for XG devices) [0,0,0,0]"..string.char(13)..string.char(10),"-n	Disable noise channel (MIDI channel 4)"..string.char(13)..string.char(10),"-b	Disable Pitch Bend (if your hardware tone generator doesn't support pitch bend, this may reduce buffer)"..string.char(13)..string.char(10),"-t	Disable Portamento Control (if your hardware tone generator doesn't support portamento control, this may reduce buffer)"..string.char(13)..string.char(10),"-s	Channel initialization type on start [1]"..string.char(13)..string.char(10).."	0=Don't sent Mono Operation, Reverb, and ADR off events"..string.char(13)..string.char(10).."	1=Use controllers 72, 73, and 75 for ADR off"..string.char(13)..string.char(10).."	2=Use NRPN for ADR off (if your MIDI tone generator doesn't support controllers 71-78 and instead has them in RRPN only)"..string.char(13)..string.char(10),"-h	Display this help info")
elseif x:sub(1,2)=="-l"or x=="--listmidi"then
table.foreach(midi.enumerateoutports(),print)
elseif x:sub(1,2)=="-o"then
local param = tonumber(x:sub(3))
if type(param)=="number" and param>=0 and param==math.floor(param)then if param<midi.getoutportcount()then portID=param else print("MIDI Device ID",param,"exceeds",midi.getoutportcount(),"connected MIDI Out devices!")end else print"-o argument (Use MIDI port #) needs to have a number!"end
elseif x:sub(1,2)=="-v"then
local param=tonumber(x:sub(3))
if type(param)=="number" and param>0 and param<128 and param==math.floor(param)then velocity=param else print"-v argument (note velocity) needs to have a number between 1 and 127!"end
elseif x:sub(1,2)=="-e"then
local param=tonumber(x:sub(3))
if type(param)=="number" and param>0 and param<128 and param==math.floor(param)then volume=param else print"-e argument (use expression instead of volume) needs to have a number between 1 and 127!"end
elseif x:sub(1,2)=="-n"or x=="--no-noise"then
noiseEnable=false
elseif x:sub(1,2)=="-d"then
if x:sub(3):len()>3 then
dmcPatches,dmcNoteShift,dmcDrums,lastNoteDMC,retriggerDMC,lastDMCPatch,lastDMCDrum={},{},{},-1,false,-1,-1
for a in x:sub(3):gmatch"[^,]+"do
local i,v=1
for b in a:gmatch"[^:]+"do
if i==1 and type(tonumber(b,16))=="number"then
v=math.floor((tonumber(b,16)-32768)/64)
if v>=0 and v<256 then
if dmcDrums[v]then
print("A drum entry of",b,"already exists!")
break
else
dmcDrums[v]=0
end
i=4
elseif v>255 and v<512 then
v=v-256
if dmcPatches[v]then
print("An entry of address",b,"already exists!")
break
else
dmcPatches[v],dmcNoteShift[v]=0,24
end
i=2
else
print("Sample address",b,"of",a,"is out of range. Must be between C000 and FFFF in hex. Subtract from 4000 (= 8000 to BFFF) to assign as a drum")
break
end
elseif i==2 and type(tonumber(b))=="number"then
local t=math.floor(tonumber(b))
if t>=0 and t<128 then dmcPatches[v]=t else print("Patch number",b,"of",a,"is out of range. Must be between 0 and 127")end
i=3
elseif i==3 and type(tonumber(b))=="number"then
local t=math.floor(tonumber(b))
if t>=0 and t<92 then dmcNoteShift[v]=t else print("Note shift",b,"of",a,"is out of range. Must be between 0 and 91")end
i=5
elseif i==4 and type(tonumber(b))=="number"then
local t=math.floor(tonumber(b))
if t>=0 and t<128 then dmcDrums[v]=t else print("Drum note",b,"of",a,"is out of range. Must be between 0 and 127")end
i=5
elseif i>4 then
print("Please do not have more colon-separated values for",a)
break
else
print(b,"of",a,"is invalid, must be a hex address with colon-separated numbers")
break
end
end
end
else
print"-d argument (Enable DMC DPCM channel) needs to have definitions!"
end
elseif x:sub(1,2)=="-0"then
local i=0
for a in x:sub(3):gmatch"[^,]+"do
if i<4 then
i=i+1
if type(tonumber(a))=="number"then
local v=math.floor(tonumber(a))
if v>=0 and v<128 then dutyPatches[i]=v end
end
else
break
end
end
if i==0 then print"-0 argument (patch # for each duty cycle) needs to have up to 4 comma-separated values of numbers between 0 and 127!"end
elseif x:sub(1,2)=="-1"then
local param=tonumber(x:sub(3))
if type(param)=="number" and param>=0 and param<128 and param==math.floor(param)then trianglePatch=param else print"-1 argument (triangle patch #) needs to have a number between 0 and 127!"end
elseif x:sub(1,2)=="-2"then
if noiseEnable then
local param=tonumber(x:sub(3))
if type(param)=="number" and param>=0 and param<128 and param==math.floor(param)then noisePatch=param else print"-2 argument (noise patch #) needs to have a number between 0 and 127!"end
else
print"Noise channel is disabled so the -5 flag can't be used"
end
elseif x:sub(1,2)=="-3"then
if noiseEnable then
local param=tonumber(x:sub(3))
if type(param)=="number" and param>=0 and param<128 and param==math.floor(param)then noiseShortPatch=param else print"-3 argument (short noise patch #) needs to have a number between 0 and 127!"end
else
print"Noise channel is disabled so the -6 flag can't be used"
end
elseif x:sub(1,2)=="-9"then
if dmcPatches then
local param=tonumber(x:sub(3))
if type(param)=="number" and param>=0 and param<128 and param==math.floor(param)then drumPatch=param else print"-9 argument (drum patch #) needs to have a number between 0 and 127!"end
else
print"DMC channel is not enabled so the -9 flag can't be used"
end
elseif x:sub(1,2)=="-g"then
local i=0
for a in x:sub(3):gmatch"[^,]+"do
if i<4 then
i=i+1
if type(tonumber(a))=="number"then
local v=math.floor(tonumber(a))
if v>=0 and v<128 then dutyBankMSB[i]=v end
end
else
break
end
end
if i==0 then print"-g argument (Bank MSB for each duty cycle) needs to have up to 4 comma-separated values of numbers between 0 and 127!"end
elseif x:sub(1,2)=="-x"then
local i=0
for a in x:sub(3):gmatch"[^,]+"do
if i<4 then
i=i+1
if type(tonumber(a))=="number"then
local v=math.floor(tonumber(a))
if v>=0 and v<128 then dutyBankLSB[i]=v end
end
else
break
end
end
if i==0 then print"-x argument (Bank LSB for each duty cycle) needs to have up to 4 comma-separated values of numbers between 0 and 127!"end
elseif x:sub(1,2)=="-s"then
if x:sub(3,3)=="0"then
init=0
elseif x:sub(3,3)=="2"then
init=2
elseif x:sub(3,3)~="1"then
print"-s argument (channel initialization type) needs to have a value between 0 and 2!"
end
elseif x:sub(1,2)=="-b"or x=="--no-pitch-bend"then
bend=false
elseif x:sub(1,2)=="-t"or x=="--no-portamento-control"then
portamentoControl=false
end
end
end
out=midi.openout(portID)
if init>0 then for i=176,noiseEnable and 179 or 178 do for _,v in pairs(init<2 and{{126,0},{91,0},{72,0},{73,0},{75,127},{80,0}}or{{126,0},{91,0},{99,1},{98,99},{6,0},{98,100},{6,127},{98,102},{6,0},{101,127},{100,127}})do out:sendMessage(i,v[1],v[2])end end end
if volume>0 then for i=176,noiseEnable and 179 or 178 do out:sendMessage(i,7,volume)end else out:sendMessage(178,7,127)end
out:sendMessage(194,trianglePatch,0)
if dmcPatches then
for c=180,185,5 do
if init>0 then
out:sendMessage(c,126,0)
out:sendMessage(c,91,0)
end
out:sendMessage(c,7,volume>0 and volume or 127)
end
if drumPatch then out:sendMessage(201,drumPatch,0)end
memory.registerwrite(16405,function()if AND(memory.readbyte(16405),16)==16 and sound.get().rp2a03.dpcm.volume==1 and lastDMCOn then retriggerDMC=true end end)
end
for c=1,2 do memory.registerwrite(16383+c*4,function()if sound.get().rp2a03["square"..c].volume>0 and lastVolume[c]>0 and not retrigger[c]then retrigger[c]=true end end)end
gui.register(function()
if not emu.paused()then
paused=false
for c=1,2 do
local channel=sound.get().rp2a03["square"..c]
local note=math.min(channel.midikey,129)
local noteNumber=round(math.min(channel.midikey,127))
if channel.volume~=lastVolume[c]then
if channel.volume==0 then
out:noteOff(round(math.min(lastNote[c],127)),c-1)
lastNote[c]=0
else
out:sendMessage(175+c,volume>0 and 11 or 7,round(math.sqrt(channel.volume)*127))
end
end
if channel.volume>0 then
if channel.duty~=lastDuty[c]then
if bankMSB[c]~=dutyBankMSB[channel.duty+1]then
bankMSB[c]=dutyBankMSB[channel.duty+1]
out:sendMessage(175+c,0,bankMSB[c])
end
if bankLSB[c]~=dutyBankLSB[channel.duty+1]then
bankLSB[c]=dutyBankLSB[channel.duty+1]
out:sendMessage(175+c,32,bankLSB[c])
end
out:sendMessage(191+c,dutyPatches[channel.duty+1],0)
if lastVolume[c]>0 and not retrigger[c]then retrigger[c]=true end
lastDuty[c]=channel.duty
end
if retrigger[c]or note~=lastNote[c]then
local pitch=bend and math.min((channel.midikey-noteNumber+2)*4096,16383)or nil
local function pitchBend()if bend and pitch~=lastPitch[c]then out:sendMessage(223+c,AND(math.floor(pitch),127),math.floor(pitch/128))end end
if portamentoControl and channel.duty==lastDuty[c]and lastVolume[c]>0 and noteNumber~=round(math.min(lastNote[c],127))and not retrigger[c]then
out:sendMessage(175+c,84,round(math.min(lastNote[c],127)))
pitchBend()
out:noteOn(noteNumber,velocity,c-1)
out:noteOff(round(math.min(lastNote[c],127)),c-1)
else
if(retrigger[c]or noteNumber~=round(math.min(lastNote[c],127)))and lastVolume[c]>0 then out:noteOff(round(math.min(lastNote[c],127)),c-1)end
pitchBend()
if retrigger[c]or noteNumber~=round(math.min(lastNote[c],127))then out:noteOn(noteNumber,velocity,c-1)end
end
lastNote[c]=note
if bend then lastPitch[c]=pitch end
end
retrigger[c]=false
end
lastVolume[c]=channel.volume
end
local triangle=sound.get().rp2a03.triangle
local note=math.min(triangle.midikey,129)
local noteNumber,triangleOn=round(math.min(triangle.midikey,127)),triangle.volume==1
if triangleOn~=lastTriangleOn and not triangleOn then
out:noteOff(round(math.min(lastNoteTriangle,127)),2)
lastNoteTriangle=0
end
if note~=lastNoteTriangle and triangleOn then
local pitch=bend and math.min((triangle.midikey-noteNumber+2)*4096,16383)or nil
local function pitchBend()if bend and pitch~=lastPitchTriangle then out:sendMessage(226,AND(math.floor(pitch),127),math.floor(pitch/128))end end
if portamentoControl and lastTriangleOn and noteNumber~=round(math.min(lastNoteTriangle,127))then
out:sendMessage(178,84,round(math.min(lastNoteTriangle,127)))
pitchBend()
out:noteOn(noteNumber,velocity,2)
out:noteOff(round(math.min(lastNoteTriangle,127)),2)
else
if lastTriangleOn and noteNumber~=round(math.min(lastNoteTriangle,127))then out:noteOff(round(math.min(lastNoteTriangle,127)),2)end
pitchBend()
if noteNumber~=round(math.min(lastNoteTriangle,127))then out:noteOn(noteNumber,velocity,2)end
end
lastNoteTriangle=note
if bend then lastPitchTriangle=pitch end
end
lastTriangleOn=triangleOn
if noiseEnable then
local noise=sound.get().rp2a03.noise
local note=({127,117,105,93,81,74,69,65,61,57,50,45,38,33,21,9})[noise.regs.frequency+1]
if noise.volume~=lastVolumeNoise then
if noise.volume==0 then
out:noteOff(lastNoteNoise,3)
lastNoteNoise=0
else
out:sendMessage(179,volume>0 and 11 or 7,round(math.sqrt(noise.volume)*127))
end
end
if noise.short~=lastNoiseMode and noise.volume>0 then
if note==lastNoteNoise and lastVolumeNoise>0 then out:noteOff(note,3)end
out:sendMessage(195,noise.short and noiseShortPatch or noisePatch,0)
if note==lastNoteNoise and lastVolumeNoise>0 then out:noteOn(note,velocity,3)end
end
if note~=lastNoteNoise and noise.volume>0 then
if lastVolumeNoise==0 then
out:noteOn(note,velocity,3)
elseif portamentoControl and noise.short==lastNoiseMode then
out:sendMessage(178,84,round(math.min(lastNoteNoise,127)))
out:noteOn(note,velocity,3)
out:noteOff(lastNoteNoise,3)
else
out:noteOff(lastNoteNoise,3)
out:noteOn(note,velocity,3)
end
lastNoteNoise=note
end
lastVolumeNoise=noise.volume
if noise.short~=lastNoiseMode and noise.volume>0 then lastNoiseMode=noise.short end
end
if dmcPatches then
local dmc=sound.get().rp2a03.dpcm
local dmcOn,dmcAddress=dmc.volume==1,math.floor((dmc.dmcaddress-49152)/64)
local dmcPatch=dmcPatches[dmcAddress]
local note,drum=dmcPatch and({0,2,4,5,7,9,11,12,14,17,19,21,24,28,31,36})[dmc.regs.frequency+1]+dmcNoteShift[dmcAddress]or -1,dmcDrums[dmcAddress]
if dmcOn~=lastDMCOn and lastNoteDMC>=0 and not dmcOn then
out:noteOff(lastNoteDMC,4)
lastNoteDMC=-1
elseif note>=0 then
if dmcPatch~=lastDMCPatch and dmcOn then
if note==lastNoteDMC and lastDMCOn then out:noteOff(note,4)end
out:sendMessage(196,dmcPatch,0)
if note==lastNoteDMC and lastDMCOn then out:noteOn(note,velocity,4)end
lastDMCPatch=dmcPatch
end
if(note~=lastNoteDMC or retriggerDMC)and dmcOn then
if lastDMCOn then out:noteOff(lastNoteDMC,4)end
out:noteOn(note,velocity,4)
lastNoteDMC=note
end
end
if(dmcOn and not lastDMCOn)or drum~=lastDMCDrum or retriggerDMC then
if lastDMCOn and lastDMCDrum then out:noteOff(lastDMCDrum,9)end
if drum then out:noteOn(drum,velocity,9)end
end
lastDMCDrum=drum
lastDMCOn=dmcOn
retriggerDMC=false
end
elseif not paused then
paused=true
for c=1,2 do
if lastVolume[c]>0 then
out:noteOff(round(math.min(lastNote[c],127)),c-1)
lastNote[c]=0
end
end
if lastTriangleOn then
out:noteOff(round(math.min(lastNoteTriangle,127)),2)
lastNoteTriangle=0
end
if noiseEnable and lastVolumeNoise>0 then
out:noteOff(lastNoteNoise,3)
lastNoteNoise=0
end
if dmcPatches and lastDMCOn then
if lastNoteDMC>=0 then
out:noteOff(lastNoteDMC,4)
lastNoteDMC=-1
end
if lastDMCDrum then
out:noteOff(lastDMCDrum,9)
lastDMCDrum=nil
end
end
end
end)
emu.registerexit(midi.gc)