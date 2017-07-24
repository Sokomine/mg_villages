
-- helper function for get_path_from_pos_to_plot
mg_villages.next_step_on_road_path = function( p, this_road_xdir, following_road )
	if( this_road_xdir == true ) then
		if( p.x < following_road.x ) then
			p.x = following_road.x;
		else
			p.x = following_road.x + following_road.bsizex -1;
		end
	else
		if( p.z < following_road.z ) then
			p.z = following_road.z;
		else
			p.z = following_road.z + following_road.bsizez -1;
		end
	end
	return p;
end


-- pos needs to be a position either on a road or at max 1 node away from a road
mg_villages.get_path_from_pos_to_plot_via_roads = function( village_id, pos, target_plot_nr )
	if(  not( mg_villages.all_villages[ village_id ] )
	  or not( target_plot_nr )
	  or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ target_plot_nr ])
	  or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ target_plot_nr ].road_nr)) then
		return {};
	end
	local bpos_list = mg_villages.all_villages[ village_id ].to_add_data.bpos;

	-- find out which road is the one next to pos
	local standing_on_road = nil;
	local roads = mg_villages.get_road_list( village_id, false );
	for i,road in ipairs( roads ) do
		local r = bpos_list[ road ]; -- road data
		-- if this is really a road, and if a parent road exists (or is 0)
		if( r and r.btype == "road" and r.parent_road_plot
		-- ..and pos is in the area of the road or next to it
		    and pos.x >= r.x-1 and pos.x <= r.x + r.bsizex + 1
		    and pos.z >= r.z-1 and pos.z <= r.z + r.bsizez + 1
		    and pos.y >= r.y-4 and pos.y <= r.y + 4 ) then
			standing_on_road = i;
		end
	end
	-- nothing found
	if( not( standing_on_road )) then
		return;
	end

	-- walk from pos up to the main road
	local start_to_main_road = {};
	local next_road_plot = roads[ standing_on_road ];
	while( next_road_plot and bpos_list[ next_road_plot ] and bpos_list[ next_road_plot ].btype=="road" ) do
		table.insert( start_to_main_road, next_road_plot );
		next_road_plot = bpos_list[ next_road_plot ].parent_road_plot;
	end

	-- walk from the target road up to the main road - until we find a road that is
	-- already part of the path from pos to the main road
	local target_to_main_road = {};
	local next_road_plot = roads[ bpos_list[ target_plot_nr ].road_nr ];
	local match_found = -1;
	while( next_road_plot and bpos_list[ next_road_plot ] and bpos_list[ next_road_plot ].btype=="road" and match_found==-1) do
		-- it may not be necessary to go all the way back to the main road
		for i,r in ipairs( start_to_main_road ) do
			if( r == next_road_plot ) then
				match_found = i;
			end
		end
		if( match_found == -1) then
			table.insert( target_to_main_road, next_road_plot );
		end
		next_road_plot = bpos_list[ next_road_plot ].parent_road_plot;
	end

	if( match_found == -1 ) then
		match_found = #start_to_main_road;
	end
	-- we may have gone too far up and can take a turn much earlier
	local start_to_target = {};
	for i=1,match_found do
		table.insert( start_to_target, start_to_main_road[i] );
	end

	-- combine the full walk through the tree-like road structure into one list of roads
	for i=#target_to_main_road,1,-1 do
		table.insert( start_to_target, target_to_main_road[i] );
	end

	-- generate a path for travelling on these roads
	local path = {};

	-- let the mob take the first step onto the road
	local first_road = bpos_list[ start_to_target[1] ];
	local p = {x=pos.x, y=first_road.y+1, z=pos.z};
	p = mg_villages.next_step_on_road_path( p, not(first_road.xdir), first_road );
	table.insert( path, {x=p.x, y=p.y, z=p.z} );

	-- travel using all the given roads
	for i=1,#start_to_target-1 do
		local this_road      = bpos_list[ start_to_target[i] ];
		local following_road = bpos_list[ start_to_target[i+1]];
		-- walk on the inside in curves instead of taking longer paths
		p = mg_villages.next_step_on_road_path( p, this_road.xdir, following_road );
		table.insert( path, {x=p.x, y=p.y, z=p.z} );
	end

	-- walk on the last road to the target plot
	local last_road = bpos_list[ start_to_target[ #start_to_target ] ];
	local target = {x=bpos_list[ target_plot_nr ].x + math.floor(bpos_list[ target_plot_nr ].bsizex/2),
			y = p.y,
			z=bpos_list[ target_plot_nr ].z + math.floor(bpos_list[ target_plot_nr ].bsizez/2),
			bsizex = 2, bsizez = 2};
	p = mg_villages.next_step_on_road_path( p, last_road.xdir, target);
	table.insert( path, {x=p.x, y=p.y, z=p.z} );

	-- take the very last step and leave the road
	p = mg_villages.next_step_on_road_path( p, not(last_road.xdir), target);
	-- make sure we do not walk further than one step into the plot
	if(     p.x <  last_road.x ) then
		p.x =  last_road.x - 1;
	elseif( p.x >= last_road.x + last_road.bsizex ) then
		p.x =  last_road.x + last_road.bsizex + 1;
	elseif( p.z <  last_road.z ) then
		p.z =  last_road.z - 1;
	elseif( p.z >= last_road.z + last_road.bsizez ) then
		p.z =  last_road.z + last_road.bsizez + 1;
	end
	table.insert( path, {x=p.x, y=p.y, z=p.z} );

--[[
	-- if you want to visualize the path with yellow wool blocks for debugging, uncomment this
	local str = " path: ";
	for i,p in ipairs( path ) do
		minetest.set_node( p, {name="wool:yellow"});
		str = str.." "..minetest.pos_to_string( p );
	end
	minetest.chat_send_player("singleplayer","roads to walk on: "..minetest.serialize( start_to_target)..str);
--]]
	return path;
end

-- try to reconstruct the tree-like road network structure (the data was
-- not saved completely from the beginning)
mg_villages.get_road_list = function( village_id, force_check )
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
	-- a village without roads (i.e. a single house)
	if( not( roads[1])) then
		return {};
	end
	-- the parent roads have already been identified
	if( not( force_check ) and bpos_list[ roads[ 1 ]].parent_road_plot == 0 ) then
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


