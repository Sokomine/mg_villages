
-- pos needs to be a position either on a road or at max 1 node away from a road
mg_villages.get_path_from_pos_to_plot = function( village_id, pos, target_plot_nr )
	if( not( mg_villages.all_villages[ village_id ] )) then
		return {};
	end
	local bpos_list = mg_villages.all_villages[ village_id ].to_add_data.bpos;

	local standing_on_road = nil;
	local roads = mg_villages.get_road_list( village_id );
	for i,road in ipairs( roads ) do
		local r = bpos_list[ road ]; -- road data
		-- if this is really a road, and if a parent road exists (or is 0)
		if( r --and r.btype == "road" and r.parent_road
		-- ..and pos is in the area of the road or next to it
		    and pos.x >= r.x-1 and pos.x <= r.x + r.bsizex + 1
		    and pos.z >= r.z-1 and pos.z <= r.z + r.bsizez + 1
		    and pos.y >= r.y-4 and pos.y <= r.y + 4 ) then
			standing_on_road = i;
		end
	end
	-- nothing found
	if( not( standing_on_road )) then
minetest.chat_send_player("singleplayer",":-( no road found for "..minetest.pos_to_string( pos ).."\nroads: "..minetest.serialize( roads ));
		return;
	end
minetest.chat_send_player("singleplayer","ROAD: "..minetest.serialize( bpos_list[ roads[standing_on_road ]]));
end

-- try to reconstruct the tree-like road network structure (the data was
-- not saved completely from the beginning)
mg_villages.get_road_list = function( village_id )
	if( not( mg_villages.all_villages[ village_id ] )) then
		return {};
	end
	local bpos_list = mg_villages.all_villages[ village_id ].to_add_data.bpos;
	local roads = {};
	for i,pos in ipairs( bpos_list ) do
		if( pos.btype and pos.btype=="road" ) then
			-- store the plot nr for each road nr
			roads[ pos.road_nr ] = i;
			-- store weather the road streches in x- or z-direction
			if( pos.bsizex >= pos.bsizez) then
				pos.xdir = true;
			else
				pos.xdir = false;
			end
		end
	end
	-- the parent roads have already been identified
	if( bpos_list[ roads[ 1 ]].parent_road_plot == 0 ) then
		return roads;
	end

	-- assume that road nr. 1 is the main road (which it is due to the way villages are constructed)
	bpos_list[ roads[ 1 ]].parent_road_plot = 0;

	-- identify all parent roads
	for i=1,#roads do
		if( bpos_list[ roads[i] ].parent_road_plot ) then
			mg_villages.mark_roads_that_branch_off( bpos_list, roads, roads[i] );
		end
	end

	return roads;
end
	

-- changes bpos_list and sets bpos_list[ road ].parent_road_plot = plot_nr for those roads where
-- plot_nr contains the road from which road branches off
mg_villages.mark_roads_that_branch_off = function( bpos_list, roads, plot_nr )
	-- see which roads branch off from this parent road
	local parent_road = bpos_list[ plot_nr ];
	for i,road in ipairs( roads ) do
		local r = bpos_list[ road ]; -- road data
		-- if the road is not yet connected to another one
		if(    r.parent_road_plot == nil
		-- and if it is 90 degree rotated compared to the potential parent road
		  and( r.xdir ~= parent_road.xdir )
		-- and if one end lies inside the parent road
		  and( (r.x          >= parent_road.x and r.x          <= parent_road.x + parent_road.bsizex)
		     or(r.x+r.bsizex >= parent_road.x and r.x+r.bsizex <= parent_road.x + parent_road.bsizex))
		  and( (r.z          >= parent_road.z and r.z          <= parent_road.z + parent_road.bsizez)
		     or(r.z+r.bsizez >= parent_road.z and r.z+r.bsizez <= parent_road.z + parent_road.bsizez))) then

			-- store plot_nr instead of road_nr as that is more useful
			bpos_list[ road ].parent_road_plot = plot_nr;
		end
	end
end


