require "include/protoplug"
local cbFilter = require "include/dsp/cookbook filters"
local Line = require "include/dsp/delay line"

local kap = 0.625
local l = 100
local len = 20
local feedback = 0
local time = 1

stereoFx.init ()

function softclip(x) 
    if x <= -1.5 then
        return -1
    elseif x >= 1.5 then
        return 1
    else
        return x - (4/27)*x*x*x
    end
end

function stereoFx.Channel:init ()
	-- create per-channel fields (filters)
	self.ap = {}
	self.len = {}
	for i=1,100 do
	    self.ap[i] = Line(1000)
	    self.len[i] = math.random(900)+90
	end
	self.time = 0
	self.last = 0
	--self.ap1 = Line(2000)
end

function stereoFx.Channel:processBlock (samples, smax)
	for i = 0, smax do
	    self.time = self.time + 1/44100

	    local input = samples[i]
		
		
		local s = input - softclip(self.last)*feedback --+ 0.0001*(math.random()-0.5)
		
		for i = 1,l do
		    --local d = self.ap[i].goBack_int(self.len[i]*time + 2*math.sin(10*self.time)) 
		    local d = self.ap[i].goBack_int(self.len[i]*time) 
		    
		    --s = softclip(s*1.05)
		    local v = s - kap * d
		    
		    
		    
		   -- v = softclip(v)
	        s = kap*v + d
	        
	        --v = softclip(v)
	        self.ap[i].push(v)
		end
		
		local signal =  s - input*(kap^l)
		self.last = signal
		
		
		samples[i] = input*(1.0-balance) + signal*balance
		
		
	end
end

local function updateFilters(filters,args)
	for _, f in pairs(filters) do
		f.update(args)
	end
end

params = plugin.manageParams {
	{
		name = "Dry/Wet";
		min = 0;
		max = 1;
		changed = function(val) balance = val end;
	};
	{
		name = "iter";
	    min = 0;
		max = 100;
		type = "int";
		changed = function(val) l = val end;
	};
	{
		name = "kap";
	    min = 0;
		max = 4;
		changed = function(val) kap = 1-math.exp(-val) end;
	};
	{
		name = "feedback";
	    min = 0;
		max = 1;
		changed = function(val) feedback = val end;
	};
	{
		name = "time";
	    min = 0.01;
		max = 1;
		changed = function(val) time = val end;
	};
	{
		name = "seed";
	    min = 0;
		max = 100;
		type = "int";
		changed = function(val) 
		    math.randomseed(val);
		    for i=1,100 do
                stereoFx.LChannel.len[i] = math.random(900)+90;
                stereoFx.RChannel.len[i] = math.random(900)+90;
            end
		end;
	};
}
  