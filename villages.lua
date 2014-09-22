mg_villages.VILLAGE_CHECK_RADIUS = 2
mg_villages.VILLAGE_CHECK_COUNT = 1
--mg_villages.VILLAGE_CHANCE = 28
--mg_villages.VILLAGE_MIN_SIZE = 20
--mg_villages.VILLAGE_MAX_SIZE = 40
mg_villages.VILLAGE_CHANCE = 28
mg_villages.VILLAGE_MIN_SIZE = 25
mg_villages.VILLAGE_MAX_SIZE = 90 --55
mg_villages.FIRST_ROADSIZE = 3
mg_villages.BIG_ROAD_CHANCE = 0

-- Enable that for really big villages (there are also really slow to generate)
--[[mg_villages.VILLAGE_CHECK_RADIUS = 3
mg_villages.VILLAGE_CHECK_COUNT = 3
mg_villages.VILLAGE_CHANCE = 28
mg_villages.VILLAGE_MIN_SIZE = 100
mg_villages.VILLAGE_MAX_SIZE = 150
mg_villages.FIRST_ROADSIZE = 5
mg_villages.BIG_ROAD_CHANCE = 50]]


-- if set to false, villages will not be integrated into the terrain - which looks very bad
mg_villages.ENABLE_TERRAIN_BLEND = true;
-- if set to false, holes digged by cavegen and mudflow inside the village will not be repaired; houses will be destroyed
mg_villages.UNDO_CAVEGEN_AND_MUDFLOW = true;

-- on average, every n.th node may be one of these trees - and it will be a relatively dense packed forrest
mg_villages.sapling_probability = {};

mg_villages.sapling_probability[ minetest.get_content_id( 'default:sapling' )       ] = 25; -- suitable for a relatively dense forrest of normal trees
mg_villages.sapling_probability[ minetest.get_content_id( 'default:junglesapling' ) ] = 40; -- jungletrees are a bit bigger and need more space
if( minetest.get_modpath( 'mg' )) then
	mg_villages.sapling_probability[ minetest.get_content_id( 'mg:savannasapling'     ) ] = 30; 
	mg_villages.sapling_probability[ minetest.get_content_id( 'mg:pinesapling'        ) ] = 35; 
end
if( minetest.get_modpath( 'moretrees' )) then
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:birch_sapling_ongen'       ) ] = 200;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:spruce_sapling_ongen'      ) ] = 200;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:fir_sapling_ongen'         ) ] =  90;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:jungletree_sapling_ongen'  ) ] = 200;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:beech_sapling_ongen'       ) ] =  30;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:apple_sapling_ongen'       ) ] = 380;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:oak_sapling_ongen'         ) ] = 380; -- ca 20x20; height: 10
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:sequoia_sapling_ongen'     ) ] =  90; -- ca 10x10
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:palm_sapling_ongen'        ) ] =  90;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:pine_sapling_ongen'        ) ] = 200;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:willow_sapling_ongen'      ) ] = 380;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:rubber_tree_sapling_ongen' ) ] = 380;
end



local function is_village_block(minp)
	local x, z = math.floor(minp.x/80), math.floor(minp.z/80)
	local vcc = mg_villages.VILLAGE_CHECK_COUNT
	return (x%vcc == 0) and (z%vcc == 0)
end

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
			if s <= mg_villages.VILLAGE_CHANCE and noise1:get2d({x = x, y = z}) >= -0.3 then return {} end
		end
	end
	end
	local pr = PseudoRandom(mg_villages.get_bseed(minp))
	if pr:next(1, 400) > mg_villages.VILLAGE_CHANCE then return {} end -- No village here
	local x = pr:next(minp.x, minp.x + 79)
	local z = pr:next(minp.z, minp.z + 79)
	if noise1:get2d({x = x, y = z}) < -0.3 then return {} end -- Deep in the ocean

	-- fallback: type "nore" (that is what the mod originally came with)
	local village_type = 'nore';
	-- if this is the first village for this world, take a medieval one
	if( (not( mg_villages.all_villages ) or mg_villages.anz_villages < 1) and minetest.get_modpath("cottages") ) then
		village_type = 'medieval';
	else
		village_type = mg_villages.village_types[ pr:next(1, #mg_villages.village_types )]; -- select a random type
	end

	if( not( mg_villages.village_sizes[ village_type ] )) then
		mg_villages.village_sizes[  village_type ] = { min = mg_villages.VILLAGE_MIN_SIZE, max = mg_villages.VILLAGE_MAX_SIZE };
	end
	local size = pr:next(mg_villages.village_sizes[ village_type ].min, mg_villages.village_sizes[ village_type ].max) 
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
		for b, i in ipairs(mg_villages.BUILDINGS) do
			if i.weight[ village_type ] and i.weight[ village_type ] > 0 and i.max_weight and i.max_weight[ village_type ] and i.max_weight[ village_type ] >= p then
				btype = b
				break
			end
		end
		-- in case no building was found: take the last one that fits
		if( not( btype )) then
			for i=#mg_villages.BUILDINGS,1,-1 do
				if( mg_villages.BUILDINGS[i].weight and mg_villages.BUILDINGS[i].weight[ village_type ] and mg_villages.BUILDINGS[i].weight[ village_type ] > 0 ) then
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
	return btype, rotation, bsizex, bsizez
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

local function generate_road(village, l, pr, roadsize, rx, rz, rdx, rdz, vnoise, space_between_buildings)
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
	-- we have one more road
	mg_villages.road_nr = mg_villages.road_nr + 1;
	while mg_villages.inside_village(rx, rz, village, vnoise) and not road_in_building(rx, rz, rdx, rdz, roadsize, l) do
		if roadsize > 1 and pr:next(1, 4) == 1 then
			--generate_road(vx, vz, vs, vh, l, pr, roadsize-1, rx, rz, math.abs(rdz), math.abs(rdx))
			calls_to_do[#calls_to_do+1] = {rx=rx+(roadsize - 1)*rdx, rz=rz+(roadsize - 1)*rdz, rdx=math.abs(rdz), rdz=math.abs(rdx)}
			m2x = rx + (roadsize - 1)*rdx
			m2z = rz + (roadsize - 1)*rdz
			rx = rx + (2*roadsize - 1)*rdx
			rz = rz + (2*roadsize - 1)*rdz
		end
		--else
			--::loop::
			local exitloop = false
			local bx
			local bz
			local tries = 0
			while true do
				if not mg_villages.inside_village(rx, rz, village, vnoise) or road_in_building(rx, rz, rdx, rdz, roadsize, l) then
					exitloop = true
					break
				end
				local village_type_sub = village_type;
				if( mg_villages.medieval_subtype and village_type_sub == 'medieval' and math.abs(village.vx-rx)>20 and math.abs(village.vz-rz)>20) then
					village_type_sub = 'fields';
				end
				btype, rotation, bsizex, bsizez = choose_building_rot(l, pr, orient1, village_type_sub)
				bx = rx + math.abs(rdz)*(roadsize+1) - when(rdx==-1, bsizex-1, 0)
				bz = rz + math.abs(rdx)*(roadsize+1) - when(rdz==-1, bsizez-1, 0)
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
			l[#l+1] = {x=bx, y=vh, z=bz, btype=btype, bsizex=bsizex, bsizez=bsizez, brotate = rotation, road_nr = mg_villages.road_nr, side=1, o=orient1 }
		--end
	end
	rx = rxx
	rz = rzz
	while mg_villages.inside_village(rx, rz, village, vnoise) and not road_in_building(rx, rz, rdx, rdz, roadsize, l) do
		if roadsize > 1 and pr:next(1, 4) == 1 then
			--generate_road(vx, vz, vs, vh, l, pr, roadsize-1, rx, rz, -math.abs(rdz), -math.abs(rdx))
			calls_to_do[#calls_to_do+1] = {rx=rx+(roadsize - 1)*rdx, rz=rz+(roadsize - 1)*rdz, rdx=-math.abs(rdz), rdz=-math.abs(rdx)}
			m2x = rx + (roadsize - 1)*rdx
			m2z = rz + (roadsize - 1)*rdz
			rx = rx + (2*roadsize - 1)*rdx
			rz = rz + (2*roadsize - 1)*rdz
		end
		--else
			--::loop::
			local exitloop = false
			local bx
			local bz
			local tries = 0
			while true do
				if not mg_villages.inside_village(rx, rz, village, vnoise) or road_in_building(rx, rz, rdx, rdz, roadsize, l) then
					exitloop = true
					break
				end
				local village_type_sub = village_type;
				if( mg_villages.medieval_subtype and village_type_sub == 'medieval' and math.abs(village.vx-rx)>(village.vs/3) and math.abs(village.vz-rz)>(village.vs/3)) then
					village_type_sub = 'fields';
				end
				btype, rotation, bsizex, bsizez = choose_building_rot(l, pr, orient2, village_type_sub)
				bx = rx - math.abs(rdz)*(bsizex+roadsize) - when(rdx==-1, bsizex-1, 0)
				bz = rz - math.abs(rdx)*(bsizez+roadsize) - when(rdz==-1, bsizez-1, 0)
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
			l[#l+1] = {x=bx, y=vh, z=bz, btype=btype, bsizex=bsizex, bsizez=bsizez, brotate = rotation, road_nr = mg_villages.road_nr, side=2, o=orient2}
		--end
	end
	if road_in_building(rx, rz, rdx, rdz, roadsize, l) then
		mmx = rx - 2*rdx
		mmz = rz - 2*rdz
	end
	mx = mmx or rdx*math.max(rdx*mx, rdx*m2x)
	mz = mmz or rdz*math.max(rdz*mz, rdz*m2z)
	if rdx == 0 then
		rxmin = rx - roadsize + 1
		rxmax = rx + roadsize - 1
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
		rzmin = rz - roadsize + 1
		rzmax = rz + roadsize - 1
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
	l[#l+1] = {x = rxmin, y = vh, z = rzmin, btype = "road",
		bsizex = rxmax - rxmin + 1, bsizez = rzmax - rzmin + 1, brotate = 0, road_nr = mg_villages.road_nr}
	
	for _, i in ipairs(calls_to_do) do
		local new_roadsize = roadsize - 1
		if pr:next(1, 100) <= mg_villages.BIG_ROAD_CHANCE then
			new_roadsize = roadsize
		end

		--generate_road(vx, vz, vs, vh, l, pr, new_roadsize, i.rx, i.rz, i.rdx, i.rdz, vnoise)
		calls[calls.index] = {village, l, pr, new_roadsize, i.rx, i.rz, i.rdx, i.rdz, vnoise, space_between_buildings}
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
	generate_road(village, l, pr, mg_villages.FIRST_ROADSIZE, rx, rz, 1, 0, vnoise, space_between_buildings)
	i = 1
	while i < calls.index do
		generate_road(unpack(calls[i]))
		i = i+1
	end
	mg_villages.road_nr = 0;
	return l
end


-- dirt roads seperate the wheat area around medieval villages into seperate fields and make it look better
mg_villages.generate_dirt_roads = function( village, vnoise, bpos, secondary_dirt_roads )
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

			elseif( pos.o == 3 ) then
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



-- they don't all grow cotton; farming_plus fruits are far more intresting!
-- Note: This function modifies replacements.ids and replacements.table for each building
--       as far as fruits are concerned. It needs to be called before placing a building
--       which contains fruits.
-- The function might as well be a local one.
mg_villages.get_fruit_replacements = function( replacements, fruit)

	if( not( fruit )) then
		return;
	end

	for i=1,8 do
		local old_name = '';
		local new_name = '';
		-- farming_plus plants sometimes come in 3 or 4 variants, but not in 8 as cotton does
		if(     minetest.registered_nodes[ 'farming_plus:'..fruit..'_'..i ]) then
			old_name = "farming:cotton_"..i;
			new_name = 'farming_plus:'..fruit..'_'..i;
	
		-- "surplus" cotton variants will be replaced with the full grown fruit
		elseif( minetest.registered_nodes[ 'farming_plus:'..fruit ]) then
			old_name = "farming:cotton_"..i;
			new_name = 'farming_plus:'..fruit;

		-- and plants from farming: are supported as well
		elseif( minetest.registered_nodes[ 'farming:'..fruit..'_'..i ]) then
			old_name = "farming:cotton_"..i;
			new_name = 'farming:'..fruit..'_'..i;

		elseif( minetest.registered_nodes[ 'farming:'..fruit ]) then
			old_name = "farming:cotton_"..i;
			new_name = 'farming:'..fruit;
		end

		if( old_name ~= '' and new_name ~= '' ) then
			-- this is mostly used by the voxelmanip based spawning of .we files
			replacements.ids[ minetest.get_content_id( old_name )] = minetest.get_content_id( new_name );
			-- this is used by the place_schematic based spawning	
			for i,v in ipairs( replacements.table ) do
				if( v and #v and v[1]==old_name ) then
					v[2] = new_name;
				end
			end
		end
	end
end



-- either uses get_node_or_nil(..) or the data from voxelmanip
-- the function might as well be local (only used by *.mg_drop_moresnow)
mg_villages.get_node_somehow = function( x, y, z, a, data, param2_data )
	if( a and data and param2_data ) then
		return { content = data[a:index(x, y, z)], param2 = param2_data[a:index(x, y, z)] };
	end
	-- no voxelmanip; get the node the normal way
	local node = minetest.get_node_or_nil( {x=x, y=y, z=z} );
	if( not( node ) ) then
		return { content = moresnow.c_ignore, param2 = 0 };
	end
	return { content = minetest.get_content_id( node.name ), param2 = node.param2, name = node.name };
end


-- "drop" moresnow snow on diffrent shapes; works for voxelmanip and node-based setting
mg_villages.mg_drop_moresnow = function( x, z, y_top, y_bottom, a, data, param2_data)

	-- this only works if moresnow is installed
	if( not( moresnow ) or not( moresnow.suggest_snow_type )) then
		return;
	end

	local y = y_top;
	local node_above = mg_villages.get_node_somehow( x, y+1, z, a, data, param2_data );	
	local node_below = nil;
	while( y >= y_bottom ) do

		node_below = mg_villages.get_node_somehow( x, y, z, a, data, param2_data );
		if(     node_above.content == moresnow.c_air
		    and node_below.content
		    and node_below.content ~= moresnow.c_ignore
		    and node_below.content ~= moresnow.c_air ) then

			-- if the node below drops snow when digged (i.e. is either snow or a moresnow node), we're finished
			local get_drop = minetest.get_name_from_content_id( node_below.content );
			if( get_drop ) then
				get_drop = minetest.registered_nodes[ get_drop ];
				if( get_drop and get_drop.drop and type( get_drop.drop )=='string' and get_drop.drop == 'default:snow') then
					return;
				end
			end
			if( not(node_below.content)
			    or  node_below.content == mg_villages.road_node
			    or  node_below.content == moresnow.c_snow ) then
				return;
			end

			local suggested = moresnow.suggest_snow_type( node_below.content, node_below.param2 );

			-- c_snow_top and c_snow_fence can only exist when the node 2 below is a solid one
			if(    suggested.new_id == moresnow.c_snow_top
			    or suggested.new_id == moresnow.c_snow_fence) then	
				local node_below2 = mg_villages.get_node_somehow( x, y-1, z, a, data, param2_data);
				if(     node_below2.content ~= moresnow.c_ignore
				    and node_below2.content ~= moresnow.c_air ) then
					local suggested2 = moresnow.suggest_snow_type( node_below2.content, node_below2.param2 );

					if( suggested2.new_id == moresnow.c_snow ) then
						return { height = y+1, suggested = suggested };
					end
				end
			-- it is possible that this is not the right shape; if so, the snow will continue to fall down
			elseif( suggested.new_id ~= moresnow.c_ignore ) then
					
				return { height = y+1, suggested = suggested };
			end
			-- TODO return; -- abort; there is no fitting moresnow shape for the node below
		end
		y = y-1;
		node_above = node_below;
	end
end



local function generate_building(pos, minp, maxp, data, param2_data, a, pr, extranodes, replacements)
tgb = minetest.get_us_time();
	local binfo = mg_villages.BUILDINGS[pos.btype]
	local scm

	-- schematics of .mts type are not handled here; they need to be placed using place_schematics
	if( binfo.is_mts == 1 ) then
		return;
	end

	if( binfo.scm_data_cache )then
		scm = binfo.scm_data_cache;
	else
		scm = binfo.scm
	end

	-- the fruit is set per building, not per village as the other replacements
	if( binfo.farming_plus and binfo.farming_plus == 1 and pos.fruit ) then
		mg_villages.get_fruit_replacements( replacements, pos.fruit);
	end

	local c_ignore = minetest.get_content_id("ignore")
	local c_air = minetest.get_content_id("air")
	local c_snow                 = minetest.get_content_id( "default:snow");
	local c_dirt                 = minetest.get_content_id( "default:dirt" );
	local c_dirt_with_grass      = minetest.get_content_id( "default:dirt_with_grass" );
	local c_dirt_with_snow       = minetest.get_content_id( "default:dirt_with_snow" );

	local scm_x = 0;
	local scm_z = 0;
	local step_x = 1;
	local step_z = 1;
	local scm_z_start = 0;

	if(     pos.brotate == 2 ) then
		scm_x  = pos.bsizex+1;
		step_x = -1;
	end
	if(     pos.brotate == 1 ) then
		scm_z  = pos.bsizez+1;
		step_z = -1;
		scm_z_start = scm_z;
	end
		
	for x = 0, pos.bsizex-1 do
	scm_x = scm_x + step_x;
	scm_z = scm_z_start;
	for z = 0, pos.bsizez-1 do
	scm_z = scm_z + step_z;
		local has_snow    = false;
		local ground_type = c_dirt_with_grass; 
		for y = 0, binfo.ysize-1 do
			ax, ay, az = pos.x+x, pos.y+y+binfo.yoff, pos.z+z
			if (ax >= minp.x and ax <= maxp.x) and (ay >= minp.y and ay <= maxp.y) and (az >= minp.z and az <= maxp.z) then
	
				local new_content = c_air;
				if( pos.brotate == 0 or pos.brotate == 2 ) then
					t = scm[y+1][scm_x][scm_z]
				else -- swap parameters
					t = scm[y+1][scm_z][scm_x]
				end
	
				if( binfo.yoff+y == 0 ) then
					local node_content = data[a:index(ax, ay, az)];
					-- no snow on the gravel roads
					if( node_content == c_dirt_with_snow or data[a:index(ax, ay+1, az)]==c_snow) then
						has_snow    = true;
					end

					ground_type = node_content;
				end
	
				if type(t) == "table" then
					new_content = t.node.content;
					-- replace unkown nodes by name
					if( new_content == c_ignore 
					    and t.node.name
					    and replacements.table[ t.node.name ]) then
						new_content = minetest.get_content_id(  replacements.table[ t.node.name ] );

					-- do replacements for normal nodes with facedir or wallmounted
					elseif( new_content ~= c_ignore and replacements.ids[ new_content ]) then
						new_content = replacements.ids[ new_content ];
					end

					-- replace all dirt and dirt with grass at that x,z coordinate with the stored ground grass node;
					if( new_content == c_dirt or new_content == c_dirt_with_grass ) then
						new_content = ground_type;
					end

					-- handle extranodes
					if( t.extranode and t.meta) then
						-- TODO: t.node.* may not contain relevant information here	
						table.insert(extranodes, {node = t.node, meta = t.meta, pos = {x = ax, y = ay, z = az}})
					end
					data[       a:index(ax, ay, az)] = new_content;
					if( t.rotation and t.node.param2 ) then
					-- TODO: this needs optimization as well
						local new_param2  = t.node.param2;
						if(     t.rotation == 'wallmounted' ) then
							for r=1, pos.brotate do
								new_param2 = mg_villages.rotate_wallmounted( new_param2 );
							end
						elseif( t.rotation == 'facedir' ) then
							for r=1, pos.brotate do
								new_param2 = mg_villages.rotate_facedir( new_param2 );
							end
						end
						param2_data[a:index(ax, ay, az)] = new_param2;
					end
				-- air and gravel
				elseif t ~= c_ignore then
	
					new_content = t;
					if( t and replacements.ids[ t ] ) then
						new_content = replacements.ids[ t ];
					end
					if( t and t==c_dirt or t==c_dirt_with_grass ) then
						new_content = ground_type;
					end
					data[a:index(ax, ay, az)] = new_content;
					-- param2 is not set here
				end
			end
		end

		local ax = pos.x + x;
		local az = pos.z + z;
		local y_top    = pos.y+binfo.yoff+binfo.ysize;
		if( y_top+1 > maxp.y ) then
			y_top = maxp.y-1;
		end
		local y_bottom = pos.y+binfo.yoff;
		if( y_bottom < minp.y ) then
			y_bottom = minp.y;
		end
		if( has_snow and ax >= minp.x and ax <= maxp.x and az >= minp.z and az <= maxp.z ) then
			local res = mg_villages.mg_drop_moresnow( ax, az, y_top, y_bottom, a, data, param2_data);
			if( res ) then
				data[       a:index(ax, res.height, az)] = res.suggested.new_id;
				param2_data[a:index(ax, res.height, az)] = res.suggested.param2;
				has_snow = false;
			end
		end
	end
	end
end


-- similar to generate_building, except that it uses minetest.place_schematic(..) instead of changing voxelmanip data;
-- this has advantages for nodes that use facedir;
-- the function is called AFTER the mapgen data has been written in init.lua
-- Function is called from init.lua.
mg_villages.place_schematics = function( bpos, replacements, voxelarea, pr )

	local mts_path = mg_villages.modpath.."/schems/";

	for _, pos in ipairs( bpos ) do

		local binfo = mg_villages.BUILDINGS[pos.btype];


		-- We need to check all 8 corners of the building.
		-- This will only work for buildings that are smaller than chunk size (relevant here: about 111 nodes)
		-- The function only spawns buildings which are at least partly contained in this chunk/voxelarea.
		if( voxelarea
		   and ( voxelarea:contains( pos.x,              pos.y - binfo.yoff,               pos.z )
		      or voxelarea:contains( pos.x + pos.bsizex, pos.y - binfo.yoff,               pos.z )
		      or voxelarea:contains( pos.x,              pos.y - binfo.yoff,               pos.z + pos.bsizez )
		      or voxelarea:contains( pos.x + pos.bsizex, pos.y - binfo.yoff,               pos.z + pos.bsizez )
		      or voxelarea:contains( pos.x,              pos.y - binfo.yoff + binfo.ysize, pos.z )
		      or voxelarea:contains( pos.x + pos.bsizex, pos.y - binfo.yoff + binfo.ysize, pos.z )
		      or voxelarea:contains( pos.x,              pos.y - binfo.yoff + binfo.ysize, pos.z + pos.bsizez )
		      or voxelarea:contains( pos.x + pos.bsizex, pos.y - binfo.yoff + binfo.ysize, pos.z + pos.bsizez ) )) then

			-- that function places schematics, adds snow where needed 
			-- and the grass type used directly in the pos/bpos data structure
			mg_villages.place_one_schematic( bpos, replacements, pos, mts_path );
		end
	end
	--print('VILLAGE DATA: '..minetest.serialize( bpos ));
end


-- also adds a snow layer for buildings spawned from .we files
-- function might as well be local
mg_villages.place_one_schematic = function( bpos, replacements, pos, mts_path )

	-- just for the record: count how many times this building has been placed already;
	-- multiple placements are commen at chunk boundaries (may be up to 8 placements)
	if( not( pos.count_placed )) then
		pos.count_placed = 1;
	else
		pos.count_placed = pos.count_placed + 1;
	end

	local binfo = mg_villages.BUILDINGS[pos.btype];

	local start_pos = { x=( pos.x           ), y=(pos.y + binfo.yoff              ), z=( pos.z )};
	local end_pos   = { x=( pos.x+pos.bsizex), y=(pos.y + binfo.yoff + binfo.ysize), z=( pos.z + pos.bsizez )};

	-- this function is only responsible for files that are in .mts format
	if( binfo.is_mts == 1 ) then
		-- translate rotation
		local rotation = 0;
		if(     pos.brotate == 1 ) then
			rotation = 90;
		elseif( pos.brotate == 2 ) then
			rotation = 180;
		elseif( pos.brotate == 3 ) then
			rotation = 270;
		else
			rotation = 0;
		end
		if( binfo.rotated ) then
			rotation = (rotation + binfo.rotated ) % 360;
		end

		-- the fruit is set per building, not per village as the other replacements
		if( binfo.farming_plus and binfo.farming_plus == 1 and pos.fruit ) then
			mg_villages.get_fruit_replacements( replacements, pos.fruit);
		end

		-- find out which ground types are used and where we need to place snow later on
		local ground_types = {};
		local has_snow     = {};
		for x = start_pos.x, end_pos.x do
			for z = start_pos.z, end_pos.z do
				-- store which particular grass type (or sand/desert sand or whatever) was there before placing the building
				local node = minetest.get_node( {x=x, y=pos.y,     z=z} );
				if( node and node.name and node.name ~= 'ignore' and node.name ~= 'air'
				         and node.name ~= 'default:dirt' and node.name ~= 'default:dirt_with_grass') then
					ground_types[ tostring(x)..':'..tostring(z) ] = node.name;
				end
				-- find out if there is snow above
				node = minetest.get_node(       {x=x, y=(pos.y+1), z=z} );
				local node2 = minetest.get_node({x=x, y=(start_pos.y-2), z=z} );
				if( node and node.name and node.name == 'default:snow' ) then
					has_snow[     tostring(x)..':'..tostring(z) ] = true; -- any value would do here; just has to be defined
					-- place snow as a marker one below the building
					minetest.swap_node(     {x=x, y=(start_pos.y-2), z=z}, {name='default:dirt_with_snow'});
				-- read the marker (the building might have been placed once already)
				elseif( node2 and node2.name and node2.name == 'default:dirt_with_snow' ) then
					has_snow[     tostring(x)..':'..tostring(z) ] = true; 
				end
			end
		end
					
--		print( 'PLACED BUILDING '..tostring( binfo.scm )..' AT '..minetest.pos_to_string( pos )..'. Max. size: '..tostring( max_xz )..' grows: '..tostring(fruit));
		-- force placement (we want entire buildings)
		minetest.place_schematic( start_pos, mts_path..binfo.scm..'.mts', tostring( rotation ), replacements, true);

		-- call on_construct for all the nodes that require it (i.e. furnaces)
		for i, v in ipairs( binfo.on_constr ) do

			-- there are only very few nodes which need this special treatment
			local nodes = minetest.find_nodes_in_area( start_pos, end_pos, v);

			for _, p in ipairs( nodes ) do
				minetest.registered_nodes[ v ].on_construct( p );
			end
		end

		-- note: after_place_node is not handled here because we do not have a player at hand that could be used for it

		-- evry dirt_with_grass node gets replaced with the grass type at that location
		-- (as long as it was something else than dirt_with_grass)
		local dirt_nodes = minetest.find_nodes_in_area( start_pos, end_pos, {'default:dirt_with_grass'} );
		for _,p in ipairs( dirt_nodes ) do
			local new_type = ground_types[ tostring( p.x )..':'..tostring( p.z ) ];
			if( new_type ) then
--				minetest.set_node( p, { name = new_type } );
			end
		end

		-- add snow on roofs, slabs, stairs, fences, ...
		for x = start_pos.x, end_pos.x do
			for z = start_pos.z, end_pos.z do
				if( moresnow and moresnow.suggest_snow_type and has_snow[ tostring(x)..':'..tostring(z) ] ) then

					local res = mg_villages.mg_drop_moresnow( x, z, end_pos.y, start_pos.y, nil, nil, nil );
					if( res ) then
						minetest.swap_node( {x=x, y=res.height, z=z}, 
							{ name=minetest.get_name_from_content_id( res.suggested.new_id ), param2=res.suggested.param2 });
					end
				end
			end
		end
	end

	-- TODO: fill chests etc.
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
		local xx = (vnoise:get2d({x=x, y=z})-2)*20+(40/(vs*vs))*((x-vx)*(x-vx)+(z-vz)*(z-vz))
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
	village.name = namegen.generate_village_name( pr_village );

	-- only generate a new village if the data is not already stored
	-- (the algorithm is fast, but village types and houses which are available may change later on,
  	-- and that might easily cause chaos if the village is generated again with diffrent input)
	if( village.to_add_data and village.to_add_data.bpos and village.to_add_data.replacements and village.to_add_data.plantlist) then
		--print('VILLAGE GENREATION: USING ALREADY GENERATED VILLAGE: Nr. '..tostring( village.nr )); 
		return;
	end

	-- in the case of medieval villages, we later on want to add wheat fields with dirt roads; 1 wide dirt roads look odd
	local space_between_buildings = mg_villages.village_sizes[ village_type ].space_between_buildings;

	-- actually generate the village structure
	local bpos = generate_bpos( village, pr_village, vnoise, space_between_buildings)


	local secondary_dirt_roads = nil; 
	-- if there is enough space, add dirt roads between the buildings (those will later be prolonged so that they reach the fields)
	if( space_between_buildings >= 2 and village_type == 'medieval') then
		secondary_dirt_roads = "dirt_road";
	end

	local dirt_roads = mg_villages.generate_dirt_roads( village, vnoise, bpos, secondary_dirt_roads );

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
	
	-- determine which plants will grow in the area around the village
	local plantlist = {};
	local sapling_id = replacements.table[ 'default:sapling' ];
	if( not( sapling_id )) then
		sapling_id = 'default:sapling';
	end
	sapling_id = minetest.get_content_id( sapling_id );
	-- 1/sapling_p = probability of a sapling beeing placed
	local sapling_p  = 25;
	if( mg_villages.sapling_probability[ sapling_id ] ) then
		sapling_p = mg_villages.sapling_probability[ sapling_id ];
	end

	-- medieval villages are sourrounded by wheat fields
	if(     village_type == 'medieval' ) then
		local c_wheat = minetest.get_content_id( 'farming:wheat_8');
		plantlist = {
			{ id=sapling_id, p=sapling_p*10 }, -- trees are rather rare
			{ id=c_wheat,    p=1         }};
	-- lumberjack camps have handy trees nearby
	elseif( village_type == 'lumberjack' ) then
		local c_junglegrass = minetest.get_content_id( 'default:junglegrass');
		plantlist = {
			{ id=sapling_id,    p=sapling_p },
			{ id=c_junglegrass, p=25        }};
	-- the villages of type taoki grow cotton
	elseif( village_type == 'taoki' ) then
		local c_cotton = minetest.get_content_id( 'farming:cotton_8');
		plantlist = {
			{ id=sapling_id, p=sapling_p*5 }, -- not too many trees
			{ id=c_cotton,   p=1         }};
	-- default/fallback: grassland
	else
		local c_grass = minetest.get_content_id( 'default:grass_5');
		plantlist = {
			{ id=sapling_id, p=sapling_p*10}, -- only few trees
			{ id=c_grass,    p=3         }};
	end

	-- store the generated data in the village table 
	village.to_add_data               = {};
	village.to_add_data.bpos          = bpos;
	village.to_add_data.replacements  = replacements.list;
	village.to_add_data.dirt_roads    = dirt_roads;
	village.to_add_data.plantlist     = plantlist;

	--print('VILLAGE GENREATION: GENERATING NEW VILLAGE Nr. '..tostring( village.nr ));
end


-- actually place the buildings (at least those which came as .we files; .mts files are handled later on)
-- this code is also responsible for tree placement
mg_villages.place_buildings = function(village, minp, maxp, data, param2_data, a, vnoise)
	local vx, vz, vs, vh = village.vx, village.vz, village.vs, village.vh
	local village_type = village.village_type;
	local seed = mg_villages.get_bseed({x=vx, z=vz})

	local bpos             = village.to_add_data.bpos;

	village.to_grow = {}; -- TODO this is a temporal solution to avoid flying tree trunks
	--generate_walls(bpos, data, a, minp, maxp, vh, vx, vz, vs, vnoise)
	local pr = PseudoRandom(seed)
	for _, g in ipairs(village.to_grow) do
		if pos_far_buildings(g.x, g.z, bpos) then
			mg.registered_trees[g.id].grow(data, a, g.x, g.y, g.z, minp, maxp, pr)
		end
	end

	local replacements = mg_villages.get_replacement_table( village.village_type, p, village.to_add_data.replacements );

	local extranodes = {}
	for _, pos in ipairs(bpos) do
		-- replacements are in table format for mapgen-based building spawning
		generate_building(pos, minp, maxp, data, param2_data, a, pr_village, extranodes, replacements )
	end

	-- replacements are in list format for minetest.place_schematic(..) type spawning
	return { extranodes = extranodes, bpos = bpos, replacements = replacements.list, dirt_roads = village.to_add_data.dirt_roads,
			plantlist = village.to_add_data.plantlist };
end


-- add the dirt roads
mg_villages.place_dirt_roads = function(village, minp, maxp, data, param2_data, a, vnoise, c_road_node)
	local c_air = minetest.get_content_id( 'air' );
	for _, pos in ipairs(village.to_add_data.dirt_roads) do
		local param2 = 0;
		if( pos.bsizex > 2 ) then
			param2 = 1;
		end
		for x = 0, pos.bsizex-1 do
			for z = 0, pos.bsizez-1 do
				local ax = pos.x+x;
				local az = pos.z+z;
			
                      			if (ax >= minp.x and ax <= maxp.x) and (ay >= minp.y and ay <= maxp.y) and (az >= minp.z and az <= maxp.z) then
					-- roads have a height of 1 block
					data[ a:index( ax, pos.y, az)] = c_road_node;
					param2_data[ a:index( ax, pos.y, az)] = param2;
					-- ...with air above
					data[ a:index( ax, pos.y+1, az)] = c_air;
					data[ a:index( ax, pos.y+2, az)] = c_air;
				end
			end
		end
	end
end

