 require "include/protoplug"


edo = 22

fifth = 12*math.floor(edo*math.log(3/2)/math.log(2) + 0.5)/edo

print(fifth)

third = 12*math.floor(edo*math.log(5/4)/math.log(2) + 0.5)/edo

print(third)

notes = {}

cx = 0
cy = 0

names = {'F','C','G','D','A','E','B'}


require "include/protoplug"

local blockEvents = {}

function plugin.processBlock(samples, smax, midiBuf)
	blockEvents = {}
	
	-- analyse midi buffer and prepare a chord for each note
	for ev in midiBuf:eachEvent() do
	    if ev:isNoteOn() then
			noteOn(ev)
		elseif ev:isNoteOff() then
		    noteOff(ev)
		else
		    table.insert(blockEvents, midi.Event(ev))
		end
	end
	-- fill midi buffer with prepared notes
	midiBuf:clear()
	if #blockEvents>0 then
		for _,e in ipairs(blockEvents) do
			midiBuf:addEvent(e)
		end
	end
end


function noteOn(root)
    local nt = root:getNote()
    
    
    local tempered = temper(nt)
    local tempnote = math.floor(edo*(tempered-69)/12 + 0.50001) + 69
   
    
    if(0 < tempnote and tempnote <= 128) then
        notes[nt] = tempnote

        local newEv = midi.Event.noteOn(
            1,
            tempnote,
            root:getVel())
        table.insert(blockEvents, newEv)
    end
end

function noteOff(root)
    local nt = root:getNote()
    local tempnote = notes[nt]
    
    if tempnote then

        local newEv = midi.Event.noteOff(
            1,
            tempnote)
        table.insert(blockEvents, newEv)
    end
end


function temper(note)
	local index = (note)%12
	local oct = note - index
	
	local x = index*7 - cx
	local y = x/4 - cy
	
	x = x % 4
	y = y % 3
	
	
	
	y = y-x*0.25
	
	
	if x > 2.0 then
	    x = x-4
	    y = y + 1
	end
	
	if y > 1.5 then
	    y = y-3
	end
	
	
	
	
	local crx = cx
	local cry = cy
	
	cx = cx + x*0.5
	cy = cy + y*0.5
	
	
	local px = math.floor(crx + x + 0.5)
	local py = math.floor(cry + y + 0.5)
	
	local sharp = math.floor((px+py*4+1)/7)
	local comma = py
	
	local sh = ''
	if sharp > 0 then
	    sh = string.rep("#",sharp)
	elseif(sharp < 0) then
	    sh = string.rep("b",-sharp)
	end
	
	local cm = ''
	if comma > 0 then
	    cm = string.rep("-",comma)
	elseif(comma < 0) then
	    cm = string.rep("+",-comma)
	end
	
	print(names[(px+py*4+1)%7+1] .. sh .. cm)
    --print(px,py)
	--print(math.floor((x)*100)/100,math.floor((y)*100)/100)
	--print(math.floor((cx)*100)/100,math.floor((cy)*100)/100)
	--print(note + px*(fifth - 7) + py*(third - 4))
	
	return note + px*(fifth - 7) + py*(third - 4) 
end

--[[

  require "include/protoplug"

local release = 0.12*44100
local releaseRate =  1 - 1/release

local decay = 0.6*44100
local decayRate =  1 - 1/decay

local sustain = 0.1

fifth = 6.956 --fifth in semitones
fifth = 3.86  --third in semitones
notes = {}


names = {'F','C','G','D','A','E','B'}

cx = 0
cy = 0

polyGen.initTracks(24)

pitchbend = 0

pedal = false

function polyGen.VTrack:init()
	-- create per-track fields here
	self.phase = 0
	self.f = 0
	self.pitch = 0
	self.fdbck = 0
	self.env = 0
	self.attack  = 0
	self.vel = 0
	self.bright = 0
	self.finished = false
end

function processMidi(msg)
    if(msg:isPitchBend()) then
        local p = msg:getPitchBendValue ()
        p = (p - 8192)/8192
        pitchbend = p*2
        for i=1,polyGen.VTrack.numTracks do
            local vt = polyGen.VTrack.tracks[i]
            vt.f = getFreq(vt.pitch+pitchbend)
        end
    elseif msg:isControl() then
        if msg:getControlNumber() == 64 then
            pedal = msg:getControlValue() ~= 0
        end
    end
end

function polyGen.VTrack:addProcessBlock(samples, smax)
	for i = 0,smax do
	    if self.env < 0.001 then self.env = 0; break end
	    
	    self.attack = self.attack + 1/40
	    
	    if self.attack >= 1.0 then
	        self.attack = 1.0
	    end
	    if self.decay and not pedal or self.finished then   
	        self.finished = true
            self.env = self.env*releaseRate
        else
            self.env = self.env*decayRate + sustain*(1-decayRate)
        end
        
        
        
		
		self.phase = self.phase + (self.f*math.pi*2) + (math.random()-0.5)*0.01
		
		local m1 = math.sin(self.phase*2.00)*0.4*self.vel*self.env
		local m2 = math.sin(self.phase*7.00)*0.02*self.vel*self.env
		local fdb = self.fdbck*self.bright*2.5
		
		
		local amp = self.env*self.attack*self.vel
		local trackSample = math.sin(self.phase+fdb+m1+m2)*amp*0.4
		self.fdbck = trackSample
		samples[0][i] = samples[0][i] + trackSample -- left
		samples[1][i] = samples[1][i] + trackSample -- right
	end
end

function polyGen.VTrack:noteOff(note, ev)
	local ind = nil
	for i,v in ipairs(notes) do
	    if v == note then
	        ind = i
	    end
	end
	if ind then
	    table.remove(notes,ind)
	end
	self.decay = true

	--temperNotes()
end

function polyGen.VTrack:noteOn(note, vel, ev)
    self.attack = 0
    self.decay = false
    self.finished = false
    self.env = 1
    
    table.insert(notes,note)
    table.sort(notes)
  
    self.pitch = temper(self.note)
    self.f = getFreq(self.pitch+pitchbend)
  
    
	self.phase = 0
	self.vel = 0.0+1.0*(vel/127)^1.5
	self.bright = math.min(2.0,0.005/self.f)
	
	--print(0.005/self.f)
end

function temper(note)
	local index = (note)%12
	local oct = note - index
	
	local x = index*7 - cx
	local y = x/4 - cy
	
	x = x % 4
	y = y % 3
	
	
	
	y = y-x*0.25
	
	
	if x > 2.0 then
	    x = x-4
	    y = y + 1
	end
	
	if y > 1.5 then
	    y = y-3
	end
	
	
	
	
	
	
	local crx = cx
	local cry = cy
	
	cx = cx + x*0.5
	cy = cy + y*0.5
	
	
	local px = math.floor(crx + x + 0.5)
	local py = math.floor(cry + y + 0.5)
	
	local sharp = math.floor((px+py*4+1)/7)
	local comma = py
	
	local sh = ''
	if sharp > 0 then
	    sh = string.rep("#",sharp)
	elseif(sharp < 0) then
	    sh = string.rep("b",-sharp)
	end
	
	local cm = ''
	if comma > 0 then
	    cm = string.rep("-",comma)
	elseif(comma < 0) then
	    cm = string.rep("+",-comma)
	end
	
	print(names[(px+py*4+1)%7+1] .. sh .. cm)
    --print(px,py)
	--print(math.floor((x)*100)/100,math.floor((y)*100)/100)
	--print(math.floor((cx)*100)/100,math.floor((cy)*100)/100)
	
	
	return note + px*(fifth - 7) + py*(third - 4)
end

function getFreq(note)
    local n = note - 69
	local f = 440 * 2^(n/12)
	return f/44100
end


params = plugin.manageParams {
	-- automatable VST/AU parameters
	-- note the new 1.3 way of declaring them
	{
		name = "Size of fifth";
		min = 6.66;
		max = 7.2;
		default = 7.02;
		changed = function(val) fifth = val end;
	};
	{
		name = "Size of third";
		min = 3.5;
		max = 4.5;
		default = 3.86;
		changed = function(val) third = val end;
	};
	{
		name = "Reset"; 
		min = 0;
		max = 1;
		default = 0;
		changed = function(val) cx = 0; cy = 0; end;
	};
}
]]