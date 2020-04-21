 require "include/protoplug"

local release = 0.12*44100
local releaseRate =  1 - 1/release

local decay = 1*44100
local decayRate =  1 - 1/decay

fifth = 6.956 --fifth in semitones
notes = {}

center = 0

polyGen.initTracks(16)

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
end

function processMidi(msg)
    if(msg:isPitchBend()) then
        local p = msg:getPitchBendValue ()
        p = (p - 8192)/8192
        p = p*2
        for i=1,polyGen.VTrack.numTracks do
            local vt = polyGen.VTrack.tracks[i]
            vt.f = getFreq(vt.pitch+p)
        end
    end
end

function polyGen.VTrack:addProcessBlock(samples, smax)
	for i = 0,smax do
	    self.attack = self.attack + 1/40
	    if self.attack >= 1.0 then
	        self.attack = 1.0
	    end
	    if self.decay then
            if self.env < 0.001 then break end
            self.env = self.env*releaseRate
        else
            self.env = self.env*decayRate
        end
		
		self.phase = self.phase + (self.f*math.pi*2)
		
		local m1 = math.sin(self.phase*2.00)*0.4*self.vel*self.env
		local m2 = math.sin(self.phase*7.00)*0.02*self.vel*self.env
		local fdb = self.fdbck*self.bright*2.5*self.env
		
		
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
    self.env = 1
    
    table.insert(notes,note)
    table.sort(notes)
  
    self.pitch = temper(self.note)
    self.f = getFreq(self.pitch)
  
    
	self.phase = 0
	self.vel = 0.3+0.7*(vel/127)^2
	self.bright = math.min(2.0,0.005/self.f)
	--print(0.005/self.f)
end

function temper(note)
	local index = (note)%12
	local oct = note - index
	
	local cround = math.floor(center + 0.5)
	
	local pos = (((index)*7 + 5 - cround)%12 - 5)
	
	center = center + (pos)*0.25
	
	
	--print(cround,pos,((pos + cround)*6.95)%12)
	print(cround,pos,index + (pos + cround)*(fifth - 7))
	
	return oct + index + (pos + cround)*(fifth - 7)
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
		min = 6.5;
		max = 7.2;
		default = 6.97;
		changed = function(val) fifth = val end;
	};
	{
		name = "Reset"; 
		min = 0;
		max = 1;
		default = 0;
		changed = function(val) center = 0 end;
	};
}
