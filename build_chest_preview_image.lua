

-- creates a 2d preview image (or rather, the data structure for it) of the building
-- internal function
build_chest.preview_image_create_one_view = function( data, side )
	local params   = {1, data.size.x, 1, 1, data.size.z,  1, 0, 0};
	if(     side==1 ) then
		params = {1, data.size.x, 1, 1, data.size.z,  1, 0, 0};
	elseif( side==2 ) then
		params = {1, data.size.z, 1, 1, data.size.x,  1, 1, 1};
	elseif( side==3 ) then
		params = {1, data.size.x, 1, data.size.z, 0, -1, 0, 1};
	elseif( side==4 ) then
		params = {1, data.size.z, 1, data.size.x, 0, -1, 1, 0};
	end

	local preview = {};
	for y = 1, data.size.y do
		preview[ y ] = {};
		for x = params[1], params[2], params[3] do
			local found = nil;
			local z = params[4];
			local target_x = x;
			if( params[8]==1 ) then
				target_x = math.max( params[1],params[2] )- x;
			end
			while( not( found ) and z~= params[5]) do
				local node = -1;
				if( params[7]==0 ) then
					node = data.scm_data_cache[y][x][z];
				else
					node = data.scm_data_cache[y][z][x];
				end
				if( node and node[1]
				   and data.nodenames[ node[1] ]
				   and data.nodenames[ node[1] ] ~= 'air'
 				   and data.nodenames[ node[1] ] ~= 'ignore'
 				   and data.nodenames[ node[1] ] ~= 'mg:ignore' 
 				   and data.nodenames[ node[1] ] ~= 'default:torch' ) then
					-- a preview node is only set if there's no air there
					preview[y][target_x] = node[1];
					found = 1;
				end
				z = z+params[6];
			end
			if( not( found )) then
				preview[y][target_x] = -1;
			end
		end
	end
	return preview;
end

-- internal function
build_chest.preview_image_create_view_from_top = function( data )
	local preview = {};
	for z = 1, data.size.z do
		preview[ z ] = {};
		for x = 1, data.size.x do
			local found = nil;
			local y = data.size.y;
			while( not( found ) and y > 1) do
				local node = data.scm_data_cache[y][x][z];
				if( node and node[1]
				   and data.nodenames[ node[1] ]
				   and data.nodenames[ node[1] ] ~= 'air'
 				   and data.nodenames[ node[1] ] ~= 'ignore'
 				   and data.nodenames[ node[1] ] ~= 'mg:ignore' 
 				   and data.nodenames[ node[1] ] ~= 'default:torch' ) then
					-- a preview node is only set if there's no air there
					preview[z][x] = node[1];
					found = 1;
				end
				y = y-1;
			end
			if( not( found )) then
				preview[z][x] = -1;
			end
		end
	end
	return preview;
end


-- function called by the build chest to display one view
build_chest.preview_image_formspec = function( building_name, replacements, side_name )
	if(  not( building_name )
	  or not( build_chest.building[ building_name ] )
	  or not( build_chest.building[ building_name ].preview )) then
		return "";
	end

	local side_names = {"front","right","back","left","top"};
	local side = 1;
	for i,v in ipairs( side_names ) do
		if( side_name and side_name==v ) then
			side = i;
		end
	end

	local formspec = "";
	for i=1,5 do
		if( i ~= side ) then
			formspec = formspec.."button["..tostring(3.3+1.2*(i-1))..
				",2.2;1,0.5;preview;"..side_names[i].."]";
		else
			formspec = formspec.."label["..tostring(3.3+1.2*(i-1))..",2.2;"..side_names[i].."]";
		end
	end

	local data = build_chest.building[ building_name ];	

	-- the mg_villages.draw_tile function is based on content_id
	local content_ids = {};
	for i,v in ipairs( data.nodenames ) do
		local found = false;
		for j,w in ipairs( replacements ) do
			if( w and w[1] and w[1]==v) then
				found        = true;
				if( minetest.registered_nodes[ w[2]] ) then
					content_ids[ i ] = minetest.get_content_id( w[2] );
				end
			end
		end
		if( not( found )) then
			if( minetest.registered_nodes[ v ]) then
				content_ids[ i ] = minetest.get_content_id( v );
			elseif( v ~= 'air' ) then
				content_ids[ i ] = -1;
			end
		end
	end

	local scale = 0.5;

	local tile_nr = 3; -- view from the side
	if( side ~= 5 ) then
		local scale_y = 6.0/data.size.y;
		local scale_z = 10.0/data.size.z;
		if( scale_y > scale_z) then
			scale = scale_z;
		else
			scale = scale_y;
		end
	else
		local scale_x = 10.0/data.size.x;  -- only relevant for view from top
		local scale_z = 6.0/data.size.z;
		if( scale_x > scale_z) then
			scale = scale_z;
		else
			scale = scale_x;
		end
		tile_nr = 1; -- view from top
	end

	if( not( side )) then
		side = 1;
	end
	local preview = data.preview[ side ];
	for y,y_values in ipairs( preview ) do
		for l,v in ipairs( y_values ) do
			-- air, ignore and mg:ignore are not stored
			if(     v and content_ids[ v ]==-1 ) then
				formspec = formspec..mg_villages.draw_tile( nil, "unknown_node.png", (l*scale), 9-(y*scale), scale*1.3, scale*1.2, tile_nr);
			elseif( v and v>0 and content_ids[v]) then
				formspec = formspec..mg_villages.draw_tile( content_ids[ v ], nil,   (l*scale), 9-(y*scale), scale*1.3, scale*1.2, tile_nr);
			end
		end
	end
	return formspec;
end
	

-- create all five preview images
build_chest.preview_image_create_views = function( res, orients )

	-- create a 2d overview image (or rather, the data structure for it)
	local preview        = {
			build_chest.preview_image_create_one_view( res, 2 ), 
			build_chest.preview_image_create_one_view( res, 1 ),
			build_chest.preview_image_create_one_view( res, 4 ),
			build_chest.preview_image_create_one_view( res, 3 )};

	-- the building might be stored in rotated form
	if( orients and #orients and orients[1] ) then
		if(     orients[1]==1 ) then
			preview = {preview[2],preview[3],preview[4],preview[1]};
		elseif( orients[1]==2 ) then
			preview = {preview[3],preview[4],preview[1],preview[2]};
		elseif( orients[1]==3 ) then
			preview = {preview[4],preview[1],preview[2],preview[3]};
		end
	end
	-- ...and add a preview image from top
	preview[5] = build_chest.preview_image_create_view_from_top( res );
	return preview;
end




-- this function makes sure that the building will always extend to the right and in front of the build chest
