-- get the id of the village pos lies in (or nil if outside of villages)
mg_villages.get_town_id_at_pos = function( pos )
	for id, v in pairs( mg_villages.all_villages ) do
		local size = v.vs * 3;
		if(   ( math.abs( pos.x - v.vx ) < size )
		  and ( math.abs( pos.z - v.vz ) < size )
		  and ( pos.y - v.vh < 40 and v.vh - pos.y < 10 )) then
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
		minetest.chat_send_player( name, 'Error: This area does not belong to a village.');
		return;
	end

	minetest.chat_send_player( name, "You are inside of the area of the village "..
		tostring( mg_villages.all_villages[ found ].name )..
		". The inhabitants do not allow you any modifications.");
end );
