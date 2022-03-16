--bubble bot
--by dps2004



--config
_ROMNAME = "Bubble Bobble (USA).nes"
_BLOCKINPUT = false



_up,_down,_left,_right,_a,_b,_start,_select = 'up','down','left','right','A','B','start','select'
inputkeys = {_up,_down,_left,_right,_a,_b,_start,_select}

colors = {
	green = {0,255,0,255},
	cleargreen = {0,255,0,50},
}

valuefuncs = {
	playerx = function() return memory.readbyteunsigned(0x0203) - 1 end,
	playery = function() return memory.readbyteunsigned(0x0200)+15 end,
	enemyy = function() return memory.readbyteunsigned(0x0240)+15 end
}
value = {}
function newinput(pl)
	pl = pl or 1
	local inp = {keys={},holdkeys = {},player = pl}
	for i,v in ipairs(inputkeys) do
		inp.keys[v] = false
		inp.holdkeys[v] = 0
	end
	
	function inp:hold(k,t)
		self.holdkeys[v] = t
	end
	
	
	function inp:press(k)
		self.holdkeys[k] = 1
	end
	
	function inp:release(k)
		self.holdkeys[k] = 0
	end
	
	function inp:send()
		local tosend = {}
		for i,v in ipairs(inputkeys) do
			if (self.holdkeys[v] ~= 0) then
				tosend[v] = true
			else
				if _BLOCKINPUT then
					tosend[v] = false
				else
					tosend[v] = nil
				end
			end
			
			if tosend[v] then
				self.holdkeys[v] = self.holdkeys[v] - 1
			end
		end
		joypad.set(self.player,tosend)
	end
	
	return inp
end

function init()
	emu.poweron()
	emu.loadrom(_ROMNAME)
end

function main()
	
	for k,v in pairs(valuefuncs) do
		value[k] = v()
	end
	
	inp = newinput(1)
	frame = emu.framecount()
	
	--get past title screen
	if frame == 248 or frame == 255 then
		inp:press(_start)
	end
	
	
	
	inp:send()
end


function draw()
	--gui.line(value.playerx,value.enemyy,value.playerx + 16, value.enemyy,'red')
	--gui.line(value.playerx,value.playery,value.playerx + 16, value.playery,'green')
	gui.rect(value.playerx,value.playery - 16,value.playerx+16,value.playery,colors.cleargreen)
end


init()
while true do
	main()
	draw()
	emu.frameadvance()
end