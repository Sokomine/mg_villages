-------------------------------------------------------------
--- contains the handling of replacements for the build chest
-------------------------------------------------------------

-- internal function
build_chest.replacements_get_extra_buttons = function( group, name, types_found_list, button_name, extra_buttons )
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



build_chest.replacements_get_list_formspec = function( pos, selected_row )
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

	local not_the_first_entry = false;
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
			if( not_the_first_entry ) then
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
			
			extra_buttons = build_chest.replacements_get_extra_buttons( 'wood',    name, types_found_list_wood,    'set_wood',    extra_buttons );
			extra_buttons = build_chest.replacements_get_extra_buttons( 'farming', name, types_found_list_farming, 'set_farming', extra_buttons );
			extra_buttons = build_chest.replacements_get_extra_buttons( 'roof',    name, types_found_list_farming, 'set_roof',    extra_buttons );

			j=j+1;

			not_the_first_entry = true;
		end
	end
	formspec = formspec.."]";
	-- add the proceed-button as soon as all unkown materials have been replaced
	if( may_proceed ) then
		formspec = formspec.."button[9.9,9.0;2.0,0.5;proceed_with_scaffolding;Proceed]";
	end
	formspec = formspec.."button[9.9,1.0;2.0,0.5;preview;Preview]";
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


build_chest.replacements_apply = function( pos, meta, old_material, new_material )
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
	

build_chest.replacements_get_group_list_formspec = function( pos, group, button_name )
	local formspec = "";
	for i,v in ipairs( replacements_group[ group ].found ) do
		formspec = formspec.."item_image_button["..tostring(((i-1)%8)+1)..","..
			tostring(3+math.floor((i-1)/8))..";1,1;"..
			tostring( v )..";"..tostring( button_name )..";"..tostring(i).."]";
	end
	return formspec;
end

 
build_chest.replacements_apply_for_group = function( pos, meta, group, selected, old_material )
	local nr = tonumber( selected );
	if( not(nr) or nr <= 0 or nr > #replacements_group[ group ].found ) then
		return;
	end	

	local new_material = replacements_group[ group ].found[ nr ];
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

