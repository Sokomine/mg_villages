
-- helper function for mg_villages.analyze_building_for_mobs
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




-- changes mg_villages.path_info and adds paths from beds and workplaces to front of building
--   mg_villages.path_info[ short_file_name ] contains the paths from the beds
--   mg_villages.path_info[ short_file_name.."|WORKPLACE" ] contains the paths from the workplaces
-- creates building_data.all_entrances
-- creates building_data.workplace_list
-- Note: parameter "res" is the raw data as provided by analyze_file
mg_villages.analyze_building_for_mobs = function( file_name, building_data, res )

	local short_file_name = string.sub(file_name, mg_villages.file_name_offset, 256);
	building_data.short_file_name = short_file_name;

	if( not( minetest.get_modpath( "mob_world_interaction" ))) then
		return building_data;
	end

	-- identify front doors and paths to them from the beds
	-- TODO: provide a more general list with beds, work places etc.
	if( building_data.bed_list
	  and #building_data.bed_list > 0 ) then
		if(not( mg_villages.path_info[ short_file_name ])) then
			print("BEDS in "..tostring( short_file_name )..":");
			mg_villages.path_info[ short_file_name ] = mob_world_interaction.find_all_front_doors( building_data, building_data.bed_list );
		end
		-- we are looking for the places in front of the front doors; not the front doors themshelves
		building_data.all_entrances = {};
		for i,e in ipairs( mg_villages.path_info[ short_file_name ] ) do
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
	if(not( mg_villages.path_info[ store_as ] )) then
		local workplace_list = mg_villages.analyze_building_for_mobs_search_nodes( res, "mg_villages:mob_workplace_marker", false );

		if( workplace_list and #workplace_list>0) then
			-- store it for later use
			building_data.workplace_list = workplace_list;

			print("WORKPLACE: "..tostring( building_data.short_file_name )..": "..minetest.serialize( workplace_list ));
			mg_villages.path_info[ store_as ] = mob_world_interaction.find_all_front_doors( building_data, workplace_list );

			-- if no entrances are known yet, then store them now; the entrances associated with
			-- beds are considered to be more important. This here is only a fallback if no beds
			-- exist in the house.
			if( not( building_data.all_entrances )) then
				-- we are looking for the places in front of the front doors; not the front doors themshelves
				building_data.all_entrances = {};
				for i,e in ipairs( mg_villages.path_info[ store_as ] ) do
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
	local pos_list = mg_villages.analyze_building_for_mobs_search_nodes( res, "farming:soil_wet", true );
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
		if(   not( mg_villages.path_info[ short_file_name ] )
		  and not( mg_villages.path_info[ store_as ] )) then
			str2 = "nothing of intrest (no bed, no workplace)"..str2;
		elseif( mg_villages.path_info[ short_file_name ]
		   and (#mg_villages.path_info[ short_file_name ]<1
		     or #mg_villages.path_info[ short_file_name ][1]<1
		     or #mg_villages.path_info[ short_file_name ][1][1]<1 )) then
			str2 = "BROKEN paths for beds"..str2;
		elseif( mg_villages.path_info[ store_as        ]
		   and (#mg_villages.path_info[ store_as        ]<1
		     or #mg_villages.path_info[ store_as        ][1]<1
		     or #mg_villages.path_info[ store_as        ][1][1]<1 )) then
			str2 = "BROKEN paths for workplaces"..str2;
		else
			if( mg_villages.path_info[ store_as ] ) then
				str2 = tostring( #mg_villages.path_info[ store_as ][1]-1 )..
					" workplaces"..str2;
			else
				str2 = "no workplaces"..str2;
			end
			if( mg_villages.path_info[ short_file_name ] ) then
				str2 = tostring( #mg_villages.path_info[ short_file_name ][1]-1 )..
					" beds and "..str2;
			else
				str2 = "no beds and "..str2;
			end
		end
		print( str2 );
	end
	return building_data;
end
