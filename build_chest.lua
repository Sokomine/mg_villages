-----------------------------------------------------------------------------------------------------------------
-- interface for manual placement of houses 
-----------------------------------------------------------------------------------------------------------------


-- functions specific to the build_chest are now stored in this table
build_chest = {};

-- scaffolding that will be placed instead of other nodes in order to show
-- how large the building will be
build_chest.SUPPORT = 'build_chest:support';


-- contains information about all the buildings
build_chest.building = {};

-- returns the id under which the building is stored
build_chest.add_building = function( file_name, data )
	if( not( file_name ) or not( data )) then
		return;
	end
	build_chest.building[ file_name ] = data;
end

-- that many options can be shown simultaneously on one menu page
build_chest.MAX_OPTIONS = 24; -- 3 columns with 8 entries each


build_chest.menu = {};
build_chest.menu.main = {};

-- create a tree structure for the menu
build_chest.add_entry = function( path )
	if( not( path ) or #path<1 ) then
		return;
	end

	local sub_menu = build_chest.menu;
	for i,v in ipairs( path ) do
		if( not( sub_menu[ v ] )) then
			sub_menu[ v ] = {};
		end
		sub_menu = sub_menu[ v ];
	end
end



-- helper function; sorts by the second element of the table
local function build_chest_comp(a,b)
	if (a[2] > b[2]) then
		return true;
	end
end

-- create a statistic about how frequent each node name occoured
build_chest.count_nodes = function( data )
	local statistic = {};
	-- make sure all node names are counted (air may sometimes be included without occouring)
	for id=1, #data.nodenames do
		statistic[ id ] = { id, 0};
	end

	for z = 1, data.size.z do
	for y = 1, data.size.y do
	for x = 1, data.size.x do

		local a = data.scm_data_cache[y][x][z];
		if( a ) then
			local id = 0;
			if( type( a )=='table' ) then
				id = a[1];
			else
				id = a;
			end
			statistic[ id ] = { id, statistic[ id ][ 2 ]+1 };
		end
	end
	end
	end
	table.sort( statistic, build_chest_comp );
	return statistic;
end


-- TODO: actually show the preview image somewhere
-- creates a 2d preview image (or rather, the data structure for it) of the building
build_chest.create_preview_image = function( data )
	local preview = {};
	for y = 1, data.size.y do
		preview[ y ] = {};
		for z = 1, data.size.z do
			local found = nil;
			local x = 1;
			while( not( found ) and x<= data.size.x ) do
				local node = data.scm_data_cache[y][x][z];
				if( node
				   and data.nodenames[ node ]
				   and data.nodenames[ node ] ~= 'air'
 				   and data.nodenames[ node ] ~= 'ignore'
 				   and data.nodenames[ node ] ~= 'mg:ignore' ) then
					-- a preview node is only set if there's no air there
					preview[y][z] = node;
				end
				x = x+1;
			end
		end
	end
	return preview;
end
	

build_chest.read_building = function( building_name )
	-- read data
	local res = handle_schematics.analyze_mts_file( building_name );
	if( not( res )) then
		return;
	end
	build_chest.building[ building_name ].size           = res.size;	
	build_chest.building[ building_name ].nodenames      = res.nodenames;	
	build_chest.building[ building_name ].rotated        = res.rotated;	
	build_chest.building[ building_name ].burried        = res.burried;	
	-- scm_data_cache is not stored as that would take up too much storage space
	--build_chest.building[ building_name ].scm_data_cache = res.scm_data_cache;	

	-- create a statistic about how often each node occours
	build_chest.building[ building_name ].statistic      = build_chest.count_nodes( res );

	-- create a 2d overview image (or rather, the data structure for it)
	build_chest.building[ building_name ].preview        = build_chest.create_preview_image( res );

	return true;
end


build_chest.get_replacement_extra_buttons = function( group, name, types_found_list, button_name, extra_buttons )
	-- find out if there are any nodes that may need a group replacement
	local found_type = "";
	for k,w in ipairs( replacements_group[ group ].all ) do
		-- we have found the full block of that group type
		if( name == w ) then
			found_type = w;
		-- no primary node found; there may still be subordinate types
		else
			for nr,t in ipairs( replacements_group[ group ].data[ w ] ) do
				if( name==t and not( types_found_list[ w ])) then
					found_type = w;
				end
			end
		end
	end
	if( found_type ~= "" and not( types_found_list[ found_type ])) then
		extra_buttons.offset = extra_buttons.offset + 1;
		extra_buttons.text = extra_buttons.text.."button[9.9,"..
				tostring( (extra_buttons.offset*0.9)+2.8 )..";3.0,0.5;"..
					tostring( button_name )..";"..
					minetest.formspec_escape( found_type ).."]";
		-- remember that we found and offered this type already; avoid duplicates
		types_found_list[ found_type ] = 1;
	end
	return extra_buttons;
end



build_chest.get_replacement_list_formspec = function( pos, selected_row )
	if( not( pos )) then
		return "";
	end
	local meta = minetest.env:get_meta( pos );
	local replacements  = minetest.deserialize( meta:get_string( 'replacements' ));
	local building_name = meta:get_string( 'building_name' );
	if( not( building_name ) or not( build_chest.building[ building_name ])) then
		return "";
	end
	local replace_row = meta:get_int('replace_row');

	local formspec = "tableoptions[" ..
				"color=#ff8000;" ..
				"background=#0368;" ..
				"border=true;" ..
				--"highlight=#00008040;" ..
				"highlight=#aaaaaaaa;" ..
				"highlight_text=#7fffff]" ..
			"tablecolumns[" ..
				"color;" ..
				"text,width=1,align=right;" ..
				"color;" ..
				"text,width=5;" ..
				"color;" ..
				"text,width=1;" ..
				"color;" ..
				"text,width=5]" ..
--			"tabheader["..
--				"1,1;columns;amount,original material,,target material;1;true;true]"..
			"table["..
				"0.5,2.7;9.4,6.8;build_chest_replacements;";

	local j=1;
	local may_proceed = true;
	local replace_row_material = nil;
	local replace_row_with     = "";
	-- make sure the statistic has been created
	if( not( build_chest.building[ building_name ].statistic )) then
		if( not( build_chest.read_building( building_name ))) then
			return "label[2,2;Error: Unable to read building file.]";
		end
	end

	-- used for setting wood type or plant(farming) type etc.
	local extra_buttons  = { text = "", offset = 0};
	-- there may be wood types that only occour as stairs and/or slabs etc., without full blocks
	local types_found_list_wood    = {};
	local types_found_list_farming = {};
	local types_found_list_roof    = {};

	for i,v in ipairs( build_chest.building[ building_name ].statistic ) do
		local name = build_chest.building[ building_name ].nodenames[ v[1]];	
		-- nodes that are to be ignored do not need to be replaced
		if( name ~= 'air' and name ~= 'ignore' and name ~= 'mg:ignore' and v[2] and v[2]>0) then
			local anz  = v[2];
			-- find out if this node name gets replaced
			local repl = name;
			for j,r in ipairs( replacements ) do
				if( r and r[1]==name ) then
					repl = r[2];
				end
			end

			-- avoid empty lines at the end
			if( i>1 ) then
				formspec = formspec..',';
			end

			formspec = formspec..'#fff,'..tostring( anz )..',';
			if( name == repl and repl and minetest.registered_nodes[ repl ]) then
				formspec = formspec.."#0ff,,#fff,,";
			else
				if( name and minetest.registered_nodes[ name ] ) then
					formspec = formspec.."#0f0,"; -- green
				else
					formspec = formspec.."#ff0,"; -- yellow
				end
				formspec = formspec..name..',#fff,'..minetest.formspec_escape('-->')..',';
			end

			if( repl and (minetest.registered_nodes[ repl ] or repl=='air') ) then
				formspec = formspec.."#0f0,"..repl; -- green
			else
				formspec = formspec.."#ff0,?"; -- yellow
				may_proceed = false; -- we need a replacement for this material
			end

			if( j == replace_row ) then
				replace_row_material = name;
				if( repl ~= name ) then
					replace_row_with     = repl;
				end
			end
			
			extra_buttons = build_chest.get_replacement_extra_buttons( 'wood',    name, types_found_list_wood,    'set_wood',    extra_buttons );
			extra_buttons = build_chest.get_replacement_extra_buttons( 'farming', name, types_found_list_farming, 'set_farming', extra_buttons );
			extra_buttons = build_chest.get_replacement_extra_buttons( 'roof',    name, types_found_list_farming, 'set_roof',    extra_buttons );

			j=j+1;
		end
	end
	formspec = formspec.."]";
	-- add the proceed-button as soon as all unkown materials have been replaced
	if( may_proceed ) then
		formspec = formspec.."button[9.9,9.0;2.0,0.5;proceed_with_scaffolding;Proceed]";
	end
	if( extra_buttons.text and extra_buttons.text ~= "" ) then
		formspec = formspec..extra_buttons.text..
			"label[9.9,2.8;Replace by type:]";
	end
	if( replace_row_material ) then
		formspec = formspec..
			"label[0.5,2.1;Replace "..
				minetest.formspec_escape( replace_row_material ).."]"..
			"label[6.5,2.1;with:]"..
			"field[7.5,2.4;4,0.5;replace_row_with;;"..
				minetest.formspec_escape( replace_row_with ).."]"..
			"field[-10,-10;0.1,0.1;replace_row_material;;"..
				minetest.formspec_escape( replace_row_material ).."]"..
			"button[11.1,2.1;1,0.5;store_replacement;Store]";
	end
	return formspec;
end


build_chest.apply_replacement = function( pos, meta, old_material, new_material )
	-- a new value has been entered - we do not need to remember the row any longer
	meta:set_int('replace_row', 0 );
	local found = false;
	-- only accept replacements which can actually be placed
	if( new_material=='air' or minetest.registered_nodes[ new_material ] ) then
		local replacements_orig  = minetest.deserialize( meta:get_string( 'replacements' ));
		for i,v in ipairs(replacements_orig) do
			if( v and v[1]==old_material ) then
				v[2] = new_material;
				found = true;
			end
		end
		if( not( found )) then
			table.insert( replacements_orig, { old_material, new_material });
		end
		-- store the new set of replacements
		meta:set_string( 'replacements', minetest.serialize( replacements_orig ));
	end
end
	

build_chest.get_group_list_formspec = function( pos, group, button_name )
	local formspec = "";
	for i,v in ipairs( replacements_group[ group ].found ) do
		formspec = formspec.."item_image_button["..tostring(((i-1)%8)+1)..","..
			tostring(3+math.floor((i-1)/8))..";1,1;"..
			tostring( v )..";"..tostring( button_name )..";"..tostring(i).."]";
	end
	return formspec;
end

 
build_chest.apply_replacement_for_group = function( pos, meta, group, selected, button_name )
	local nr = tonumber( selected );
	if( not(nr) or nr <= 0 or nr > #replacements_group[ group ].found ) then
		return;
	end	

	local new_material = replacements_group[ group ].found[ nr ];
	local old_material = meta:get_string( button_name );

	-- go back in the menu (even if the same material has been selected)
	meta:set_string( button_name, nil );

	if( old_material and old_material == new_material ) then
		return;
	end

	local replacements  = minetest.deserialize( meta:get_string( 'replacements' ));
	if( not( replacements )) then
		replacements = {};
	end
	replacements_group[ group ].replace_material( replacements, old_material, new_material );

	-- store the new set of replacements
	meta:set_string( 'replacements', minetest.serialize( replacements ));
end



-- this function makes sure that the building will always extend to the right and in front of the build chest
handle_schematics.translate_param2_to_rotation = function( param2, mirror, start_pos, orig_max, rotated, burried, orients )

	-- mg_villages stores available rotations of buildings in orients={0,1,2,3] format
	if( orients and #orients and orients[1]~=0) then
		if(     orients[1]==1 ) then
			rotated = rotated + 90;
		elseif( orients[1]==2 ) then
			rotated = rotated + 180;
		elseif( orients[1]==3 ) then
			rotated = rotated + 270;
		end
		if( rotated > 360 ) then
			rotated = rotated % 360;
		end
	end

	local max = {x=orig_max.x, y=orig_max.y, z=orig_max.z};
	-- if the schematic has been saved in a rotated way, swapping x and z may be necessary
	if( rotated==90 or rotated==270) then
		max.x = orig_max.z;
		max.z = orig_max.x;
	end

	-- the building may have a cellar or something alike
	if( burried > 0 ) then
		start_pos.y = start_pos.y - burried;
	end

	-- make sure the building always extends forward and to the right of the player
	local rotate = 0;
	if(     param2 == 0 ) then rotate = 270; if( mirror==1 ) then start_pos.x = start_pos.x - max.x + max.z; end -- z gets larger
	elseif( param2 == 1 ) then rotate =   0;    start_pos.z = start_pos.z - max.z; -- x gets larger  
	elseif( param2 == 2 ) then rotate =  90;    start_pos.z = start_pos.z - max.x;
	                       if( mirror==0 ) then start_pos.x = start_pos.x - max.z; -- z gets smaller 
	                       else                 start_pos.x = start_pos.x - max.x; end
	elseif( param2 == 3 ) then rotate = 180;    start_pos.x = start_pos.x - max.x; -- x gets smaller 
	end

	if(     param2 == 1 or param2 == 0) then
		start_pos.z = start_pos.z + 1;
	elseif( param2 == 1 or param2 == 2 ) then
		start_pos.x = start_pos.x + 1;
	end
	if( param2 == 1 ) then
		start_pos.x = start_pos.x + 1;
	end

	rotate = rotate + rotated;
	-- make sure the rotation does not reach or exceed 360 degree
	if( rotate >= 360 ) then
		rotate = rotate - 360;
	end
	-- rotate dimensions when needed
	if( param2==0 or param2==2) then
		local tmp = max.x;
		max.x = max.z;
		max.z = tmp;
	end

	return { rotate=rotate, start_pos = {x=start_pos.x, y=start_pos.y, z=start_pos.z},
				end_pos   = {x=(start_pos.x+max.x-1), y=(start_pos.y+max.y-1), z=(start_pos.z+max.z-1) },
				max       = {x=max.x, y=max.y, z=max.z}};
end



build_chest.get_start_pos = function( pos )
	-- rotate the building so that it faces the player
	local node = minetest.env:get_node( pos );
	local meta = minetest.env:get_meta( pos );

	local building_name = meta:get_string( 'building_name' );
	if( not( building_name )) then
		return;
	end
	if( not( build_chest.building[ building_name ] )) then
		return;
	end

	if( not( build_chest.building[ building_name ].size )) then
		if( not( build_chest.read_building( building_name ))) then
			return;
		end
	end
	local selected_building = build_chest.building[ building_name ];

	local mirror = 0; -- place_schematic does not support mirroring

	local start_pos = {x=pos.x, y=pos.y, z=pos.z};
	-- yoff(set) from mg_villages (manually given)
	if( selected_building.yoff ) then
		start_pos.y = start_pos.y + selected_building.yoff -1;
	end
	
	-- make sure the building always extends forward and to the right of the player
	local param2_rotated = handle_schematics.translate_param2_to_rotation( node.param2, mirror, start_pos,
				selected_building.size, selected_building.rotated, selected_building.burried, selected_building.orients );

	-- save the data for later removal/improvement of the building in the chest
	meta:set_string( 'start_pos',    minetest.serialize( param2_rotated.start_pos ));
	meta:set_string( 'end_pos',      minetest.serialize( param2_rotated.end_pos ));
	meta:set_string( 'rotate',       tostring(param2_rotated.rotate ));
	meta:set_int(    'mirror',       mirror );
	-- no replacements yet
	meta:set_string( 'replacements', minetest.serialize( {} ));
	return start_pos;
end
      




build_chest.update_formspec = function( pos, page, player )

   local meta = minetest.env:get_meta( pos );
   local current_path = minetest.deserialize( meta:get_string( 'current_path' ) or 'return {}' );
   local page_nr = meta:get_int( 'page_nr' );
   local material_type = meta:get_string( 'material_type');
   local village_name = meta:get_string( 'village' );
   local village_pos  = minetest.deserialize( meta:get_string( 'village_pos' ));
   local owner_name   = meta:get_string( 'owner' );

   -- distance from village center
   local distance = math.floor( math.sqrt( (village_pos.x - pos.x ) * (village_pos.x - pos.x ) 
                                         + (village_pos.y - pos.y ) * (village_pos.x - pos.y )
                                         + (village_pos.z - pos.z ) * (village_pos.x - pos.z ) ));

   local button_back = '';
   if( #current_path > 0 ) then
      button_back = "button[9.9,0.4;2,0.5;back;Back]";
   end
   local depth = #current_path;
   local formspec = "size[13,10]"..
                            "label[3.3,0.0;Building box]"..button_back.. -- - "..table.concat( current_path, ' -> ').."]"..
                            "label[0.3,0.4;Located at:]"      .."label[3.3,0.4;"..(minetest.pos_to_string( pos ) or '?')..", which is "..tostring( distance ).." m away]"
                                                              .."label[7.3,0.4;from the village center]".. 
                            "label[0.3,0.8;Part of village:]" .."label[3.3,0.8;"..(village_name or "?").."]"
                                                              .."label[7.3,0.8;located at "..(minetest.pos_to_string( village_pos ) or '?').."]"..
                            "label[0.3,1.2;Owned by:]"        .."label[3.3,1.2;"..(owner_name or "?").."]"..
                            "label[3.3,1.6;Click on a menu entry to select it:]";


	local building_name = meta:get_string('building_name' );
	if( building_name and building_name ~= '' and build_chest.building[ building_name ] and build_chest.building[ building_name ].size) then
		local size = build_chest.building[ building_name ].size;
		formspec = formspec..
				-- show which building has been selected
				"label[0.3,9.5;Selected building:]"..
				"label[2.3,9.5;"..minetest.formspec_escape(building_name).."]"..
				-- size of the building
				"label[0.3,9.8;Size ( w x l x h ):]"..
				"label[2.3,9.8;"..tostring( size.x )..' x '..tostring( size.z )..' x '..tostring( size.y ).."]";
	end


	if( page == 'main') then
		local start_pos     = meta:get_string('start_pos');

		local backup_file   = meta:get_string('backup');
		if( backup_file and backup_file ~= "" ) then
			formspec = formspec.."button[3,3;3,0.5;restore_backup;Restore original landscape]";
			meta:set_string('formspec', formspec );
			return;
		end

		local set_wood      = meta:get_string('set_wood' );
		if( set_wood and set_wood ~= "" ) then
			formspec = formspec..
				"label[1,2.2;Select replacement for "..tostring( set_wood )..".]"..
				"label[1,2.5;Trees, saplings and other blocks will be replaced accordingly as well.]"..
				build_chest.get_group_list_formspec( pos, 'wood',    'wood_selection' );
			meta:set_string('formspec', formspec );
			return;
		end

		local set_farming     = meta:get_string('set_farming' );
		if( set_farming and set_farming ~= "" ) then
			formspec = formspec..
				"label[1,2.5;Select the fruit the farm is going to grow:]"..
				build_chest.get_group_list_formspec( pos, 'farming', 'farming_selection' );
			meta:set_string('formspec', formspec );
			return;
		end

		local set_roof        = meta:get_string('set_roof' );
		if( set_roof and set_roof ~= "" ) then
			formspec = formspec..
				"label[1,2.5;Select a roof type for the house:]"..
				build_chest.get_group_list_formspec( pos, 'roof',    'roof_selection' );
			meta:set_string('formspec', formspec );
			return;
		end

		if( building_name and building_name ~= '' and start_pos and start_pos ~= '' and meta:get_string('replacements')) then
			formspec = formspec..build_chest.get_replacement_list_formspec( pos );
			meta:set_string('formspec', formspec );
			return;
		end

		-- find out where we currently are in the menu tree
		local menu = build_chest.menu;
		for i,v in ipairs( current_path ) do
			if( menu and menu[ v ] ) then
				menu = menu[ v ];
			end
		end

		-- all submenu points at this menu position are options that need to be shown
		local options = {};
		for k,v in pairs( menu ) do
			table.insert( options, k );
		end

		if( #options == 1 and options[1] and build_chest.building[ options[1]] ) then
			-- a building has been selected
			meta:set_string( 'building_name', options[1] );
			local start_pos = build_chest.get_start_pos( pos );
			if( start_pos and start_pos.x and build_chest.building[ options[1]].size) then
-- TODO: also show size and such
				-- do replacements for realtest where necessary (this needs to be done only once)
				local replacements = {};
				replacements_realtest.replace( replacements );
				meta:set_string( 'replacements', minetest.serialize( replacements ));

				formspec = formspec..build_chest.get_replacement_list_formspec( pos );
				meta:set_string('formspec', formspec );
				return;
			end
		end
		table.sort( options );

		-- if the options do not fit on a single page, split them up
		if( #options > build_chest.MAX_OPTIONS ) then 
			if( not( page_nr )) then
				page_nr = 0;
			end
			local new_options = {};
			local new_index   = build_chest.MAX_OPTIONS*page_nr;
			for i=1,build_chest.MAX_OPTIONS do
				if( options[ new_index+i ] ) then
					new_options[ i ] = options[ new_index+i ];
				end
			end

			-- we need to add prev/next buttons to the formspec
			formspec = formspec.."label[7.5,1.5;"..minetest.formspec_escape(
				"Showing "..tostring( new_index+1 )..
				       '-'..tostring( math.min( new_index+build_chest.MAX_OPTIONS, #options))..
				       '/'..tostring( #options )).."]";
			if( page_nr > 0 ) then
				formspec = formspec.."button[9.5,1.5;1,0.5;prev;prev]";
			end
			if( build_chest.MAX_OPTIONS*(page_nr+1) < #options ) then
				formspec = formspec.."button[11,1.5;1,0.5;next;next]";
			end
			options = new_options;
		end

      
                -- found an end node of the menu graph
--                elseif( build_chest.stages_formspec_page_first_stage ) then
--			formspec = build_chest.stages_formspec_page_first_stage( v.menu_path[( depth )], player, pos, meta, );
--                        meta:set_string( "formspec", formspec );
--                        return;
--                end

      local i = 0;
      local x = 0;
      local y = 0;
      if( #options < 9 ) then
         x = x + 4;
      end
      -- order alphabeticly
      table.sort( options, function(a,b) return a < b end );

      for index,k in ipairs( options ) do

         i = i+1;

         -- new column
         if( y==8 ) then
            x = x+4;
            y = 0;
         end

         formspec = formspec .."button["..(x)..","..(y+2.5)..";4,0.5;selection;"..k.."]"
         y = y+1;
         --x = x+4;
      end

   elseif( page == 'please_remove' ) then
		if( build_chest.stages_formspec_page_please_remove ) then
			formspec = build_chest.stages_formspec_page_please_remove( building_name, owner_name, village_name, village_pos, distance );
		end
   elseif( page == 'finished' ) then
		if( build_chest.stages_formspec_page_finished ) then
			formspec = build_chest.stages_formspec_page_finished(      building_name, owner_name, village_name, village_pos, distance );
		end
   end

   meta:set_string( "formspec", formspec );
end



-- TODO: check if it is the owner of the chest/village
build_chest.on_receive_fields = function(pos, formname, fields, player)

	local meta = minetest.env:get_meta(pos);
-- general menu handling
	-- back button selected
	if( fields.back ) then

		local current_path = minetest.deserialize( meta:get_string( 'current_path' ) or 'return {}' );

		table.remove( current_path ); -- revert latest selection
		meta:set_string( 'current_path', minetest.serialize( current_path ));
		meta:set_string( 'building_name', '');
		meta:set_string( 'set_wood',      '');
		meta:set_string( 'set_farming',   '');
		meta:set_string( 'set_roof',      '');
		meta:set_int(    'replace_row', 0 );
		meta:set_int(    'page_nr',     0 );
		build_chest.update_formspec( pos, 'main', player );

	-- menu entry selected
	elseif( fields.selection ) then

		local current_path = minetest.deserialize( meta:get_string( 'current_path' ) or 'return {}' );
		table.insert( current_path, fields.selection );
		meta:set_string( 'current_path', minetest.serialize( current_path ));
		build_chest.update_formspec( pos, 'main', player );

	-- if there are more menu items than can be shown on one page: show previous page
	elseif( fields.prev ) then
		local page_nr = meta:get_int( 'page_nr' );
		if( not( page_nr )) then
			page_nr = 0;
		end
		page_nr = math.max( page_nr - 1 );
		meta:set_int( 'page_nr', page_nr );
		build_chest.update_formspec( pos, 'main', player );
     
	-- if there are more menu items than can be shown on one page: show next page
	elseif( fields.next ) then
		local page_nr = meta:get_int( 'page_nr' );
		if( not( page_nr )) then
			page_nr = 0;
		end
		meta:set_int( 'page_nr', page_nr+1 );
		build_chest.update_formspec( pos, 'main', player );

-- specific to the build chest
	-- the player has choosen a material from the list; ask for a replacement
	elseif( fields.build_chest_replacements ) then
		local event = minetest.explode_table_event( fields.build_chest_replacements ); 
		local building_name = meta:get_string('building_name');
		if( event and event.row and event.row > 0
		   and building_name
		   and build_chest.building[ building_name ] ) then
	
			meta:set_int('replace_row', event.row );
		end
		--      build_chest.update_formspec( pos, 'ask_for_replacement', player );
		build_chest.update_formspec( pos, 'main', player );

	-- the player has asked for a particular replacement
	elseif( fields.store_replacement
	    and fields.replace_row_with     and fields.replace_row_with ~= ""
	    and fields.replace_row_material and fields.replace_row_material ~= "") then
   
		build_chest.apply_replacement( pos, meta, fields.replace_row_material, fields.replace_row_with );
		build_chest.update_formspec( pos, 'main', player );


	elseif( fields.set_wood ) then
		meta:set_string('set_wood', fields.set_wood );
		build_chest.update_formspec( pos, 'main', player );

	elseif( fields.set_farming ) then
		meta:set_string('set_farming', fields.set_farming );
		build_chest.update_formspec( pos, 'main', player );

	elseif( fields.set_roof ) then
		meta:set_string('set_roof',    fields.set_roof );
		build_chest.update_formspec( pos, 'main', player );


	elseif( fields.wood_selection ) then
		build_chest.apply_replacement_for_group( pos, meta, 'wood',    fields.wood_selection,    'set_wood' );
		build_chest.update_formspec( pos, 'main', player );

	elseif( fields.farming_selection ) then
		build_chest.apply_replacement_for_group( pos, meta, 'farming', fields.farming_selection, 'set_farming' );
		build_chest.update_formspec( pos, 'main', player );

	elseif( fields.roof_selection ) then
		build_chest.apply_replacement_for_group( pos, meta, 'roof',    fields.roof_selection,    'set_roof' );
		build_chest.update_formspec( pos, 'main', player );


	elseif( fields.proceed_with_scaffolding ) then
		local building_name = meta:get_string('building_name');
		local start_pos     = minetest.deserialize( meta:get_string('start_pos'));
		local end_pos       = minetest.deserialize( meta:get_string('end_pos'));
-- TODO: <worldname>/schems/playername_x_y_z_burried_rotation.mts
		local filename      = meta:get_string('backup' );
		if( not( filename ) or filename == "" ) then
			filename      = "todo.mts";
print('CREATING schematic '..tostring( filename )..' from '..minetest.serialize( start_pos )..' to '..minetest.serialize( end_pos ));
			-- store a backup of the original landscape
			minetest.create_schematic( start_pos, end_pos, nil, filename, nil);
-- TODO: what if the creation of the backup failed?
			meta:set_string('backup', filename );
		end
		-- place the building
-- TODO: use scaffolding here (exchange some replacements)
print('USING ROTATION: '..tostring( meta:get_string('rotate')));
		minetest.place_schematic( start_pos, building_name..'.mts', meta:get_string('rotate'), minetest.deserialize( meta:get_string('replacements')), true );
-- TODO: all those calls to on_construct need to be done now!
-- TODO: handle metadata
		build_chest.update_formspec( pos, 'main', player );

	-- restore the original landscape
	elseif( fields.restore_backup ) then
		local start_pos     = minetest.deserialize( meta:get_string('start_pos'));
		local end_pos       = minetest.deserialize( meta:get_string('end_pos'));
		local backup_file   = meta:get_string( 'backup' );
		if( start_pos and end_pos and start_pos.x and end_pos.x and backup_file and backup_file ~= "") then
			minetest.place_schematic( start_pos, backup_file, "0", {}, true );
			meta:set_string('backup', nil );
		end
		build_chest.update_formspec( pos, 'main', player );
	
	end
	-- the final build stage may offer further replacements
	if( build_chest.stages_on_receive_fields ) then
		build_chest.stages_on_receive_fields(pos, formname, fields, player, meta);
	end
end



minetest.register_node("mg_villages:build", { --TODO
	description = "Building-Spawner",
	tiles = {"default_chest_side.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
--        drawtype = 'signlike',
--        paramtype = "light",
--        paramtype2 = "wallmounted",
--        sunlight_propagates = true,
--        walkable = false,
--        selection_box = {
--                type = "wallmounted",
--        },

	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,
        after_place_node = function(pos, placer, itemstack)

 -- TODO: check if placement is allowed
      
           local meta = minetest.env:get_meta( pos );
           meta:set_string( 'current_path', minetest.serialize( {} ));
           meta:set_string( 'village',      'BEISPIELSTADT' ); --TODO
           meta:set_string( 'village_pos',  minetest.serialize( {x=1,y=2,z=3} )); -- TODO
           meta:set_string( 'owner',        placer:get_player_name());

           build_chest.update_formspec( pos, 'main', placer );
        end,
        on_receive_fields = function( pos, formname, fields, player )
           return build_chest.on_receive_fields(pos, formname, fields, player);
        end,
        -- taken from towntest 
        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
                if from_list=="needed" or to_list=="needed" then return 0 end
                return count
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
                return stack:get_count()
        end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
--                if listname=="lumberjack" then return 0 end
                return stack:get_count()
        end,

        can_dig = function(pos,player)
            local meta          = minetest.env:get_meta( pos );
            local inv           = meta:get_inventory();
            local owner_name    = meta:get_string( 'owner' );
            local building_name = meta:get_string( 'building_name' );
            local name          = player:get_player_name();

            if( not( meta ) or not( owner_name )) then
               return true;
            end
            if( owner_name ~= name ) then
               minetest.chat_send_player(name, "This building chest belongs to "..tostring( owner_name )..". You can't take it.");
               return false;
            end
            if( building_name ~= nil and building_name ~= "" ) then
               minetest.chat_send_player(name, "This building chest has been assigned to a building project. You can't take it away now.");
               return false;
            end
            return true;
        end,

        -- have all materials been supplied and the remaining parts removed?
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
            local meta          = minetest.env:get_meta( pos );
            local inv           = meta:get_inventory();
            local stage         = meta:get_int( 'building_stage' );
            
            if( inv:is_empty( 'needed' ) and inv:is_empty( 'main' )) then
               if( stage==nil or stage < 6 ) then
                  build_chest.update_needed_list( pos, stage+1 ); -- request the material for the very first building step
               else
                  build_chest.update_formspec( pos, 'finished', player );
               end
            end
        end,

        on_metadata_inventory_put = function(pos, listname, index, stack, player)
            return build_chest.on_metadata_inventory_put( pos, listname, index, stack, player );
        end,

})


