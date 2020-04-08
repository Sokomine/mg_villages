-- Intllib
local S = mg_villages.intllib

-- get the id of the village pos lies in (or nil if outside of villages)
mg_villages.get_town_id_at_pos = function( pos )
	for id, v in pairs( mg_villages.all_villages ) do
		local height_diff = pos.y - v.vh;
		if( height_diff < 40 and height_diff > -10 ) then

			local size = v.vs * 3;
			if(   ( math.abs( pos.x - v.vx ) < size )
			  and ( math.abs( pos.z - v.vz ) < size )) then
				local village_noise = minetest.get_perlin(7635, 3, 0.5, 16);
				if( mg_villages.inside_village_area( pos.x,  pos.z, v, village_noise)) then

					local node = minetest.get_node( pos );
					-- leaves can be digged in villages
					if( node and node.name ) then
						if(    minetest.registered_nodes[ node.name ]
						   and minetest.registered_nodes[ node.name ].groups
					           and minetest.registered_nodes[ node.name ].groups.leaves ) then
							return nil;
						elseif( node.name=='default:snow' ) then
							return nil;
						-- bones can be digged in villages
						elseif( node.name == 'bones:bones' ) then
							return nil;
						else
							return id;
						end
					else
						return id;
					end
				end
			end
		end
	end
	return nil;
end


-- checks if the plot marker is still present; places a new one if needed
-- p: plot data (position, size, orientation, owner, ..)
mg_villages.check_plot_marker = function( p, plot_nr, village_id )
	-- roads cannot be bought
	if( p.btype and p.btype=="road" ) then
		return;
	end
	local plot_pos = { x=p.x, y=p.y, z=p.z };
	if(      p.o==3 ) then
		plot_pos = { x=p.x,            y=p.y+1, z=p.z-1          };
	elseif(  p.o==1 ) then
		plot_pos = { x=p.x+p.bsizex-1, y=p.y+1, z=p.z+p.bsizez   };
	elseif ( p.o==2 ) then
		plot_pos = { x=p.x+p.bsizex,   y=p.y+1, z=p.z            };
	elseif ( p.o==0 ) then
		plot_pos = { x=p.x-1,          y=p.y+1, z=p.z+p.bsizez-1 };
	end
	-- is the plotmarker still present?
	local node = minetest.get_node( plot_pos );
	if( not(node) or not(node.name) or node.name ~= "mg_villages:plotmarker" ) then
		-- place a new one if needed
		minetest.set_node( plot_pos, {name="mg_villages:plotmarker", param2=p.o});
		local meta = minetest.get_meta( plot_pos );
		-- strange error happend; maybe we're more lucky next time...
		if( not( meta )) then
			return;
		end
		meta:set_string('village_id', village_id );
		meta:set_int(   'plot_nr',    plot_nr );
	end
end



local old_is_protected = minetest.is_protected
minetest.is_protected = function(pos, name)

	if( not( mg_villages.ENABLE_PROTECTION )) then
		return old_is_protected( pos, name );
	end

	-- allow players with protection_bypass to build anyway
	if( minetest.check_player_privs( name, {protection_bypass=true})) then
		return false;
	end

	local village_id = mg_villages.get_town_id_at_pos( pos );
	if( village_id ) then
		local is_houseowner = false;
		for nr, p in ipairs( mg_villages.all_villages[ village_id ].to_add_data.bpos ) do

			local trustedusers = p.can_edit
			local trustedUser = false
			if trustedusers ~= nil then
				for _,trusted in ipairs(trustedusers) do
					if trusted == name then
						trustedUser = true
					end
				end
			end

			-- we have located the right plot; the player can build here if he owns this particular plot
			if(   p.x <= pos.x and (p.x + p.bsizex) >= pos.x
			  and p.z <= pos.z and (p.z + p.bsizez) >= pos.z) then

				-- place a new plot marker if necessary
				mg_villages.check_plot_marker( p, nr, village_id );

				-- If player has been trusted by owner, can build
				if (trustedUser) then
					return false;
				-- If player is owner, can build
				elseif( p.owner and p.owner == name ) then
					return false;
				-- the allmende can be used by all
				elseif( mg_villages.BUILDINGS[p.btype] and mg_villages.BUILDINGS[p.btype].typ=="allmende" ) then
					return false;
				-- the player cannot modify other plots, even though he may be house owner of another house and be allowed to modify common ground
				else
					return true;
				end
			-- if the player just owns another plot in the village, check if it's one where villagers may live
			elseif( p.owner and p.owner == name or trustedUser) then
				local btype = mg_villages.all_villages[ village_id ].to_add_data.bpos[ nr ].btype;
				if(   btype ~= 'road'
				  and mg_villages.BUILDINGS[btype]
				  and mg_villages.BUILDINGS[btype].inh
				  and mg_villages.BUILDINGS[btype].inh > 0 ) then
					is_houseowner = true;
					-- check the node below
					local node = minetest.get_node( {x=pos.x, y=pos.y-1, z=pos.z});
					-- replace the fake, inaktive village soil with real farming soil if a player diggs the plant above
					if( node and node.name and node.name=="mg_villages:soil" ) then
						minetest.swap_node( {x=pos.x, y=pos.y-1, z=pos.z}, {name="farming:soil_wet"});
					end
				end
			end
		end
		-- players who own a house in town where villagers may live (not only work!)
		--  are allowed to modify common ground
		if( is_houseowner ) then
			return false;
		end
		return true;
	end
	return old_is_protected(pos, name);
end			 


minetest.register_on_protection_violation( function(pos, name)

	if( not( mg_villages.ENABLE_PROTECTION )) then
		return;
	end

	local found = mg_villages.get_town_id_at_pos( pos );
	if( not( found ) or not( mg_villages.all_villages[ found ]))  then
		minetest.chat_send_player( name, S("Error: This area does not belong to a village."));
		return;
	end

	minetest.chat_send_player( name, S("You are inside of the area of the village @1. The inhabitants do not allow you any modifications.", tostring( mg_villages.all_villages[ found ].name )))
end );


mg_villages.plotmarker_formspec = function( pos, formname, fields, player )

--	if( not( mg_villages.ENABLE_PROTECTION )) then
--		return;
--	end
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
		minetest.chat_send_player( pname, S("Error. This plot marker is not configured correctly.").." "..minetest.serialize({village_id,plot_nr }));
		return;
	end

	local village    = mg_villages.all_villages[ village_id ];
	local plot       = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ];

	local owner_name = plot.owner;
	if( not( owner_name ) or owner_name == "" ) then
		if( plot.btype=="road" ) then
			owner_name = " - "..S("the village community").." - ";
		else
			owner_name = " - "..S("for sale").." - ";
		end
	end

	local building_name = mg_villages.BUILDINGS[ plot.btype ].mts_path..mg_villages.BUILDINGS[ plot.btype ].scm;

	-- show coordinates of the village center to the player
	local village_pos = minetest.pos_to_string( {x=village.vx, y=village.vh, z=village.vz});
	-- distance from village center
	local distance = math.floor( math.sqrt( (village.vx - pos.x ) * (village.vx - pos.x )
					      + (village.vh - pos.y ) * (village.vh - pos.y )
					      + (village.vz - pos.z ) * (village.vz - pos.z ) ));

	-- create the header
	local formspec = "size[9,8,true]"..
		default.gui_bg..default.gui_bg_img..
		"label[0.3,0.0;"..S("Plot No. : @1, with @2", tostring( plot_nr ), tostring( mg_villages.BUILDINGS[ plot.btype ].scm )).."]"..
		"label[0.3,0.4;"..S("Located at").." : ]"      ..
			"label[2.3,0.4;"..(minetest.pos_to_string( pos ) or '?')..S(", which is").."]"..
			"label[2.3,0.8;"..tostring( distance )..' '..S("m away")..' '..S("from the village center").."]"..
		"label[0.3,1.2;"..S("Part of village").." :]" ..
			"label[2.3,1.2;"..(village.name or " - "..S("name unknown")).." - ".."]"
		     .."label[4.9,1.2;"..S("Located at").." : "..(village_pos).."]"..
		"label[0.3,1.6;"..S("Owned by").." : ]"        .."label[2.3,1.6;"..(owner_name).."]"..
		"label[0.3,2.2;"..S("Click on a menu entry to select it").." : ]"..
		"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]";
                            build_chest.show_size_data( building_name );

	if( plot and plot.traders ) then
		if( #plot.traders > 1 ) then
			formspec = formspec.."label[0.3,4.8;"..S("Some traders live here. One works as a")..' '..S(tostring(plot.traders[1].typ))..".]";
			for i=2,#plot.traders do
				formspec = formspec.."label[0.3,"..(4.5+i).."; "..S("Another trader works as a")..' '..S(tostring(plot.traders[i].typ))..".]";
			end
		elseif( plot.traders[1] and plot.traders[1].typ) then
			formspec = formspec..
				"label[0.3,4.8;"..S("A trader lives here. He works as a")..' '..tostring( plot.traders[1].typ )..".]";
		else
			formspec = formspec..
				"label[0.3,4.8;"..S("No trader currently works at this place.").."]";
		end
		-- add buttons for visiting (teleport to trader), calling (teleporting trader to plot) and firing the trader
		for i,trader in ipairs(plot.traders) do
			local trader_entity = mg_villages.plotmarker_search_trader( trader, village.vh );

			formspec = formspec..
					"button[0.3.0,"..(4.5+i)..";2.8,0.5;visit_trader_"..i..";"..S("visit").."]"..
					"button[3.2,"..(4.5+i)..";2.8,0.5;call_trader_"..i..";"..S("call").."]"..
					"button[6.2,"..(4.5+i)..";2.8,0.5;fire_trader_"..i..";"..S("fire").."]";

			if( fields[ "visit_trader_"..i ] ) then

				player:moveto( {x=trader.x, y=(village.vh+1), z=trader.z} );
				minetest.chat_send_player( pname, S("You are visiting the")..' '..S(tostring( trader.typ ))..' '..
					S("trader, who is supposed to be somewhere here. He might also be on a floor above you."));
				return;
			end
			if( fields[ "visit_call_"..i ] ) then
				-- TODO: spawning: mob_basics.spawn_mob( {x=v.x, y=v.y, z=v.z}, v.typ, nil, nil, nil, nil, true );
			end
			-- TODO: fire mob
		end
		formspec = formspec.."button[4.4,"..(5.5+math.max(1,#plot.traders))..";4.6,0.5;hire_trader;"..S("Hire a new random trader").."]";
		-- TODO: hire mob
	end


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
		minetest.show_formspec( pname, "mg_villages:plotmarker",
				handle_schematics.get_formspec_group_replacement( pos, fields, formspec ));
		return;
	end

	-- show which materials (and replacements!) where used for the building
        if( (fields.show_materials       and fields.show_materials ~= "" )
	 or (fields.replace_row_with     and fields.replace_row_with ~= "")
	 or (fields.replace_row_material and fields.replace_row_material ~= "")) then


		-- big formspec for the material list
		formspec ="size[13,10]"..
			default.gui_bg..default.gui_bg_img..
			"button[9.9,0.4;2,0.5;back;"..S("Back").."]"..
			"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]";

		
		if( not( minetest.check_player_privs( pname, {protection_bypass=true}))) then
			-- do not allow any changes; just show the materials and their replacements
			minetest.show_formspec( pname, "mg_villages:plotmarker",
				formspec..build_chest.replacements_get_list_formspec( pos, nil, 0, meta, village_id, building_name, replace_row ));
		else
			minetest.show_formspec( pname, "mg_villages:plotmarker",
				formspec..build_chest.replacements_get_list_formspec( pos, nil, 1, nil,  village_id, building_name, replace_row ));
		end
		return;

	-- place the building again
	elseif(   (fields.reset_building  and fields.reset_building  ~= "")
           or (fields.remove_building and fields.remove_building ~= "")) then

		formspec = formspec.."button[7.4,0.1;1.5,0.5;back;"..S("Back").."]";

		if( not( minetest.check_player_privs( pname, {protection_bypass=true}))) then
			minetest.show_formspec( pname, "mg_villages:plotmarker", formspec..
				"label[0.3,3;"..S("You need the 'protection_bypass' priv in order to use this function.").."]"
				);
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
				formspec = formspec..'label[4,3;Error: '..tostring( fields.error_msg ).."]";
	                end
		end
		minetest.show_formspec( pname, "mg_villages:plotmarker", formspec );
		return;

	elseif( fields.info and fields.info ~= "" ) then
		local show_material_text = S("Change materials used");
		if( not( minetest.check_player_privs( pname, {protection_bypass=true}))) then
			show_material_text = S("Show materials used");
		end

		minetest.show_formspec( pname, "mg_villages:plotmarker",
			formspec..
				"button[7.4,0.1;1.5,0.5;back;"..S("Back").."]"..
				"button[0.2,3;4.5,0.4;create_backup;"..S("Create backup of current stage").."]"..
				"button[0.2,4;4.5,0.4;show_materials;"..show_material_text.."]"..
				"button[4.6,3;4.5,0.4;reset_building;"..S("Reset building").."]"..
				"button[4.6,4;4.5,0.4;remove_building;"..S("Remove building").."]"
				);
		return;
	end

	local owner      = plot.owner;
	local btype      = plot.btype;


	local original_formspec = "size[8,4,true]"..
		default.gui_bg..default.gui_bg_img..
		"button[7.0,0.0;1.0,0.5;info;"..S("Info").."]"..
		"label[0.3.0,0.1;"..S("Plot No.").." : "..tostring( plot_nr ).."]"..
		"label[0.3,0.5;"..S("Building").." : ]"..
			"label[1.9,0.5;"..tostring( mg_villages.BUILDINGS[btype].scm ).."]"..
		"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]";
		local formspec = "";
	local ifinhabit = "";

	-- Get Price
	local price = "default:gold_ingot 2";

	if (btype ~= 'road' and mg_villages.BUILDINGS[btype]) then
		local plot_descr = S("Plot No. : @1, with @2", tostring( plot_nr ), tostring( mg_villages.BUILDINGS[btype].scm))

		if (mg_villages.BUILDINGS[btype].price) then
			price = mg_villages.BUILDINGS[btype].price;
		elseif (mg_villages.BUILDINGS[btype].typ and mg_villages.prices[ mg_villages.BUILDINGS[btype].typ ]) then
			price = mg_villages.prices[ mg_villages.BUILDINGS[btype].typ ];
		end
		-- Get if is inhabitant house
		if (mg_villages.BUILDINGS[btype].inh and mg_villages.BUILDINGS[btype].inh > 0 ) then
			ifinhabit = "label[0.3,2.2;"..S("Owners of this plot count as village inhabitants.").."]";
		end
	end
	-- Determine price depending on building type
	local price_stack= ItemStack( price );


	-- If nobody owns the plot
	if (not(owner) or owner=='') then

		formspec = original_formspec ..
			"label[0.3,1;"..S("You can buy this plot for").."]".. 
				"label[3.5,1.7;"..tostring( price_stack:get_count() ).." x ]"..
				"item_image[4,1.5;0.8,0.8;"..(  price_stack:get_name() ).."]"..
				ifinhabit..
				"button[3,3.4;1.5,0.5;buy;"..S("Buy plot").."]"..
				"button_exit[5.75,3.4;1.5,0.5;abort;"..S("Exit").."]";
				--"button_exit[4,3.4;1.5,0.5;abort;"..S("Exit").."]";

		-- On Press buy button
		if (fields['buy']) then
			local inv = player:get_inventory();

			if not mg_villages.all_villages[village_id].ownerlist then
				mg_villages.all_villages[village_id].ownerlist = {}
			end

			-- Check if player already has a house in the village
			if mg_villages.all_villages[village_id].ownerlist[pname] then
				formspec = formspec.."label[0.3,1.9;"..S("Sorry. You already have a plot in this village.").."]";

			-- Check if the price can be paid
			elseif( inv and inv:contains_item( 'main', price_stack )) then
				formspec = original_formspec..
					"label[0.3,1;"..S("Congratulations! You have bought this plot.").."]"..
					"button_exit[5.75,3.4;1.5,0.5;abort;"..S("Exit").."]";
				mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner = pname;
				if mg_villages.all_villages[village_id].ownerlist then
					mg_villages.all_villages[village_id].ownerlist[pname] = true;
				else
					mg_villages.all_villages[village_id].ownerlist[pname] = true;
				end
				meta:set_string('infotext', S("Plot No.").." "..tostring( plot_nr ).." "..S("with").." "..tostring( mg_villages.BUILDINGS[btype].scm).." ("..S("owned by").." "..tostring( pname )..")");
				-- save the data so that it survives server restart
				mg_villages.save_data();
				-- substract the price from the players inventory
				inv:remove_item( 'main', price_stack );
			else
				formspec = formspec.."label[0.3,1.9;"..S("Sorry. You are not able to pay the price.").."]";
			end
		end

	-- If player is the owner of the plot
	elseif (owner==pname) then

		-- Check if inhabitant house
		if(btype ~= 'road'
			and mg_villages.BUILDINGS[btype]
			and mg_villages.BUILDINGS[btype].inh
			and mg_villages.BUILDINGS[btype].inh > 0 ) then

			ifinhabit = "label[0.3,1.5;"..S("You are allowed to modify the common village area.").."]";
		end

		formspec = original_formspec.."size[8,4,true]"..
			default.gui_bg..default.gui_bg_img..
			"label[0.3,1;"..S("This is your plot. You have bought it.").."]"..
			"button[0.25,3.4;3.5,0.5;add_remove;"..S("Add/Remove Players").."]"..
			ifinhabit..
			"button_exit[3.75,3.4;2.0,0.5;abandon;"..S("Abandon plot").."]"..
			"button_exit[5.75,3.4;1.5,0.5;abort;"..S("Exit").."]";

		-- If Player wants to abandon plot
		if(fields['abandon'] ) then
			formspec = original_formspec..
				"label[0.3,1;"..S("You have abandoned this plot.").."]"..
				"button_exit[5.75,3.4;1.5,0.5;abort;"..S("Exit").."]";
			mg_villages.all_villages[village_id].ownerlist[pname] = nil;
			mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit = {}
			mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner = nil;
			-- Return price to player
			local inv = player:get_inventory();
			inv:add_item( 'main', price_stack );
			meta:set_string('infotext', S("Plot No.").." "..tostring( plot_nr ).." "..S("with").." "..tostring( mg_villages.BUILDINGS[btype].scm) );
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
				default.gui_bg..default.gui_bg_img..
				"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
				"textarea[0.3,0.2;8,2.5;ownerplayers;"..S("Trusted Players")..";"..output.."]"..
				"button[3,2.5;2,0.5;savetrustees;"..S("Save").."]";

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
		formspec = original_formspec.."label[0.3,1;"..tostring( owner )..' '..S("owns this plot")..".]"..
					"button_exit[3,3.4;1.5,0.5;abort;"..S("Exit").."]";
	end

	minetest.show_formspec( pname, "mg_villages:plotmarker", formspec );
end



mg_villages.form_input_handler = function( player, formname, fields)
--	mg_villages.print(mg_villages.DEBUG_LEVEL_NORMAL,minetest.serialize(fields));
	if( not( mg_villages.ENABLE_PROTECTION )) then
		return false;
	end
	if( (formname == "mg_villages:plotmarker") and fields.pos2str and not( fields.abort )) then
		local pos = minetest.string_to_pos( fields.pos2str );
		mg_villages.plotmarker_formspec( pos, formname, fields, player );
		return true;
	end
	return false;
end


minetest.register_on_player_receive_fields( mg_villages.form_input_handler )
