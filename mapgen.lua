
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


mg_villages.inside_village = function(x, z, village, vnoise)
        return mg_villages.get_vn(x, z, vnoise:get2d({x = x, y = z}), village) <= 40
end

mg_villages.inside_village_area = function(x, z, village, vnoise)
        return mg_villages.get_vn(x, z, vnoise:get2d({x = x, y = z}), village) <= 80
end

mg_villages.get_vnoise = function(x, z, village, vnoise) -- PM v
        return mg_villages.get_vn(x, z, vnoise:get2d({x = x, y = z}), village)
end -- PM ^

mg_villages.get_vn = function(x, z, noise, village)
        local vx, vz, vs = village.vx, village.vz, village.vs
        return (noise - 2) * 20 +
                (40 / (vs * vs)) * ((x - vx) * (x - vx) + (z - vz) * (z - vz))
end


mg_villages.villages_in_mapchunk = function( minp )
	local noise1raw = minetest.get_perlin(12345, 6, 0.5, 256)
	
	local vcr = mg_villages.VILLAGE_CHECK_RADIUS
	local villages = {}
	local generate_new_villages = true;
	for xi = -vcr, vcr do
	for zi = -vcr, vcr do
		for _, village in ipairs(mg_villages.villages_at_point({x = minp.x + xi * 80, z = minp.z + zi * 80}, noise1raw)) do
			village.to_grow = {}
			villages[#villages+1] = village
		end
		-- check if the village exists already
		local v_nr = 1;
		for v_nr, village in ipairs(villages) do
			local village_id = tostring( village.vx )..':'..tostring( village.vz );
			if( mg_villages.all_villages and mg_villages.all_villages[ village_id ]) then
				villages[ v_nr ] = mg_villages.all_villages[ village_id ];
				generate_new_villages = false;
			end
		end
	end
	end
	return villages;
end


mg_villages.node_is_ground = {}; -- store nodes which have previously been identified as ground

mg_villages.check_if_ground = function( ci )

	-- pre-generate a list of no-ground-nodes for caching
	if( #mg_villages.node_is_ground < 1 ) then
		local no_ground_nodes = {'air','ignore','default:sandstonebrick','default:cactus','default:wood','default:junglewood'};
		for _,name in ipairs( no_ground_nodes ) do
			mg_villages.node_is_ground[ minetest.get_content_id( name )] = false;
		end
	end

	if( not( ci )) then
		return false;
	end
	if( mg_villages.node_is_ground[ ci ]) then
		return true;
	end
	-- analyze the node
	-- only nodes on which walking is possible may be counted as ground
	local node_name = minetest.get_name_from_content_id( ci );
	local def = minetest.registered_nodes[ node_name ];	
	if( def and def.walkable == true and def.is_ground_content == true) then
		-- store information about this node type for later use
		mg_villages.node_is_ground[ ci ] = true;
		return true;
	end
end


-- sets evrything at x,z and above height target_height to air;
-- the area below gets filled up in a suitable way (i.e. dirt with grss - dirt - stone)
mg_villages.lower_or_raise_terrain_at_point = function( x, z, target_height, minp, maxp, vm, data, param2_data, a, cid )

	local surface_node  = nil;
	local has_snow      = false;
	local tree          = false;
	local jree          = false;
	local old_height    = maxp.y;
	y = maxp.y;
	-- search for a surface and set everything above target_height to air
	while( y > minp.y) do
		local ci = data[a:index(x, y, z)];
		if(     ci == cid.c_snow ) then
			has_snow = true;
		elseif( ci == cid.c_tree ) then
			tree  = true;
		elseif( ci == cid.c_jtree ) then
			jtree = true;
		elseif( not( surface_node) and ci ~= cid.c_air and ci ~= cid.c_ignore and mg_villages.check_if_ground( ci ) == true) then
			-- we have found a surface of some kind
			surface_node = ci;
			old_height   = y;
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

	if( not( surface_node ) or surface_node == cid.c_dirt) then
		surface_node = cid.c_dirt_with_grass;
	end
	local below_1 = cid.c_dirt;
	local below_2 = cid.c_stone;
	if(     surface_node == cid.c_desert_sand ) then
		below_1 = cid.c_desert_sand;
		below_2 = cid.c_desert_stone;
	elseif( surface_node == cid.c_sand ) then
		below_1 = cid.c_sand;
		below_2 = cid.c_stone;
	else
		below_1 = cid.c_dirt;
		below_2 = cid.c_stone;
	end
	
	if( has_snow ) then
		data[       a:index( x, target_height+1, z)] = cid.c_snow;
	end
	data[               a:index( x, target_height,   z)] = surface_node;
	if( target_height-1 >= minp.y ) then
		data[       a:index( x, target_height-1, z)] = below_1;
	end

	-- not every column will get a coal block; some may get two
	local coal_height1 = math.random( minp.y, maxp.y );
	local coal_height2 = math.random( minp.y, maxp.y );
	y = target_height-2;
	while( y > minp.y and y > target_height-40 ) do
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
mg_villages.flatten_village_area = function( villages, village_noise, minp, maxp, vm, data, param2_data, a, village_area, cid )
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		for _, village in ipairs(villages) do
			local n_village = mg_villages.get_vnoise(x, z, village, village_noise) -- PM
			if( village_area[ x ][ z ][ 2 ] > 0 and data[a:index(x,village.vh,z)] ~= cid.c_ignore) then -- inside a village
				mg_villages.lower_or_raise_terrain_at_point( x, z, village.vh, minp, maxp, vm, data, param2_data, a, cid );

			elseif (mg_villages.ENABLE_TERRAIN_BLEND and n_village <= 160) then -- PM v
				local blend = ((n_village - 80) / 80) ^ 2 -- 0 at village edge, 1 at normal terrain
				local ysurf = 1 -- y of surface
				local surfnod -- surface node id
				local tree = false -- bools for replanting trees as saplings
				local jcount = 0 -- count jungle trunks to avoid planting saplings where roots were
				local jtree = false
				for y = maxp.y, minp.y, -1 do -- detect ground and trees, remove trees
					local vi = a:index(x, y, z)
					local nodid = data[vi]
					if nodid == cid.c_tree then
						tree = true
					elseif nodid == cid.c_jtree then
						jcount = jcount + 1
					end
					if nodid == cid.c_dirt -- if ground detected
					or nodid == cid.c_dirt_with_grass
					or nodid == cid.c_stone
					or nodid == cid.c_desert_sand
					or nodid == cid.c_desert_stone
					or nodid == cid.c_sand then
						ysurf = y
						surfnod = nodid
						break
					elseif y > 1 then
						data[vi] = cid.c_air -- remove trees but not water
					end
				end
				if jcount > 1 then -- if jungle trunk detected
					jtree = true
				end

				local n_rawnoise = village_noise:get2d({x = x, y = z}) -- create new blended terrain
				local yblend = ysurf
				if n_rawnoise > 0 then -- leave some cliffs unblended
					yblend = math.floor(village.vh + blend * (ysurf - village.vh))
				end
				if yblend > 3 and surfnod == cid.c_sand then -- no beach above y = 3
					surfnod = cid.c_dirt_with_grass
				end
				local step = -1;
				if( ysurf < yblend - 2 ) then
					step = 1;
					-- better blending for the farming land
					yblend = yblend + 1;
				end
				-- this loop only does something if ysurf > village.vh
				for y = ysurf, yblend + (2*step), step do
					local vi = a:index(x, y, z)
					if y == yblend + 1 then -- plant saplngs to replace trees
						if tree then
							data[vi] = cid.c_sapling
						elseif jtree then
							data[vi] = cid.c_jsapling
						elseif y < 0 then
							data[vi] = cid.c_water
						else
							data[vi] = cid.c_air
						end
					elseif y > yblend then
						if y <= 1 then
							data[vi] = cid.c_water
						else
							data[vi] = cid.c_air
						end
					else
						-- when raising terrain, two nodes will remain the surface node type
						if(     step == 1 and y < yblend-1 ) then
							if(     surfnod == cid.c_desert_sand ) then
								data[vi] = cid.c_desert_stone;
							else 
								data[vi] = cid.c_stone;
							end
						elseif( step == 1 and y == yblend and surfnod == cid.c_dirt ) then
							data[vi] = cid.c_dirt_with_grass;
						else
							data[vi] = surfnod
						end
						if surfnod == cid.c_dirt_with_grass then
							surfnod = cid.c_dirt
						end
					end
				end
			end -- PM ^
		end
	end
	end
end


-- TODO: limit this function to the shell in order to speed things up
-- repair mapgen griefings
mg_villages.repair_outer_shell = function( villages, village_noise, minp, maxp, vm, data, param2_data, a, village_area, cid )
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		-- inside a village
		if( village_area[ x ][ z ][ 2 ] > 0 ) then
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
			while( y < village.vh+40 and y < maxp.y ) do
				local ci = data[a:index(x, y, z)];
				if( ci ~= cid.c_ignore and (ci==cid.c_dirt or ci==cid.c_dirt_with_grass or ci==cid.c_sand or ci==cid.c_desert_sand)) then
					data[a:index(x,y,z)] = cid.c_air;
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

				for village_nr, village in ipairs(villages) do
					if( mg_villages.inside_village_area(x, z, village, village_noise)) then
						village_area[ x ][ z ] = { village_nr, 1};
					end
				end
			end
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
			    and ( village_area[ x+1 ][ z   ][ 2 ] == 0
			       or village_area[ x-1 ][ z   ][ 2 ] == 0 
			       or village_area[  x  ][ z+1 ][ 2 ] == 0 
			       or village_area[  x  ][ z-1 ][ 2 ] == 0 )
			  -- if the corners of the mapblock are inside the village area, they may count as borders here as well
			  or ( x==minp.x+1 and village_area[ x-1 ][ z   ][ 1 ] ~= 0 )
			  or ( x==maxp.x-1 and village_area[ x+1 ][ z   ][ 1 ] ~= 0 )
			  or ( z==minp.z-1 and village_area[ x   ][ z-1 ][ 1 ] ~= 0 )
			  or ( z==maxp.z+1 and village_area[ x   ][ z+1 ][ 1 ] ~= 0 )) then

				y = maxp.y;
				while( y > minp.y and y >= 0) do
					local ci = data[a:index(x, y, z)];
					if( ci ~= cid.c_air and ci ~= cid.c_ignore and mg_villages.check_if_ground( ci ) == true) then
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
		if( village.optimal_height ) then
		-- villages above a size of 40 are *always* place at a convenient height of 1
		elseif( village.vs >= 40 ) then
			village.optimal_height = 2;
		elseif( village.vs >= 30 ) then
			village.optimal_height = 40 - village.vs;
		elseif( village.vs >= 25 ) then
			village.optimal_height = 35 - village.vs;
		
		-- if no border height was found, there'd be no point in calculating anything;
		-- also, this is done only if the village has its center inside this mapchunk	
		elseif(  height_count[ village_nr ] > 0 ) then
--		    and village.vx >= minp.x and village.vx <= maxp.x
----		    and village.vh >= minp.y and village.vh <= maxp.y  -- the height is what we're actually looking for here
--		    and village.vz >= minp.z and village.vz <= maxp.z ) then

			local ideal_height = math.floor( height_sum[ village_nr ] / height_count[ village_nr ]);
print('For village_nr '..tostring( village_nr )..', a height of '..tostring( ideal_height )..' would be optimal. Sum: '..tostring( height_sum[ village_nr ] )..' Count: '..tostring( height_count[ village_nr ])..'. VS: '..tostring( village.vs)); -- TODO

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
				qmw = math.floor( math.sqrt( qmw / height_count[ village_nr ]) +0.5); -- round the value
			else
				qmw = 0; -- if in doubt, a height of 0 usually works well
			end

			village.optimal_height = qmw;

			print('Majority vote for '..tostring( village_nr )..' is: '..tostring( target )..' with '..tostring( max )..' counts. Details: '..minetest.serialize( height_statistic[ village_nr] ).." QMW: "..tostring( qmw ));
		end
	end
end



mg_villages.change_village_height = function( village, new_height )
print('CHANGING HEIGHT from '..tostring( village.vh )..' to '..tostring( new_height ));
	for _, pos in ipairs(village.to_add_data.bpos) do
		pos.y = new_height;
	end
	for _, pos in ipairs(village.to_add_data.dirt_roads) do
		pos.y = new_height;
	end
	village.vh = new_height;
end



-- places trees and plants at empty spaces
mg_villages.village_area_fill_with_plants = function( village_area, villages, minp, maxp, data, param2_data, a, cid )
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
	local c_water_source    = minetest.get_content_id( 'default:water_source');
	local c_clay            = minetest.get_content_id( 'default:clay');
	local c_feldweg         = minetest.get_content_id( 'cottages:feldweg');
	if( not( c_feldweg )) then
		c_feldweg = cid.c_dirt_with_grass;
	end


	local pr = PseudoRandom(mg_villages.get_bseed(minp));
	for x = minp.x, maxp.x do
		for z = minp.z, maxp.z do
			-- turn unused land (which is either dirt or desert sand) into a field that grows wheat
			if( village_area[ x ][ z ][ 2 ]==1 ) then

				local village_nr = village_area[ x ][ z ][ 1 ];
				local village    = villages[ village_nr ];
				local h = village.vh;
				local g = data[a:index( x, h, z )];

				-- choose a plant/tree with a certain chance
				-- Note: There are no checks weather the tree/plant will actually grow there or not;
				--       Tree type is derived from wood type used in the village
				local plant_id = data[a:index( x, h+1, z)];
				local on_soil  = false;
				for _,v in ipairs( village.to_add_data.plantlist ) do
					-- select the first plant that fits; if the node is not air, keep what is currently inside
					if( plant_id==cid.c_air and (( v.p == 1 or pr:next( 1, v.p )==1 ))) then
						-- TODO: check if the plant grows on that soil
						plant_id = v.id;
						-- wheat and cotton require soil
						if( plant_id == cid.c_wheat or plant_id == cid.c_cotton ) then
							on_soil = true;
						end
					end
				end

				local pos = {x=x, y=h+1, z=z};
				-- a normal tree; sometimes comes with apples
				if(     plant_id == cid.c_sapling ) then
					default.grow_tree(       data, a, pos, math.random(1, 4) == 1, math.random(1,100000))
				-- a normal jungletree
				elseif( plant_id == cid.c_jsapling ) then
					default.grow_jungletree( data, a, pos, math.random(1,100000))
				-- a savannatree from the mg mod
				elseif( plant_id == cid.c_savannasapling and add_savannatree) then
					add_savannatree(         data, a, pos.x, pos.y, pos.z, minp, maxp, pr)
				-- a pine tree from the mg mod
				elseif( plant_id == cid.c_pinesapling    and add_pinetree   ) then
					add_pinetree(            data, a, pos.x, pos.y, pos.z, minp, maxp, pr)
	
				-- grow wheat and cotton on normal wet soil (and re-plant if it had been removed by mudslide)
				elseif( on_soil and (g==cid.c_dirt_with_grass or g==cid.c_soil_wet)) then	
					param2_data[a:index( x, h+1, z)] = math.random( 1, 179 );
					data[a:index( x,  h+1, z)] = plant_id;
					data[a:index( x,  h,   z)] = cid.c_soil_wet;
--[[
					-- avoid water spills if the neighbour nodes are not part of the field
					if(    x<maxp.x and village_area[ x+1 ][ z   ][ 2 ] == 1 and village_area[ x+1 ][ z   ][ 1 ]==village_nr 
					   and z<maxp.z and village_area[ x   ][ z+1 ][ 2 ] == 1 and village_area[ x   ][ z+1 ][ 1 ]==village_nr 
					   and x>minp.x and village_area[ x-1 ][ z   ][ 2 ] == 1 and village_area[ x-1 ][ z   ][ 1 ]==village_nr 
					   and z>minp.z and village_area[ x   ][ z-1 ][ 2 ] == 1 and village_area[ x   ][ z-1 ][ 1 ]==village_nr ) then
						data[a:index( x,  h-1, z)] = c_water_source;
						data[a:index( x,  h-2, z)] = c_clay;
					else
						data[a:index( x,  h-1, z)] = cid.c_dirt;
						data[a:index( x,  h-2, z)] = cid.c_dirt;
					end
--]]

				-- grow wheat and cotton on desert sand soil - or on soil previously placed (before mudslide overflew it; same as above)
				elseif( on_soil and (g==cid.c_desert_sand or g==cid.c_soil_sand) and cid.c_soil_sand and cid.c_soil_sand > 0) then
					param2_data[a:index( x, h+1, z)] = math.random( 1, 179 );
					data[a:index( x,  h+1, z)] = plant_id;
					data[a:index( x,  h,   z)] = cid.c_soil_sand;
--[[
					-- avoid water spills if the neighbour nodes are not part of the field
					if(    x<maxp.x and village_area[ x+1 ][ z   ][ 2 ] == 1 and village_area[ x+1 ][ z   ][ 1 ]==village_nr 
					   and z<maxp.z and village_area[ x   ][ z+1 ][ 2 ] == 1 and village_area[ x   ][ z+1 ][ 1 ]==village_nr 
					   and x>minp.x and village_area[ x-1 ][ z   ][ 2 ] == 1 and village_area[ x-1 ][ z   ][ 1 ]==village_nr 
					   and z>minp.z and village_area[ x   ][ z-1 ][ 2 ] == 1 and village_area[ x   ][ z-1 ][ 1 ]==village_nr ) then
						data[a:index( x,  h-1, z)] = c_clay;      -- so that desert sand soil does not fall down
						data[a:index( x,  h-2, z)] = c_water_source;
						data[a:index( x,  h-3, z)] = c_clay;
					else
						data[a:index( x,  h-1, z)] = cid.c_desert_stone;
						data[a:index( x,  h-2, z)] = cid.c_desert_stone;
					end
--]]
	
				elseif( on_soil ) then
					if( math.random(1,5)==1 ) then
						data[a:index( pos.x,  pos.y, pos.z)] = cid.c_shrub;
					end

				elseif( plant_id ) then -- place the sapling or plant (moretrees uses spawn_tree)
					data[a:index( pos.x,  pos.y, pos.z)] = plant_id;
				end
			end
		end
	end
end




mg_villages.place_villages_via_voxelmanip = function( villages, minp, maxp, vm, data, param2_data, a, top )
	local cid = {}
	cid.c_air    = minetest.get_content_id( 'air' );
	cid.c_ignore = minetest.get_content_id( 'ignore' );
	cid.c_stone  = minetest.get_content_id( 'default:stone');
	cid.c_dirt   = minetest.get_content_id( 'default:dirt');
	cid.c_snow   = minetest.get_content_id( 'default:snow');
	cid.c_dirt_with_grass = minetest.get_content_id( 'default:dirt_with_grass' );
	cid.c_desert_sand = minetest.get_content_id( 'default:desert_sand' ); -- PM v
	cid.c_desert_stone  = minetest.get_content_id( 'default:desert_stone');
	cid.c_sand = minetest.get_content_id( 'default:sand' ); 
	cid.c_tree = minetest.get_content_id( 'default:tree');
	cid.c_sapling = minetest.get_content_id( 'default:sapling');
	cid.c_jtree = minetest.get_content_id( 'default:jungletree');
	cid.c_jsapling = minetest.get_content_id( 'default:junglesapling');
	cid.c_water = minetest.get_content_id( 'default:water_source'); -- PM ^
	cid.c_stone_with_coal = minetest.get_content_id( 'default:stone_with_coal');


	
--[[
	local centered_here = 0;
	for _,village in ipairs( villages ) do
		if(   village.vx >= minp.x and village.vx <= maxp.x 
		  and village.vh >= minp.y and village.vh <= maxp.y 
		  and village.vz >= minp.z and village.vz <= maxp.z ) then
			village.center_in_this_mapchunk = true;
			centered_here = centered_here + 1;
		else
			village.center_in_this_mapchunk = false;
		end
	end
	if( centered_here < 1 ) then
		return; -- TODO
	end
--]]

	local village_noise = minetest.get_perlin(7635, 3, 0.5, 16);

	-- determine which coordinates are inside the village and which are not
	local village_area = {};

	for village_nr, village in ipairs(villages) do
		-- generate the village structure: determine positions of buildings and roads
		mg_villages.generate_village( village, village_noise);

		mg_villages.village_area_mark_buildings(   village_area, village_nr, village.to_add_data.bpos );
		mg_villages.village_area_mark_dirt_roads(  village_area, village_nr, village.to_add_data.dirt_roads );
        end

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

	-- all vm manipulation functions write their content to the *entire* volume/area - including those 16 nodes that
	-- extend into neighbouring mapchunks; thus, cavegen griefing and mudflow can be repaired by placing everythiing again
	local tmin = emin;
	local tmax = emax;
	-- if set to true, cavegen eating through houses and mudflow on roofs will NOT be repaired
	if( not( mg_villages.UNDO_CAVEGEN_AND_MUDFLOW )) then
		tmin = minp;
		tmax = maxp;
	end
	mg_villages.village_area_mark_inside_village_area( village_area, villages, village_noise, tmin, tmax );

	-- determine optimal height for all villages that have their center in this mapchunk; sets village.optimal_height
	mg_villages.village_area_get_height( village_area, villages, tmin, tmax, data, param2_data, a, cid );
	-- change height of those villages where an optimal_height could be determined
	for _,village in ipairs(villages) do
		if( village.optimal_height and village.optimal_height >= 0 and village.optimal_height ~= village.vh ) then
			mg_villages.change_village_height( village, village.optimal_height );
		end
	end


	mg_villages.flatten_village_area( villages, village_noise, minp, maxp, vm, data, param2_data, a, village_area, cid );
	-- repair cavegen griefings and mudflow which may have happened in the outer shell (which is part of other mapnodes)
	mg_villages.repair_outer_shell(   villages, village_noise, tmin, tmax, vm, data, param2_data, a, village_area, cid );

	local c_feldweg =  minetest.get_content_id('cottages:feldweg');
	if( not( c_feldweg )) then
		c_feldweg = minetest.get_content_id('default:cobble');
	end

	for _, village in ipairs(villages) do

		village.to_add_data = mg_villages.place_buildings( village, tmin, tmax, data, param2_data, a, village_noise);

		mg_villages.place_dirt_roads(                      village, tmin, tmax, data, param2_data, a, village_noise, c_feldweg);
	end

	mg_villages.village_area_fill_with_plants( village_area, villages, tmin, tmax, data, param2_data, a, cid );

	vm:set_data(data)
	vm:set_param2_data(param2_data)

	vm:calc_lighting(
		{x=minp.x-16, y=minp.y, z=minp.z-16},
		{x=maxp.x+16, y=maxp.y, z=maxp.z+16}
	)

	vm:write_to_map(data)

	-- initialize the pseudo random generator so that the chests will be filled in a reproducable pattern
	local pr = PseudoRandom(mg_villages.get_bseed(minp));
	local meta
	for _, village in ipairs(villages) do
		for _, n in pairs(village.to_add_data.extranodes) do
			minetest.set_node(n.pos, n.node)
			if n.meta ~= nil then
				meta = minetest.get_meta(n.pos)
				meta:from_table(n.meta)
				if n.node.name == "default:chest" then
					local inv = meta:get_inventory()
					local items = inv:get_list("main")
					for i=1, inv:get_size("main") do
						inv:set_stack("main", i, ItemStack(""))
					end
					local numitems = pr:next(3, 20) 
					for i=1,numitems do
						local ii = pr:next(1, #items) 
						local prob = items[ii]:get_count() % 2 ^ 8
						local stacksz = math.floor(items[ii]:get_count() / 2 ^ 8)
						if pr:next(0, prob) == 0 and stacksz>0 then
							stk = ItemStack({name=items[ii]:get_name(), count=pr:next(1, stacksz), wear=items[ii]:get_wear(), metadata=items[ii]:get_metadata()})
							local ind = pr:next(1, inv:get_size("main"))
							while not inv:get_stack("main",ind):is_empty() do
								ind = pr:next(1, inv:get_size("main"))
							end
							inv:set_stack("main", ind, stk)
						end
					end
				end
			end
		end

		-- now add those buildings which are .mts files and need to be placed by minetest.place_schematic(...)
		mg_villages.place_schematics( village.to_add_data.bpos, village.to_add_data.replacements, a, pr );

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
			village.nr = count;
			mg_villages.anz_villages = count;
			mg_villages.all_villages[ village_id ] = minetest.deserialize( minetest.serialize( village ));

			print("Village No. "..tostring( count ).." of type \'"..tostring( village.village_type ).."\' of size "..tostring( village.vs ).." spawned at: x = "..village.vx..", z = "..village.vz)
			save_restore.save_data( 'mg_all_villages.data', mg_villages.all_villages );
		end
	end
end



local function spawnplayer(player)
	local noise1 = minetest.get_perlin(12345, 6, 0.5, 256)
	local min_dist = math.huge
	local min_pos = {x = 0, y = 3, z = 0}
	for bx = -20, 20 do
	for bz = -20, 20 do
		local minp = {x = -32 + 80 * bx, y = -32, z = -32 + 80 * bz}
		for _, village in ipairs(mg_villages.villages_at_point(minp, noise1)) do
			if math.abs(village.vx) + math.abs(village.vz) < min_dist then
				min_pos = {x = village.vx, y = village.vh + 2, z = village.vz}
				min_dist = math.abs(village.vx) + math.abs(village.vz)
			end
		end
	end
	end
	player:setpos(min_pos)
end

minetest.register_on_newplayer(function(player)
	spawnplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	spawnplayer(player)
	return true
end)


-- the actual mapgen
-- It only does changes if there is at least one village in the area that is to be generated.
minetest.register_on_generated(function(minp, maxp, seed)
	-- only generate village on the surface chunks
	if( minp.y ~= -32 or minp.y < -32 or minp.y > 64) then
		return;
	end
	local villages = mg_villages.villages_in_mapchunk( minp );
	if( villages and #villages > 0 ) then
		mg_villages.place_villages_via_voxelmanip( villages, minp, maxp, nil, nil,  nil, nil, nil );
	end
end)


