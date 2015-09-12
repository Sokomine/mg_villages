
------------------------------------------------------------------------------
-- Interface for other mdos

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
	-- mobf needs a way to spawn its traders
	if( minetest.get_modpath( 'mobf_trader' )) then
		mob_village_traders.part_of_village_spawned( village, minp, maxp, data, param2_data, a, cid );
	end
end
------------------------------------------------------------------------------


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
        return mg_villages.get_vn(x, z, vnoise:get2d({x = x, y = z}), village) <= 40
end

mg_villages.inside_village_area = function(x, z, village, vnoise)
        return mg_villages.get_vn(x, z, vnoise:get2d({x = x, y = z}), village) <= 80
end

mg_villages.inside_village_terrain_blend_area = function(x, z, village, vnoise)
        return mg_villages.get_vn(x, z, vnoise:get2d({x = x, y = z}), village) <= 160
end


mg_villages.get_vnoise = function(x, z, village, vnoise) -- PM v
        return mg_villages.get_vn(x, z, vnoise:get2d({x = x, y = z}), village)
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


-- TODO: determine water level from mapgens?
local MG_VILLAGES_WATER_LEVEL = 1;
if( minetest.get_modpath( 'mg' )) then
	MG_VILLAGES_WATER_LEVEL = 0;
end

--replacements_group.node_is_ground = {}; -- store nodes which have previously been identified as ground

mg_villages.check_if_ground = function( ci )

	-- pre-generate a list of no-ground-nodes for caching
	if( replacements_group.node_is_ground[ minetest.get_content_id('air')]==nil) then
		local no_ground_nodes = {'air','ignore','default:sandstonebrick','default:cactus','default:wood','default:junglewood',
			'default:pine_wood','default:pine_tree','default:acacia_wood','default:acacia_tree',
			'ethereal:mushroom_pore','ethereal:mushroom_trunk','ethereal:bamboo', 'ethereal:mushroom'};
		-- TODO: add all those other tree and leaf nodes that might be added by mapgen
		for _,name in ipairs( no_ground_nodes ) do
			replacements_group.node_is_ground[ minetest.get_content_id( name )] = false;
		end
		local ground_nodes = {'ethereal:dry_dirt'};
		for _,name in ipairs( ground_nodes ) do
			replacements_group.node_is_ground[ minetest.get_content_id( name )] = true;
		end
	end

	if( not( ci )) then
		return false;
	end
	if( replacements_group.node_is_ground[ ci ] ~= nil) then
		return replacements_group.node_is_ground[ ci ];
	end
	-- analyze the node
	-- only nodes on which walking is possible may be counted as ground
	local node_name = minetest.get_name_from_content_id( ci );
	local def = minetest.registered_nodes[ node_name ];	
	-- store information about this node type for later use
	if(     not( def )) then
		replacements_group.node_is_ground[ ci ] = false;
	elseif( not( def.walkable)) then
		replacements_group.node_is_ground[ ci ] = false;
	elseif( def.groups and def.groups.tree ) then
		replacements_group.node_is_ground[ ci ] = false;
	elseif(	def.drop   and def.drop == 'default:dirt') then
		replacements_group.node_is_ground[ ci ] = true;
	elseif( def.walkable == true and def.is_ground_content == true and not(def.node_box)) then
		replacements_group.node_is_ground[ ci ] = true;
	else
		replacements_group.node_is_ground[ ci ] = false;
	end
	return replacements_group.node_is_ground[ ci ];
end


-- sets evrything at x,z and above height target_height to air;
-- the area below gets filled up in a suitable way (i.e. dirt with grss - dirt - stone)
mg_villages.lower_or_raise_terrain_at_point = function( x, z, target_height, minp, maxp, vm, data, param2_data, a, cid, vh, treepos, has_artificial_snow, blend, force_ground, force_underground )
	local surface_node  = nil;
	local has_snow      = has_artificial_snow;
	local tree          = false;
	local jtree         = false;
	local ptree         = false;
	local atree         = false;
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
		if(     look_for_snow and (ci == cid.c_snow or ci == cid.c_ice or ci == cid.c_snowblock)) then
			has_snow = true;
		elseif( ci == cid.c_tree ) then
			tree  = true;
		-- no jungletrees for branches
		elseif( ci == cid.c_jtree and data[a:index( x, y-1, z)]==cid.c_jtree) then
			jtree = true;
		-- pinetrees
		elseif( ci == cid.c_ptree and data[a:index( x, y-1, z)]==cid.c_ptree) then
			ptree = true;
		-- acacia
		elseif( ci == cid.c_atree and data[a:index( x, y-1, z)]==cid.c_atree) then
			atree = true;
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
	elseif( surface_node == cid.c_sand ) then
		below_1 = cid.c_sand;
		below_2 = cid.c_stone;
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
			yblend = math.floor(vh + blend * (old_height - vh))
			target_height = yblend+1;
		else	
			target_height = old_height;
		end
		for y = math.max( minp.y, yblend), maxp.y do
			if( y<=MG_VILLAGES_WATER_LEVEL ) then
				-- keep ice
				if( data[a:index( x, y, z )] ~= cid.c_ice ) then
					data[a:index( x, y, z)] = cid.c_water;
				end
			else
				data[a:index( x, y, z)] = cid.c_air;
			end
		end
	end
	
	-- only place the surface node if it is actually contained in this node
	if( target_height >= minp.y and target_height < maxp.y ) then
		if( target_height < 1 ) then
			-- no trees or snow below water level
		elseif( tree  and not( mg_villages.ethereal_trees ) and treepos) then
			data[       a:index( x, target_height+1, z)] = cid.c_sapling
			table.insert( treepos, {x=x, y=target_height+1, z=z, typ=0, snow=has_artificial_snow});
		elseif( jtree and not( mg_villages.ethereal_trees ) and treepos) then
			data[       a:index( x, target_height+1, z)] = cid.c_jsapling
			table.insert( treepos, {x=x, y=target_height+1, z=z, typ=1, snow=has_artificial_snow});
		elseif( ptree and not( mg_villages.ethereal_trees ) and treepos) then
			data[       a:index( x, target_height+1, z)] = cid.c_psapling
			table.insert( treepos, {x=x, y=target_height+1, z=z, typ=2, snow=has_artificial_snow});
		elseif( atree and not( mg_villages.ethereal_trees ) and treepos) then
			data[       a:index( x, target_height+1, z)] = cid.c_asapling
			table.insert( treepos, {x=x, y=target_height+1, z=z, typ=3, snow=has_artificial_snow});
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
mg_villages.flatten_village_area = function( villages, minp, maxp, vm, data, param2_data, a, village_area, cid )
	local treepos = {};
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		for village_nr, village in ipairs(villages) do
			local force_ground = nil;
			local force_underground = nil;
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
			-- is village_nr the village that is the one that is relevant for this spot?
			if(    village_area[ x ][ z ][ 1 ] > 0
			   and village_area[ x ][ z ][ 1 ]==village_nr 
			   and village_area[ x ][ z ][ 2 ]~= 0
			   and data[a:index(x,village.vh,z)] ~= cid.c_ignore) then

				local has_artificial_snow = false;
				if( village.artificial_snow and village.artificial_snow==1) then
					has_artificial_snow = true;
				end

				if( village_area[ x ][ z ][ 2 ] > 0 ) then -- inside a village
					mg_villages.lower_or_raise_terrain_at_point( x, z, village.vh, minp, maxp, vm, data, param2_data, a, cid, village.vh,
											nil,     has_artificial_snow, 0, force_ground, force_underground   );
				elseif( mg_villages.ENABLE_TERRAIN_BLEND and village_area[ x ][ z ][ 2 ] < 0) then
					mg_villages.lower_or_raise_terrain_at_point( x, z, maxp.y,     minp, maxp, vm, data, param2_data, a, cid, village.vh,
											treepos, has_artificial_snow, -1* village_area[ x ][ z ][ 2 ],
											force_ground, force_underground);
				end
			end -- PM ^
		end
	end
	end

	-- grow normal trees and jungletrees in those parts of the terrain where height blending occours
	for _, tree in ipairs(treepos) do
		local plant_id = cid.c_jsapling;
		if( tree.typ == 0 ) then
			plant_id = cid.c_sapling;
		elseif( tree.typ == 2 ) then
			plant_id = cid.c_psapling;
		elseif( tree.typ == 3 ) then
			plant_id = cid.c_asapling;
		end
		mg_villages.grow_a_tree( {x=tree.x, y=tree.y, z=tree.z}, plant_id, minp, maxp, data, a, cid, nil, tree.snow ) -- no pseudorandom present
	end

end


-- repair mapgen griefings
mg_villages.repair_outer_shell = function( villages, minp, maxp, vm, data, param2_data, a, village_area, cid, edge_min, edge_max )
	-- find out if this part of the shell has already been generated or not
	if(    data[a:index(minp.x,minp.y,minp.z)] == cid.c_ignore

	   and data[a:index(maxp.x,minp.y,minp.z)] == cid.c_ignore
	   and data[a:index(minp.x,maxp.y,minp.z)] == cid.c_ignore
	   and data[a:index(minp.x,minp.y,maxp.z)] == cid.c_ignore

	   and data[a:index(maxp.x,maxp.y,maxp.z)] == cid.c_ignore

	   and data[a:index(maxp.x,maxp.y,minp.z)] == cid.c_ignore
	   and data[a:index(maxp.x,minp.y,maxp.z)] == cid.c_ignore
	   and data[a:index(minp.x,maxp.y,maxp.z)] == cid.c_ignore ) then

		-- no - none of the edges has been created yet; no point to place anything there
		return;
	end

	if( minp.x < edge_min.x ) then
		edge_min.x = minp.x;
	end
	if( minp.y < edge_min.y ) then
		edge_min.y = minp.y;
	end
	if( minp.z < edge_min.z ) then
		edge_min.z = minp.z;
	end
	if( maxp.x > edge_max.x ) then
		edge_max.x = maxp.x;
	end
	if( maxp.y > edge_max.y ) then
		edge_max.y = maxp.y;
	end
	if( maxp.z > edge_max.z ) then
		edge_max.z = maxp.z;
	end


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
					
			-- remove mudflow
			y = village.vh + 1;
			while( y <= maxp.y ) do
				local ci = data[a:index(x, y, z)];
				if( ci ~= cid.c_ignore and (ci==cid.c_dirt or ci==cid.c_dirt_with_grass or ci==cid.c_sand or ci==cid.c_desert_sand)) then
					data[a:index(x,y,z)] = cid.c_air;
				-- if there was a moresnow cover, add a snow on top of the new floor node
				elseif( ci ~= cid.c_ignore
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
		end
	end
	end
end



-- helper functions for mg_villages.place_villages_via_voxelmanip
-- this one marks the positions of buildings plus a frame around them 
mg_villages.village_area_mark_buildings = function( village_area, village_nr, bpos)

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

				local n_rawnoise = village_noise:get2d({x = x, y = z}) -- create new blended terrain
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
			if(     village_area[ x ][ z ][ 1 ] ~= 0
                            and village_area[ x ][ z ][ 2 ] ~= 0
			    and ( village_area[ x+1 ][ z   ][ 2 ] <= 0
			       or village_area[ x-1 ][ z   ][ 2 ] <= 0 
			       or village_area[  x  ][ z+1 ][ 2 ] <= 0 
			       or village_area[  x  ][ z-1 ][ 2 ] <= 0 )
			  -- if the corners of the mapblock are inside the village area, they may count as borders here as well
			  or ( x==minp.x+1 and village_area[ x-1 ][ z   ][ 1 ] >= 0 )
			  or ( x==maxp.x-1 and village_area[ x+1 ][ z   ][ 1 ] >= 0 )
			  or ( z==minp.z-1 and village_area[ x   ][ z-1 ][ 1 ] >= 0 )
			  or ( z==maxp.z+1 and village_area[ x   ][ z+1 ][ 1 ] >= 0 )) then

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
	mg_villages.print( mg_villages.DEBUG_LEVEL_TIMING, 'CHANGING HEIGHT from '..tostring( village.vh )..' to '..tostring( new_height ));
	for _, pos in ipairs(village.to_add_data.bpos) do
		pos.y = new_height;
	end
	for _, pos in ipairs(village.to_add_data.dirt_roads) do
		pos.y = new_height;
	end
	village.vh = new_height;
end


-- those functions from the mg mod do not have their own namespace
if( minetest.get_modpath( 'mg' )) then
	mg_villages.add_savannatree = add_savannatree;
	mg_villages.add_pinetree    = add_pinetree;
end

mg_villages.grow_a_tree = function( pos, plant_id, minp, maxp, data, a, cid, pr, snow )
	-- a normal tree; sometimes comes with apples
	if(     plant_id == cid.c_sapling and minetest.registered_nodes[ 'default:tree']) then
		mg_villages.grow_tree(       data, a, pos, math.random(1, 4) == 1, math.random(1,100000), snow)
		return true;
	-- a normal jungletree
	elseif( plant_id == cid.c_jsapling and minetest.registered_nodes[ 'default:jungletree']) then
		mg_villages.grow_jungletree( data, a, pos, math.random(1,100000), snow)
		return true;
	-- a pine tree
	elseif( plant_id == cid.c_psapling and minetest.registered_nodes[ 'default:pine_tree']) then
		mg_villages.grow_pinetree(   data, a, pos, snow);
		return true;
	-- an acacia tree; it does not have its own grow function
	elseif( plant_id == cid.c_asapling and minetest.registered_nodes[ 'default:acacia_tree']) then
		data[ a:index( pos.x, pos.y, pos.z )] = cid.c_asapling;
		return true;
	-- a savannatree from the mg mod
	elseif( plant_id == cid.c_savannasapling and mg_villages.add_savannatree) then
		mg_villages.add_savannatree(         data, a, pos.x, pos.y, pos.z, minp, maxp, pr) -- TODO: snow
		return true;
	-- a pine tree from the mg mod
	elseif( plant_id == cid.c_pinesapling    and mg_villages.add_pinetree   ) then
		mg_villages.add_pinetree(            data, a, pos.x, pos.y, pos.z, minp, maxp, pr) -- TODO: snow
		return true;
	end
	return false;
end


-- places trees and plants at empty spaces
mg_villages.village_area_fill_with_plants = function( village_area, villages, minp, maxp, data, param2_data, a, cid )
	-- do not place any plants if we are working on the mapchunk above
	if( minp.y > 0 ) then
		return;
	end
	-- trees which require grow functions to be called
	cid.c_savannasapling  = minetest.get_content_id( 'mg:savannasapling');
	cid.c_pinesapling     = minetest.get_content_id( 'mg:pinesapling');
	-- add farmland
	cid.c_wheat           = minetest.get_content_id( 'farming:wheat_8' );
	cid.c_cotton          = minetest.get_content_id( 'farming:cotton_8' );
	cid.c_shrub           = minetest.get_content_id( 'default:dry_shrub');
	-- these extra nodes are used in order to avoid abms on the huge fields around the villages
	cid.c_soil_wet        = minetest.get_content_id( 'mg_villages:soil' ); --'farming:soil_wet' );
	cid.c_soil_sand       = minetest.get_content_id( 'mg_villages:desert_sand_soil'); --'farming:desert_sand_soil_wet' );
	-- desert sand soil is only available in minetest_next
	if( not( cid.c_soil_sand )) then
		cid.c_soil_sand = cid.c_soil_wet;
	end
	local c_feldweg         = minetest.get_content_id( 'cottages:feldweg');
	if( not( c_feldweg )) then
		c_feldweg = cid.c_dirt_with_grass;
	end

	if( mg_villages.realtest_trees ) then
		cid.c_soil_wet        = minetest.get_content_id( 'farming:soil' ); -- TODO: the one from mg_villages would be better...but that one lacks textures
		cid.c_soil_sand       = minetest.get_content_id( 'farming:soil' ); -- TODO: the one from mg_villages would be better...but that one lacks textures
		cid.c_wheat           = minetest.get_content_id( 'farming:spelt_4' );
		cid.c_cotton          = minetest.get_content_id( 'farming:flax_4' );
--		cid.c_shrub           = minetest.get_content_id( 'default:dry_shrub');
	end

	local pr = PseudoRandom(mg_villages.get_bseed(minp));
	for x = minp.x, maxp.x do
		for z = minp.z, maxp.z do
			-- turn unused land (which is either dirt or desert sand) into a field that grows wheat
			if( village_area[ x ][ z ][ 2 ]==1 
			 or village_area[ x ][ z ][ 2 ]==6) then

				local village_nr = village_area[ x ][ z ][ 1 ];
				local village    = villages[ village_nr ];
				local h = village.vh;
				local g = data[a:index( x, h, z )];

				-- choose a plant/tree with a certain chance
				-- Note: There are no checks weather the tree/plant will actually grow there or not;
				--       Tree type is derived from wood type used in the village
				local plant_id = data[a:index( x, h+1, z)];
				local on_soil  = false;
				local plant_selected = false;
				local has_snow_cover = false;
				for _,v in ipairs( village.to_add_data.plantlist ) do
					if( plant_id == cid.c_snow or g==cid.c_dirt_with_snow or g==cid.c_snowblock) then
						has_snow_cover = true;
					end
					-- select the first plant that fits; if the node is not air, keep what is currently inside
					if( (plant_id==cid.c_air or plant_id==cid.c_snow) and (( v.p == 1 or pr:next( 1, v.p )==1 ))) then
						-- TODO: check if the plant grows on that soil
						plant_id = v.id;
						plant_selected = true;
					end
					-- wheat and cotton require soil
					if( plant_id == cid.c_wheat or plant_id == cid.c_cotton ) then
						on_soil = true;
					end
				end

				local pos = {x=x, y=h+1, z=z};
				if( not( plant_selected )) then -- in case there is something there already (usually a tree trunk)
					has_snow_cover = nil;

				elseif( mg_villages.grow_a_tree( pos, plant_id, minp, maxp, data, a, cid, pr, has_snow_cover )) then
					param2_data[a:index( x, h+1, z)] = 0; -- make sure the tree trunk is not rotated
					has_snow_cover = nil; -- else the sapling might not grow
					-- nothing to do; the function has grown the tree already
	
				-- grow wheat and cotton on normal wet soil (and re-plant if it had been removed by mudslide)
				elseif( on_soil and (g==cid.c_dirt_with_grass or g==cid.c_soil_wet or g==cid.c_dirt_with_snow)) then	
					param2_data[a:index( x, h+1, z)] = math.random( 1, 179 );
					data[a:index( x,  h,   z)] = cid.c_soil_wet;
					-- no plants in winter
					if( has_snow_cover and mg_villages.use_soil_snow) then
						data[a:index( x,  h+1, z)] = cid.c_msnow_soil;
						has_snow_cover = nil;
					else
						data[a:index( x,  h+1, z)] = plant_id;
					end

				-- grow wheat and cotton on desert sand soil - or on soil previously placed (before mudslide overflew it; same as above)
				elseif( on_soil and (g==cid.c_desert_sand or g==cid.c_soil_sand) and cid.c_soil_sand and cid.c_soil_sand > 0) then
					param2_data[a:index( x, h+1, z)] = math.random( 1, 179 );
					data[a:index( x,  h,   z)] = cid.c_soil_sand;
					-- no plants in winter
					if( has_snow_cover and mg_villages.use_soil_snow) then
						data[a:index( x,  h+1, z)] = cid.c_msnow_soil;
						has_snow_cover = nil;
					else
						data[a:index( x,  h+1, z)] = plant_id;
					end

				elseif( on_soil ) then
					if( math.random(1,5)==1 ) then
						data[a:index( pos.x,  pos.y, pos.z)] = cid.c_shrub;
					end

				elseif( plant_id ) then -- place the sapling or plant (moretrees uses spawn_tree)
					data[a:index( pos.x,  pos.y, pos.z)] = plant_id;
				end

				-- put a snow cover on plants where needed
				if( has_snow_cover and cid.c_msnow_1 ~= cid.c_ignore) then
					data[a:index( x,  h+2, z)] = cid.c_msnow_1;
				end
			end
		end
	end
end




time_elapsed = function( t_last, msg )
	mg_villages.t_now = minetest.get_us_time();
	mg_villages.print( mg_villages.DEBUG_LEVEL_TIMING, 'TIME ELAPSED: '..tostring( mg_villages.t_now - t_last )..' '..msg );
	return mg_villages.t_now;
end


mg_villages.save_data = function()
	save_restore.save_data( 'mg_all_villages.data', mg_villages.all_villages );
end


mg_villages.place_villages_via_voxelmanip = function( villages, minp, maxp, vm, data, param2_data, a, top, seed )
	local t1 = minetest.get_us_time();

	local cid = {}
	cid.c_air    = minetest.get_content_id( 'air' );
	cid.c_ignore = minetest.get_content_id( 'ignore' );
	cid.c_stone  = minetest.get_content_id( 'default:stone');
	cid.c_dirt   = minetest.get_content_id( 'default:dirt');
	cid.c_snow   = minetest.get_content_id( 'default:snow');
	cid.c_snowblock   = minetest.get_content_id( 'default:snowblock');
	cid.c_dirt_with_snow  = minetest.get_content_id( 'default:dirt_with_snow' );
	cid.c_dirt_with_grass = minetest.get_content_id( 'default:dirt_with_grass' );
	cid.c_desert_sand = minetest.get_content_id( 'default:desert_sand' ); -- PM v
	cid.c_desert_stone  = minetest.get_content_id( 'default:desert_stone');
	cid.c_sand = minetest.get_content_id( 'default:sand' ); 
	cid.c_tree = minetest.get_content_id( 'default:tree');
	cid.c_sapling = minetest.get_content_id( 'default:sapling');
	cid.c_jtree = minetest.get_content_id( 'default:jungletree');
	cid.c_jsapling = minetest.get_content_id( 'default:junglesapling');
	cid.c_ptree = minetest.get_content_id( 'default:pine_tree');
	cid.c_psapling = minetest.get_content_id( 'default:pine_sapling');
	cid.c_atree    = minetest.get_content_id( 'default:acacia_tree');
	cid.c_asapling = minetest.get_content_id( 'default:acacia_sapling');
	cid.c_water = minetest.get_content_id( 'default:water_source'); -- PM ^
	cid.c_stone_with_coal = minetest.get_content_id( 'default:stone_with_coal');
	cid.c_sandstone       = minetest.get_content_id( 'default:sandstone');

	cid.c_msnow_1  = minetest.get_content_id( 'moresnow:snow_top' );
	cid.c_msnow_2  = minetest.get_content_id( 'moresnow:snow_fence_top');
	cid.c_msnow_3  = minetest.get_content_id( 'moresnow:snow_stair_top');
	cid.c_msnow_4  = minetest.get_content_id( 'moresnow:snow_slab_top');
	cid.c_msnow_5  = minetest.get_content_id( 'moresnow:snow_panel_top');
	cid.c_msnow_6  = minetest.get_content_id( 'moresnow:snow_micro_top');
	cid.c_msnow_7  = minetest.get_content_id( 'moresnow:snow_outer_stair_top');
	cid.c_msnow_8  = minetest.get_content_id( 'moresnow:snow_inner_stair_top');
	cid.c_msnow_9  = minetest.get_content_id( 'moresnow:snow_ramp_top');	
	cid.c_msnow_10 = minetest.get_content_id( 'moresnow:snow_ramp_outer_top');
	cid.c_msnow_11 = minetest.get_content_id( 'moresnow:snow_ramp_inner_top');
	cid.c_msnow_soil=minetest.get_content_id( 'moresnow:snow_soil' );

	cid.c_ice      = minetest.get_content_id( 'default:ice' );

	cid.c_plotmarker = minetest.get_content_id( 'mg_villages:plotmarker');

	if( minetest.get_modpath('ethereal')) then
		cid.c_ethereal_clay_red    = minetest.get_content_id( 'bakedclay:red' );
		cid.c_ethereal_clay_orange = minetest.get_content_id( 'bakedclay:orange' );
	end
	

	t1 = time_elapsed( t1, 'defines' );

	local village_noise = minetest.get_perlin(7635, 3, 0.5, 16);

	-- determine which coordinates are inside the village and which are not
	local village_area = {};

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
			mg_villages.village_area_mark_buildings(   village_area, village_nr, village.to_add_data.bpos );
			-- will set village_area to N where .. is:
			--  8: a dirt road
			mg_villages.village_area_mark_dirt_roads(  village_area, village_nr, village.to_add_data.dirt_roads );
		else -- mark the terrain below single houses
			mg_villages.village_area_mark_buildings(   village_area, village_nr, village.to_add_data.bpos );
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

		data = vm:get_data()
		param2_data = vm:get_param2_data()
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
	t1 = time_elapsed( t1, 'get_height' );

	mg_villages.village_area_get_height( village_area, villages, tmin, tmax, data, param2_data, a, cid );
	-- the villages in the first mapchunk are set to a fixed height of 1 so that players will not end up embedded in stone
	if( not( mg_villages.all_villages ) or mg_villages.anz_villages < 1 ) then
		villages[1].optimal_height = 1;
	end


	-- change height of those villages where an optimal_height could be determined
	local village_data_updated = false;
	for _,village in ipairs(villages) do
		if( village.optimal_height and village.optimal_height > 0 and village.optimal_height ~= village.vh ) then
			-- towers are usually found on elevated places
			if( village.village_type == 'tower' ) then
				village.optimal_height = village.optimal_height + math.max( math.floor(village.vs/2), 2 );
			end
			mg_villages.change_village_height( village, village.optimal_height );
			village_data_updated = true;
		end
	end
	t1 = time_elapsed( t1, 'change_height' );

	--mg_villages.flatten_village_area( villages, minp, maxp, vm, data, param2_data, a, village_area, cid );
	mg_villages.flatten_village_area( villages, tmin, tmax, vm, data, param2_data, a, village_area, cid );
	t1 = time_elapsed( t1, 'flatten_village_area' );
	-- repair cavegen griefings and mudflow which may have happened in the outer shell (which is part of other mapnodes)
	local e1 = {x=minp.x,y=minp.y,z=minp.z};
	local e2 = {x=maxp.x,y=maxp.y,z=maxp.z};
	mg_villages.repair_outer_shell(   villages, {x=tmin.x,   y=tmin.y,z=tmin.z},    {x=tmin.x+16, y=tmax.y, z=tmax.z}, vm, data, param2_data, a, village_area, cid, e1, e2 );
	mg_villages.repair_outer_shell(   villages, {x=tmax.x-16,y=tmin.y,z=tmin.z},    {x=tmax.x,    y=tmax.y, z=tmax.z}, vm, data, param2_data, a, village_area, cid, e1, e2 );
	mg_villages.repair_outer_shell(   villages, {x=tmin.x+16,y=tmin.y,z=tmin.z},    {x=tmax.x-16, y=tmax.y, z=tmin.z+16}, vm, data, param2_data, a, village_area, cid, e1, e2 );
	mg_villages.repair_outer_shell(   villages, {x=tmin.x+16,y=tmin.y,z=tmax.z-16}, {x=tmax.x-16, y=tmax.y, z=tmax.z},    vm, data, param2_data, a, village_area, cid, e1, e2 );
--	mg_villages.repair_outer_shell(   villages, tmin, tmax, vm, data, param2_data, a, village_area, cid );

	t1 = time_elapsed( t1, 'repair_outer_shell' );

	local c_feldweg =  minetest.get_content_id('cottages:feldweg');
	if( not( c_feldweg )) then
		c_feldweg = minetest.get_content_id('default:cobble');
	end

	for _, village in ipairs(villages) do

		-- the village_id will be stored in the plot markers
		local village_id = tostring( village.vx )..':'..tostring( village.vz );
		village.anz_buildings = mg_villages.count_inhabitated_buildings(village);
		village.to_add_data = handle_schematics.place_buildings( village, tmin, tmax, data, param2_data, a, cid, village_id);

		handle_schematics.place_dirt_roads(                village, tmin, tmax, data, param2_data, a, c_feldweg);

		-- grow trees which are part of buildings into saplings
		for _,v in ipairs( village.to_add_data.extra_calls.trees ) do
			mg_villages.grow_a_tree( v, v.typ, minp, maxp, data, a, cid, nil, v.snow ); -- TODO: supply pseudorandom value?
		end
	end
	t1 = time_elapsed( t1, 'place_buildings and place_dirt_roads' );

	mg_villages.village_area_fill_with_plants( village_area, villages, tmin, tmax, data, param2_data, a, cid );
	t1 = time_elapsed( t1, 'fill_with_plants' );

	if( mg_villages.CREATE_HIGHLANDPOOLS ) then
		mg_villages.do_highlandpools(minp, maxp, seed, vm, a, data, village_area);
	end
	t1 = time_elapsed( t1, 'create highlandpools' );

	vm:set_data(data)
	vm:set_param2_data(param2_data)
	t1 = time_elapsed( t1, 'vm data set' );

	-- only update lighting where we actually placed the nodes
	vm:calc_lighting( e1, e2 ); --minp, maxp ); --tmin, tmax)
	t1 = time_elapsed( t1, 'vm calc lighting' );

	vm:write_to_map(data)
	t1 = time_elapsed( t1, 'vm data written' );

	vm:update_liquids()
	t1 = time_elapsed( t1, 'vm update liquids' );

	-- do on_construct calls AFTER the map data has been written - else i.e. realtest fences can not update themshevles
	for _, village in ipairs(villages) do
		for k, v in pairs( village.to_add_data.extra_calls.on_constr ) do
			local node_name = minetest.get_name_from_content_id( k );
			if( minetest.registered_nodes[ node_name ].on_construct ) then
				for _, pos in ipairs(v) do
					minetest.registered_nodes[ node_name ].on_construct( pos );
				end
			end
		end
	end

	local pr = PseudoRandom(mg_villages.get_bseed(minp));
	for _, village in ipairs(villages) do
		for _,v in ipairs( village.to_add_data.extra_calls.chests ) do
			local building_nr  = village.to_add_data.bpos[ v.bpos_i ];
			local building_typ = mg_villages.BUILDINGS[ building_nr.btype ].scm;
			mg_villages.fill_chest_random( v, pr, building_nr, building_typ );
		end
	end
	-- TODO: extra_calls.signs

	
	-- useful for spawning mobs etc.
	for _, village in ipairs(villages) do
		mg_villages.part_of_village_spawned( village, minp, maxp, data, param2_data, a, cid );
	end

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
			village.extra_calls = {}; -- do not save these values
			village.nr = count;
			mg_villages.anz_villages = count;
			mg_villages.all_villages[ village_id ] = minetest.deserialize( minetest.serialize( village ));

			mg_villages.print( mg_villages.DEBUG_LEVEL_NORMAL, "Village No. "..tostring( count ).." of type \'"..
					tostring( village.village_type ).."\' of size "..tostring( village.vs )..
					" spawned at: x = "..village.vx..", z = "..village.vz)
			village_data_updated = true;

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

	-- if this mapchunk contains no part of a village, probably a lone building may be found in it
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
		mg_villages.place_villages_via_voxelmanip( villages, minp, maxp, nil, nil,  nil, nil, nil, seed );
	end
end)


