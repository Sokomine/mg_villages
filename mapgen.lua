-- Intllib
local S = mg_villages.intllib

-- mapgen v6 has mudflow and requires additional fixes for that
local is_mapgen_v6 = false
-- no need to adjust height if it is a flat mapgen
local is_mapgen_flat_at_height = false
if(minetest.get_mapgen_setting("mg_name") == "v6") then
	is_mapgen_v6 = true
elseif(minetest.get_mapgen_setting("mg_name") == "flat") then
	-- mapgen flat places ground level at this height
	is_mapgen_flat_at_height = 8
end


-- determine water level from mapgens?
local water_level = minetest.get_mapgen_setting("water_level")
if(water_level and water_level ~= "") then
	-- minetest.get_mapgen_setting returns string format (which is
	-- not very helpful here)
	water_level = tonumber(water_level)
else
	-- fallback for older mapgens
	water_level = 0
end

------------------------------------------------------------------------------
-- Interface for other mods

-- this function gets executed only once per village - namely when the first
-- part of a village is generated;
-- relevant data about the vilalge can be found in the following data structure:
--     mg_villages.all_villages[ village_id ]
mg_villages.new_village_spawned = function( village_id )
	-- dummy function
end


-- use this function if you want to i.e. spawn mobs/traders/etc;
-- the village data structure contains information about the entire village;
-- minp, maxp indicates which part has actually been spawned;
-- the function may add information to the  village  data structure if needed;
-- the voxelmanip data (data, param2_data, a) is just for reading, i.e. finding
--   a good spawning position for the trader
mg_villages.part_of_village_spawned = function( village, minp, maxp, data, param2_data, a, cid )
	-- assign jobs and names and age and gender etc. to bed positions
	mg_villages.inhabitants.part_of_village_spawned( village, minp, maxp, data, param2_data, a, cid );
end
------------------------------------------------------------------------------

local data_vm          = {}  -- voxelmanip data buffer
local data_param2_data = {}  -- param2 voxelmanip data buffer



-- trees in the area around the village may need to be removed and replanted
-- at a diffrent height
local trunk_to_sapling = {}
for k,v in pairs(replacements_group['wood'].data) do
	-- if tree trunk and sapling exist in this game
	if(   minetest.registered_nodes[v[4]]
	  and minetest.registered_nodes[v[6]]) then
		trunk_to_sapling[ minetest.get_content_id(v[4]) ] = {
			wood    = k,
			trunk   = v[4],
			sapling = v[6],
			sapling_id = minetest.get_content_id(v[6])}
	end
end


mg_villages.wseed = 0;

minetest.register_on_mapgen_init(function(mgparams)
        mg_villages.wseed = math.floor(mgparams.seed/10000000000)
end)

function mg_villages.get_bseed(minp)
        return mg_villages.wseed + math.floor(5*minp.x/47) + math.floor(873*minp.z/91)
end

function mg_villages.get_bseed2(minp)
        return mg_villages.wseed + math.floor(87*minp.x/47) + math.floor(73*minp.z/91) + math.floor(31*minp.y/12)
end


-- if you change any of the 3 constants below, also change them in the function
--   mg_villages.village_area_mark_inside_village_area
mg_villages.inside_village = function(x, z, village, vnoise)
        return mg_villages.get_vn(x, z, vnoise:get_2d({x = x, y = z}), village) <= 40
end

mg_villages.inside_village_area = function(x, z, village, vnoise)
        return mg_villages.get_vn(x, z, vnoise:get_2d({x = x, y = z}), village) <= 80
end

mg_villages.inside_village_terrain_blend_area = function(x, z, village, vnoise)
        return mg_villages.get_vn(x, z, vnoise:get_2d({x = x, y = z}), village) <= 160
end


mg_villages.get_vnoise = function(x, z, village, vnoise) -- PM v
        return mg_villages.get_vn(x, z, vnoise:get_2d({x = x, y = z}), village)
end -- PM ^

mg_villages.get_vn = function(x, z, noise, village)
        local vx, vz, vs = village.vx, village.vz, village.vs
        return (noise - 2) * 20 +
                (40 / (vs * vs)) * ((x - vx) * (x - vx) + (z - vz) * (z - vz))
end


mg_villages.villages_in_mapchunk = function( minp, mapchunk_size )
	local noise1raw = minetest.get_perlin(12345, 6, 0.5, 256)
	
	local vcr = mg_villages.VILLAGE_CHECK_RADIUS
	local villages = {}
	for xi = -vcr, vcr do
	for zi = -vcr, vcr do
		for _, village in ipairs(mg_villages.villages_at_point({x = minp.x + xi * mapchunk_size, z = minp.z + zi * mapchunk_size}, noise1raw)) do
			villages[#villages+1] = village
		end
	end
	end
	return villages;
end


-- air and ignore are definitely no ground on which players can stand
-- replacements_group.node_is_ground is defined in handle_schematics
replacements_group.node_is_ground[ minetest.get_content_id('air'   )] = false
replacements_group.node_is_ground[ minetest.get_content_id('ignore')] = false

-- can we use this as a ground node in the village?
mg_villages.check_if_ground = function( ci )
	if( not( ci )) then
		return false;
	end
	-- information about already analyzed nodes is cached for faster access
	if( replacements_group.node_is_ground[ ci ] ~= nil) then
		return replacements_group.node_is_ground[ ci ];
	end
	-- analyze the node
	-- only nodes on which walking is possible may be counted as ground
	local node_name = minetest.get_name_from_content_id( ci );
	local def = minetest.registered_nodes[ node_name ];	

	-- if there is not enough information to classify the node, then it
	-- is not suitable as ground
	if(     not( def )
	     or not( def.walkable)
	     or not( def.groups)) then
		replacements_group.node_is_ground[ ci ] = false
		return false
	end

	-- shortcut for quick access to groups
	local g = def.groups
	-- trees and their parts, grass, flowers, liquids etc. are not suitable as ground
	if((g.leaves or g.sapling or g.tree or g.leaves or g.leafdecay
	 or g.grass or g.dry_grass or g.flora or g.plant or g.growing
	 or g.choppy or g.snappy or g.fleshy
	 or g.attached_node or g.rail
	 or g.water or g.liquid or g.lava)
	 -- the drawtype may sometimes also be helpful
	 -- (glasslike or partly transparent nodes won't do as ground)
	 or (def.drawtype and def.drawtype ~= "normal")) then

		replacements_group.node_is_ground[ ci ] = false
		return false
	-- stone, sand, dirt and things diggable with a pick or shovel count as ground
	elseif(( g.stone or g.sand or g.soil or g.cracky or g.crumbly or g.spreading_dirt_type )
	     -- anything that drops dirt when digged
	     or (def.drop and def.drop == 'default:dirt')
	     -- cavegen is allowed to eat through these nodes
	     or (def.walkable == true and def.is_ground_content == true and not(def.node_box))) then
		replacements_group.node_is_ground[ ci ] = true
		return true
	end
	-- fallback: node is not suitable as ground
	replacements_group.node_is_ground[ ci ] = false
	return false
end


-- sets evrything at x,z and above height target_height to air;
-- the area below gets filled up in a suitable way (i.e. dirt with grss - dirt - stone)
mg_villages.lower_or_raise_terrain_at_point = function( x, z, target_height, minp, maxp, vm, data, param2_data, a, cid, vh, treepos, has_artificial_snow, blend, force_ground, force_underground )
	local surface_node  = nil;
	local has_snow      = has_artificial_snow;
	local sapling_type  = nil
	local old_height    = maxp.y;
	local y = maxp.y;

	local look_for_snow = true;
	if( cid.c_snow==cid.c_ignore or cid.c_snow==cid.c_air
	 or cid.c_ice ==cid.c_ignore or cid.c_ice ==cid.c_air ) then
		look_for_snow = nil;
	end

	-- if we are working on a mapchunk above, set all to air;
	-- any terrain blending happens in the mapchunk below
	if( minp.y > vh ) then
		local air_counted = 0;
		for y=minp.y, minp.y+16 do
			if( data[a:index( x, y, z )] == cid.c_air ) then
				air_counted = air_counted + 1;
			end
		end
		if( air_counted > 3 or blend==0) then
			for y=minp.y+15, maxp.y do
				data[a:index( x, y, z)] = cid.c_air;
			end
		end
		-- else do nothing
		return;
	end

	-- search for a surface and set everything above target_height to air
	while( y > minp.y) do
		local ci = data[a:index(x, y, z)];
		local ci_below = data[a:index( x, y-1, z)];
		if(     look_for_snow and (ci == cid.c_snow or ci == cid.c_ice or ci == cid.c_snowblock)) then
			has_snow = true;
		elseif( trunk_to_sapling[ ci ] and ci_below == ci) then
			sapling_type = trunk_to_sapling[ ci ].sapling_id
		elseif( not( surface_node) and ci ~= cid.c_air and ci ~= cid.c_ignore and mg_villages.check_if_ground( ci ) == true) then
			-- we have found a surface of some kind
			surface_node = ci;
			old_height   = y;
			if( look_for_snow and surface_node == cid.c_dirt_with_snow and cid.c_dirt_with_snow~=cid.c_ignore) then
				has_snow = true;
			end
		end
		-- make sure there is air for the village
		if( y > target_height ) then
			data[a:index( x, y, z)] = cid.c_air;
		-- abort search once we've reached village ground level and found a surface node
		elseif( y <= target_height and surface_node ) then
			y = minp.y - 1;
		end
		y = y-1;
	end
		
	if( not( surface_node ) and old_height == maxp.y ) then
		if(     data[a:index( x, minp.y, z)]==cid.c_air) then
			old_height = vh - 2;	
		elseif( minp.y < 0 ) then
			old_height = minp.y;	
		end
	end
	if( not( surface_node ) or surface_node == cid.c_dirt) then
		surface_node = cid.c_dirt_with_grass;
	end
	if( look_for_snow and has_snow and surface_node == cid.c_dirt_with_grass and target_height > 1) then
		surface_node = cid.c_dirt_with_snow;
	end
	local below_1 = cid.c_dirt;
	local below_2 = cid.c_stone;
	if(     force_ground and force_underground ) then
		below_1 = force_ground;
		below_2 = force_underground;
		surface_node = below_1;
	elseif( surface_node == cid.c_desert_sand ) then
		below_1 = cid.c_desert_sand;
		below_2 = cid.c_desert_stone;
	elseif( surface_node == cid.c_silver_sand ) then
		below_1 = cid.c_silver_sand;
		below_2 = cid.c_silver_sandstone;
	elseif( surface_node == cid.c_sand ) then
		below_1 = cid.c_sand;
		below_2 = cid.c_sandstone;
	elseif( cid.c_ethereal_clay_read
	    and (surface_node == cid.c_ethereal_clay_red
	      or surface_node == cid.c_ethereal_clay_orange)) then
		below_1 = cid.c_ethereal_clay_orange;
		below_2 = cid.c_ethereal_clay_orange;
	elseif( surface_node == cid.c_sandstone ) then
		below_1 = cid.c_sandstone;
		below_2 = cid.c_sandstone;
	else
		below_1 = cid.c_dirt;
		below_2 = cid.c_stone;
	end

	-- do terrain blending; target_height has to be calculated based on old_height
	if( target_height == maxp.y and old_height < maxp.y ) then
		local yblend = old_height;
		if blend > 0 then -- leave some cliffs unblended
			yblend = math.floor(vh + blend * (old_height - vh) - 0.5)
			target_height = yblend+1;
		else	
			target_height = old_height;
		end
		for y = math.max( minp.y, yblend), maxp.y do
			local a_index = a:index( x, y, z );
			if( y<=water_level ) then
				-- keep ice
				if( data[a_index] ~= cid.c_ice ) then
					data[a_index] = cid.c_water;
				end
			else
				data[a_index] = cid.c_air;
			end
		end
	end
	
	-- only place the surface node if it is actually contained in this node
	if( target_height >= minp.y and target_height < maxp.y ) then
		if( target_height < 1 ) then
			-- no trees or snow below water level
		elseif( sapling_type and treepos) then
			data[       a:index( x, target_height+1, z)] = sapling_type
			table.insert( treepos, {x=x, y=target_height+1, z=z, typ=sapling_type, snow=has_artificial_snow});
		elseif( has_snow ) then
			data[       a:index( x, target_height+1, z)] = cid.c_snow;
		end
		data[               a:index( x, target_height,   z)] = surface_node;
		if( target_height-1 >= minp.y ) then
			data[       a:index( x, target_height-1, z)] = below_1;
		end
	end

	-- not every column will get a coal block; some may get two
	local coal_height1 = math.random( minp.y, maxp.y );
	local coal_height2 = math.random( minp.y, maxp.y );
	y = target_height-2;
	while( y > minp.y and y > target_height-40 and y <=maxp.y) do
		local old_node = data[a:index( x, y, z)];
		-- abort as soon as we hit anything other than air
		if( old_node == cid.c_air or old_node == cid.c_water ) then
			-- the occasional coal makes large stone cliffs slightly less boring
			if( y == coal_height1 or y == coal_height2 ) then
				data[a:index( x, y, z )] = cid.c_stone_with_coal;
			else
				data[a:index( x, y, z)] = below_2;
			end
			y = y-1;
		else
			y = minp.y - 1;
		end
	end
end


-- adjust the terrain level to the respective height of the village
mg_villages.flatten_village_area = function( villages, minp, maxp, vm, data, param2_data, a, village_area, cid, trees_to_grow_via_voxelmanip )
	-- prepare information about all villages that might occour here
	local village_tmp = {};
	for village_nr, village in ipairs(villages) do
		village_tmp[ village_nr ] = {};
		local force_ground = nil;
		local force_underground = nil;
		local has_artificial_snow = false;
		if( village.village_type
		   and mg_villages.village_type_data[ village.village_type ]
		   and mg_villages.village_type_data[ village.village_type ].force_ground
		   and mg_villages.village_type_data[ village.village_type ].force_underground ) then
			force_ground      = minetest.get_content_id(mg_villages.village_type_data[ village.village_type ].force_ground);
			force_underground = minetest.get_content_id(mg_villages.village_type_data[ village.village_type ].force_underground);
			if( not( force_ground ) or force_ground < 0 or force_ground == cid.c_ignore
			   or not( force_underground ) or force_underground < 0 or force_underground == cid.c_ignore ) then
				force_ground = nil;
				force_underground = nil;
			end
		end
		if( village.artificial_snow and village.artificial_snow==1) then
			has_artificial_snow = true;
		end
		village_tmp[ village_nr ].force_ground = force_ground;
		village_tmp[ village_nr ].force_underground = force_underground;
		village_tmp[ village_nr ].has_artificial_snow = has_artificial_snow;
		village_tmp[ village_nr ].vh = village.vh; -- height of village
	end

	local treepos = {};
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		local village_nr = village_area[ x ][ z ][ 1 ];
		local terrain_blending_value = village_area[ x ][ z ][ 2 ];
		-- use a _special_ given terrain height
		if(    village_nr > 0
		   and terrain_blending_value == 11
		   and village_area[ x ][ z ][3]) then
			mg_villages.lower_or_raise_terrain_at_point( x, z,
				village_area[ x ][ z ][ 3 ],
				minp, maxp, vm, data, param2_data, a, cid,
				village_area[ x ][ z ][ 3 ],
				nil,
				village_tmp[ village_nr ].has_artificial_snow,
				0,
				village_tmp[ village_nr ].force_ground,
				village_tmp[ village_nr ].force_underground );

		-- is there a village at this spot?
		elseif(village_nr > 0
		   and terrain_blending_value ~= 0
		   -- some data is stored in a temp table
		   and village_tmp[ village_nr]
		   and data[a:index(x, village_tmp[ village_nr ].vh  ,z)] ~= cid.c_ignore) then

			if( terrain_blending_value > 0 ) then -- inside a village
				mg_villages.lower_or_raise_terrain_at_point( x, z,
					village_tmp[ village_nr ].vh,
					minp, maxp, vm, data, param2_data, a, cid,
					village_tmp[ village_nr ].vh,
					nil,
					village_tmp[ village_nr ].has_artificial_snow,
					0,
					village_tmp[ village_nr ].force_ground,
					village_tmp[ village_nr ].force_underground );
			elseif( mg_villages.ENABLE_TERRAIN_BLEND and terrain_blending_value < 0) then
				mg_villages.lower_or_raise_terrain_at_point( x, z,
					maxp.y,
					minp, maxp, vm, data, param2_data, a, cid,
					village_tmp[ village_nr ].vh,
					treepos,
					village_tmp[ village_nr ].has_artificial_snow,
					-1* terrain_blending_value,
					village_tmp[ village_nr ].force_ground,
					village_tmp[ village_nr ].force_underground);
				end
			end
		end
	end

	-- grow normal trees and jungletrees in those parts of the terrain where height blending occours
	-- (trees from the mg mod/mapgen need pr to be passed on)
	local pr = PseudoRandom(mg_villages.get_bseed(minp));
	for _, tree in ipairs(treepos) do
		mg_villages.grow_a_tree( {x=tree.x, y=tree.y, z=tree.z}, tree.typ, minp, maxp, data, a, cid, pr, tree.snow, trees_to_grow_via_voxelmanip )
	end

end


-- repair mapgen griefings
mg_villages.fill_cavegen_holes_in_outer_shell = function( villages, minp, maxp, vm, data, param2_data, a, village_area, cid)
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		-- inside a village
		if( village_area[ x ][ z ][ 2 ] > 0 ) then
			local y;
			local village = villages[ village_area[ x ][ z ][ 1 ]];
			-- the current node at the ground
			local node    = data[a:index(x,village.vh,z)];
			-- there ought to be something - but there is air
			if( village and village.vh and (node==cid.c_air or node==cid.c_water)) then 
				y = village.vh-1;
				-- search from village height downards for holes generated by cavegen and fill them up
				while( y > minp.y ) do
					local ci = data[a:index(x, y, z)];
					if(     ci == cid.c_desert_stone or ci == cid.c_desert_sand ) then
						data[a:index(x, village.vh, z)] = cid.c_desert_sand;
						y = minp.y-1;
					elseif( ci == cid.c_sand ) then
						data[a:index(x, village.vh, z)] = cid.c_sand;
						y = minp.y-1;
					elseif( ci == cid.c_silver_sand or ci == cid.c_silver_sandstone) then
						data[a:index(x, village.vh, z)] = cid.c_silver_sand;
						y = minp.y-1;
					-- use dirt_with_grass as a fallback
					elseif( ci ~= cid.c_air and ci ~= cid.c_ignore and ci ~= cid.c_water and mg_villages.check_if_ground( ci ) == true) then
						data[a:index(x, village.vh, z)] = cid.c_dirt_with_grass;
						y = minp.y-1;
					-- abort the search - there is no data available yet
					elseif( ci == cid.c_ignore ) then
						y = minp.y-1;
					end
					y = y-1;
				end
			end
		end
	end
	end
end


-- TODO: handle moresnow and normal snow covers
mg_villages.undo_mudflow = function( villages, minp, maxp, vm, data, param2_data, a, village_area, cid)
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		-- inside a village
		if( village_area[ x ][ z ][ 2 ] > 0 ) then
			local village = villages[ village_area[ x ][ z ][ 1 ]];
			if( village and village.vh and village.vh > minp.y and village.vh < maxp.y) then
				-- remove any floating leaves, tree nodes, dirt etc.; any houses
				-- accidentally removed this way will be placed anew later on anyway
				local y = maxp.y
				while( y > village.vh) do
					local ci = data[a:index(x, y, z)]
					if(ci == cid.c_dirt or ci == cid.c_dirt_with_grass or ci == cid.c_dirt_with_snow or ci == cid.c_snowblock or ci == cid.c_sand or ci == cid.c_desert_sand) then
						data[a:index(x, y, z)] = cid.c_air
					elseif(y > village.vh+14 and ci ~= cid.c_air and ci ~= cid.c_ignore) then
						data[a:index(x, y, z)] = cid.c_air
					end
					y = y-1
				end
			end
		end
	end
	end

--[[
			while( y <= maxp.y ) do
				local ci = data[a:index(x, y, z)];
				if( ci ~= cid.c_ignore and (ci==cid.c_dirt or ci==cid.c_dirt_with_grass or ci==cid.c_sand or ci==cid.c_desert_sand)) then
					data[a:index(x,y,z)] = cid.c_air;
				-- if there was a moresnow cover, add a snow on top of the new floor node
				elseif( ci ~= cid.c_ignore
						 -- only if the game provides the snow nodes
						 and cid.c_snow ~= cid.c_air
						 and cid.c_dirt_with_snow ~= cid.c_air
						 -- only if moresnow is installed
						 and cid.c_msnow_1 ~= cid.c_air
					         and (ci==cid.c_msnow_1 or ci==cid.c_msnow_2 or ci==cid.c_msnow_3 or ci==cid.c_msnow_4 or
					              ci==cid.c_msnow_5 or ci==cid.c_msnow_6 or ci==cid.c_msnow_7 or ci==cid.c_msnow_8 or
					              ci==cid.c_msnow_9 or ci==cid.c_msnow_10 or ci==cid.c_msnow_11)) then
					data[a:index(x, village.vh+1, z)] = cid.c_snow;
					data[a:index(x, village.vh,   z)] = cid.c_dirt_with_snow;
				elseif( ci == cid.c_ignore ) then
					--data[a:index(x,y,z)] = cid.c_air;
				end
				y = y+1;
			end
--]]
end



-- helper functions for mg_villages.place_villages_via_voxelmanip
-- this one marks the positions of buildings plus a frame around them 
-- if keep_house_height is set, then the y position of the house will
--   be stored as a third parameter
mg_villages.village_area_mark_buildings = function( village_area, village_nr, bpos, keep_house_height)

	-- mark the roads and buildings and the area between buildings in the village_area table
	-- 2: road
	-- 3: border around a road 
	-- 4: building
	-- 5: border around a building
	for _, pos in ipairs( bpos ) do
		local reserved_for = 4; -- a building will be placed here
		if( pos.btype and pos.btype == 'road' ) then
			reserved_for = 2; -- the building will be a road
		end
		-- the building + a border of 1 around it
		for x = -1, pos.bsizex do
			for z = -1, pos.bsizez do
				local p = {x=pos.x+x, z=pos.z+z};
				if( not( village_area[ p.x ] )) then
					village_area[ p.x ] = {};
				end
				if( x==-1 or z==-1 or x==pos.bsizex or z==pos.bsizez ) then
					village_area[ p.x ][ p.z ] = { village_nr, reserved_for+1}; -- border around a building
				else
					village_area[ p.x ][ p.z ] = { village_nr, reserved_for }; -- the actual building
				end
				if(keep_house_height) then
					-- special "keep heigt" value
					village_area[ p.x ][ p.z ][2] = 11
					village_area[ p.x ][ p.z ][3] = pos.y
				end
			end
		end
	end
end

mg_villages.village_area_mark_dirt_roads = function( village_area, village_nr, dirt_roads )
	-- mark the dirt roads
	-- 8: dirt road
	for _, pos in ipairs(dirt_roads) do
		-- the building + a border of 1 around it
		for x = 0, pos.bsizex-1 do
			for z = 0, pos.bsizez-1 do
				local p = {x=pos.x+x, z=pos.z+z};
				if( not( village_area[ p.x ] )) then
					village_area[ p.x ] = {};
				end
				village_area[ p.x ][ p.z ] = { village_nr, 8 }; -- the actual dirt road
			end
		end
	end
end

mg_villages.village_area_mark_inside_village_area = function( village_area, villages, village_noise, minp, maxp )
	-- mark the rest ( inside_village but not part of an actual building) as well		 
	for x = minp.x, maxp.x do
		if( not( village_area[ x ] )) then
			village_area[ x ] = {};
		end
		for z = minp.z, maxp.z do
			if( not( village_area[ x ][ z ] )) then
				village_area[ x ][ z ] = { 0, 0 };

				local n_rawnoise = village_noise:get_2d({x = x, y = z}) -- create new blended terrain
				for village_nr, village in ipairs(villages) do
					local vn = mg_villages.get_vn(x, z, n_rawnoise, village);
					if(     village.is_single_house ) then
						-- do nothing here; the village area will be specificly marked later on

					-- the village core; this is where the houses stand (but there's no house or road at this particular spot)
					elseif( vn <= 40 ) then -- see mg_villages.inside_village
						village_area[ x ][ z ] = { village_nr, 6};

					-- the flattened land around the village where wheat, cotton, trees or grass may be grown (depending on village type)
					elseif( vn <= 80 ) then -- see mg_villages.inside_village_area
						village_area[ x ][ z ] = { village_nr, 1};

					-- terrain blending for the flattened land
					elseif( vn <= 160 and mg_villages.ENABLE_TERRAIN_BLEND) then -- see mg_villages.inside_village_terrain_blend_area
						if n_rawnoise > -0.5 then -- leave some cliffs unblended
							local blend = (( vn - 80) / 80) ^ 2 -- 0 at village edge, 1 at normal terrain
							-- assign a negative value to terrain that needs to be adjusted in height
							village_area[ x ][ z ] = { village_nr, -1 * blend};
						else
							-- no height adjustments for this terrain; the terrain is not considered to be part of the village
							village_area[ x ][ z ] = { village_nr, 0};
						end
					end
				end
			end
		end
	end
	
	-- single houses get their own form of terrain blend
	local pr = PseudoRandom(mg_villages.get_bseed(minp));
	for village_nr, village in ipairs( villages ) do
		if( village and village.is_single_house and village.to_add_data and village.to_add_data.bpos and #village.to_add_data.bpos>=1) then
			mg_villages.village_area_mark_single_house_area( village_area, minp, maxp, village.to_add_data.bpos[1], pr, village_nr, village );
		end
	end
end


-- analyzes optimal height for villages which have their center inside this mapchunk
mg_villages.village_area_get_height = function( village_area, villages, minp, maxp, data, param2_data, a, cid )
-- figuring out the height this way hardly works - because only a tiny part of the village may be contained in this chunk	
	local height_sum   = {};
	local height_count = {};
	local height_statistic = {};
	-- initialize the variables for counting
	for village_nr, village in ipairs( villages ) do
		height_sum[       village_nr ] = 0;
		height_count[     village_nr ] = 0;
		height_statistic[ village_nr ] = {};
	end
	-- try to find the optimal village height by looking at the borders defined by inside_village
	for x = minp.x+1, maxp.x-1 do
		for z = minp.z+1, maxp.z-1 do
			-- we are only intrested in the borders of the blending area
			if(     village_area[ x ][ z ][ 1 ] ~= 0
                            and village_area[ x ][ z ][ 2 ] ~= 0
			    -- is any neighbour not part of the village or its blending area?
			    and ( village_area[ x+1 ][ z   ][ 2 ] == 0
			       or village_area[ x-1 ][ z   ][ 2 ] == 0
			       or village_area[  x  ][ z+1 ][ 2 ] == 0
			       or village_area[  x  ][ z-1 ][ 2 ] == 0 )) then
				local y = maxp.y;
				while( y > minp.y and y >= 0) do
					local ci = data[a:index(x, y, z)];
					if(( ci ~= cid.c_air and ci ~= cid.c_ignore and mg_villages.check_if_ground( ci ) == true) or (y==0)) then
						local village_nr = village_area[ x ][ z ][ 1 ];
						if( village_nr > 0 and height_sum[ village_nr ] ) then
							height_sum[   village_nr ] = height_sum[   village_nr ] + y;
							height_count[ village_nr ] = height_count[ village_nr ] + 1;
			
							if( not( height_statistic[ village_nr ][ y ] )) then
								height_statistic[ village_nr ][ y ] = 1;
							else
								height_statistic[ village_nr ][ y ] = height_statistic[ village_nr ][ y ] + 1;
							end
						end
						y = minp.y - 1;
					end
					y = y-1;
				end
			end
		end
	end
	for village_nr, village in ipairs( villages ) do

		local tmin = maxp.y;
		local tmax = minp.y;
		local topt = 2;
		for k,v in pairs( height_statistic[ village_nr ] ) do
			if( k >= 2 and k < tmin and k >= minp.y) then
				tmin = k;
			end
			if( k <= maxp.y and k > tmax ) then
				tmax = k;
			end
			if(    height_statistic[ village_nr ][ topt ] 
			   and height_statistic[ village_nr ][ topt ] < height_statistic[ village_nr ][ k ]) then
				topt = k;
			end
		end
		--print('HEIGHT for village '..tostring( village.name )..' min:'..tostring( tmin )..' max:'..tostring(tmax)..' opt:'..tostring(topt)..' count:'..tostring( height_count[ village_nr ]));

		-- the very first village gets a height of 1
		if( village.nr and village.nr == 1 ) then
			village.optimal_height = 1;
		end

		if( village.optimal_height ) then
		-- villages above a size of 40 are *always* place at a convenient height of 1
		elseif( village.vs >= 40 and not(village.is_single_house)) then
			village.optimal_height = 2;
		elseif( village.vs >= 30 and not(village.is_single_house)) then
			village.optimal_height = 41 - village.vs;
		elseif( village.vs >= 25 and not(village.is_single_house)) then
			village.optimal_height = 36 - village.vs;
		
		-- in some cases, choose that height which was counted most often
		elseif( topt and (tmax - tmin ) > 8 and height_count[ village_nr ] > 0) then

			local qmw;
			if( ( tmax - topt ) > ( topt - tmin )) then
				qmw = tmax;
			else
				qmw = tmin;
			end
			village.optimal_height = qmw;
			
		-- if no border height was found, there'd be no point in calculating anything;
		-- also, this is done only if the village has its center inside this mapchunk	
		elseif(  height_count[ village_nr ] > 0 ) then

			local max    = 0;
			local target = village.vh;
			local qmw    = 0;
			for k, v in pairs( height_statistic[ village_nr ] ) do
				qmw = qmw + v * (k*k );
				if( v > max ) then
					target = k;
					max    = v;
				end
			end
			if( height_count[ village_nr ] > 5 ) then
				qmw = math.floor( math.sqrt( qmw / height_count[ village_nr ]) +1.5); -- round the value
				-- a height of 0 would be one below water level; so let's choose something higher;
				-- as this may be an island created withhin deep ocean, it might look better if it extends a bit from said ocean
				if( qmw < 1 ) then
					qmw = 2;
				end
			else
				qmw = 0; -- if in doubt, a height of 0 usually works well
			end

			village.optimal_height = qmw;
		end
	end
end



mg_villages.change_village_height = function( village, new_height )
	mg_villages.print( mg_villages.DEBUG_LEVEL_TIMING, S("CHANGING HEIGHT from @1 to @2.", tostring( village.vh ), tostring( new_height )));
	for _, pos in ipairs(village.to_add_data.bpos) do
		pos.y = new_height;
	end
	for _, pos in ipairs(village.to_add_data.dirt_roads) do
		pos.y = new_height;
	end
	village.vh = new_height;
end



time_elapsed = function( t_last, msg )
	mg_villages.t_now = minetest.get_us_time();
	mg_villages.print( mg_villages.DEBUG_LEVEL_TIMING, S("TIME ELAPSED").." : "..tostring( mg_villages.t_now - t_last )..' '..msg );
	return mg_villages.t_now;
end


mg_villages.save_data = function()
	save_restore.save_data( 'mg_all_villages.data', mg_villages.all_villages );
end


mg_villages.place_villages_via_voxelmanip = function( villages, minp, maxp, vm, data, param2_data, a, top, seed )
	local t1 = minetest.get_us_time();

	local cid = handle_schematics.get_cid_table()
	t1 = time_elapsed( t1, 'defines' );

	local village_noise = minetest.get_perlin(7635, 3, 0.5, 16);

	-- determine which coordinates are inside the village and which are not
	local village_area = {};

	-- trees grown that way are placed a bit later on in this function
	local trees_to_grow_via_voxelmanip = {}

	for village_nr, village in ipairs(villages) do
		-- generate the village structure: determine positions of buildings and roads
		mg_villages.generate_village( village, village_noise);

		if( not( village.is_single_house )) then
			-- only add artificial snow if the village has at least a size of 15 (else it might look too artificial)
			if( not( village.artificial_snow ) and village.vs > 15) then
				if( mg_villages.artificial_snow_probability and math.random( 1, mg_villages.artificial_snow_probability )==1
				    -- forbid artificial snow for some village types
			   	    and not( mg_villages.village_type_data[ village.village_type ].no_snow )
				    and minetest.registered_nodes['default:snow']) then
					village.artificial_snow = 1;
				else
					village.artificial_snow = 0;
				end
			end
	
			-- will set village_area to N where .. is:
			--  2: a building
			--  3: border around a building
			--  4: a road
			--  5: border around a road
			mg_villages.village_area_mark_buildings(   village_area, village_nr, village.to_add_data.bpos, village.keep_house_height );
			-- will set village_area to N where .. is:
			--  8: a dirt road
			mg_villages.village_area_mark_dirt_roads(  village_area, village_nr, village.to_add_data.dirt_roads );
		else -- mark the terrain below single houses
			mg_villages.village_area_mark_buildings(   village_area, village_nr, village.to_add_data.bpos, village.keep_house_height );
		end
        end
	t1 = time_elapsed( t1, 'generate_village, mark_buildings and mark_dirt_roads' );

	local emin;
	local emax;
	-- if no voxelmanip data was passed on, read the data here
	if( not( vm ) or not( a) or not( data ) or not( param2_data ) ) then
		vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
		if( not( vm )) then 
			return;
		end

		a = VoxelArea:new{
			MinEdge={x=emin.x, y=emin.y, z=emin.z},
			MaxEdge={x=emax.x, y=emax.y, z=emax.z},
		}

		-- use already defined buffers for speedup
		vm:get_data(data)
		vm:get_param2_data(param2_data)
	end
	t1 = time_elapsed( t1, 'get_vmap_data' );

	-- all vm manipulation functions write their content to the *entire* volume/area - including those 16 nodes that
	-- extend into neighbouring mapchunks; thus, cavegen griefing and mudflow can be repaired by placing everythiing again
	local tmin = emin;
	local tmax = emax;
	-- if set to true, cavegen eating through houses and mudflow on roofs will NOT be repaired
	if( not( mg_villages.UNDO_CAVEGEN_AND_MUDFLOW )) then
		tmin = minp;
		tmax = maxp;
	end
	-- will set village_area to N where .. is:
	--  0: not part of any village
	--  1: flattened area around the village; plants (wheat, cotton, trees, grass, ...) may be planted here
  	--  6: free/unused spot in the core area of the village where the buildings are
        -- negative value: do terrain blending
	mg_villages.village_area_mark_inside_village_area( village_area, villages, village_noise, tmin, tmax );

	t1 = time_elapsed( t1, 'mark_inside_village_area' );

	-- determine optimal height for all villages that have their center in this mapchunk; sets village.optimal_height
	mg_villages.village_area_get_height( village_area, villages, tmin, tmax, data, param2_data, a, cid );
	t1 = time_elapsed( t1, 'get_height' );
	-- the villages in the first mapchunk are set to a fixed height of 1 so that players will not end up embedded in stone
	if( not( mg_villages.all_villages ) or mg_villages.anz_villages < 1 ) then
		villages[1].optimal_height = 1;
	end

	-- change height of those villages where an optimal_height could be determined
	for _,village in ipairs(villages) do
		-- for a flat mapgen: use surface level
		if( is_mapgen_flat_at_height ) then
			village.optimal_height = is_mapgen_flat_at_height
		end
		if( village.vh and village.vh < water_level ) then
			village.optimal_height = water_level
		end
		if( village.optimal_height and village.optimal_height >= water_level and village.optimal_height ~= village.vh
		    -- no point in changing the village height if the houses are at a fixed height already
		    and not(village.keep_house_height)) then
			-- towers are usually found on elevated places
			if( village.village_type == 'tower' ) then
				village.optimal_height = village.optimal_height + math.max( math.floor(village.vs/2), 2 );
			end
			mg_villages.change_village_height( village, village.optimal_height );
		end
	end
	t1 = time_elapsed( t1, 'change_height' );

	-- flatten only the core area - not the outer shell as the shell may not be generated
	-- in all parts yet - and lowering terrain there would cause wrong lighting
	mg_villages.flatten_village_area( villages, minp, maxp, vm, data, param2_data, a, village_area, cid, trees_to_grow_via_voxelmanip );
	t1 = time_elapsed( t1, 'flatten_village_area' );

	-- repair cavegen griefings in the outer shell (which is part of other mapchunks);
	-- such griefings may be caused by caves starting in this mapchunk;
	-- the holes need to be filled inside the villages as they would look extremly ugly
	mg_villages.fill_cavegen_holes_in_outer_shell( villages, {x=tmin.x,   y=tmin.y,z=tmin.z},    {x=tmin.x+16, y=tmax.y, z=tmax.z}, vm, data, param2_data, a, village_area, cid );
	mg_villages.fill_cavegen_holes_in_outer_shell( villages, {x=tmax.x-16,y=tmin.y,z=tmin.z},    {x=tmax.x,    y=tmax.y, z=tmax.z}, vm, data, param2_data, a, village_area, cid );
	mg_villages.fill_cavegen_holes_in_outer_shell( villages, {x=tmin.x+16,y=tmin.y,z=tmin.z},    {x=tmax.x-16, y=tmax.y, z=tmin.z+16}, vm, data, param2_data, a, village_area, cid );
	mg_villages.fill_cavegen_holes_in_outer_shell( villages, {x=tmin.x+16,y=tmin.y,z=tmax.z-16}, {x=tmax.x-16, y=tmax.y, z=tmax.z},    vm, data, param2_data, a, village_area, cid );
	t1 = time_elapsed( t1, 'repair_outer_shell' );


	-- mapgen v6 has mudflow; while this is fine outside of villages, it needs to be removed inside them
	if( is_mapgen_v6 ) then
		mg_villages.undo_mudflow( villages, {x=minp.x-3, y=minp.y, z=minp.z-3}, {x=minp.x+3, y=maxp.y, z=maxp.z+3}, vm, data, param2_data, a, village_area, cid)
		mg_villages.undo_mudflow( villages, {x=maxp.x-3, y=minp.y, z=minp.z-3}, {x=maxp.x+3, y=maxp.y, z=maxp.z+3}, vm, data, param2_data, a, village_area, cid)
		mg_villages.undo_mudflow( villages, {x=minp.x-3, y=minp.y, z=minp.z-3}, {x=maxp.x+3, y=maxp.y, z=minp.z+3}, vm, data, param2_data, a, village_area, cid)
		mg_villages.undo_mudflow( villages, {x=minp.x-3, y=minp.y, z=maxp.z-3}, {x=maxp.x+3, y=maxp.y, z=maxp.z+3}, vm, data, param2_data, a, village_area, cid)
	end

	local c_feldweg =  minetest.get_content_id('cottages:feldweg');
	if( not( c_feldweg )) then
		c_feldweg = minetest.get_content_id('default:cobble');
	end

	-- up til now, cid.c_water had to be default:water_source (or whatever the current
	-- game uses) so that the terrain could be adjusted; now, we may change it to
	-- river water for the individual buildings because fountains, lakes and the like
	-- ought to use river water instead of salt water if possible
	if(minetest.registered_nodes["default:river_water_source"]) then
		cid.c_water = minetest.get_content_id('default:river_water_source')
	end

	for _, village in ipairs(villages) do

		-- the village_id will be stored in the plot markers
		local village_id = tostring( village.vx )..':'..tostring( village.vz );
		village.anz_buildings = mg_villages.count_inhabitated_buildings(village);
		village.to_add_data = handle_schematics.place_buildings( village, tmin, tmax, data, param2_data, a, cid, village_id);

		handle_schematics.place_dirt_roads(                village, tmin, tmax, data, param2_data, a, c_feldweg);

		-- grow trees which are part of buildings into saplings
		for _,v in ipairs( village.to_add_data.extra_calls.trees ) do
			mg_villages.grow_a_tree( v, v.typ, minp, maxp, data, a, cid, nil, v.snow, trees_to_grow_via_voxelmanip ); -- TODO: supply pseudorandom value?
		end
	end
	t1 = time_elapsed( t1, 'place_buildings and place_dirt_roads' );

	mg_villages.village_area_fill_with_plants( village_area, villages, tmin, tmax, data, param2_data, a, cid, trees_to_grow_via_voxelmanip );
	t1 = time_elapsed( t1, 'fill_with_plants' );

	vm:set_data(data)
	vm:set_param2_data(param2_data)
	t1 = time_elapsed( t1, 'vm data set' );

	-- needs to be the last because after this data/param2_data will no longer be valid
	-- the code can be found in trees.lua
	mg_villages.grow_trees_voxelmanip( vm, trees_to_grow_via_voxelmanip );
	t1 = time_elapsed( t1, 'vm growing trees' );

	-- calc_lighting will figure out for which volume of the VM it is responsible (minp, maxp)
	vm:calc_lighting()
	t1 = time_elapsed( t1, 'vm calc lighting' );

	vm:write_to_map()
	t1 = time_elapsed( t1, 'vm data written' );

	vm:update_liquids()
	t1 = time_elapsed( t1, 'vm update liquids' );

	mg_villages.after_place_villages(villages, minp, maxp, data, param2_data, a, cid)
end


-- called by mg_villages.place_villages_via_voxelmanip(..) and other mods after a village has been placed;
-- calls on_constr and does other needed stetup of metadata;
-- prepares mob spawning;
-- stores the village data
mg_villages.after_place_villages = function( villages, minp, maxp, data, param2_data, a, cid )
	local t1 = minetest.get_us_time();
	-- do on_construct calls AFTER the map data has been written - else i.e. realtest fences can not update themshevles
	for _, village in ipairs(villages) do
		handle_schematics.call_on_construct( village.to_add_data.extra_calls.on_constr );
	end
	t1 = time_elapsed( t1, 'do on_construct calls' );


	-- the doors need to be adjusted as well
	for _, village in ipairs(villages) do
		handle_schematics.call_door_setup( village.to_add_data.extra_calls.door_b );
	end
	t1 = time_elapsed( t1, 'do door setup' );


	local pr = PseudoRandom(mg_villages.get_bseed(minp));
	for _, village in ipairs(villages) do
		for _,v in ipairs( village.to_add_data.extra_calls.chests ) do
			local building_nr  = village.to_add_data.bpos[ v.bpos_i ];
			local building_data_typ = mg_villages.BUILDINGS[ building_nr.btype ].typ;
			handle_schematics.fill_chest_random( v, pr, building_nr, building_data_typ );
		end
	end
	t1 = time_elapsed( t1, 'do fill chests' );
	-- TODO: extra_calls.signs

	-- set up mob data and workplace markers so that they know for which mob they are responsible
	for _, village in ipairs(villages) do
		local village_id = tostring( village.vx )..':'..tostring( village.vz );
		-- analyze road network, assign workers to buildings, assign mobs to beds
		mg_villages.inhabitants.assign_mobs( village, village_id, false );
		-- set infotexts for beds and workplace markers
		mg_villages.inhabitants.prepare_metadata( village, village_id, minp, maxp);
	end

	-- useful for spawning mobs etc.
	for _, village in ipairs(villages) do
		mg_villages.part_of_village_spawned( village, minp, maxp, data, param2_data, a, cid );
	end
	t1 = time_elapsed( t1, 'do spawn mobs' );

	-- initialize the pseudo random generator so that the chests will be filled in a reproducable pattern
	local meta
	for _, village in ipairs(villages) do
		-- now add those buildings which are .mts files and need to be placed by minetest.place_schematic(...)
		-- place_schematics is no longer needed	
		--mg_villages.place_schematics( village.to_add_data.bpos, village.to_add_data.replacements, a, pr );
		--t1 = time_elapsed( t1, 'place_schematics' );

		if( not( mg_villages.all_villages )) then
			mg_villages.all_villages = {};
		end
		-- unique id - there can only be one village at a given pair of x,z coordinates
		local village_id = tostring( village.vx )..':'..tostring( village.vz );	
		-- the village data is saved only once per village - and not whenever part of the village is generated
		if( not( mg_villages.all_villages[ village_id ])) then

			-- count how many villages we already have and assign each village a uniq number
			local count = 1;
			for _,v in pairs( mg_villages.all_villages ) do
				count = count + 1;
			end
			village.to_add_data.extra_calls = {};
			village.extra_calls = {}; -- do not save these values
			village.nr = count;
			mg_villages.anz_villages = count;
			mg_villages.all_villages[ village_id ] = minetest.deserialize( minetest.serialize( village ));

			mg_villages.print( mg_villages.DEBUG_LEVEL_NORMAL, "Village No. "..tostring( count ).." of type \'"..
					tostring( village.village_type ).."\' of size "..tostring( village.vs )..
					" spawned at: x = "..village.vx..", z = "..village.vz)

			-- hook for doing stuff that needs to be done exactly once per village
			mg_villages.new_village_spawned( village_id );
		end
	end
	-- always save the changed village data
	t1 = time_elapsed( t1, 'update village data' );
	mg_villages.save_data();
	t1 = time_elapsed( t1, 'save village data' );

end


--minetest.set_gen_notify('dungeon, temple, cave_begin, cave_end, large_cave_begin, large_cave_end',{});


-- the actual mapgen
-- It only does changes if there is at least one village in the area that is to be generated.
minetest.register_on_generated(function(minp, maxp, seed)
-- this is just for learning more about dungeons and caves; it is not used anywhere here
--	local structures = minetest.get_mapgen_object('gennotify');
--	print('STRUCTURES BY MAPGEN: '..minetest.serialize( structures ));

	-- only generate village on the surface chunks
	if( minp.y < -32 or minp.y > mg_villages.MAX_HEIGHT_TREATED) then --64
		return;
	end
	
	-- this function has to be called ONCE and AFTER all village types and buildings have been added
	-- (which might have been done by other mods so we can't do this earlier)
	if( not( mg_villages.village_types )) then
		mg_villages.init_weights();
	end


	local villages = {};
	-- create normal villages
	if( mg_villages.ENABLE_VILLAGES == true ) then
		villages = mg_villages.villages_in_mapchunk( minp, maxp.x-minp.x+1 );
	end

	-- are there any lone buildings in this mapchunk?
	-- if so, they have to be taken into consideration even if this mapchunk
	-- already contains a village (else lone houses might be cut off)
	if( mg_villages.INVERSE_HOUSE_DENSITY > 0 ) then
		villages = mg_villages.houses_in_mapchunk(   minp, maxp.x-minp.x+1, villages );
	end

	-- check if the village exists already
	local v_nr = 1;
	for v_nr, village in ipairs(villages) do
		local village_id = tostring( village.vx )..':'..tostring( village.vz );

		if( not( village.name ) or village.name == '') then
			village.name = 'unknown';
		end

		if( mg_villages.all_villages and mg_villages.all_villages[ village_id ]) then
			villages[ v_nr ] = mg_villages.all_villages[ village_id ];
		end
	end

	if( villages and #villages > 0 ) then
		mg_villages.place_villages_via_voxelmanip( villages, minp, maxp, nil, data_vm, data_param2_data, nil, nil, seed );
	end
end)
