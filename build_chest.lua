-----------------------------------------------------------------------------------------------------------------
-- interface for manual placement of houses 
-----------------------------------------------------------------------------------------------------------------

-- 25.12.13 cleaned up namespace

-- from random_buildings, these functions/values are used:
--   random_buildings.building[ building_name ]: menu_path, nodes   
--   random_buildings.spawn_building(..)
--   random_buildings.build_building(..)
--   random_buildings.spawn_trader_at_building(..)


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
	for z = 1, data.size.z do
	for y = 1, data.size.y do
	for x = 1, data.size.x do

		local a = data.scm_data_cache[y][x][z];
		local id = 0;
		if( type( a )=='table' ) then
			id = a[1];
		else
			id = a;
		end
		if( not( statistic[ id ] )) then
			statistic[ id ] = { id, 1};
		else
			statistic[ id ] = { id, statistic[ id ][ 2 ]+1 };
		end
	end
	end
	end
	table.sort( statistic, build_chest_comp );
	return statistic;
end


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
		build_chest.read_building( building_name );
	end

	-- used for setting wood type or plant type etc.
	local set_wood_type_offset = 0;
	local extra_buttons        = "";

	for i,v in ipairs( build_chest.building[ building_name ].statistic ) do
		local name = build_chest.building[ building_name ].nodenames[ v[1]];	
		-- nodes that are to be ignored do not need to be replaced
		if( name ~= 'air' and name ~= 'ignore' and name ~= 'mg:ignore' ) then
			local anz  = v[2];
			-- find out if this node name gets replaced
			local repl = name;
			for j,r in ipairs( replacements ) do
				if( r and r[1]==name ) then
					repl = r[2];
				end
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

			if( i<#build_chest.building[ building_name ].statistic ) then
				formspec = formspec..",";
			end

			if( j == replace_row ) then
				replace_row_material = name;
				if( repl ~= name ) then
					replace_row_with     = repl;
				end
			end
			
			-- find out if there are any wood nodes that may need replacement
			for k,w in ipairs( replacements_wood.all ) do
				if( name == w ) then
					set_wood_type_offset = set_wood_type_offset + 1;
					extra_buttons = extra_buttons.."button[9.9,"..
						tostring( (set_wood_type_offset*0.9)+2.8 )..";3.0,0.5;set_wood;"..
						minetest.formspec_escape( w ).."]";
				end
			end
			j=j+1;
		end
	end
	formspec = formspec.."]";
	-- add the proceed-button as soon as all unkown materials have been replaced
	if( may_proceed ) then
		formspec = formspec.."button[9.9,9.0;2.0,0.5;proceed_with_scaffolding;Proceed]";
	end
	if( extra_buttons ) then
		formspec = formspec..extra_buttons..
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
	


build_chest.get_wood_list_formspec = function( pos, set_wood )
	local formspec = "label[1,2.2;Select replacement for "..tostring( set_wood )..".]"..
			 "label[1,2.5;Trees, saplings and other blocks will be replaced accordingly as well.]";
	for i,v in ipairs( replacements_wood.found ) do
		formspec = formspec.."item_image_button["..tostring(((i-1)%8)+1)..","..
			tostring(3+math.floor((i-1)/8))..";1,1;"..
			tostring( v )..";wood_selection;"..tostring(i).."]";
	end
	return formspec;
end


build_chest.apply_replacement_for_wood = function( pos, meta, old_material, new_material )

	local replacements  = minetest.deserialize( meta:get_string( 'replacements' ));
	if( not( replacements )) then
		replacements = {};
	end
	replacements_wood.replace_wood( replacements, old_material, new_material );

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
		build_chest.read_building( building_name );
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
      




--                       -- TODO: some nodes are double ones - i.e. doors
--                       -- TODO: given how much air there is, probably do not store air at all?
--                       -- TODO: stairs:stair_woodupside_down and its coutnerpart - slabs - are in effect the same as well...



-- building consists of several steps:
-- 0. cobble, tree
-- 1. wood, loam, everything else that doesn't fit elsewhere
-- 2. straw (for roof)
-- 3. window shutters, doors, halfdoors, gates
-- 4. straw mat, steel hoe, bucket water/lava
-- 5. furniture 
-- 6. bed and decoration
build_chest.update_needed_list = function( pos, step )

   local meta = minetest.env:get_meta( pos );
   local inv  = meta:get_inventory();
   local building_name = meta:get_string( 'building_name' );
   local material_type = meta:get_string( 'material_type');

   local menu_path     = build_chest.building[ building_name ].menu_path;

   -- at the beginning, *each* node is replaced by a scaffolding-like support structure
   local replacements = {};
   local node_needed_list = {};
   for k,v in pairs( build_chest.building[ building_name ].nodes ) do
      replacements[ v.node ] = build_chest.SUPPORT; 

      local node_needed = v.node;   -- name of the node we are working on
      local anz         = #v.posx;  -- how many of that type do we need?
      local needed_in_step = 1; -- building works in steps: basic materials (wood, straw, cobble, ..); doors, fences etc; hoe+water; furniture

      -- the workers supply the building with free dirt
      if(     v.node == 'default:dirt'
           or v.node == 'default:dirt_with_grass' 
           -- ignore the upper parts of doors
           or v.node == 'doors:door_wood_t_1'
           or v.node == 'doors:door_wood_t_2' ) then

         anz = 0;
         needed_in_step = 0;
      -- the lower part of the door counts as one door
      elseif( v.node == 'doors:door_wood_b_1' 
           or v.node == 'doors:door_wood_b_2' ) then

         node_needed = 'doors:door_wood';
         needed_in_step = 3; -- after the basic frame has been built

      elseif( v.node == 'cottages:half_door' 
           or v.node == 'cottages:half_door_inverted' ) then

         needed_in_step = 3;
         node_needed    = 'cottages:half_door';

      elseif( v.node == 'cottages:gate_open'
           or v.node == 'cottages:gate_closed' ) then

         needed_in_step = 3;
         node_needed    = 'cottages:gate_closed';

      elseif( v.node == 'cottages:window_shutter_open'
           or v.node == 'cottages:window_shutter_closed' ) then

         needed_in_step = 3;
         node_needed    = 'cottages:window_shutter_closed';

-- TODO: in general: require what the nodes gives when the player digs it (that ought to cover doors)
--       (at least as long as it's a single drop)

      --
      -- lumberjacks bring their own wood (provided they get an axe!)
      --
      elseif( menu_path[2]=='lumberjack'
-- TODO: node names may have to be adjusted once this is switched to blueprints
         and (v.node == 'moretrees:TYP_planks' 
           or v.node == 'moretrees:TYP_trunk'
           or v.node == 'moretrees:TYP_trunk_sideways'
           or v.node == 'moretrees:slab_TYP_planks'        
           -- they also build their own roofs
           or v.node == 'cottages:roof_wood'
           or v.node == 'cottages:roof_connector_wood'
           or v.node == 'cottages:roof_flat_wood' )) then

         anz = 1;
         needed_in_step = 1;
         -- lumberjacks love mese picks and use them to get wood
         node_needed = 'default:axe_mese';



      --
      -- clay traders dig clay, sandstone and sandstonebricks on their own
      --
      elseif( menu_path[2]=='clay'
         and (v.node == 'default:clay'
           or v.node == 'default:sand' 
           or v.node == 'default:desert_sand' 
           or v.node == 'default:sandstone'
           or v.node == 'default:sandstonebrick'        

           or v.node == 'stairs:slab_sandstone'
           or v.node == 'stairs:slab_sandstonebrick')) then

         anz = 1;
         needed_in_step = 1;
         -- clay traders dig their own clay and sandstone
         node_needed = 'default:shovel_mese';

      --
      -- clay traders know how to use furnaces on sand and clay lumps
      --
      elseif( menu_path[2]=='clay'
         and (v.node == 'default:brick'
           or v.node == 'default:glass'
           or v.node == 'stairs:slab_brick'
           or v.node == 'stairs:slab_glass')) then

         anz = 1;
         needed_in_steP = 1;
         -- clay traders produce their own brick and glass
         node_needed = 'default:furnace';
         -- one furnace is sufficient for production
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end
    

      --
      -- farmers produce farmland and grow plants; they also bring their own straw for roofs
      --
      elseif( menu_path[2]=='small_farm'
         and (v.node == 'farming:soil'
           or v.node == 'farming:soil_wet'
           or v.node == 'farming:cotton'
           or v.node == 'farming:cotton_1'
           or v.node == 'farming:cotton_2'       
           or v.node == 'farming:cotton_3' )) then

-- TODO: more suitable for large farms
--           or v.node == 'cottages:roof'
--           or v.node == 'cottages:roof_connector'
--           or v.node == 'cottages:roof_flat'
--           or v.node == 'cottages:roof_straw'
--           or v.node == 'cottages:roof_connector_straw'
--           or v.node == 'cottages:roof_flat_straw' )) then

         anz = 1;
         node_needed = 'farming:hoe_steel';
         needed_in_step = 4; -- step4: hoe + water
         -- one hoe is sufficient
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end


      -- water comes in buckets; one is enough (they can refill it...in theory)
      elseif( v.node == 'default:water_source' ) then
         anz = 1;
         node_needed = 'bucket:bucket_water';
         needed_in_step = 4; -- step4: hoe + water
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end
      -- same with lava
      elseif( v.node == 'default:lava_source' ) then
         anz = 1;
         node_needed = 'bucket:bucket_lava';
         needed_in_step = 4; -- step4: hoe + water (well, ok, and lava)
         if( node_needed_list[ node_needed ] and node_needed_list[ node_needed ] > 0 ) then
            anz = 0;
         end

      -- those nodes can not be placed
      elseif( v.node == 'default:water_flowing'
           or v.node == 'default:lava_flowing' ) then
         anz = 0;

      -- in the farm_tiny_?.we buildings, sandstone is used for the floor, and clay for the lower walls
      elseif( v.node == 'default:sandstone' 
           or v.node == 'default:clay'
           or v.node == 'cottages:straw_ground' ) then
         node_needed = 'cottages:loam';
         needed_in_step = 1;

      -- for the various roof parts, we need straw; the roof can later be upgraded
      elseif( v.node == 'cottages:roof'
           or v.node == 'cottages:roof_connector'
           or v.node == 'cottages:roof_flat'
           or v.node == 'cottages:roof_straw'
           or v.node == 'cottages:roof_connector_straw'
           or v.node == 'cottages:roof_flat_straw' ) then

         anz = math.ceil( anz/3 ); -- one straw bale can be turned into several roof parts
         node_needed = 'cottages:straw_bale';
         needed_in_step = 2;


      -- do not add this before the walls are standing...
      elseif( v.node == 'default:torch' ) then
         needed_in_step = 5;

      -- these chests are diffrent so that they can be filled differently by fill_chests.lua
      -- chests count as furniture and are added in the second step
      elseif( v.node == 'cottages:chest_private' 
           or v.node == 'cottages:chest_work' 
           or v.node == 'cottages:chest_storage'
           or v.node == 'default:chest' ) then
         node_needed = 'default:chest'; 
         needed_in_step = 5;
      
      -- furniture and outside decoration is nothing the future inhabitant needs immediately; it can be supplied after moving in
      elseif( v.node == 'cottages:bench' 
           or v.node == 'cottages:table'
           or v.node == 'cottages:shelf'
           or v.node == 'cottages:washing' 
           or v.node == 'cottages:wagon_wheel' 
           or v.node == 'cottages:tub' ) then
         needed_in_step = 6;

      elseif( v.node == 'cottages:barrel'
           or v.node == 'cottages:barrel_open'
           or v.node == 'cottages:barrel_lying'
           or v.node == 'cottages:barrel_lying_open' ) then
         node_needed = 'cottages:barrel';
         needed_in_step = 6;

      -- at first, a simple straw mat is enough for the NPC to sleep on - and that can be created from straw
      -- changed so that the bed is built immediately
      elseif( v.node == 'cottages:bed_head'
           or v.node == 'cottages:bed_foot'
           or v.node == 'cottages:sleeping_mat'
           or v.node == 'cottages:straw_mat' ) then

         if(     v.node=='cottages:straw_mat') then -- or step == 4) then
            node_needed = 'cottages:straw_mat';
            replacements[ 'cottages:bed_head'    ] = 'cottages:staw_mat';
            replacements[ 'cottages:bed_foot'    ] = 'cottages:staw_mat';
            replacements[ 'cottages:sleeping_mat'] = 'cottages:staw_mat';
            replacements[ 'cottages:straw_mat'   ] = 'cottages:staw_mat';
            needed_in_step = 4;
         elseif( v.node == 'cottages:sleeping_mat') then -- or step == 5 ) then
            node_needed = 'cottages:sleeping_mat';
            replacements[ 'cottages:bed_head'    ] = 'cottages:sleeping_mat';
            replacements[ 'cottages:bed_foot'    ] = 'cottages:sleeping_mat';
            replacements[ 'cottages:sleeping_mat'] = 'cottages:sleeping_mat';
            needed_in_step = 5;
         elseif( true ) then -- and step == 6 ) then
            node_needed = v.node;
            replacements[ 'cottages:bed_head'    ] = 'cottages:bed_head';
            replacements[ 'cottages:bed_foot'    ] = 'cottages:bed_foot';
            needed_in_step = 6;
         else
            anz = 0;
         end

      -- a basic house has fence posts as windows; glass panes are a later upgrade
      elseif( v.node == 'cottages:glass_pane' 
           or v.node == 'default:fence_wood' ) then
         node_needed = 'default:fence_wood';
         needed_in_step = 2;

      -- wooden slabs and stairs are crafted automaticly
      elseif( v.node == 'stairs:slab_wood' 
           or v.node == 'stairs:stair_wood' 
           or v.node ==  'stairs:slab_woodupside_down' ) then
        
         anz = math.ceil( anz/2 ); -- stairs are thus minimally cheaper
         node_needed = 'default:wood';
         needed_in_step = 1;

      -- same with cobble: cobble slabs and stairs are crafted automaticly
      elseif( v.node == 'stairs:slab_cobble' 
           or v.node == 'stairs:stair_cobble' 
           or v.node == 'stairs:slab_cobbleupside_down' ) then
        
         anz = math.ceil( anz/2 ); -- stairs are thus minimally cheaper
         node_needed = 'default:cobble';
         needed_in_step = 0;

      elseif( v.node == 'default:cobble' 
         or   v.node == 'default:tree' ) then
         needed_in_step = 0;
      end
      -- TODO: replace default:tree and default:wood with the local wood the village is specialized on?
      -- TODO: combine bed_foot and bed_head into one to save space?

      -- it is better if these buildings request all materials in one step (they produce most material by themshelves)
      if(( menu_path[2]=='lumberjack'
        or menu_path[2]=='clay' 
        or menu_path[2]=='small_farm' )
        and needed_in_step > 1 ) then
         needed_in_step = 2;
      end
      -- list the items as needed in the suitable fields
      if( anz > 0 and needed_in_step == step) then

         -- avoid new stacks for nodes with diffrent facedir
         if( not(node_needed_list[ node_needed ] )) then
            node_needed_list[ node_needed ] = anz;
         else
            node_needed_list[ node_needed ] = node_needed_list[ node_needed ] + anz;
         end

      end
   end 

   -- insert full stacks into the list of needed things
   for k, v in pairs(node_needed_list) do
      inv:add_item("needed", k.." "..node_needed_list[ k ]);
      --print('  adding needed items: '..tostring( k.." "..node_needed_list[ k ] ));
   end

   meta:set_int( 'building_stage', step );

   -- if in this step nothing is needed, move to the next step
   if( inv:is_empty( 'needed') and step < 6 and (#node_needed_list==0)) then
      return build_chest.update_needed_list( pos, step+1 );
   end

   return replacements;
end



-- built support platform and scaffholding where building will be built
build_chest.build_scaffolding = function( pos, player, building_name )

   local name = player:get_player_name();

   -- rotate the building so that it faces the player
   local node = minetest.env:get_node( pos );
   local meta = minetest.env:get_meta( pos );
   local inv  = meta:get_inventory();

   local start_pos = {x=pos.x, y=pos.y, z=pos.z};

   local mirror = math.random(0,1); -- TODO

   local selected_building = build_chest.building[ building_name ];

   local max    = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
--   local min    = { x = selected_building.min.x, y = selected_building.min.y, z = selected_building.min.z };

   -- make sure the building always extends forward and to the right of the player
   local rotate = 0;
   if(     node.param2 == 0 ) then rotate = 3;  if( mirror==1 ) then start_pos.x = start_pos.x - max.x + max.z; end -- z gets larger
   elseif( node.param2 == 1 ) then rotate = 0;  start_pos.z = start_pos.z - max.z; -- x gets larger  
   elseif( node.param2 == 2 ) then rotate = 1;  start_pos.z = start_pos.z - max.x; 
                                                if( mirror==0 ) then start_pos.x = start_pos.x - max.z; -- z gets smaller 
                                                else                 start_pos.x = start_pos.x - max.x; end
   elseif( node.param2 == 3 ) then rotate = 2;  start_pos.x = start_pos.x - max.x; -- x gets smaller 
   end
      

   -- the chest becomes part of the building
   if(     node.param2 == 0 ) then start_pos.z = start_pos.z - 1;
   elseif( node.param2 == 1 ) then start_pos.x = start_pos.x - 1;
   elseif( node.param2 == 2 ) then start_pos.z = start_pos.z + 1;
   elseif( node.param2 == 3 ) then start_pos.x = start_pos.x + 1;
   end

 minetest.chat_send_player( name, "Facedir: "..minetest.serialize( node.param2 ).." rotate: "..tostring( rotate ).." mirror: "..tostring( mirror));

   local replacements = build_chest.update_needed_list( pos, 0 ); -- request the material for the very first building step

   -- default replacements that will always be supplied
   -- the inhabitants have enough dirt to spare
   replacements[ 'default:dirt'            ] = 'default:dirt';
   replacements[ 'default:dirt_with_grass' ] = 'default:dirt';
   -- soil has not been worked on yet and thus is just dirt
   replacements[ 'farming:soil'     ] = 'default:dirt';
   replacements[ 'farming:soil_wet' ] = 'default:dirt';
   -- weed can be made to grow everywhere..so why not on dirt
   replacements[ 'farming:cotton'   ] = 'farming:weed'; 
   replacements[ 'farming:cotton_1' ] = 'farming:weed'; 
   replacements[ 'farming:cotton_2' ] = 'farming:weed'; 

   --print( 'nodes: '..minetest.serialize( build_chest.building[ building_name ].nodes ))
   --print( 'replacements: '..minetest.serialize( replacements )); 

   -- so that the building with its possible platform does not end up too high
   --start_pos.y = start_pos.y - 1;
   -- save the data for later removal/improvement of the building in the chest
   meta:set_string( 'start_pos', minetest.serialize( start_pos ) );
   -- building_name has already been saved
   meta:set_int( 'rotate', rotate );
   meta:set_int( 'mirror', mirror );
   meta:set_string( 'replacements', minetest.serialize( replacements ));
print('SETTING replacements IN build_scaffolding');
   -- the replacements are not yet of much intrest
   local result = random_buildings.spawn_building( start_pos, building_name, rotate, mirror, replacements, nil, pos); -- do not spawn an inhabitant yet
   -- in case spawn_building decided to place the building higher
   meta:set_string( 'start_pos', minetest.serialize( {x=result.x, y=result.y, z=result.z}) );

   if( result.status == 'aborted' ) then
      minetest.chat_send_player(name, "Could not build here! Reason: "..tostring( result.reason or 'unknown'));
   elseif( result.status == 'need_to_wait' ) then
      minetest.chat_send_player(name, "The terrain has not been generated/loaded completely. Please wait a moment and try again!");
   elseif( result.status ~= 'ok' ) then
      minetest.chat_send_player(name, "Error: Could not build. Status: "..tostring( result.reason or 'unknown' ));
   else
      minetest.chat_send_player(name, "Building of scaffolding for building finished. Status: "..minetest.serialize( result ));
   end

   return result;
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


	if( page == 'main') then
      
		local building_name = meta:get_string('building_name' );
		local start_pos     = meta:get_string('start_pos');

		local backup_file   = meta:get_string('backup');
		if( backup_file and backup_file ~= "" ) then
			formspec = formspec.."button[3,3;3,0.5;restore_backup;Restore original landscape]";
			meta:set_string('formspec', formspec );
			return;
		end

		local set_wood      = meta:get_string('set_wood' );
		if( set_wood and set_wood ~= "" ) then
			formspec = formspec..build_chest.get_wood_list_formspec( pos, set_wood );
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
			if( start_pos and start_pos.x ) then
-- TODO: also show size and such
				-- do replacements for realtest where necessary (this needs to be done only once)
				local replacements = {};
				replacements_realtest.replace( replacements );
				meta:set_string( 'replacements', minetest.serialize( replacements ));

				formspec = formspec..build_chest.get_replacement_list_formspec( pos );
				meta:set_string('formspec', formspec );
				-- TODO minetest.place_schematic( start_pos, options[1]..'.mts', meta:get_string('rotate'), meta:get_string('replacements'), true );
				return;
			end
			meta:set_string( 'selected_building', "" );
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

      
      -- this is not a very efficient way to implement a menu; for this case, it is sufficient
      for k,v in pairs( build_chest.building ) do
         if( k ~= nil and v.menu_path ~= nil and #v.menu_path>0) then
             local found = true;

             for i,p in ipairs( current_path ) do
                if( i<=(#v.menu_path )) then
                   if( v.menu_path[i] ~= p ) then 
                      found = false;
                   end
                end
             end

             if( found ) then
                if( #v.menu_path > depth ) then
                   -- only insert entries we have not found yet
                   local f2 = false;
                   for j,ign in ipairs( options ) do
                      if( ign == v.menu_path[(depth+1)] ) then
                         f2 = true;
                      end
                   end
                   -- avoid duplicates
                   if( not( f2 )) then
                      table.insert( options, v.menu_path[(depth+1)] );
                   end
                elseif( (not( material_type ) or material_type == '' ) and v.menu_path[2]=='lumberjack') then

                   -- ask for wood material
                   -- default:tree and default:jungletree
                   options = { 'normal', 'jungletree' };
                   -- trees from moretrees - provided they are enabled
                   if( moretrees ) then
                      if( moretrees.enable_apple_tree ) then table.insert( options, 'apple tree' ); end
                      if( moretrees.enable_oak        ) then table.insert( options, 'oak'        ); end
                      if( moretrees.enable_sequoia    ) then table.insert( options, 'sequoia'    ); end
                      if( moretrees.enable_palm       ) then table.insert( options, 'palm'       ); end
                      if( moretrees.enable_pine       ) then table.insert( options, 'pine'       ); end
                      if( moretrees.enable_rubber_tree) then table.insert( options, 'rubber tree'); end
                      if( moretrees.enable_willow     ) then table.insert( options, 'willow'     ); end
                      if( moretrees.enable_birch      ) then table.insert( options, 'birch'      ); end
                      if( moretrees.enable_spruce     ) then table.insert( options, 'spruce'     ); end
--                      if( moretrees.enable_jungle_tree) then table.insert( options, 'jungletree' ); end
                      if( moretrees.enable_fir        ) then table.insert( options, 'fir'        ); end
                      if( moretrees.enable_beech      ) then table.insert( options, 'beech'      ); end
                   end
  
                   -- TODO:realtest-trees
                   if( true ) then
                      table.insert( options, 'ash (small)' );
                      table.insert( options, 'aspen (small)' );
                      table.insert( options, 'birch (small)' );
                      table.insert( options, 'maple (small)' );
                      table.insert( options, 'chestnut (small)' );
                      table.insert( options, 'pine (small)' );
                      table.insert( options, 'spruce (small)' );
                   end


                elseif( (not( material_type ) or material_type == '' ) and v.menu_path[2]=='clay') then
                   options = {};
                   -- desert_stone and stone would fit optically
                   local clay_materials = {'clay','brick','sandstone','sandstonebrick' }; 
                   for i,v in ipairs( clay_materials ) do
                      for j,w in ipairs( clay_materials ) do
                         table.insert( options, v..' and '..w );
                      end
                   end
                else
                   -- found an end node of the menu graph
                   local building_name = v.menu_path[( depth )];

                   if( not( build_chest.building[ building_name ])) then
                      minetest.chat_send_player(player:get_player_name(), "ERROR: Building \""..minetest.serialize( building_name ).."\" does not exist!");
                      return;
                   end
                   meta:set_string( 'building_name', building_name );

                   -- set new formspecs for the input materials - this is taken from towntest
                   meta:get_inventory():set_size("main", 8)
                   meta:get_inventory():set_size("needed", 8*5) -- 2 larger than what is displayed - as a reserve for houses with many diffrent nodes
                   meta:get_inventory():set_size("builder", 2*5) -- there are many items he has to carry around

                   local result = build_chest.build_scaffolding( pos, player, building_name );
                   if( not( result ) or result.status ~= 'ok' ) then
                      meta:set_string( 'current_path',  minetest.serialize( {} ));
                      meta:set_string( 'building_name', '');
                      build_chest.update_formspec( pos, 'main', player );
                      return;
                   end

                   formspec = "size[12,10]"

--                          "size[10.5,9]"
                        .."list[current_player;main;0,6;8,4;]"

                        .."label[0,0; items needed:]"
                        .."list[current_name;needed;0,0.5;8,3;]"

                        .."label[0,3.5; put items here to build:]"
                        .."list[current_name;main;0,4;8,1;]"..

--                        .."label[8.5,1; builder:]"
--                        .."list[current_name;builder;8.5,1.5;2,5;]"..

--                        .."label[8.5,3.5; lumberjack:]"
--                        .."list[current_name;lumberjack;8.5,4;2,2;]"..

                            "label[8.5,6.0;Project:]"   .."label[9.5,6.0;"..(building_name or '?').."]"..
                            "label[8.5,6.4;Owner:]"     .."label[9.5,6.4;"..(owner_name or "?").."]"..
                            "label[8.5,6.8;Village:]"   .."label[9.5,6.8;"..(village_name or "?").."]"..
                            "label[8.5,7.2;located at]" .."label[9.5,7.2; "..(minetest.pos_to_string( village_pos ) or '?').."]"..
                            "label[8.5,7.6;Distance:]"  .."label[9.5,7.6;"..tostring( distance ).." m]"..

                            "button[9.0,8.5;2,0.5;abort;Abort building]"  .."label[9.5,7.6;"..tostring( distance ).." m]";


                   meta:set_string( "formspec", formspec );
                   return;
                end
             end
         end
      end

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
      local building_name = meta:get_string( 'building_name' );
                   formspec = "size[12,10]"

--                          "size[10.5,9]"
                        .."list[current_player;main;0,6;8,4;]"

                        .."label[0,3.5;please remove these items:]"
                        .."list[current_name;main;0,4;8,1;]"..

                            "label[8.5,6.0;Project:]"   .."label[9.5,6.0;"..(building_name or '?').."]"..
                            "label[8.5,6.4;Owner:]"     .."label[9.5,6.4;"..(owner_name or "?").."]"..
                            "label[8.5,6.8;Village:]"   .."label[9.5,6.8;"..(village_name or "?").."]"..
                            "label[8.5,7.2;located at]" .."label[9.5,7.2; "..(minetest.pos_to_string( village_pos ) or '?').."]"..
                            "label[8.5,7.6;Distance:]"  .."label[9.5,7.6;"..tostring( distance ).." m]"..

                            "button[9.0,8.5;2,0.5;abort;Remove building]"  .."label[9.5,7.6;"..tostring( distance ).." m]";

   elseif( page == 'finished' ) then
      
      -- when finished, let the NPC move into the building (provided there is one that lives there)
      build_chest.move_trader_in( pos );
      
      local building_name = meta:get_string( 'building_name' );
                   formspec = "size[12,11]"..
                            "label[1,1;Building finished successfully.]"..

                            "button[0.3,2;4,0.5;make_white;paint building white]"..
                            "button[0.3,3;4,0.5;make_brick;upgrade to brick]"..
                            "button[0.3,4;4,0.5;make_stone;upgrade to stone]"..
                            "button[0.3,5;4,0.5;make_cobble;upgrade to cobble]"..
                            "button[0.3,6;4,0.5;make_loam;downgrade to loam]"..
                            "button[0.3,7;4,0.5;make_wood;turn into wood]"..
                            "button[0.3,8;4,0.5;make_junglewood;turn into dark junglewood]"..
                            "button[0.3,9;4,0.5;white_and_jungle;bottom white, top junglewood]"..
                            "button[0.3,10;4,0.5;white_and_loam;bottom white, top loam]"..

                            "button[4.3,2;4,0.5;roof_straw;turn roof into straw]"..
                            "button[4.3,3;4,0.5;roof_tree;turn roof into tree]"..
                            "button[4.3,4;4,0.5;roof_black;roof: black (asphalt)]"..
                            "button[4.3,5;4,0.5;roof_red;roof: red (terracotta)]"..
                            "button[4.3,6;4,0.5;roof_brown;roof: brown (wood)]"..

                            "button[4.3,7;4,0.5;make_glass;upgrade to glass panes]"..
                            "button[4.3,8;4,0.5;make_noglass;downgrade to simple windows]"..

                            "button[8.3,2;4,0.5;cobble_cobble;turn cobble into cobble]"..
                            "button[8.3,3;4,0.5;cobble_brick;turn cobble into stonebrick]"..
                            "button[8.3,4;4,0.5;cobble_stone;turn cobble into stone]"..
                            "button[8.3,5;4,0.5;wood_junglewood;turn wood into junglewood]"..

                            "button[8.3,1;4,0.5;wood_wood;turn wood into wood]"..

                            "label[8.5,6.0;Object:]"    .."label[9.5,6.0;"..(building_name or '?').."]"..
                            "label[8.5,6.4;Owner:]"     .."label[9.5,6.4;"..(owner_name or "?").."]"..
                            "label[8.5,6.8;Village:]"   .."label[9.5,6.8;"..(village_name or "?").."]"..
                            "label[8.5,7.2;located at]" .."label[9.5,7.2; "..(minetest.pos_to_string( village_pos ) or '?').."]"..
                            "label[8.5,7.6;Distance:]"  .."label[9.5,7.6;"..tostring( distance ).." m]"..
                            "button[9.0,8.5;2,0.5;abort;Remove building]"  .."label[9.5,7.6;"..tostring( distance ).." m]";


   end

   meta:set_string( "formspec", formspec );
end


build_chest.upgrade_building = function( pos, player, old_material, new_material )

  local meta = minetest.env:get_meta(pos);

  local building_name = meta:get_string( 'building_name');
  local start_pos     = minetest.deserialize( meta:get_string( 'start_pos' ));
  local rotate        = meta:get_int( 'rotate' );
  local mirror        = meta:get_int( 'mirror' );

  if( not( build_chest.building[ building_name ] )) then
     minetest.chat_send_player( player:get_player_name(), 'Sorry. This building type is not known. Changing it is not possible.');
     return;
  end

  local replacements_orig = minetest.deserialize( meta:get_string( 'replacements'));
  local replacements      = {};
  replacements[      old_material ] = new_material;  
  replacements_orig[ old_material ] = new_material;  
  meta:set_string( 'replacements', minetest.serialize( replacements_orig ));
print('SETTING replacements IN upgrade_building');
  random_buildings.build_building( start_pos, building_name, rotate, mirror, platform_materials, replacements_orig, replacements, 0, pos );
  build_chest.update_formspec( pos, 'finished', player );
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


	elseif( fields.wood_selection ) then
		local nr = tonumber( fields.wood_selection );
		if( nr > 0 and nr <= #replacements_wood.found ) then
			local new_wood = replacements_wood.found[ nr ];
			local set_wood = meta:get_string( 'set_wood' );
			if( set_wood and new_wood ~= set_wood ) then
				build_chest.apply_replacement_for_wood( pos, meta, set_wood, new_wood );
			end
			-- go back in the menu
			meta:set_string( 'set_wood', nil );
		end
		build_chest.update_formspec( pos, 'main', player );


	elseif( fields.set_wood ) then
		meta:set_string('set_wood', fields.set_wood );
		build_chest.update_formspec( pos, 'main', player );


	elseif( fields.proceed_with_scaffolding ) then
		local building_name = meta:get_string('building_name');
		local start_pos     = minetest.deserialize( meta:get_string('start_pos'));
		local end_pos       = minetest.deserialize( meta:get_string('end_pos'));
-- TODO: <worldname>/schems/playername_x_y_z_burried_rotation.mts
		local filename      = "todo.mts";
print('CREATING schematic '..tostring( filename )..' from '..minetest.serialize( start_pos )..' to '..minetest.serialize( end_pos ));
		-- store a backup of the original landscape
		minetest.create_schematic( start_pos, end_pos, nil, filename, nil);
		-- place the building
-- TODO: use scaffolding here (exchange some replacements)
print('USING ROTATION: '..tostring( meta:get_string('rotate')));
		minetest.place_schematic( start_pos, building_name..'.mts', meta:get_string('rotate'), minetest.deserialize( meta:get_string('replacements')), true );
-- TODO: all those calls to on_construct need to be done now!
-- TODO: handle metadata
		meta:set_string('backup', filename );
		build_chest.update_formspec( pos, 'main', player );

	-- restore the original landscape
	elseif( fields.restore_backup ) then
		local start_pos     = minetest.deserialize( meta:get_string('start_pos'));
		local end_pos       = minetest.deserialize( meta:get_string('end_pos'));
		local backup_file   = meta:get_string( 'backup' );
		if( start_pos and end_pos and start_pos.x and end_pos.x and backup_file ) then
			minetest.place_schematic( start_pos, backup_file, "0", {}, true );
			meta:set_string('backup', nil );
		end
		build_chest.update_formspec( pos, 'main', player );
	

		

-- TODO
   -- abort the building - remove scaffolding
   elseif( fields.abort ) then

      local inv  = meta:get_inventory();

      if( not( inv:is_empty('main' ))) then
          minetest.chat_send_player( player:get_player_name(), 'Please remove the surplus materials first!' );
          return;
      end

      local start_pos     = minetest.deserialize( meta:get_string( 'start_pos' ));
      local building_name = meta:get_string( 'building_name');
      local rotate        = meta:get_int( 'rotate' );
      local mirror        = meta:get_int( 'mirror' );
      local platform_materials = {};
      local replacements = minetest.deserialize( meta:get_string( 'replacements' ));
      -- action is remove in this case
      random_buildings.build_building( start_pos, building_name, rotate, mirror, platform_materials, replacements, nil, 2, pos );

      -- reset the needed materials in the building chest
      for i=1,inv:get_size("needed") do
         inv:set_stack("needed", i, nil)
      end

      meta:set_string( 'current_path', minetest.serialize( {} ));
      meta:set_string( 'building_name', "" );
      meta:set_string( 'material_type', "" );
      build_chest.update_formspec( pos, 'main', player );



   -- chalk the loam to make it white
   elseif( fields.make_white ) then
      build_chest.upgrade_building( pos, player, 'cottages:loam', 'default:clay' );
      build_chest.upgrade_building( pos, player, 'default:clay',          'default:clay' );

   -- turn chalked loam into brick
   elseif( fields.make_brick or fields.make_white) then
      build_chest.upgrade_building( pos, player, 'cottages:loam', 'default:brick' );
      build_chest.upgrade_building( pos, player, 'default:clay',          'default:brick' );

   -- turn it into stone
   elseif( fields.make_stone ) then
      build_chest.upgrade_building( pos, player, 'cottages:loam', 'default:stone' );
      build_chest.upgrade_building( pos, player, 'default:clay',          'default:stone' );

   -- turn it into cobble
   elseif( fields.make_cobble ) then
      build_chest.upgrade_building( pos, player, 'cottages:loam', 'default:cobble' );
      build_chest.upgrade_building( pos, player, 'default:clay',          'default:cobble' );

   elseif( fields.make_loam ) then
      build_chest.upgrade_building( pos, player, 'cottages:loam', 'cottages:loam' );
      build_chest.upgrade_building( pos, player, 'default:clay',          'cottages:loam' );

   elseif( fields.make_wood ) then
      build_chest.upgrade_building( pos, player, 'cottages:loam', 'default:wood' );
      build_chest.upgrade_building( pos, player, 'default:clay',          'default:wood' );

   elseif( fields.roof_straw ) then
      build_chest.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_straw' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_straw' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_straw' );

   elseif( fields.roof_tree  ) then
      build_chest.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_wood' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_wood' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_wood' );

   elseif( fields.roof_black ) then
      build_chest.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_black' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_black' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_black' );

   elseif( fields.roof_red   ) then
      build_chest.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_red' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_red' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_red' );

   elseif( fields.roof_brown ) then
      build_chest.upgrade_building( pos, player, 'cottages:roof_straw',           'cottages:roof_brown' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_flat_straw',      'cottages:roof_flat_brown' );
      build_chest.upgrade_building( pos, player, 'cottages:roof_connector_straw', 'cottages:roof_connector_brown' );

   elseif( fields.make_glass ) then
      build_chest.upgrade_building( pos, player, 'cottages:glass_pane', 'cottages:glass_pane' );
   
   elseif( fields.make_noglass ) then
      build_chest.upgrade_building( pos, player, 'cottages:glass_pane', 'default:fence_wood' );

   elseif( fields.cobble_cobble ) then
      build_chest.upgrade_building( pos, player, 'default:cobble',                'default:cobble' );
      build_chest.upgrade_building( pos, player, 'stairs:slab_cobble',            'stairs:slab_cobble' );

   elseif( fields.cobble_brick ) then
      build_chest.upgrade_building( pos, player, 'default:cobble',                'default:stonebrick' );
      build_chest.upgrade_building( pos, player, 'stairs:slab_cobble',            'stairs:slab_stonebrick' );

   elseif( fields.cobble_stone ) then
      build_chest.upgrade_building( pos, player, 'default:cobble',                'default:stone' );
      build_chest.upgrade_building( pos, player, 'stairs:slab_cobble',            'stairs:slab_stone' );

   elseif( fields.wood_junglewood ) then
      build_chest.upgrade_building( pos, player, 'default:wood',                  'default:junglewood' );

   elseif( fields.wood_wood ) then
      build_chest.upgrade_building( pos, player, 'default:wood',                  'default:wood' );

   elseif( fields.white_and_jungle ) then
      build_chest.upgrade_building( pos, player, 'cottages:clay',                 'cottages:clay' );
      build_chest.upgrade_building( pos, player, 'cottages:loam',                 'default:junglewood' );

   elseif( fields.white_and_loam ) then
      build_chest.upgrade_building( pos, player, 'cottages:clay',                 'cottages:clay' );
      build_chest.upgrade_building( pos, player, 'cottages:loam',                 'cottages:loam' );
   end

end



build_chest.move_trader_in = function( pos )

   local meta          = minetest.env:get_meta( pos );
   local building_name = meta:get_string( 'building_name');
   local rotate        = meta:get_int( 'rotate' );
   local start_pos     = minetest.deserialize( meta:get_string( 'start_pos' ));
   local menu_path     = build_chest.building[ building_name ].menu_path;


   local selected_building = build_chest.building[ building_name ];
   local max = {};
   if( rotate == 0 or rotate == 2 ) then 
      max  = { x = selected_building.max.x, y = selected_building.max.y, z = selected_building.max.z };
   else
      max  = { x = selected_building.max.z, y = selected_building.max.y, z = selected_building.max.x };
   end

   local trader_typ   = meta:get_string( 'material_type' );
   if( not( trader_typ )) then
      trader_typ = '';
   end


   if(     menu_path[2]=='lumberjack' ) then
      -- TODO: realtest-trees?
      trader_typ = trader_typ..'_wood';

   elseif( menu_path[2]=='clay'       ) then
      trader_typ = 'clay';

   elseif( menu_path[2]=='small_farm' ) then
      trader_typ = trader_typ..'_farmer';

   else
      trader_typ = '';
   end               

   -- actually spawn the trader 
   if( trader_typ ~= '' ) then
      random_buildings.spawn_trader_at_building( start_pos, max, trader_typ );
   end
end



build_chest.on_metadata_inventory_put = function( pos, listname, index, stack, player )

   local meta          = minetest.env:get_meta( pos );
   local inv           = meta:get_inventory();
   local input         = stack:get_name();
   local stage         = meta:get_int( 'building_stage' );

   -- this item is not needed
   if( not( stack ) or not(input) or not( inv:contains_item( 'needed', input..' 1' ))) then
      return;
   end

   -- find out how many of that item we nee
   local anz_needed = 0;
   local gesucht    = "";
   for i=1,inv:get_size("needed") do
      gesucht = inv:get_stack( 'needed', i );
      if( gesucht:get_name() == input ) then
         anz_needed = gesucht:get_count();
      end
   end

   -- not enough input yet
   if( anz_needed < 1 or not( inv:contains_item( 'main', input..' '..anz_needed  ))) then
      return;
   end
   inv:remove_item( 'main',   input..' '..anz_needed  );
   inv:remove_item( 'needed', input..' '..anz_needed  );


   local start_pos     = minetest.deserialize( meta:get_string( 'start_pos' ));
   local building_name = meta:get_string( 'building_name');
   local rotate        = meta:get_int( 'rotate' );
   local mirror        = meta:get_int( 'mirror' );
   local replacements_orig  = minetest.deserialize( meta:get_string( 'replacements' ));
   local platform_materials = {};
   local replacements       = {}; 

   local menu_path     = build_chest.building[ building_name ].menu_path;


   -- all parts for the building have been supplied
   if( inv:is_empty( 'needed')) then

      if( stage==nil or stage < 6 ) then
         build_chest.update_needed_list( pos, stage+1 ); -- request the material for the very first building step
      else

         -- there are leftover parts that need to be removed
         if( not( inv:is_empty( 'main' ))) then
            build_chest.update_formspec( pos, 'please_remove', player );
         else
            -- show the finished formspec
            build_chest.update_formspec( pos, 'finished', player );
         end
      end
   end



   -- straw is good for a lot of things! (mostly roof and beds)
   if(     input == 'cottages:straw_bale' ) then

      replacements[ 'cottages:roof'                ] = 'cottages:roof_straw';
      replacements[ 'cottages:roof_connector'      ] = 'cottages:roof_connector_straw';
      replacements[ 'cottages:roof_flat'           ] = 'cottages:roof_flat_straw';
      replacements[ 'cottages:roof_straw'          ] = 'cottages:roof_straw';
      replacements[ 'cottages:roof_connector_straw'] = 'cottages:roof_connector_straw';
      replacements[ 'cottages:roof_flat_straw'     ] = 'cottages:roof_flat_straw';

      replacements[ 'cottages:bed_head'            ] = 'cottages:straw_mat';
      replacements[ 'cottages:bed_foot'            ] = 'cottages:straw_mat';
      replacements[ 'cottages:sleeping_mat'        ] = 'cottages:straw_mat';
      replacements[ 'cottages:straw_mat'           ] = 'cottages:straw_mat';

   elseif( input == 'cottages:sleeping_mat' ) then

      replacements[ 'cottages:bed_head'            ] = 'cottages:sleeping_mat';
      replacements[ 'cottages:bed_foot'            ] = 'cottages:sleeping_mat';
      replacements[ 'cottages:sleeping_mat'        ] = 'cottages:sleeping_mat';

   elseif( input == 'cottages:bed_head' ) then
      replacements[ 'cottages:bed_head'            ] = 'cottages:bed_head';

   elseif( input == 'cottages:bed_foot' ) then
      replacements[ 'cottages:bed_foot'            ] = 'cottages:bed_foot';

   -- wooden slabs and stairs are included in the wood
   elseif( input == 'default:wood' ) then

      replacements[ 'default:wood'                ] = 'default:wood';
      replacements[ 'stairs:slab_wood'            ] = 'stairs:slab_wood';
      replacements[ 'stairs:stair_wood'           ] = 'stairs:stair_wood';
      replacements[ 'stairs:slab_woodupside_down' ] = 'stairs:slab_woodupside_down';

   -- same applies to cobble - no need to create seperate slabs
   elseif( input == 'default:cobble' ) then

      replacements[ 'default:cobble'              ] = 'default:cobble';
      replacements[ 'stairs:slab_cobble'          ] = 'stairs:slab_cobble';
      replacements[ 'stairs:stair_cobble'         ] = 'stairs:stair_cobble';
      replacements[ 'stairs:slab_cobbleupside_down' ] = 'stairs:slab_cobbleupside_down';

   -- the first windows are built using fences
   elseif( input == 'default:fence_wood' ) then
      
      replacements[ 'default:fence_wood'          ] = 'default:fence_wood';
      replacements[ 'cottages:glass_pane' ] = 'default:fence_wood';

   -- there are four nodes representing doors - replace them all
   elseif( input == 'doors:door_wood' ) then

      replacements[ 'doors:door_wood_t_1' ] = 'doors:door_wood_t_1';
      replacements[ 'doors:door_wood_t_2' ] = 'doors:door_wood_t_2';
      replacements[ 'doors:door_wood_b_1' ] = 'doors:door_wood_b_1';
      replacements[ 'doors:door_wood_b_2' ] = 'doors:door_wood_b_2';

   -- work on the land
   elseif( input == 'farming:hoe_steel' ) then 

      local possible_types = {'cotton','carrot', 'orange', 'potatoe', 'rhubarb', 'strawberry', 'tomato' };
      local typ = possible_types[ math.random(1,#possible_types) ];

      meta:set_string( 'material_typ', typ );

      replacements[ 'farming:soil'        ] = 'farming:soil_wet';
      replacements[ 'farming:soil_wet'    ] = 'farming:soil_wet'; -- makes it easier for protection

      replacements[ 'farming:cotton'      ] = 'farming:'..typ..'_1'; -- seeds need to grow manually
      replacements[ 'farming:cotton_1'    ] = 'farming:'..typ..'_1';
      replacements[ 'farming:cotton_2'    ] = 'farming:'..typ..'_1';
      replacements[ 'farming:cotton_3'    ] = 'farming:'..typ..'_1';


   --
   -- lumberjacks know how to use an axe
   --
   elseif( input == 'default:axe_mese' 
       and menu_path[2]=='lumberjack' ) then
      tree_typ = meta:get_string( 'material_type' );
    
      if( tree_typ == 'normal' ) then
         tree_typ = 'common';
      elseif( tree_typ == 'apple tree' ) then
         tree_typ = 'apple_tree';
      elseif( tree_typ == 'rubber tree' ) then
         tree_typ = 'rubber_tree';
      elseif( tree_typ == 'jungletree' ) then
         tree_typ = 'jungle_tree';
      end

      -- realtest trees
      if( tree_typ ~= 'common' and (tree_typ == 'ash (small)' or tree_typ == 'aspen (small)' or tree_typ == 'birch (small)'
                                or  tree_typ == 'maple (small)' or tree_typ == 'chestnut (small)' or tree_typ == 'pine (small)'
                                or  tree_typ == 'spruce (small)' )) then

         -- TODO: pretty chaotic...
         if(     tree_typ == 'ash (small)'     ) then tree_typ = 'ash';
         elseif( tree_typ == 'aspen (small)'   ) then tree_typ = 'aspen';
         elseif( tree_typ == 'birch (small)'   ) then tree_typ = 'birch';
         elseif( tree_typ == 'maple (small)'   ) then tree_typ = 'maple';
         elseif( tree_typ == 'chestnut (small)') then tree_typ = 'chestnut';
         elseif( tree_typ == 'pine (small)'    ) then tree_typ = 'pine';
         elseif( tree_typ == 'spruce (small)'  ) then tree_typ = 'spruce';
         end

         replacements[ 'moretrees:TYP_planks' ]         = 'trees:'..tree_typ..'_planks';
         replacements[ 'moretrees:TYP_trunk'  ]         = 'trees:'..tree_typ..'_trunk';
         replacements[ 'moretrees:TYP_trunk_sideways' ] = 'trees:'..tree_typ..'_trunk'; -- those are now normal trunks rotated
         replacements[ 'moretrees:slab_TYP_planks' ]    = 'trees:'..tree_typ..'_planks_slab'; -- those are now normal trunks rotated

      elseif( tree_typ ~= 'common' and minetest.get_modpath("moretrees") ~= nil ) then
         replacements[ 'moretrees:TYP_planks' ]         = 'moretrees:'..tree_typ..'_planks';
         replacements[ 'moretrees:TYP_trunk'  ]         = 'moretrees:'..tree_typ..'_trunk';
         replacements[ 'moretrees:TYP_trunk_sideways' ] = 'moretrees:'..tree_typ..'_trunk'; -- those are now normal trunks rotated

      else
         replacements[ 'moretrees:TYP_planks' ]         = 'default:wood';
         replacements[ 'moretrees:TYP_trunk'  ]         = 'default:tree';
         replacements[ 'moretrees:TYP_trunk_sideways' ] = 'default:tree';
      end

      -- TODO: replacement of wooden slabs for now disabled - because the normal wood forms a nicer contrast
      if( false and minetest.registered_nodes[ 'moretrees:slab_'..tree_typ..'_planks' ] ) then
         replacements[ 'moretrees:slab_TYP_planks' ]    = 'moretrees:slab_'..tree_typ..'_planks'; -- those are now normal trunks rotated
      else
         replacements[ 'moretrees:slab_TYP_planks' ]    = 'stairs:slab_wood'; -- those are now normal trunks rotated
      end

      -- lumberjacks do their own roof
      replacements[ 'cottages:roof_wood'           ] = 'cottages:roof_wood';
      replacements[ 'cottages:roof_connector_wood' ] = 'cottages:roof_connector_wood';
      replacements[ 'cottages:roof_flat_wood'      ] = 'cottages:roof_flat_wood';

   --
   -- this is intresting for clay traders - they know how to use a shovel
   --
   elseif( input == 'default:shovel_mese'       
       and menu_path[2]=='clay' ) then

      replacements[ 'default:clay'                 ] = 'default:clay';
      replacements[ 'default:sand'                 ] = 'default:sand';
      replacements[ 'default:desert_sand'          ] = 'default:desert_sand';
      replacements[ 'default:sandstone'            ] = 'default:sandstone';
      replacements[ 'default:sandstonebrick'       ] = 'default:sandstonebrick';

      replacements[ 'stairs:slab_sandstone'        ] = 'stairs:slab_sandstone';
      replacements[ 'stairs:slab_sandstonebrick'   ] = 'stairs:slab_sandstonebrick';


   --
   -- clay traders are also quite capable of using a furnace
   --
   elseif( input == 'default:furnace'        
       and menu_path[2]=='clay' ) then
      replacements[ 'default:brick'                ] = 'default:brick';
      replacements[ 'default:glass'                ] = 'default:glass';

      replacements[ 'stairs:slab_brick'            ] = 'stairs:slab_brick';
      replacements[ 'stairs:slab_glass'            ] = 'stairs:slab_glass';

      replacements[ 'default:furnace'              ] = 'default:furnace';


-- TODO: change the house blueprints
      replacements[ 'default:stone'         ] = 'default:stone';
      replacements[ 'stairs:slab_stone'         ] = 'cottages:roof_flat_red';
      replacements[ 'stairs:stair_stone'        ] = 'cottages:roof_red';


   elseif( input == 'cottages:half_door' 
        or input == 'cottages:half_door_inverted' ) then

      replacements[ 'cottages:half_door_inverted'   ] = 'cottages:half_door_inverted';
      replacements[ 'cottages:half_door'            ] = 'cottages:half_door';


   elseif( input == 'cottages:gate_open'
        or input == 'cottages:gate_closed' ) then

      replacements[ 'cottages:gate_open'            ] = 'cottages:gate_open';
      replacements[ 'cottages:gate_closed'          ] = 'cottages:gate_closed';

   elseif( input == 'cottages:window_shutter_open'
        or input == 'cottages:window_shutter_closed' ) then

      replacements[ 'cottages:window_shutter_open'  ] = 'cottages:window_shutter_open';
      replacements[ 'cottages:window_shutter_closed'] = 'cottages:window_shutter_closed';

   -- we got water!
   elseif( input == 'bucket:bucket_water' ) then

      replacements[ 'default:water_source' ] = 'default:water_source';
      replacements[ 'farming:soil' ]         = 'farming:soil_wet'; -- so that the protection can work

   elseif( input == 'cottages:barrel' ) then

      replacements[ 'cottages:barrel'            ] = 'cottages:barrel';
      replacements[ 'cottages:barrel_open'       ] = 'cottages:barrel_open';
      replacements[ 'cottages:barrel_lying'      ] = 'cottages:barrel_lying';
      replacements[ 'cottages:barrel_lying_open' ] = 'cottages:barrel_lying_open';

   -- lets hope the house is ready for the lava...
   elseif( input == 'bucket:bucket_lava' ) then

      replacements[ 'default:lava_source' ] = 'default:lava_source';
  
   -- this is special for the farm_*.we buildings
   elseif( input == 'cottages:loam' ) then

      replacements[ 'default:sandstone'             ] = 'cottages:loam';
      replacements[ 'default:clay'                  ] = 'cottages:loam';
      replacements[ 'cottages:straw_ground' ] = 'cottages:loam';
      replacements[ 'cottages:loam'         ] = 'cottages:loam';

   -- ...and normal chests replace the privat/work/storage chests that are special for npc
   elseif( input == 'default:chest' ) then

      replacements[ 'cottages:chest_private'] = 'cottages:chest_private';
      replacements[ 'cottages:chest_work'   ] = 'cottages:chest_work'   ;
      replacements[ 'cottages:chest_storage'] = 'cottages:chest_storage';
      replacements[ 'default:chest']          = 'default:chest';

   elseif( input == 'cottages:roof' ) then
      replacements[ 'cottages:roof' ] = 'cottages:roof_straw';
   elseif( input == 'cottages:roof_flat' ) then
      replacements[ 'cottages:roof_flat' ] = 'cottages:roof_flat_straw';
   elseif( input == 'cottages:roof_connector' ) then
      replacements[ 'cottages:roof_connector' ] = 'cottages:roof_connector_straw';

   -- we got normal input that can be used directly
   elseif( replacements_orig[ input ]==build_chest.SUPPORT ) then
      replacements[ input ] = input;
   end

   for k,v in pairs( replacements_orig ) do
      if( replacements[ k ] ) then
          replacements_orig[ k ] = replacements[ k ];
      end
   end
   meta:set_string( 'replacements', minetest.serialize( replacements_orig ));
   random_buildings.build_building( start_pos, building_name, rotate, mirror, platform_materials, replacements_orig, replacements, 0, pos );
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


