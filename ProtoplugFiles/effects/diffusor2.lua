require "include/protoplug"
local cbFilter = require "include/dsp/cookbook filters"
local Line = require "include/dsp/delay line"

local kap = 0.625
local l = 100
local len = 20
local last = 0
local feedback = 0
local time = 1

stereoFx.init ()

function softclip(x) 
    if x <= -1 then
        return -2.0/3.0
    elseif x >= 1 then
        return 2.0/3.0
    else
        return x - (x*x*x)/3.0
    end
end

function stereoFx.Channel:init ()
	-- create per-channel fields (filters)
	self.ap = {}
	self.len = {}
	for i=1,100 do
	    self.ap[i] = Line(1000)
	    self.len[i] = math.random(700)+210
	end
	--self.ap1 = Line(2000)
end

function stereoFx.Channel:processBlock (samples, smax)
	for i = 0, smax do
	    

	    local input = samples[i]
	    
	    --local d = self.ap1.goBack_int(500) 
		--local v = input - kap * d
		--local signal = kap*v + d
		
		local s = input + last*feedback --+ 0.0001*(math.random()-0.5)
		
		local tab = self.ap
		local tablen = self.len
		for i = 1,l do
		    local d = tab[i].goBack_int(tablen[i]*time) 
		    local v = s - kap * d
		    
		    --v = softclip(v)
	        s = kap*v + d
	        
	        
	        self.ap[i].push(v)
		end
		
		last = s
		local signal = s
		
		
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
		max = 6;
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
}
 