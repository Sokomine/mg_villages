
-- helper function for mg_villages.analyze_building_for_mobs_update_paths
-- "res" is the raw data as provided by analyze_file
-- "node_name" is the name of the node we are looking for
mg_villages.analyze_building_for_mobs_search_nodes = function( res, node_name, check_place_for_standing )
	local node_positions = {};
	-- find out if the building contains any of the nodes we are looking for
	local found = -1;
	for i,n in ipairs( res.nodenames ) do
		if( n == node_name ) then
			found = i;
		end
	end
	-- that node does not exist in the building
	if( found == -1 ) then
		return {};
	end

	for z = 1, res.size.z do
	for y = 1, res.size.y do
	for x = 1, res.size.x do
		if(  res.scm_data_cache[y]
		 and res.scm_data_cache[y][x]
	         and res.scm_data_cache[y][x][z]
		 and res.scm_data_cache[y][x][z][1] == found ) then

			if( (check_place_for_standing==false)
) then
--			 or (   mob_world_interaction.can_stand_in_node_type( TODO )
--			    and mob_world_interaction.can_stand_in_node_type( TODO ))) then
				table.insert( node_positions, {x=x, y=y, z=z, p2=res.scm_data_cache[y][x][z][2]});
			end
		end
	end
	end
	end
	return node_positions;
end




-- changes path_info and adds paths from beds and workplaces to front of building
--   path_info[ short_file_name ] contains the paths from the beds
--   path_info[ short_file_name.."|WORKPLACE" ] contains the paths from the workplaces
-- creates building_data.all_entrances
-- creates building_data.workplace_list
mg_villages.analyze_building_for_mobs_update_paths = function( file_name, building_data, path_info )

	local short_file_name = string.sub(file_name, mg_villages.file_name_offset, 256);
	building_data.short_file_name = short_file_name;

	if( not( minetest.get_modpath( "mob_world_interaction" ))) then
		return building_data;
	end

	-- identify front doors and paths to them from the beds
	-- TODO: provide a more general list with beds, work places etc.
	if( building_data.bed_list
	  and #building_data.bed_list > 0 ) then
		if(not( path_info[ short_file_name ])) then
			print("BEDS in "..tostring( short_file_name )..":");
			path_info[ short_file_name ] = mob_world_interaction.find_all_front_doors( building_data, building_data.bed_list );
		end
		-- we are looking for the places in front of the front doors; not the front doors themshelves
		building_data.all_entrances = {};
		for i,e in ipairs( path_info[ short_file_name ] ) do
			-- the last entry in the list for the first bed is what we are looking for
			-- (provided there actually is a path)
			if( e[1] and #e[1]>0 ) then
				table.insert( building_data.all_entrances, e[1][ #e[1] ]);
			end
		end
	end

	-- some buildings (i.e. a tavern, school, shop, church, ...) contain places where a mob working
	-- there will most likely be standing, awaiting his guests/doing his job. Such places can be
	-- manually marked by placing mg_villages:mob_workplace_marker

	-- this is diffrent information from the normal bed list
	local store_as = short_file_name.."|WORKPLACE";
	if(not( path_info[ store_as ] )) then
		local workplace_list = mg_villages.analyze_building_for_mobs_search_nodes( building_data, "mg_villages:mob_workplace_marker", false );

		if( workplace_list and #workplace_list>0) then
			-- store it for later use
			building_data.workplace_list = workplace_list;

			print("WORKPLACE: "..tostring( building_data.short_file_name )..": "..minetest.serialize( workplace_list ));
			path_info[ store_as ] = mob_world_interaction.find_all_front_doors( building_data, workplace_list );

			-- if no entrances are known yet, then store them now; the entrances associated with
			-- beds are considered to be more important. This here is only a fallback if no beds
			-- exist in the house.
			if( not( building_data.all_entrances )) then
				-- we are looking for the places in front of the front doors; not the front doors themshelves
				building_data.all_entrances = {};
				for i,e in ipairs( path_info[ store_as ] ) do
					-- might just be the place outside the house instead of a door
					if( e[1] and #e[1]>0 ) then
						table.insert( building_data.all_entrances, e[1][ #e[1] ]);
					end
				end
			end
--		else
--			print("NO workplace found in "..tostring(building_data.short_file_name ));
		end
	end

--[[
TODO: check if 2 nodes above the target node are air or walkable;
TODO: exceptions to that: bench (only 1 above needs to be walkable)
TODO: other exceptions: furnace, chests, washing place: place in front is wanted - not on top
TODO: search for:
	local pos_list = mg_villages.analyze_building_for_mobs_search_nodes( building_data, "farming:soil_wet", true );
farming:soil   farming:soil_wet
cottages:straw_ground
default:chest cottages:shelf cottages:chest_storage  cottages:chest_private cottages:chest_work
cottages:bench (cottages:table?)
cottages:washing
default:furnace
cottages:barrel (and variants); cottages:tub

default:ladder
default:fence_wood cottages:gate_closed cottages:gate_open
any door...
any hatch...
--]]

	-- some debug information
	if( mg_villages.DEBUG_LEVEL and mg_villages.DEBUG_LEVEL == mg_villages.DEBUG_LEVEL_TIMING ) then
		local str2 = " in "..short_file_name.." ["..building_data.typ.."]";
		if(   not( path_info[ short_file_name ] )
		  and not( path_info[ store_as ] )) then
			str2 = "nothing of intrest (no bed, no workplace)"..str2;
		elseif( path_info[ short_file_name ]
		   and (#path_info[ short_file_name ]<1
		     or #path_info[ short_file_name ][1]<1
		     or #path_info[ short_file_name ][1][1]<1 )) then
			str2 = "BROKEN paths for beds"..str2;
		elseif( path_info[ store_as        ]
		   and (#path_info[ store_as        ]<1
		     or #path_info[ store_as        ][1]<1
		     or #path_info[ store_as        ][1][1]<1 )) then
			str2 = "BROKEN paths for workplaces"..str2;
		else
			if( path_info[ store_as ] ) then
				str2 = tostring( #path_info[ store_as ][1]-1 )..
					" workplaces"..str2;
			else
				str2 = "no workplaces"..str2;
			end
			if( path_info[ short_file_name ] ) then
				str2 = tostring( #path_info[ short_file_name ][1]-1 )..
					" beds and "..str2;
			else
				str2 = "no beds and "..str2;
			end
		end
		print( str2 );
	end
	return building_data;
end



-- Calls mg_villages.analyze_building_for_mobs_update_paths and evaluates the output:
-- * determines the position of front doors (building_data.front_door_list)
-- * position of beds (building_data.bed_list)
-- * places where mobs can stand when they got up from their bed or want
--   to go to bed (building_data.stand_next_to_bed_list)
-- * amount of usable beds in the house (building_data.bed_count)
-- * position of workplaces where a currently working mob may want to
--   stand (i.e. behind a shop's counter, next to a machine, in front
--   of the class/congregation, ..) (building_data.workplace_list)
-- Returns: Updated building_data with the values mentionned above set.
-- 	building_data	Information about the building as gained from registration
-- 	                and from handle_schematics.analze_file(..)
--      file_name       with complete path to the schematic
--      path_info       Data structure where path_info (paths from doors to beds etc.)
--                      is cached.
mg_villages.analyze_building_for_mobs = function( building_data, file_name, path_info )

	-- identify front doors, calculate paths from beds/workplaces to front of house
	building_data = mg_villages.analyze_building_for_mobs_update_paths( file_name, building_data, path_info );

	-- building_data.bed_list and building_data.workspace_list are calculated withhin
	-- the above function - provided they are not part of path_info yet;
	-- the information stored in path_info is the relevant one for mob movement/pathfinding

	-- store the front doors in extra list
	building_data.front_door_list = {};
	-- gain the list of beds from path_info data
	building_data.bed_list = {};
	-- mobs are seldom able to stand directly on or even next to the bed when getting up
	building_data.stand_next_to_bed_list = {};
	-- have any beds been found?
	if( building_data.short_file_name
	 and path_info[ building_data.short_file_name ] ) then
		local paths = path_info[ building_data.short_file_name];
		if( paths and paths[1] ) then
			-- iterate over all bed-to-first-front-door-paths (we want to identify beds)
			for i,p in ipairs( paths[1] ) do
				-- the last entry has a diffrent meaning
				if( p and p[1] and i<#paths[1]) then
					-- param2 is the 5th parameter
					building_data.bed_list[i] = {p[1][1],p[1][2],p[1][3],p[1][5]};
					-- also store where the mob may stand
					if( p[2] ) then
						building_data.stand_next_to_bed_list[i] = p[2];
					end
				end
			end
			-- iterate over all paths and take a look at the first bed only (we want to
			-- get the doors now, not the beds)
			for i,p in ipairs( paths ) do
				-- paths[i]: paths from all beds to front door i
				-- paths[i][1]: path from first bed to front door i
				if( p and p[1] and p[1][ #p[1] ]) then
					-- the place in front of the door is the last entry
					local d = p[1][ #p[1] ];
					building_data.front_door_list[i] = {d[1],d[2],d[3]};
				end
			end
		end
	end
	-- make sure this refers to the same data as building_data.bed_list
	building_data.bed_count = #building_data.bed_list;

	-- gain the list of workplaces from the path_info data
	building_data.workplace_list = {};
	-- have any workplaces been found?
	if( building_data.short_file_name
	 and path_info[ building_data.short_file_name.."|WORKPLACE" ] ) then
		local paths = path_info[ building_data.short_file_name.."|WORKPLACE"];
		if( paths and paths[1] ) then
			for i,p in ipairs( paths[1] ) do
				if( p and p[1] and i<#paths[1]) then
					building_data.workplace_list[i] = {p[1][1],p[1][2],p[1][3],p[1][4]};
				end
			end
			-- no front doors found through beds? then take a look if the workplaces found doors
			if( #building_data.front_door_list < 1 ) then
				for i,p in ipairs( paths ) do
					if( p and p[1] ) then
						local d = p[1][ #p[1] ];
						building_data.front_door_list[i] = {d[1],d[2],d[3]};
					end
				end
			end
		end
	end
	return building_data;
end
