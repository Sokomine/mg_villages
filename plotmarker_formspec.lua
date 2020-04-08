local S = mg_villages.intllib

-- used for buying plots, restoring buildings, getting information about mobs etc.
mg_villages.plotmarker_formspec = function( pos, formname, fields, player )

--	if( not( mg_villages.ENABLE_PROTECTION )) then
--		return;
--	end
	if( not( pos )) then
		return;
	end
	local meta = minetest.get_meta( pos );
	if( not( meta )) then
		return;
	end
	local village_id = meta:get_string('village_id');
	local plot_nr    = meta:get_int(   'plot_nr');
	local pname      = player:get_player_name();

	if( not( village_id )
		or not( mg_villages.all_villages )
		or not( mg_villages.all_villages[ village_id ] )
		or not( plot_nr )
		or not( mg_villages.all_villages[ village_id ].to_add_data )
		or not( mg_villages.all_villages[ village_id ].to_add_data.bpos )
		or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ] )) then
		minetest.chat_send_player( pname, S('Error. This plot marker is not configured correctly.')..minetest.serialize({village_id,plot_nr }));
		return;
	end

	local village    = mg_villages.all_villages[ village_id ];
	local plot       = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ];

	local owner_name = plot.owner;
	if( not( owner_name ) or owner_name == "" ) then
		if( plot.btype=="road" ) then
			owner_name = "- "..S("the village community").." -";
		else
			owner_name = "- "..S("for sale").." -";
		end
	end

	-- missing data
	if( not( plot.btype ) or not( mg_villages.BUILDINGS[ plot.btype ] )
	  or not( mg_villages.BUILDINGS[ plot.btype ].mts_path )
	  or not( mg_villages.BUILDINGS[ plot.btype ].scm )) then
		minetest.chat_send_player( pname, S('Error. Unknown building.')..' btype: '..tostring( plot.btype ));
		return;
	end
	local building_name = mg_villages.BUILDINGS[ plot.btype ].mts_path..mg_villages.BUILDINGS[ plot.btype ].scm;

	-- show coordinates of the village center to the player
	local village_pos = minetest.pos_to_string( {x=village.vx, y=village.vh, z=village.vz});
	-- distance from village center
	local distance = math.floor( math.sqrt( (village.vx - pos.x ) * (village.vx - pos.x )
					      + (village.vh - pos.y ) * (village.vh - pos.y )
					      + (village.vz - pos.z ) * (village.vz - pos.z ) ));

	-- show a list of who lives (or works) here at this plot
	if( fields and fields.inhabitants ) then
		minetest.show_formspec( pname, "mg_villages:plot_mob_list",
			mg_villages.inhabitants.print_house_info( village.to_add_data.bpos, plot_nr, village_id, pname ));
		--mg_villages.debug_inhabitants( village, plot_nr);
		return;
	end

	local mirror_str = "";
	if( plot.mirror ) then
		mirror_str = minetest.formspec_escape(" "..S("(mirrored)"));
	end
	-- create the header
	local formspec = "size[13,10]"..
		"label[3.3,0.0;"..S("Plot No.: @1, with @2", tostring( plot_nr ), tostring( mg_villages.BUILDINGS[ plot.btype ].scm )).."]"..
		"label[0.3,0.4;Located at:]"      .."label[3.3,0.4;"..(minetest.pos_to_string( pos ) or '?')..S(", which is ")..tostring( distance )..S(" m away").."]"
		                                  .."label[7.3,0.4;"..S("from the village center").."]"..
		"label[0.3,0.8;Part of village:]" .."label[3.3,0.8;"..(village.name or "- "..S("name unknown").." -").."]"
		                                  .."label[7.3,0.8;"..S("located at").." "..(village_pos).."]"..
		"label[0.3,1.2;Owned by:]"        .."label[3.3,1.2;"..(owner_name).."]"..
		"label[3.3,1.6;"..S("Click on a menu entry to select it")..":]"..
		"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]";
                            build_chest.show_size_data( building_name );

	-- deprecated; adds buttons for registered mobf_traders
	--formspec = mg_villages.plotmarker_list_traders( plot, formspec );

	local replace_row = -1;
	-- the player selected a material which ought to be replaced
	if(     fields.build_chest_replacements ) then
                local event = minetest.explode_table_event( fields.build_chest_replacements );
                if( event and event.row and event.row > 0 ) then
                        replace_row = event.row;
			fields.show_materials = "show_materials";
                end

	-- the player provided the name of the material for the replacement of the currently selected
	elseif( fields.store_replacement    and fields.store_repalcement    ~= ""
	    and fields.replace_row_with     and fields.replace_row_with     ~= ""
	    and fields.replace_row_material and fields.replace_row_material ~= "") then

                build_chest.replacements_apply( pos, meta, fields.replace_row_material, fields.replace_row_with, village_id );
		fields.show_materials = "show_materials";


	-- group selections for easily changing several nodes at once
	elseif( fields.wood_selection ) then
                build_chest.replacements_apply_for_group( pos, meta, 'wood',    fields.wood_selection,    fields.set_wood,    village_id );
                fields.set_wood    = nil;
		fields.show_materials = "show_materials";

	elseif( fields.farming_selection ) then
                build_chest.replacements_apply_for_group( pos, meta, 'farming', fields.farming_selection, fields.set_farming, village_id );
                fields.set_farming = nil;
		fields.show_materials = "show_materials";

	elseif( fields.roof_selection ) then
                build_chest.replacements_apply_for_group( pos, meta, 'roof',    fields.roof_selection,    fields.set_roof,    village_id );
                fields.set_roof    = nil;
		fields.show_materials = "show_materials";


	-- actually store the new group replacement
	elseif(  (fields.set_wood    and fields.set_wood     ~= "")
	      or (fields.set_farming and fields.set_farming ~= "" )
	      or (fields.set_roof    and fields.set_roof    ~= "" )) then
		minetest.show_formspec( pname, "mg_villages:formspec_plotmarker",
				handle_schematics.get_formspec_group_replacement( pos, fields, formspec ));
		return;
	end

	-- show which materials (and replacements!) where used for the building
        if( (fields.show_materials       and fields.show_materials ~= "" )
	 or (fields.replace_row_with     and fields.replace_row_with ~= "")
	 or (fields.replace_row_material and fields.replace_row_material ~= "")) then

		formspec = formspec.."button[9.9,0.4;2,0.5;info;"..S("Back").."]";
		if( not( minetest.check_player_privs( pname, {protection_bypass=true}))) then
			-- do not allow any changes; just show the materials and their replacements
			minetest.show_formspec( pname, "mg_villages:formspec_plotmarker",
				formspec..build_chest.replacements_get_list_formspec( pos, nil, 0, meta, village_id, building_name, replace_row ));
		else
			minetest.show_formspec( pname, "mg_villages:formspec_plotmarker",
				formspec..build_chest.replacements_get_list_formspec( pos, nil, 1, nil,  village_id, building_name, replace_row ));
		end
		return;

	-- place the building again
	elseif(   (fields.reset_building  and fields.reset_building  ~= "")
           or (fields.remove_building and fields.remove_building ~= "")) then

		formspec = formspec.."button[9.9,0.4;2,0.5;back;"..S("Back").."]";

		if( not( minetest.check_player_privs( pname, {protection_bypass=true}))) then
			minetest.show_formspec( pname, "mg_villages:formspec_plotmarker", formspec..
				"label[3,3;"..S("You need the 'protection_bypass' priv in order to use this function.").."]" );
			return;
		end

		local selected_building = build_chest.building[ building_name ];
		local start_pos = {x=plot.x, y=plot.y, z=plot.z, brotate=plot.brotate};
		if( selected_building.yoff ) then
			start_pos.y = start_pos.y + selected_building.yoff;
		end
		local end_pos = {x=plot.x+plot.bsizex-1,
				 y=plot.y+selected_building.yoff-1+selected_building.ysize,
				 z=plot.z+plot.bsizez-1};

		local replacements = build_chest.replacements_get_current( meta, village_id );

		if( fields.remove_building and fields.remove_building ~= "" ) then
			-- clear the space above ground, put dirt below ground, but keep the
			-- surface intact
			handle_schematics.clear_area( start_pos, end_pos, pos.y-1, replacements);
			-- also clear the meta data to avoid strange effects
			handle_schematics.clear_meta( start_pos, end_pos );
			formspec = formspec.."label[3,3;"..S("The plot has been cleared.").."]";
		else
			-- actually place it (disregarding mirroring)
			local error_msg = handle_schematics.place_building_from_file(
						start_pos,
						end_pos,
						building_name,
						replacements,
						plot.o,
						build_chest.building[ building_name ].axis, plot.mirror, 1, true );
			formspec = formspec.."label[3,3;"..S("The building has been reset.").."]";
			if( error_msg ) then
				formspec = formspec..'label[4,3;'..S('Error:')..' '..tostring( fields.error_msg ).."]";
	                end
		end
		minetest.show_formspec( pname, "mg_villages:formspec_plotmarker", formspec );
		return;

	elseif( fields.info and fields.info ~= "" ) then
		local show_material_text = S("Change materials used");
		if( not( minetest.check_player_privs( pname, {protection_bypass=true}))) then
			show_material_text = S("Show materials used");
		end

		minetest.show_formspec( pname, "mg_villages:formspec_plotmarker",
			formspec..
				"button[9.9,0.4;2,0.5;back;"..S("Back").."]"..
				"button[3,3;5,0.5;create_backup;"..S("Create backup of current stage").."]"..
				"button[4,4;3,0.5;show_materials;"..show_material_text.."]"..
				"button[4,5;3,0.5;reset_building;"..S("Reset building").."]"..
				"button[4,6;3,0.5;remove_building;"..S("Remove building").."]");
		return;
	end

	local owner      = plot.owner;
	local btype      = plot.btype;


	local original_formspec = "size[8,3]"..
		"button[7.0,0.0;1.0,0.5;info;Info]"..
		"button[6.0,1.0;2.0,0.5;inhabitants;"..S("Who lives here").."]"..
		"label[1.0,0.5;"..S("Plot No.")..": "..tostring( plot_nr ).."]"..
		"label[2.5,0.5;"..S("Building:").."]"..
		"label[3.5,0.5;"..tostring( mg_villages.BUILDINGS[btype].scm )..mirror_str.."]"..
		"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]";
		local formspec = "";
	local ifinhabit = "";

	-- Get Price
	local price = "default:gold_ingot 2";

	if (btype ~= 'road' and mg_villages.BUILDINGS[btype]) then
		local plot_descr = S('Plot No.')..' '..tostring( plot_nr ).. ' '..S('with')..' '..tostring( mg_villages.BUILDINGS[btype].scm)

		if (mg_villages.BUILDINGS[btype].price) then
			price = mg_villages.BUILDINGS[btype].price;
		elseif (mg_villages.BUILDINGS[btype].typ and mg_villages.prices[ mg_villages.BUILDINGS[btype].typ ]) then
			price = mg_villages.prices[ mg_villages.BUILDINGS[btype].typ ];
		end
		-- Get if is inhabitant house
		if (mg_villages.BUILDINGS[btype].inh and mg_villages.BUILDINGS[btype].inh > 0 ) then
			ifinhabit = "label[1,1.5;"..S("Owners of this plot count as village inhabitants.").."]";
		end
	end
	-- Determine price depending on building type
	local price_stack= ItemStack( price );


	-- If nobody owns the plot
	if (not(owner) or owner=='') then

		formspec = original_formspec ..
			"label[1,1;"..S("You can buy this plot for").."]".. 
			"label[3.8,1;"..tostring( price_stack:get_count() ).." x ]"..
			"item_image[4.3,0.8;1,1;"..(  price_stack:get_name() ).."]"..
			ifinhabit..
			"button[2,2.5;1.5,0.5;buy;"..S("Buy plot").."]"..
			"button_exit[4,2.5;1.5,0.5;abort;"..S("Exit").."]";

		-- On Press buy button
		if (fields['buy']) then
			local inv = player:get_inventory();

			if not mg_villages.all_villages[village_id].ownerlist then
				mg_villages.all_villages[village_id].ownerlist = {}
			end

			-- Check if player already has a house in the village
			if mg_villages.all_villages[village_id].ownerlist[pname] then
				formspec = formspec.."label[1,1.9;"..S("Sorry. You already have a plot in this village.").."]";

			-- Check if the price can be paid
			elseif( inv and inv:contains_item( 'main', price_stack )) then
				formspec = original_formspec..
					"label[1,1;"..S("Congratulations! You have bought this plot.").."]"..
					"button_exit[5.75,2.5;1.5,0.5;abort;"..S("Exit").."]";
				mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner = pname;
				if mg_villages.all_villages[village_id].ownerlist then
					mg_villages.all_villages[village_id].ownerlist[pname] = true;
				else
					mg_villages.all_villages[village_id].ownerlist[pname] = true;
				end
				meta:set_string('infotext', S('Plot No. @1 with @2 (owned by @3)', tostring( plot_nr ), tostring( mg_villages.BUILDINGS[btype].scm), tostring( pname )));
				-- save the data so that it survives server restart
				mg_villages.save_data();
				-- substract the price from the players inventory
				inv:remove_item( 'main', price_stack );
			else
				formspec = formspec.."label[1,1.9;"..S("Sorry. You are not able to pay the price.").."]";
			end
		end

	-- If player is the owner of the plot
	elseif (owner==pname) then

		-- Check if inhabitant house
		if(btype ~= 'road'
			and mg_villages.BUILDINGS[btype]
			and mg_villages.BUILDINGS[btype].inh
			and mg_villages.BUILDINGS[btype].inh > 0 ) then

			ifinhabit = "label[1,1.5;"..S("You are allowed to modify the common village area.").."]";
		end

		formspec = original_formspec.."size[8,3]"..
			"label[1,1;"..S("This is your plot. You have bought it.").."]"..
			"button[0.75,2.5;3,0.5;add_remove;"..S("Add/Remove Players").."]"..
			ifinhabit..
			"button_exit[3.75,2.5;2.0,0.5;abandon;"..S("Abandon plot").."]"..
			"button_exit[5.75,2.5;1.5,0.5;abort;"..S("Exit").."]";

		-- If Player wants to abandon plot
		if(fields['abandon'] ) then
			formspec = original_formspec..
				"label[1,1;"..S("You have abandoned this plot.").."]"..
				"button_exit[5.75,2.5;1.5,0.5;abort;"..S("Exit").."]";
			mg_villages.all_villages[village_id].ownerlist[pname] = nil;
			mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit = {}
			mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner = nil;
			-- Return price to player
			local inv = player:get_inventory();
			inv:add_item( 'main', price_stack );
			meta:set_string('infotext', S('Plot No. @1 with @2', tostring( plot_nr ), tostring( mg_villages.BUILDINGS[btype].scm)));
			mg_villages.save_data();
		end

		-- If Player wants to add/remove trusted players
		if (fields['add_remove']) then
			local previousTrustees = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit
			local output = "";
			if previousTrustees == nil then
				previousTrustees = {}
			else
				for _, player in ipairs(previousTrustees) do
					output = output..player.."\n"
				end
			end
			formspec = "size[8,3]"..
				"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
				"textarea[0.3,0.2;8,2.5;ownerplayers;"..S("Trusted Players")..";"..output.."]"..
				"button[3.25,2.5;1.5,0.5;savetrustees;"..S("Save").."]";

			mg_villages.save_data()
		end

		-- Save trusted players
		if (fields["savetrustees"] == "Save") then

			if not mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit then
				mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit = {}
			end

			local x = 1;
			for _, player in ipairs(fields.ownerplayers:split("\n")) do
				mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit[x] = player
				x = x + 1
			end

			mg_villages.save_data();
		end

	-- If A different Player owns plot
	else
		formspec = original_formspec.."label[1,1;"..tostring( owner ).." "..S("owns this plot")..".]"..
					"button_exit[3,2.5;1.5,0.5;abort;"..S("Exit").."]";
	end

	minetest.show_formspec( pname, "mg_villages:formspec_plotmarker", formspec );
end



mg_villages.form_input_handler = function( player, formname, fields)
--	mg_villages.print(mg_villages.DEBUG_LEVEL_NORMAL,minetest.serialize(fields));
	if( not( mg_villages.ENABLE_PROTECTION )) then
		return false;
	end

	-- teleport to a plot or mob
	if( fields[ 'teleport_to' ]
	  and fields[ 'pos2str' ]
	  and player ) then
		local pname = player:get_player_name();
		if( minetest.check_player_privs( pname, {teleport=true})) then
			local pos = minetest.string_to_pos( fields.pos2str );
			-- teleport the player to the target position
			player:move_to( { x=pos.x, y=(pos.y+1), z=pos.z }, false);
		else
			minetest.chat_sned_player( pname, S("Sorry. You do not have the teleport privilege."));
		end
		-- do not abort; continue with showing the formspec
	end


	-- are we supposed to show information about a particular mob?
	local mob_selected = nil;
	-- show previous mob that lives on the plot
	if(     formname=="mg_villages:formspec_list_one_mob" and fields["prev"] and fields["bed_nr"]) then
		mob_selected = tonumber(fields.bed_nr) - 1;
	-- show next mob that lives on the mob
	elseif( formname=="mg_villages:formspec_list_one_mob" and fields["next"] and fields["bed_nr"]) then
		mob_selected = tonumber(fields.bed_nr) + 1;
	-- show informaton about mob selected from list of inhabitants
	elseif( not( fields['back_to_houselist'])
	  and fields['mg_villages:formspec_list_inhabitants']
	  and fields['mg_villages:formspec_list_inhabitants']~=""
	  and fields['village_id']
	  and fields['plot_nr']) then
		local selection = minetest.explode_table_event( fields['mg_villages:formspec_list_inhabitants'] );
		mob_selected = selection.row;
	end

	-- this index has to be a number and not a string
	fields.plot_nr = tonumber( fields.plot_nr or "0");
	local pname = player:get_player_name();

	-- provide information about a particular mob
	if( mob_selected
	  and fields.village_id
	  and fields.plot_nr
	  and mg_villages.all_villages[ fields.village_id ]
	  and mg_villages.all_villages[ fields.village_id ].to_add_data
	  and mg_villages.all_villages[ fields.village_id ].to_add_data.bpos
	  and mg_villages.all_villages[ fields.village_id ].to_add_data.bpos[ fields.plot_nr ])then
--	  and mg_villages.all_villages[ fields.village_id ].to_add_data.bpos[ fields.plot_nr ].beds[mob_selected]) then
		if( not( mg_villages.all_villages[ fields.village_id ].to_add_data.bpos[ fields.plot_nr ].beds)
		 or not( mg_villages.all_villages[ fields.village_id ].to_add_data.bpos[ fields.plot_nr ].beds[ mob_selected] )) then
			-- allow to click at the worker
			local bpos = mg_villages.all_villages[ fields.village_id ].to_add_data.bpos;
			if(   bpos[ fields.plot_nr ].worker
			  and bpos[ fields.plot_nr ].worker.lives_at
			  and bpos[ bpos[ fields.plot_nr ].worker.lives_at ]
			  and bpos[ bpos[ fields.plot_nr ].worker.lives_at ].beds
			  and bpos[ bpos[ fields.plot_nr ].worker.lives_at ].beds[1] ) then
				fields.plot_nr = tonumber(bpos[ fields.plot_nr ].worker.lives_at);
				mob_selected = 1;
			-- allow to click at the owner
			elseif( bpos[ fields.plot_nr ].belongs_to
			  and bpos[ bpos[ fields.plot_nr ].belongs_to ]
			  and bpos[ bpos[ fields.plot_nr ].belongs_to ].beds
			  and bpos[ bpos[ fields.plot_nr ].belongs_to ].beds[1] ) then
				fields.plot_nr = tonumber(bpos[ fields.plot_nr ].belongs_to);
				mob_selected = 1;
			-- this is not a mob
			else
				mob_selected = nil;
			end
		end
		if( mob_selected ) then
			local village = mg_villages.all_villages[ fields.village_id ];
			minetest.show_formspec( pname, "mg_villages:formspec_list_one_mob",
				mg_villages.inhabitants.print_mob_info( village.to_add_data.bpos, fields.plot_nr, fields.village_id, mob_selected, pname ));
			return true;
		end
	end


	-- are we supposed to show information about a particular plot?
	local plot_selected = nil;
	-- show previous plot of that village
	if(     formname=="mg_villages:formspec_list_inhabitants" and fields["prev"] and fields["plot_nr"]) then
		plot_selected = fields.plot_nr - 1;
	-- show next plot of that village
	elseif( formname=="mg_villages:formspec_list_inhabitants" and fields["next"] and fields["plot_nr"]) then
		plot_selected = fields.plot_nr + 1;
	-- back from the list of details of a mob to the list of inhabitants of the plot where it lives
	elseif( fields['back_to_houselist'] ) then
		plot_selected = fields.plot_nr;
	-- show informaton about plot selected from list of plots in a village
	elseif( not( fields['back_to_plotlist'])
	  and fields['mg_villages:formspec_list_plots']
	  and fields['mg_villages:formspec_list_plots']~=""
	  and fields['village_id']) then
		local selection = minetest.explode_table_event( fields['mg_villages:formspec_list_plots'] );
		plot_selected = selection.row-1;
	end

	-- provide information about the inhabitants of a particular plot
	if( plot_selected
	  and fields.village_id
	  and mg_villages.all_villages[ fields.village_id ]
	  and mg_villages.all_villages[ fields.village_id ].to_add_data
	  and mg_villages.all_villages[ fields.village_id ].to_add_data.bpos
	  and mg_villages.all_villages[ fields.village_id ].to_add_data.bpos[ plot_selected ]) then

		local village = mg_villages.all_villages[ fields.village_id ];
		minetest.show_formspec( pname, "mg_villages:formspec_list_inhabitants",
			mg_villages.inhabitants.print_house_info( village.to_add_data.bpos, plot_selected, fields.village_id, pname ));
		return true;
	end


	-- are we supposed to show the plots contained in a particular village?
	local village_selected = nil;
	-- where are we currently in the list of villages as shown to that particular player?
	local liste = mg_villages.tmp_player_village_list[ pname ];
	local curr_list_pos = -1;
	if( liste ) then
		for i,v in ipairs( liste ) do
			if( fields.village_id and v==fields.village_id ) then
				curr_list_pos = i;
			end
		end
	end
	-- show previous village in list
	if(     formname=="mg_villages:formspec_list_plots" and fields["prev"] and curr_list_pos>1) then
		village_selected = liste[ curr_list_pos - 1 ];
	-- show next village
	elseif( formname=="mg_villages:formspec_list_plots" and fields["next"] and curr_list_pos<#liste) then
		village_selected = liste[ curr_list_pos + 1 ];
	-- back from the list of inhabitants to the list of plots of a village
	elseif( fields['back_to_plotlist'] and fields.village_id) then
		village_selected = fields.village_id;
	-- show informaton about all plots in the selected village
	elseif( not( fields['back_to_villagelist'])
	  and fields['mg_villages:formspec_list_villages']
	  and fields['mg_villages:formspec_list_villages']~="" ) then
		local selection = minetest.explode_table_event( fields['mg_villages:formspec_list_villages'] );
		-- this is the village the player is intrested in
		village_selected = mg_villages.tmp_player_village_list[ pname ][ selection.row-1 ];
	end

	-- the player has selected a village in the village list
	if( village_selected
	  and mg_villages.all_villages[ village_selected ]
	  and mg_villages.all_villages[ village_selected ].to_add_data
	  and mg_villages.all_villages[ village_selected ].to_add_data.bpos ) then

		fields.village_id = village_selected;
		-- show the player a list of plots of the selected village
		mg_villages.list_plots_formspec( player, 'mg_villages:formspec_list_plots', fields );
		return true;
	end

	-- back from plotlist of a village to the list of nearby villages
	--   mg_villages.list_villages_formspec can be found in chat_commands.lua
	if( fields['back_to_villagelist']) then
		mg_villages.list_villages_formspec( player, "mg_villages:formspec_list_villages", {});

		return true;
	end

	if( (formname == "mg_villages:formspec_plotmarker") and fields.pos2str and not( fields.abort )) then
		local pos = minetest.string_to_pos( fields.pos2str );
		mg_villages.plotmarker_formspec( pos, formname, fields, player );
		return true;
	end
	return false;
end


minetest.register_on_player_receive_fields( mg_villages.form_input_handler )
