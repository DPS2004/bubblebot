--bubble bot
--by dps2004



--config
_MODE = "mousecontrol" --mousecontrol

_MOUSE_CONTROL_OPTIONS = {
	snaptofloor = true

}

_ROMNAME = "Bubble Bobble (USA).nes"
_BLOCKINPUT = false



_up,_down,_left,_right,_a,_b,_start,_select = 'up','down','left','right','A','B','start','select'
inputkeys = {_up,_down,_left,_right,_a,_b,_start,_select}

colors = {
	green = {0,255,0,255},
	cleargreen = {0,255,0,50},
	
	white = {255,255,255,255},
	clearwhite = {255,255,255,50},
}

valuefuncs = {
	level = function() return memory.readbyteunsigned(0x0401) end,

	mousex = function() local minp = input.get() return minp.xmouse end,
	mousey = function() local minp = input.get() return minp.ymouse end,
	
	playerx = function() return memory.readbyteunsigned(0x0203) - 1 end,
	playery = function() return memory.readbyteunsigned(0x0200)+15 end,
	playerjump = function() return memory.readbyteunsigned(0x0167) end,
	
	enemyy = function() return memory.readbyteunsigned(0x0240)+15 end,
}
value = {}

function updatevalues()
	for k,v in pairs(valuefuncs) do
		value[k] = v()
	end
end

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

function newmap()
	print('making new map')
	local map = {tiles = {}}
	
	local mx = 0 -- 0-31
	local my = 0 -- 0-24
	for i=0x2060,0x237f do
		if not map.tiles[mx] then map.tiles[mx] = {} end
		
		local ppb = ppu.readbyte(i)
		local tile = {}
		
		tile.id = ppb
		tile.solid = (ppb ~= 0x26)
		map.tiles[mx][my] = tile
		mx = mx + 1
		if mx == 32 then
			mx = 0
			my = my + 1
		end
	end
	
	function map:tile(x,y)
		return self.tiles[x][y-3]
	end
	
	function map:pxtile(x,y)
		return self:tile(math.floor(x/8),math.floor(y/8))
	end
	
	function map:draw()
		for x=0,31 do
			for y=3,27 do
				local tile = self:tile(x,y)
				if tile.solid then
					gui.rect(x*8,(y)*8,x*8+8,(y+1)*8,colors.clearwhite)
					
				end
			end
		end
	end
	
	return map
end

function newplayer()
	local player = {
		x=0,
		y=0,
		grounded = true,
		jumping = true,
		falling = true,
		slowfall = true,
		target = {
			x=0,
			y=0
		},
		seektarget = false
	}
	
	if _MODE == 'mousecontrol' then
		player.seektarget = true
	end
	
	function player:update()
		self.x = value.playerx + 8
		self.y = value.playery
		
		if value.playerjump == 0 then -- going up
			self.grounded = false
			self.jumping = true
			self.falling = false
			self.slowfall = false
		elseif value.playerjump == 48 then --slow fall
			self.grounded = false
			self.jumping = false
			self.falling = true
			self.slowfall = true
		elseif value.playerjump == 50 then --on ground
			self.grounded = true
			self.jumping = false
			self.falling = false
			self.slowfall = false
		elseif value.playerjump == 211 then --freefall
			self.grounded = false
			self.jumping = false
			self.falling = true
			self.slowfall = false
		end
		
		if _MODE == 'mousecontrol' then
			self.target.x = value.mousex
			if _MOUSE_CONTROL_OPTIONS.snaptofloor then
				local xtile = math.floor(value.mousex/8)
				local ytile = math.floor(value.mousey/8)+0
				local loops = 0
				while true do
					local tile = map:tile(xtile,ytile)
					
					if tile and tile.solid then
						break
					end
					ytile = ytile + 1
					loops = loops + 1
					if ytile > 30 then
						ytile = 0
					end
					if loops > 60 then
						ytile = 12
						break
					end
				end
				self.target.y = ytile * 8
			else
				self.target.y = value.mousey
			end
		else
			self.target.x = self.x
			self.target.y = self.y
		end
		
		if self.seektarget then
			if self.target.x > self.x then
				inp:press(_right)
			end
			if self.target.x < self.x then
				inp:press(_left)
			end
			if self.target.y < self.y and self.grounded then
				inp:press(_a)
			end
		end
		
	end

	function player:draw()
		-- draw bub hitbox
		gui.rect(self.x-8,self.y - 16,self.x+8,self.y,colors.cleargreen)
		if player.seektarget then
			-- draw line to target
			gui.line(self.target.x,self.target.y,self.x, self.y,colors.green)
		end
	end
	
	return player

end

function init()
	emu.poweron()
	emu.loadrom(_ROMNAME)
	
	player = newplayer()
	level = 0
	map = newmap()
	
end

savestate.registerload(function() map = newmap() end) --reload map on savestate load

function main()
	
	frame = emu.framecount()
	
	inp = newinput(1)
	updatevalues()
	
	
	
	
	--get past title screen
	if frame == 5 then
		map = newmap()
	end
	if frame == 248 or frame == 255 then
		inp:press(_start)
	end
	if frame == 261 then
		map = newmap()
	end
	if frame > 255 then --in game
		if value.level ~= 0 and value.level ~= level then
			level = value.level
			map = newmap()
		end
	
		player:update()
	end
	inp:send()
end


function draw()
	
	player:draw()
	map:draw()
end


init()
while true do
	main()
	draw()
	emu.frameadvance()
	
end