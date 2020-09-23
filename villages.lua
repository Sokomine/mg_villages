-- this contains the functions to actually generate the village structure in a table;
-- said table will hold information about which building will be placed where,
-- how the buildings are rotated, where the roads will be, which replacement materials
-- will be used etc.

local calls;

-- Intllib
local S = mg_villages.intllib

local function is_village_block(minp)
	local x, z = math.floor(minp.x/80), math.floor(minp.z/80)
	local vcc = mg_villages.VILLAGE_CHECK_COUNT
	return (x%vcc == 0) and (z%vcc == 0)
end

-- called by mapgen.lua and spawn_player.lua
mg_villages.villages_at_point = function(minp, noise1)
	if not is_village_block(minp) then return {} end
	local vcr, vcc = mg_villages.VILLAGE_CHECK_RADIUS, mg_villages.VILLAGE_CHECK_COUNT
	-- Check if there's another village nearby
	for xi = -vcr, vcr, vcc do
	for zi = -vcr, 0, vcc do
		if xi ~= 0 or zi ~= 0 then
			local mp = {x = minp.x + 80*xi, z = minp.z + 80*zi}
			local pi = PseudoRandom(mg_villages.get_bseed(mp))
			local s = pi:next(1, 400)
			local x = pi:next(mp.x, mp.x + 79)
			local z = pi:next(mp.z, mp.z + 79)
			if s <= mg_villages.VILLAGE_CHANCE and noise1:get_2d({x = x, y = z}) >= -0.3 then return {} end
		end
	end
	end
	local pr = PseudoRandom(mg_villages.get_bseed(minp))
	if pr:next(1, 400) > mg_villages.VILLAGE_CHANCE then return {} end -- No village here
	local x = pr:next(minp.x, minp.x + 79)
	local z = pr:next(minp.z, minp.z + 79)
	if noise1:get_2d({x = x, y = z}) < -0.3 then return {} end -- Deep in the ocean

	-- fallback: type "nore" (that is what the mod originally came with)
	local village_type = 'nore';
	village_type = mg_villages.village_types[ pr:next(1, #mg_villages.village_types )]; -- select a random type
	-- if this is the first village for this world, take a medieval one
	if( (not( mg_villages.all_villages ) or mg_villages.anz_villages < 1) and minetest.get_modpath("cottages") and mg_villages.FIRST_VILLAGE_TYPE) then
		village_type = mg_villages.FIRST_VILLAGE_TYPE;
	end

	if( not( mg_villages.village_type_data[ village_type ] )) then
		mg_villages.village_type_data[  village_type ] = { min = mg_villages.VILLAGE_MIN_SIZE, max = mg_villages.VILLAGE_MAX_SIZE };
	end
	local size = pr:next(mg_villages.village_type_data[ village_type ].min, mg_villages.village_type_data[ village_type ].max) 
--	local height = pr:next(5, 20)
	local height = pr:next(1, 5)
	-- villages of a size >= 40 are always placed at a height of 1
	if(     size >= 40 ) then
		height = 1;
	-- slightly smaller but still relatively large villages have a deterministic height now as well
	elseif( size >= 30 ) then
		height = 40-height;
	elseif( size >= 25 ) then
		height = 35-height;
	-- even smaller villages need to have a height depending on their sourroundings (at least they're pretty small!)
	end

--	print("A village of type \'"..tostring( village_type ).."\' of size "..tostring( size ).." spawned at: x = "..x..", z = "..z)
	--print("A village spawned at: x = "..x..", z = "..z)
	return {{vx = x, vz = z, vs = size, vh = height, village_type = village_type}}
end



--local function dist_center2(ax, bsizex, az, bsizez)
--	return math.max((ax+bsizex)*(ax+bsizex),ax*ax)+math.max((az+bsizez)*(az+bsizez),az*az)
--end

local function inside_village2(bx, sx, bz, sz, village, vnoise)
	return mg_villages.inside_village(bx, bz, village, vnoise) and mg_villages.inside_village(bx+sx, bz, village, vnoise) and mg_villages.inside_village(bx, bz+sz, village, vnoise) and mg_villages.inside_village(bx+sx, bz+sz, village, vnoise)
end

local function choose_building(l, pr, village_type)
	--::choose::
	local btype
	while true do
		local p = pr:next(1, 3000)
		
		if(  not( mg_villages.village_type_data[ village_type ] )
		  or not( mg_villages.village_type_data[ village_type ][ 'building_list'] )) then
			mg_villages.print( mg_villages.DEBUG_LEVEL_INFO, S("Unsupported village type").." : "..tostring( village_type )); --..' '..S("for house at") ' '..tostring(bx)..':'..tostring(bz)..'.');
			-- ...and crash in the next few lines (because there is no real solution for this problem)
		end

		for _, b in ipairs( mg_villages.village_type_data[ village_type ][ 'building_list'] ) do
			if (   mg_villages.BUILDINGS[ b ] and mg_villages.BUILDINGS[ b ].max_weight
			   and mg_villages.BUILDINGS[ b ].max_weight[ village_type ] and  mg_villages.BUILDINGS[ b ].max_weight[ village_type ] >= p) then

--		for b, i in ipairs(mg_villages.BUILDINGS) do
--			if i.weight[ village_type ] and i.weight[ village_type ] > 0 and i.max_weight and i.max_weight[ village_type ] and i.max_weight[ village_type ] >= p then
				btype = b
				break
			end
		end
		-- in case no building was found: take the last one that fits
		if( not( btype )) then
			for i=#mg_villages.BUILDINGS,1,-1 do
				if (  mg_villages.BUILDINGS[i] and mg_villages.BUILDINGS[i].weight
				  and mg_villages.BUILDINGS[i].weight[ village_type ] and mg_villages.BUILDINGS[i].weight[ village_type ] > 0 ) then
					btype = i;
					i = 1;
				end
			end
		end
		if( not( btype )) then
			return 1;
		end
		if( #l<1
			or not( mg_villages.BUILDINGS[btype].avoid )
			or mg_villages.BUILDINGS[btype].avoid==''
			or not( mg_villages.BUILDINGS[ l[#l].btype ].avoid )
			or mg_villages.BUILDINGS[btype].avoid ~= mg_villages.BUILDINGS[ l[#l].btype ].avoid) then

			if mg_villages.BUILDINGS[btype].pervillage ~= nil then
				local n = 0
				for j=1, #l do
					if( l[j].btype == btype or (mg_villages.BUILDINGS[btype].typ and mg_villages.BUILDINGS[btype].typ == mg_villages.BUILDINGS[ l[j].btype ].typ)) then
						n = n + 1
					end
				end
				--if n >= mg_villages.BUILDINGS[btype].pervillage then
				--	goto choose
				--end
				if n < mg_villages.BUILDINGS[btype].pervillage then
					return btype
				end
			else
				return btype
			end
		end
	end
	--return btype
end

local function choose_building_rot(l, pr, orient, village_type)
	local btype = choose_building(l, pr, village_type)
	local rotation
	if mg_villages.BUILDINGS[btype].no_rotate then
		rotation = 0
	else
		if mg_villages.BUILDINGS[btype].orients == nil then
			mg_villages.BUILDINGS[btype].orients = {0,1,2,3}
		end
		rotation = (orient+mg_villages.BUILDINGS[btype].orients[pr:next(1, #mg_villages.BUILDINGS[btype].orients)])%4
	end
	local bsizex = mg_villages.BUILDINGS[btype].sizex
	local bsizez = mg_villages.BUILDINGS[btype].sizez
	if rotation%2 == 1 then
		bsizex, bsizez = bsizez, bsizex
	end
	-- some buildings are mirrored
	local mirror = nil;
	-- some buildings may be too difficult for mirroring (=many nodebox-nodes that can't be mirrored well by rotation) or
	-- be too symmetric to be worth the trouble
	if( not(mg_villages.BUILDINGS[btype].nomirror) and pr:next( 1,2 )==1 ) then
		mirror = true;
	end
	return btype, rotation, bsizex, bsizez, mirror
end


-- choose_building_rot is not public, thus cannot be used by other mods;
-- also, that functions return values are impractical for other mods;
-- Returns: Array that is a new entry for array l (list of buildings in the village)
-- Parameters:
--   l             array consisting of previous return values of this function here
--   pos           pos.x, pos.y, pos.z will be part of the returned data structure
--   pr            instance of PseudoRandom(..)
--   orient        desired orientation
--   village_type  type of the desired village (i.e. medieval, taoki, ...)
mg_villages.choose_building_rotated = function(l, pos, pr, orient, village_type)
	local btype, rotation, bsizex, bsizez, mirror = choose_building_rot(l, pr, orient, village_type)
	-- road_nr and side have no relevance for other mods
	return	{x=pos.x, y=pos.y, z=pos.z, btype=btype, bsizex=bsizex, bsizez=bsizez, brotate = rotation, road_nr = 1, side=1, o=orient, mirror=mirror }
end


local function placeable(bx, bz, bsizex, bsizez, l, exclude_roads, orientation)
	for _, a in ipairs(l) do
		-- with < instead of <=, space_between_buildings can be zero (important for towns where houses are closely packed)
		if (a.btype ~= "road" or not exclude_roads) and math.abs(bx+bsizex/2-a.x-a.bsizex/2)<(bsizex+a.bsizex)/2 and math.abs(bz+bsizez/2-a.z-a.bsizez/2)<(bsizez+a.bsizez)/2 then
			-- dirt roads which go at a 90 degree angel to the current road are not a problem
			if( not( orientation ) or a.o%2 == orientation%2 ) then
				return false
			end
		end
	end
	return true
end

local function road_in_building(rx, rz, rdx, rdz, roadsize, l)
	if rdx == 0 then
		return not placeable(rx-roadsize+1, rz, 2*roadsize-2, 0, l, true)
	else
		return not placeable(rx, rz-roadsize+1, 0, 2*roadsize-2, l, true)
	end
end

local function when(a, b, c)
	if a then return b else return c end
end

mg_villages.road_nr = 0;

local function generate_road(village, l, pr, roadsize_list, road_materials, rx, rz, rdx, rdz, vnoise, space_between_buildings, iteration_depth, parent_road)
	local roadsize = math.floor(roadsize_list[ iteration_depth ]/2);
	if( not( roadsize ) or roadsize==0) then
		roadsize = mg_villages.FIRST_ROADSIZE;
	end
	local roadsize_a = roadsize;
	local roadsize_b = roadsize;
	if( roadsize_list[ iteration_depth ] % 2==1 ) then
		roadsize_a = roadsize+1;
	end	
	local vx, vz, vh, vs = village.vx, village.vz, village.vh, village.vs
	local village_type   = village.village_type;
	local calls_to_do = {}
	local rxx = rx
	local rzz = rz
	local mx, m2x, mz, m2z, mmx, mmz
	mx, m2x, mz, m2z = rx, rx, rz, rz
	local orient1, orient2
	if rdx == 0 then
		orient1 = 0
		orient2 = 2
	else
		orient1 = 3
		orient2 = 1
	end
	local btype;
	local rotation;
	local bsizex;
	local bsizez;
	local mirror;
	-- we have one more road
	mg_villages.road_nr = mg_villages.road_nr + 1;
	local first_building_a = false;
	local first_building_b = false;
	while mg_villages.inside_village(rx, rz, village, vnoise) and not road_in_building(rx, rz, rdx, rdz, roadsize_a, l) do
		if iteration_depth > 1 and pr:next(1, 4) == 1 and first_building_a then
			--generate_road(vx, vz, vs, vh, l, pr, roadsize-1, rx, rz, math.abs(rdz), math.abs(rdx))
			calls_to_do[#calls_to_do+1] = {rx=rx+(roadsize_a - 0)*rdx, rz=rz+(roadsize_a - 0)*rdz, rdx=math.abs(rdz), rdz=math.abs(rdx), parent_road = mg_villages.road_nr }
			m2x = rx + (roadsize_a - 0)*rdx
			m2z = rz + (roadsize_a - 0)*rdz
			rx = rx + (2*roadsize_a - 0)*rdx
			rz = rz + (2*roadsize_a - 0)*rdz
		end
		--else
			--::loop::
			local exitloop = false
			local bx
			local bz
			local tries = 0
			while true do
				if not mg_villages.inside_village(rx, rz, village, vnoise) or road_in_building(rx, rz, rdx, rdz, roadsize_a, l) then
					exitloop = true
					break
				end
				local village_type_sub = village_type;
				if( mg_villages.medieval_subtype and village_type_sub == 'medieval' and math.abs(village.vx-rx)>20 and math.abs(village.vz-rz)>20) then
					village_type_sub = 'fields';
				end
				btype, rotation, bsizex, bsizez, mirror = choose_building_rot(l, pr, orient1, village_type_sub)
				bx = rx + math.abs(rdz)*(roadsize_a+1) - when(rdx==-1, bsizex-1, 0)
				bz = rz + math.abs(rdx)*(roadsize_a+1) - when(rdz==-1, bsizez-1, 0)
				if placeable(bx, bz, bsizex, bsizez, l) and inside_village2(bx, bsizex, bz, bsizez, village, vnoise) then
					break
				end
				if tries > 5 then
					rx = rx + rdx
					rz = rz + rdz
					tries = 0
				else
					tries = tries + 1
				end
				--goto loop
			end
			if exitloop then break end
			rx = rx + (bsizex+space_between_buildings)*rdx
			rz = rz + (bsizez+space_between_buildings)*rdz
			mx = rx - 2*rdx
			mz = rz - 2*rdz
			l[#l+1] = {x=bx, y=vh, z=bz, btype=btype, bsizex=bsizex, bsizez=bsizez, brotate = rotation, road_nr = mg_villages.road_nr, side=1, o=orient1, mirror=mirror }
			first_building_a = true;
		--end
	end
	rx = rxx
	rz = rzz
	while mg_villages.inside_village(rx, rz, village, vnoise) and not road_in_building(rx, rz, rdx, rdz, roadsize_b, l) do
		if roadsize_b > 1 and pr:next(1, 4) == 1 and first_building_b then
			--generate_road(vx, vz, vs, vh, l, pr, roadsize-1, rx, rz, -math.abs(rdz), -math.abs(rdx))
			calls_to_do[#calls_to_do+1] = {rx=rx+(roadsize_b - 0)*rdx, rz=rz+(roadsize_b - 0)*rdz, rdx=-math.abs(rdz), rdz=-math.abs(rdx), parent_road = mg_villages.road_nr }
			m2x = rx + (roadsize_b - 0)*rdx
			m2z = rz + (roadsize_b - 0)*rdz
			rx = rx + (2*roadsize_b - 0)*rdx
			rz = rz + (2*roadsize_b - 0)*rdz
		end
		--else
			--::loop::
			local exitloop = false
			local bx
			local bz
			local tries = 0
			while true do
				if not mg_villages.inside_village(rx, rz, village, vnoise) or road_in_building(rx, rz, rdx, rdz, roadsize_b, l) then
					exitloop = true
					break
				end
				local village_type_sub = village_type;
				if( mg_villages.medieval_subtype and village_type_sub == 'medieval' and math.abs(village.vx-rx)>(village.vs/3) and math.abs(village.vz-rz)>(village.vs/3)) then
					village_type_sub = 'fields';
				end
				btype, rotation, bsizex, bsizez, mirror = choose_building_rot(l, pr, orient2, village_type_sub)
				bx = rx - math.abs(rdz)*(bsizex+roadsize_b) - when(rdx==-1, bsizex-1, 0)
				bz = rz - math.abs(rdx)*(bsizez+roadsize_b) - when(rdz==-1, bsizez-1, 0)
				if placeable(bx, bz, bsizex, bsizez, l) and inside_village2(bx, bsizex, bz, bsizez, village, vnoise) then
					break
				end
				if tries > 5 then
					rx = rx + rdx
					rz = rz + rdz
					tries = 0
				else
					tries = tries + 1
				end
				--goto loop
			end
			if exitloop then break end
			rx = rx + (bsizex+space_between_buildings)*rdx
			rz = rz + (bsizez+space_between_buildings)*rdz
			m2x = rx - 2*rdx
			m2z = rz - 2*rdz
			l[#l+1] = {x=bx, y=vh, z=bz, btype=btype, bsizex=bsizex, bsizez=bsizez, brotate = rotation, road_nr = mg_villages.road_nr, side=2, o=orient2, mirror=mirror}
			first_building_b = true;
		--end
	end
	if road_in_building(rx, rz, rdx, rdz, roadsize, l) then
		mmx = rx - 2*rdx
		mmz = rz - 2*rdz
	end
	mx = mmx or rdx*math.max(rdx*mx, rdx*m2x)
	mz = mmz or rdz*math.max(rdz*mz, rdz*m2z)
	local rxmin;
	local rxmax;
	local rzmin;
	local rzmax;
	if rdx == 0 then
		rxmin = rx - roadsize_a + 1
		rxmax = rx + roadsize_b - 1
		rzmin = math.min(rzz, mz)
		rzmax = math.max(rzz, mz)
		-- prolong the main road to the borders of the village
		if( mg_villages.road_nr == 1 ) then	
			while( mg_villages.inside_village_area(rxmin, rzmin, village, vnoise)) do
				rzmin = rzmin-1;
				rzmax = rzmax+1;
			end
			rzmin = rzmin-1;
			rzmax = rzmax+1;
			while( mg_villages.inside_village_area(rxmax, rzmax, village, vnoise)) do
				rzmax = rzmax+1;
			end
			rzmax = rzmax+1;
		end
	else
		rzmin = rz - roadsize_a + 1
		rzmax = rz + roadsize_b - 1
		rxmin = math.min(rxx, mx)
		rxmax = math.max(rxx, mx)
		-- prolong the main road to the borders of the village
		if( mg_villages.road_nr == 1 ) then	
			while( mg_villages.inside_village_area(rxmin, rzmin, village, vnoise)) do
				rxmin = rxmin-1;
				rxmax = rxmax+1;
			end
			rxmin = rxmin-1;
			rxmax = rxmax+1;
			while( mg_villages.inside_village_area(rxmax, rzmax, village, vnoise)) do
				rxmax = rxmax+1;
			end
			rxmax = rxmax+1;
		end
	end
	l[#l+1] = {x = rxmin+1, y = vh, z = rzmin, btype = "road",
		bsizex = rxmax - rxmin + 1, bsizez = rzmax - rzmin + 1, brotate = 0, road_nr = mg_villages.road_nr}
	if( road_materials and road_materials[ iteration_depth ] and minetest.registered_nodes[ road_materials[ iteration_depth ]] ) then
		l[#l].road_material = minetest.get_content_id( road_materials[ iteration_depth ] );
	end
	
	for _, i in ipairs(calls_to_do) do
--		local new_roadsize = roadsize -- - 1
		if pr:next(1, 100) <= mg_villages.BIG_ROAD_CHANCE then
			--new_roadsize = roadsize
			iteration_depth = iteration_depth + 1;
		end

		--generate_road(vx, vz, vs, vh, l, pr, new_roadsize, i.rx, i.rz, i.rdx, i.rdz, vnoise)
		calls[calls.index] = {village, l, pr, roadsize_list, road_materials, i.rx, i.rz, i.rdx, i.rdz, vnoise, space_between_buildings, iteration_depth-1, i.parent_road}
		calls.index = calls.index+1
	end
end

local function generate_bpos(village, pr, vnoise, space_between_buildings)
	local vx, vz, vh, vs = village.vx, village.vz, village.vh, village.vs
	local l = {}
	local rx = vx - vs
	--[=[local l={}
	local total_weight = 0
	for _, i in ipairs(mg_villages.BUILDINGS) do
		if i.weight == nil then i.weight = 1 end
		total_weight = total_weight+i.weight
		i.max_weight = total_weight
	end
	local multiplier = 3000/total_weight
	for _,i in ipairs(mg_villages.BUILDINGS) do
		i.max_weight = i.max_weight*multiplier
	end
	for i=1, 2000 do
		bx = pr:next(vx-vs, vx+vs)
		bz = pr:next(vz-vs, vz+vs)
		::choose::
		--[[btype = pr:next(1, #mg_villages.BUILDINGS)
		if mg_villages.BUILDINGS[btype].chance ~= nil then
			if pr:next(1, mg_villages.BUILDINGS[btype].chance) ~= 1 then
				goto choose
			end
		end]]
		p = pr:next(1, 3000)
		for b, i in ipairs(mg_villages.BUILDINGS) do
			if i.max_weight > p then
				btype = b
				break
			end
		end
		if mg_villages.BUILDINGS[btype].pervillage ~= nil then
			local n = 0
			for j=1, #l do
				if l[j].btype == btype then
					n = n + 1
				end
			end
			if n >= mg_villages.BUILDINGS[btype].pervillage then
				goto choose
			end
		end
		local rotation
		if mg_villages.BUILDINGS[btype].no_rotate then
			rotation = 0
		else
			rotation = pr:next(0, 3)
		end
		bsizex = mg_villages.BUILDINGS[btype].sizex
		bsizez = mg_villages.BUILDINGS[btype].sizez
		if rotation%2 == 1 then
			bsizex, bsizez = bsizez, bsizex
		end
		if dist_center2(bx-vx, bsizex, bz-vz, bsizez)>vs*vs then goto out end
		for _, a in ipairs(l) do
			if math.abs(bx-a.x)<=(bsizex+a.bsizex)/2+2 and math.abs(bz-a.z)<=(bsizez+a.bsizez)/2+2 then goto out end
		end
		l[#l+1] = {x=bx, y=vh, z=bz, btype=btype, bsizex=bsizex, bsizez=bsizez, brotate = rotation}
		::out::
	end
	return l]=]--
	local rz = vz
	while mg_villages.inside_village(rx, rz, village, vnoise) do
		rx = rx - 1
	end
	rx = rx + 5
	calls = {index = 1}
	-- the function below is recursive; we need a way to count roads
	mg_villages.road_nr = 0;
	local roadsize_list = {};
	for i=1,mg_villages.FIRST_ROADSIZE*2 do
		roadsize_list[i] = i;
	end
	if( mg_villages.village_type_data[ village.village_type ].roadsize_list ) then
		roadsize_list = mg_villages.village_type_data[ village.village_type ].roadsize_list;
	end
	-- last 0 in parameter list: no parent road yet (this is the first)
	generate_road(village, l, pr, roadsize_list, mg_villages.village_type_data[ village.village_type ].road_materials, rx, rz, 1, 0, vnoise, space_between_buildings, #roadsize_list, 0)
	local i = 1
	while i < calls.index do
		generate_road(unpack(calls[i]))
		i = i+1
	end
	mg_villages.road_nr = 0;
	return l
end


-- dirt roads seperate the wheat area around medieval villages into seperate fields and make it look better
local function generate_dirt_roads( village, vnoise, bpos, secondary_dirt_roads )
	local dirt_roads = {};
	if( not( secondary_dirt_roads)) then
		return dirt_roads;
	end
	for _, pos in ipairs( bpos ) do

		local x = pos.x;
		local z = pos.z; 
		local sizex = pos.bsizex;
		local sizez = 2;
		local orientation = 0;
		local vx;
		local vz;
		local vsx;
		local vsz;
		-- prolong the roads; start with a 3x2 piece of road for testing
		if( pos.btype == 'road' ) then
			-- the road streches in x direction
			if( pos.bsizex > pos.bsizez ) then
				sizex = 3; -- start with a road of length 3
				sizez = 2;
				vx    = -1; vz    = 0; vsx   = 1; vsz   = 0;
				x     = pos.x - sizex;
				z     = pos.z + math.floor((pos.bsizez-2)/2); -- aim for the middle of the road
				orientation = 0;
				-- if it is not possible to prolong the road at one end, then try the other
				if( not( placeable( x, z, sizex, sizez, bpos,       false, nil))) then
					x = pos.x + pos.bsizex;
					vx = 0;
					orientation = 2;
				end
			-- the road stretches in z direction
			else
				sizex = 2;
				sizez = 3;
				vx    = 0;  vz = -1; vsx   = 0; vsz   = 1;
				x     = pos.x + math.floor((pos.bsizex-2)/2); -- aim for the middle of the road
				z     = pos.z - sizez;
				orientation = 1;
				if( not( placeable( x, z, sizex, sizez, bpos,       false, nil))) then
					z = pos.z + pos.bsizez;
					vz = 0;
					orientation = 3;
				end
			end
				
		else
			if(     pos.o == 0 ) then
				x = pos.x-pos.side;
				z = pos.z-2; 
				sizex = pos.bsizex+1;
				sizez = 2;
				vx = 0; vz = 0;  vsx = 1; vsz = 0;

			elseif( pos.o == 2 ) then
				x = pos.x-pos.side+2;
				z = pos.z-2; 
				sizex = pos.bsizex+1;
				sizez = 2;
				vx = -1; vz = 0;  vsx = 1; vsz = 0;

			elseif( pos.o == 1 ) then
				x = pos.x-2;
				z = pos.z-pos.side+2; 
				sizex = 2;
				sizez = pos.bsizez+1;
				vx = 0;  vz = -1; vsx = 0; vsz = 1;

			else --if( pos.o == 3 ) then
				x = pos.x-2;
				z = pos.z-pos.side; 
				sizex = 2;
				sizez = pos.bsizez+1;
				vx = 0;  vz = 0;  vsx = 0; vsz = 1;
			end
			orientation = pos.o;

		end

		-- prolong the dirt road by 1
		while( placeable( x, z, sizex, sizez, bpos,       false, nil)
		   and placeable( x, z, sizex, sizez, dirt_roads, false, orientation)
 		   and mg_villages.inside_village_area(x, z, village, vnoise)
 		   and mg_villages.inside_village_area(x+sizex, z+sizez, village, vnoise)) do
			sizex = sizex + vsx;
			sizez = sizez + vsz;
			x     = x + vx;
			z     = z + vz;
		end

		-- the dirt road may exceed the village boundaries slightly, but it may not interfere with other buildings
		if(   not( placeable( x, z, sizex, sizez, bpos,       false, nil))
		   or not( placeable( x, z, sizex, sizez, dirt_roads, false, orientation))) then
			sizex = sizex - vsx;
			sizez = sizez - vsz;
			x     = x - vx;
			z     = z - vz;
		end

		if(    placeable( x, z, sizex, sizez, bpos,       false, nil)  
		   and placeable( x, z, sizex, sizez, dirt_roads, false, orientation)) then 
			dirt_roads[#dirt_roads+1] = {x=x, y=village.vh, z=z, btype="dirt_road", bsizex=sizex, bsizez=sizez, brotate = 0, o=orientation}
		end
	end
	return dirt_roads;
end




local MIN_DIST = 1

local function pos_far_buildings(x, z, l)
	for _, a in ipairs(l) do
		if a.x - MIN_DIST <= x and x <= a.x + a.bsizex + MIN_DIST and
		   a.z - MIN_DIST <= z and z <= a.z + a.bsizez + MIN_DIST then
			return false
		end
	end
	return true
end


local function generate_walls(bpos, data, a, minp, maxp, vh, vx, vz, vs, vnoise)
	for x = minp.x, maxp.x do
	for z = minp.z, maxp.z do
		local xx = (vnoise:get_2d({x=x, y=z})-2)*20+(40/(vs*vs))*((x-vx)*(x-vx)+(z-vz)*(z-vz))
		if xx>=40 and xx <= 44 then
			bpos[#bpos+1] = {x=x, z=z, y=vh, btype="wall", bsizex=1, bsizez=1, brotate=0}
		end
	end
	end
end


-- determine which building is to be placed where
-- also choose which blocks to replace with which other blocks (to make villages more intresting)
mg_villages.generate_village = function(village, vnoise)
	local vx, vz, vs, vh = village.vx, village.vz, village.vs, village.vh
	local village_type = village.village_type;
	local seed = mg_villages.get_bseed({x=vx, z=vz})
	local pr_village = PseudoRandom(seed)

	-- generate a name for the village
	village.name = namegen.generate_village_name_with_prefix( pr_village, village );

	-- only generate a new village if the data is not already stored
	-- (the algorithm is fast, but village types and houses which are available may change later on,
  	-- and that might easily cause chaos if the village is generated again with diffrent input)
	if( village.to_add_data and village.to_add_data.bpos and village.to_add_data.replacements and village.to_add_data.plantlist) then
		--print('VILLAGE GENREATION: USING ALREADY GENERATED VILLAGE: Nr. '..tostring( village.nr )); 
		return;
	end

	-- in the case of medieval villages, we later on want to add wheat fields with dirt roads; 1 wide dirt roads look odd
	local space_between_buildings = 1;
	if( mg_villages.village_type_data[ village_type ] and mg_villages.village_type_data[ village_type ].space_between_buildings) then
		space_between_buildings = mg_villages.village_type_data[ village_type ].space_between_buildings;
	end

	local bpos = {};
	local dirt_roads = {};
	local secondary_dirt_roads = nil; 
	if( village.to_add_data and village.to_add_data.bpos ) then
		-- If it is a single building instead of a full village, then village.to_add_data.bpos will
		-- already have been generated (but not the replacements and other data structures which still need to be generated here)
		bpos = village.to_add_data.bpos;
	else
		-- actually generate the village structure
		bpos = generate_bpos( village, pr_village, vnoise, space_between_buildings)

		-- if there is enough space, add dirt roads between the buildings (those will later be prolonged so that they reach the fields)
		-- only add dirt roads if there are at least 3 buildings in the village
		if( space_between_buildings >= 2 and village_type == 'medieval' and #bpos>3) then
			secondary_dirt_roads = "dirt_road";
		end

		dirt_roads = generate_dirt_roads( village, vnoise, bpos, secondary_dirt_roads );
	end

	-- set fruits for all buildings in the village that need it - regardless weather they will be spawned
	-- now or later; after the first call to this function here, the village data will be final
	for _, pos in ipairs( bpos ) do
		local binfo = mg_villages.BUILDINGS[pos.btype];
		if( binfo.farming_plus and binfo.farming_plus == 1 and mg_villages.fruit_list and not pos.furit) then
 			pos.fruit = mg_villages.fruit_list[ pr_village:next( 1, #mg_villages.fruit_list )];
		end
	end

	-- a changing replacement list would also be pretty confusing
	local p = PseudoRandom(seed);
	-- if the village is new, replacement_list is nil and a new replacement list will be created
	local replacements = mg_villages.get_replacement_table( village.village_type, p, nil );
	
	local sapling_id = handle_schematics.get_content_id_replaced( 'default:sapling', replacements );
	-- 1/sapling_p = probability of a sapling beeing placed
	local sapling_p  = 25;
	if( mg_villages.sapling_probability[ sapling_id ] ) then
		sapling_p = mg_villages.sapling_probability[ sapling_id ];
	end

	local c_plant = handle_schematics.get_content_id_replaced( mg_villages.village_type_data[ village.village_type ].plant_type, replacements);
	local plantlist = {
		{ id=sapling_id, p=sapling_p * mg_villages.village_type_data[ village.village_type ].sapling_divisor }, -- only few trees
		{ id=c_plant,    p=            mg_villages.village_type_data[ village.village_type ].plant_frequency }};

	if( village.is_single_house and plantlist and #plantlist>0 ) then
		local c_grass = handle_schematics.get_content_id_replaced( 'default:grass_5', replacements);
		plantlist[2] = { id=c_grass,    p=10        };
		-- reduce the amount of plants grown so that the area stands out less from the sourroundings
		plantlist[2].p = plantlist[2].p*3;
	end

	-- store the generated data in the village table 
	village.to_add_data               = {};
	village.to_add_data.bpos          = bpos;
	village.to_add_data.replacements  = replacements.list;
	village.to_add_data.dirt_roads    = dirt_roads;
	village.to_add_data.plantlist     = plantlist;

	--print('VILLAGE GENREATION: GENERATING NEW VILLAGE Nr. '..tostring( village.nr ));
end


-- not all buildings contain beds so that mobs could live inside; some are just workplaces;
-- roads get only placed if there are enough inhabitants
mg_villages.count_inhabitated_buildings = function(village)
	local bpos             = village.to_add_data.bpos;
	-- count the buildings
	local anz_buildings = 0;
	for i, pos in ipairs(bpos) do
		if( pos.btype and not(pos.btype == 'road' )) then 
			local binfo = mg_villages.BUILDINGS[pos.btype];
			-- count buildings which can house inhabitants as well as those requiring workers
			if( binfo and binfo.inh and binfo.inh ~= 0 ) then
				anz_buildings = anz_buildings + 1;
			end
		end
	end
	return anz_buildings;
end


-- creates individual buildings outside of villages;
-- the data structure is like that of a village, except that bpos (=buildings to be placed) is already set;
-- Note: one building per mapchunk is more than enough (else it would look too crowded);
mg_villages.house_in_one_mapchunk = function( minp, mapchunk_size, vnoise )

	local pr = PseudoRandom(mg_villages.get_bseed(minp))
	-- only each mg_villages.INVERSE_HOUSE_DENSITY th mapchunk gets a building
	if( pr:next(1,mg_villages.INVERSE_HOUSE_DENSITY) > 1 ) then
		return {};
	end


	-- pseudorandom orientation
	local orient1 = pr:next(0,3);
	-- determine which kind of building to use
	-- TODO: select only types fitting to that particular place
	-- TODO: select only types that exist
	-- the village type is "single" here - since not all houses which might fit into a village might do for lone standing houses
	-- (i.e. church, forge, wagon, ..)
	local btype, rotation, bsizex, bsizez, mirror = choose_building_rot({}, pr, orient1, 'single');
	if( not( bsizex )) then
		mg_villages.print( mg_villages.DEBUG_LEVEL_INFO, 'FAILURE to generate a building.');
		btype, rotation, bsizex, bsizez, mirror = choose_building_rot({}, pr, orient1, 'nore');
	end
	-- if no building was found, give up
	if( not( bsizex ) or not(mg_villages.BUILDINGS[ btype ].weight)) then
		return {};
	end


	local village = {};
	-- store that this is not a village but a lone house
	village.is_single_house = 1;
	-- village height will be set to a value fitting the terrain later on
	village.vh = 10;
	-- this will force re-calculation of height
	village.vs = 5;
	-- find out the real village type of this house (which is necessary for the replacements);
	-- the "single" type only indicates that this building may be used for one-house-villages such as this one
	for k, _ in pairs( mg_villages.BUILDINGS[ btype ].weight ) do
		if( k and k ~= 'single' ) then
			village.village_type = k;
		end
	end


	-- taken from paramats terrain blending code for single houses
	local FFAPROP = 0.5 -- front flat area proportion of dimension

	local xdim, zdim -- dimensions of house plus front flat area
	if rotation == 0 or rotation == 2 then
		xdim = bsizex
		zdim = bsizez + math.floor(FFAPROP * bsizez)
	else
		xdim = bsizex + math.floor(FFAPROP * bsizex)
		zdim = bsizez
	end
	local blenrad = math.floor((math.max(xdim, zdim) + 16) / 2)+2 -- radius of blend area
--[[
	if( blenrad >= math.ceil(mapchunk_size/2)-2 ) then
		blenrad = math.floor(mapchunk_size/2)-2;
	end
	local blencenx = pr:next(minp.x + blenrad, minp.x + mapchunk_size - blenrad - 1) -- blend area centre point
	local blencenz = pr:next(minp.z + blenrad, minp.z + mapchunk_size - blenrad - 1)
--]]
	local blencenx = pr:next(minp.x, minp.x + mapchunk_size - 1) -- blend area centre point
	local blencenz = pr:next(minp.z, minp.z + mapchunk_size - 1)

	local minx = blencenx - math.ceil(xdim / 2) -- minimum point of house plus front flat area
	local minz = blencenz - math.ceil(zdim / 2)
	local bx, bz -- house minimum point
	if rotation == 2 or rotation == 3 then -- N, E
		bx = minx
		bz = minz
	elseif rotation == 1 then -- W
		bx = minx + math.floor(FFAPROP * bsizex)
		bz = minz
	else -- rotation = 2, S
		bx = minx
		bz = minz + math.floor(FFAPROP * bsizez)
	end

	village.vx = blencenx;
	village.vz = blencenz;
	village.vs = blenrad;
	local village_id = tostring( village.vx )..':'..tostring( village.vz );

	-- these values have to be determined once per village; afterwards, they need to be fixed
	-- if a village has been generated already, it will continue to exist
--	if( mg_villages.all_villages[ village_id ] ) then
--		return village;
--	end

	if( mg_villages.all_villages  and mg_villages.all_villages[ village_id ] and mg_villages.all_villages[ village_id ].optimal_height) then
		village.optimal_height  = mg_villages.all_villages[ village_id ].optimal_height;
		village.vh              = mg_villages.all_villages[ village_id ].optimal_height;
		village.artificial_snow = mg_villages.all_villages[ village_id ].artificial_snow;
	end

	village.to_add_data = {};
	village.to_add_data.bpos = { {x=bx, y=village.vh, z=bz,  btype=btype, bsizex=bsizex, bsizez=bsizez, brotate = rotation, road_nr = 0, side=1, o=orient1, mirror=mirror }}
	return village;
end


mg_villages.house_in_mapchunk_mark_intersection = function( villages, c, vnoise ) -- c: candidate for a new one-house-village
	-- now check if this village can be placed here or if it intersects with another village in any critical manner;
	-- the village area may intersect (=unproblematic; may even look nice), but the actual building must not be inside another village

	-- exclude misconfigured villages
	if( not( c ) or not( c.to_add_data )) then
		--print('WRONG DATA: '..minetest.serialize( c ));
		c.areas_intersect = 1;
		return;
	end

	local bx     = c.to_add_data.bpos[1].x;
	local bz     = c.to_add_data.bpos[1].z;
	local bsizex = c.to_add_data.bpos[1].bsizex;
	local bsizez = c.to_add_data.bpos[1].bsizez;

	-- make sure that the house does not intersect with the area of a village
	for _,v in ipairs( villages ) do
		local id = v.vx..':'..v.vz;
		if( id and mg_villages.all_villages and mg_villages.all_villages[ id ] ) then
			v = mg_villages.all_villages[ id ];
		end

		if( v.vx ~= c.vx and v.vz ~= c.vz ) then
			local dist = math.sqrt(  ( c.vx - v.vx ) * ( c.vx - v.vx )
			                       + ( c.vz - v.vz ) * ( c.vz - v.vz ));
			if( dist < ( c.vs + v.vs )*1.1 ) then
				mg_villages.print( mg_villages.DEBUG_LEVEL_WARNING, 'DROPPING house at '..c.vx..':'..c.vz..' because it is too close to '..v.vx..':'..c.vx);
				c.areas_intersect = 1;
				-- the other village can't be spawned either as we don't know which one will be loaded first
				if( v.is_single_house ) then
					v.areas_intersect = 1;
				end
			end
	
			if( not( v.is_single_house ) and
			   ( mg_villages.inside_village_terrain_blend_area( c.vx,       c.vz,        v, vnoise)
			  or mg_villages.inside_village_terrain_blend_area( bx,         bz,          v, vnoise)
			  or mg_villages.inside_village_terrain_blend_area((bx+bsizex), bz,          v, vnoise)
			  or mg_villages.inside_village_terrain_blend_area((bx+bsizex), (bz+bsizez), v, vnoise)
			  or mg_villages.inside_village_terrain_blend_area( bx,         (bz+bsizez), v, vnoise))) then
	
				mg_villages.print( mg_villages.DEBUG_LEVEL_WARNING, 'DROPPING house at '..c.vx..':'..c.vz..' due to intersection with village at '..id);
				c.areas_intersect = 1;
				-- the other village can't be spawned either as we don't know which one will be loaded first
				if( v.is_single_house ) then
					v.areas_intersect = 1;
				end
			end
		end
	end
end


-- we need to determine where single houses will be placed in neighbouring mapchunks as well because
-- they may be so close to the border that they will affect this mapchunk
mg_villages.houses_in_mapchunk = function( minp, mapchunk_size, villages )
	local village_noise = minetest.get_perlin(7635, 3, 0.5, 16);

	local village_candidates = {};
	local vcr = 2; --mg_villages.VILLAGE_CHECK_RADIUS
        for xi = -vcr, vcr do
        for zi = -vcr, vcr do
			local new_village = mg_villages.house_in_one_mapchunk(
					{x=minp.x+(xi*mapchunk_size), y=minp.y, z=minp.z+(zi*mapchunk_size)},
					mapchunk_size,
					village_noise );
			if( new_village and new_village.vs and new_village.vx and new_village.vz ) then
				table.insert( village_candidates, new_village );
			end
		end
	end

	for _,candidate in ipairs(village_candidates) do
		-- mark all one-house-village-candidates that intersect with villages in this mapchunk
		mg_villages.house_in_mapchunk_mark_intersection( villages,           candidate, village_noise );
		-- mark all one-house-village-candidates that intersect with other candidates in this mapchunk
		mg_villages.house_in_mapchunk_mark_intersection( village_candidates, candidate, village_noise );
	end

	-- now add those villages that do not intersect with others and which *may* at least be part of this mapchunk
	local d = math.ceil( mapchunk_size / 2 );
	for _,candidate in ipairs(village_candidates) do
		if( not( candidate.areas_intersect )
		    and (candidate.vx > minp.x - d or candidate.vx < (minp.x+mapchunk_size+d) )
		    and (candidate.vz > minp.z - d or candidate.vz < (minp.z+mapchunk_size+d) )) then
			table.insert( villages, candidate );

			-- there may be quite a lot of single houses added; plus they are less intresting than entire villages. Thus, logfile spam is reduced
			mg_villages.print( mg_villages.DEBUG_LEVEL_WARNING, S("adding SINGLE HOUSE of type")..' '..tostring( candidate.village_type )..
				' '..S("to map at")..' '..tostring( candidate.vx )..':'..tostring( candidate.vz )..'.');
		end
	end
	return villages;
end


