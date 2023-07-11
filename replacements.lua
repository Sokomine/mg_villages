
-- some games (like realtest_v5) may not have river water
if(not(minetest.registered_nodes["default:river_water_source"])) then
	handle_schematics.global_replacement_table[ 'default:river_water_source' ] = 'default:water_source';
	handle_schematics.global_replacement_table[ 'default:river_water_flowing'] = 'default:water_flowing';
end
-- always use the cheaper simulated soil that has no problem with water beeing 4 nodes away
handle_schematics.global_replacement_table[ 'farming:soil_wet'             ] = 'mg_villages:soil';
handle_schematics.global_replacement_table[ 'farming:soil'                 ] = 'mg_villages:soil';
handle_schematics.global_replacement_table[ 'farming:desert_sand_soil_wet' ] = 'mg_villages:desert_sand_soil';
handle_schematics.global_replacement_table[ 'farming:desert_sand_soil'     ] = 'mg_villages:desert_sand_soil';

handle_schematics.stonebrick_stair_replacements = {
	'cobble', 'desert_cobble', 'mossycobble',
	'stone',            'stone_block',            'stonebrick',
	'sandstone',        'sandstone_block',        'sandstonebrick',
	'desert_stone',     'desert_stone_block',     'desert_stonebrick',
	'desert_sandstone', 'desert_sandstone_block', 'desert_sandstone_brick',
	'silver_sandstone', 'silver_sandstone_block', 'silver_sandstone_brick',
	'stone_flat','desert_stone_flat','stone_bricks','desert_strone_bricks',
	}

-- TODO: take the wood types from the replacement groups instead of hardcoded wood types
-- (the rest here are handle_schematics.stonebrick_stair_replacements)
handle_schematics.wood_stair_replacements = {
	'wood', 'junglewood', 'pine_wood', 'acaica_wood', 'aspen_wood',
	'wood', 'junglewood', 'pine_wood', 'acaica_wood', 'aspen_wood',
	'wood', 'junglewood', 'pine_wood', 'acaica_wood', 'aspen_wood',
	'wood', 'junglewood', 'pine_wood', 'acaica_wood', 'aspen_wood',
	'wood', 'junglewood', 'pine_wood', 'acaica_wood', 'aspen_wood',

	'cobble', 'desert_cobble', 'mossycobble',
	'stone',            'stone_block',            'stonebrick',
	'sandstone',        'sandstone_block',        'sandstonebrick',
	'desert_stone',     'desert_stone_block',     'desert_stonebrick',
	'desert_sandstone', 'desert_sandstone_block', 'desert_sandstone_brick',
	'silver_sandstone', 'silver_sandstone_block', 'silver_sandstone_brick',

	'stone_flat','desert_stone_flat','stone_bricks','desert_strone_bricks',
	}

-- TODO: take the wood types from the replacement groups instead of hardcoded wood types
-- (the rest here are handle_schematics.stonebrick_stair_replacements plus
-- brick, clay and loam)
handle_schematics.brick_stair_replacements = {
	'wood', 'junglewood', 'pine_wood', 'acaica_wood', 'aspen_wood',
	'cobble', 'desert_cobble', 'mossycobble',
	'stone',            'stone_block',            'stonebrick',
	'sandstone',        'sandstone_block',        'sandstonebrick',
	'desert_stone',     'desert_stone_block',     'desert_stonebrick',
	'desert_sandstone', 'desert_sandstone_block', 'desert_sandstone_brick',
	'silver_sandstone', 'silver_sandstone_block', 'silver_sandstone_brick',
	'stone_flat','desert_stone_flat','stone_bricks','desert_strone_bricks',
	'brick', 'brick', 'brick', 'brick', 'brick',
	'clay', 'clay', 'loam', 'loam',
	}

-- if cottages is not installed, place "normal" beds in the chateau and wherever else needed
if( not( minetest.get_modpath( 'cottages' ))) then
	handle_schematics.global_replacement_table[ 'cottages:bed_head' ] = 'beds:fancy_bed_top';
	handle_schematics.global_replacement_table[ 'cottages:bed_foot' ] = 'beds:fancy_bed_bottom';
end

-- ethereal comes with some intresting trees
if( minetest.get_modpath( 'ethereal' )) then
	mg_villages.ethereal_trees = {'acacia','willow','redwood','frost','mushroom','yellow','palm','banana'};
end

if( minetest.get_modpath( 'forest' )) then
	mg_villages.forest_trees = {'beech','birch','cherry','fir','ginkgo','lavender','mirabelle','oak','plum','willow'};
end

-- we are dealing with the TinyTrees mod from Bas080
if( minetest.get_modpath( 'trees' )
   and minetest.registered_nodes[ 'trees:wood_mangrove' ] ) then
	mg_villages.tinytrees_trees = {'mangrove','palm','conifer'};
end

-- The trees modname is not unique; there are other mods which bear that name.
-- If all the other mods are present as well, it's a strong indication for realtest beeing the game.
if(	    minetest.get_modpath( 'trees' )
	and minetest.get_modpath( 'anvil')
	and minetest.get_modpath( 'joiner_table')
	and minetest.get_modpath( 'scribing_table' )) then
	mg_villages.realtest_trees = {'ash','aspen','birch','maple','chestnut','pine','spruce'};
	--print('REALTEST trees will be used.'); else print( 'NO REALTEST trees');

	-- realtest is very special as far as stairs are concerned
	mg_villages.realtest_stairs = {'default:stone','default:stone_flat','default:stone_bricks',
	                               'default:desert_stone_flat','default:desert_stone_bricks',
				       'default:stone_macadam', 'default:stone', 'default:desert_stone',
				       'default:sandstone','default:sandstone',
				       -- very decorative...so more likely to appear
				       'default:stone_bricks', 'default:desert_stone_bricks'};
	-- the metals are very decorative; but they'd also invite players to grief villages...so better not
--	for i,v in ipairs(metals.list) do
--		table.insert( mg_villages.realtest_stairs, 'metals:'..v..'_block' );
--	end
	-- the list of minteral names is local; so we can't add "decorations:"..mineral[1].."_block"
end


-- only the function mg_villages.get_replacement_table(..) is called from outside this file

-- returns a random material that is part of the replacement group given by
-- material_type, i.e. default:junglewood for material_type 'wood';
-- does not apply the replacements directly as there may be more than one wood
-- type used in a house
mg_villages.get_group_replacement = function( material_type, pr )
	return replacements_group[ material_type ].found[
		pr:next(     1, #replacements_group[ material_type ].found )];
end


-- this is so common that an extra function is helpful to combine the two lines
--      material_type     usually either 'wood' or 'roof'
--      new_material      optional; if a specific new material ought to be used
mg_villages.do_group_replacement = function( replacements, pr, material_tpye, new_material)
	if( new_material == nil or new_material == "") then
		new_material = mg_villages.get_group_replacement( material_tpye, pr )
	end
	return handle_schematics.replace_material( replacements, material_tpye, nil, new_material)
end


mg_villages.replace_materials = function( replacements, pr, original_materials, prefixes, materials, old_material )
	
	local postfixes = {};
	local use_realtest_stairs = false;
	-- handle realtest stairs/slabs
	if( mg_villages.realtest_trees 
		and #prefixes==3
		and prefixes[1]=='stairs:stair_' and prefixes[2]=='stairs:slab_' and prefixes[3]=='default:' ) then 

		prefixes  = {''};
		materials = mg_villages.realtest_stairs;
		postfixes = {''};
		use_realtest_stairs = true;	

	elseif( mg_villages.realtest_trees 
		and #prefixes==1 
		and prefixes[1]=='stairs:stair_') then
	
		return;
	else
		for i,v in ipairs( prefixes ) do
			postfixes[i] = '';
		end
	end

	local known_materials = {};
	local wood_found = false;
	-- for all alternate materials
	for i,m in ipairs( materials ) do
		-- check if that material exists for each supplied prefix
		for j,p in ipairs( prefixes ) do
			-- if wood is present, later on try moretrees wood as well
			if( 'default:wood' == m ) then
				wood_found = true;
			end
			if( minetest.registered_nodes[ p..m..postfixes[j] ] ) then
				table.insert( known_materials, m..postfixes[j] );
			end
		end	
	end
	
	-- support wooden planks from moretrees
	if( wood_found and mg_villages.moretrees_treelist ) then
		for _,v in ipairs( mg_villages.moretrees_treelist ) do
			if( minetest.registered_nodes[ "moretrees:"..v[1].."_planks"] ) then
				table.insert( known_materials, "moretrees:"..v[1].."_planks" );
			end	
		end
	end

--[[
	-- deco is used by BigFreakingDig; as that one lacks default nodes, it doesn't work out here
	if( wood_found and minetest.get_modpath('deco')) then
		local bfd_treelist = {'birch', 'cherry', 'evergreen', 'oak' };
		for _,v in ipairs( bfd_treelist ) do
			if( minetest.registered_nodes[ "deco:"..v.."_plank"] ) then
				table.insert( known_materials, "deco:"..v.."_plank" );
			end	
		end
	end
--]]
		
	if( wood_found and mg_villages.ethereal_trees ) then
		for _,v in ipairs( mg_villages.ethereal_trees ) do
			-- mushroom in ethereal is a pretty decorative material; increase its probability
			if( v == 'mushroom' ) then
				table.insert( known_materials, "ethereal:mushroom_pore" );
				table.insert( known_materials, "ethereal:mushroom_pore" );
				table.insert( known_materials, "ethereal:mushroom_pore" );
				-- also increase probability for the decorative blueish wood
				table.insert( known_materials, "ethereal:frost_wood" );
				table.insert( known_materials, "ethereal:frost_wood" );
			elseif( minetest.registered_nodes[ "ethereal:"..v.."_wood"] ) then
				table.insert( known_materials, "ethereal:"..v.."_wood" );
			end	
		end
	end

	if( wood_found and mg_villages.forest_trees ) then
		for _,v in ipairs( mg_villages.forest_trees ) do
			if( minetest.registered_nodes[ 'forest:'..v..'_wood'] ) then
				table.insert( known_materials, 'forest:'..v..'_wood' );
			end	
		end
	end

	if( wood_found and mg_villages.tinytrees_trees ) then
		for _,v in ipairs( mg_villages.tinytrees_trees ) do
			if( minetest.registered_nodes[ 'trees:wood_'..v] ) then
				table.insert( known_materials, 'trees:wood_'..v );
			end	
		end
	end

	if( wood_found and mg_villages.realtest_trees ) then
		for _,v in ipairs( mg_villages.realtest_trees ) do
			if( minetest.registered_nodes[ 'trees:'..v..'_planks'] ) then
				table.insert( known_materials, 'trees:'..v..'_planks' );
			end	
		end
	end


	-- nothing found which could be used
	if( #known_materials < 1 ) then
		return;
	end
	local new_material  = known_materials[ pr:next( 1, #known_materials )]; 

	if( use_realtest_stairs == true	) then
		table.insert( replacements, { original_materials[ 1 ], new_material..'_stair' } );
		table.insert( replacements, { original_materials[ 2 ], new_material..'_slab' } );
		table.insert( replacements, { original_materials[ 3 ], new_material } );
		table.insert( replacements, { original_materials[ 1 ]..'upside_down', new_material..'_stair_upside_down' } );
		table.insert( replacements, { original_materials[ 2 ]..'upside_down', new_material..'_slab_upside_down' } );
		return new_material;
	end

	-- no replacement necessary if we did choose the same material as before
	if( new_material == old_material or old_material == (prefixes[1]..new_material)) then
		return old_material;
	end

	for i,v in ipairs( prefixes ) do
		table.insert( replacements, { original_materials[ i ], v..new_material } );
	end
	return new_material;
end



-- Note: This function is taken from the villages mod (by Sokomine)
-- at least the cottages may come in a variety of building materials
-- IMPORTANT: don't add any nodes which have on_construct here UNLESS they where in the original file already
--            on_construct will only be called for known nodes that need that treatment (see villages.analyze_mts_file and on_constr)
mg_villages.get_replacement_list = function( housetype, pr )

   local replacements = {};

  -- else some grass would never (re)grow (if it's below a roof)
--   table.insert( replacements, {'default:dirt',            dirt_with_grass_replacement });
--   table.insert( replacements, {'default:dirt_with_grass', dirt_with_grass_replacement });
   table.insert( replacements, {'default:dirt',            'default:dirt_with_grass' });

   -- realtest lacks quite a lot from default
   if( mg_villages.realtest_trees ) then
	for i=1,8 do
   		table.insert( replacements, {'farming:wheat_'..i,       'farming:spelt_'..tostring( (i+(i%2))/2) });
   		table.insert( replacements, {'farming:cotton_'..i,      'farming:flax_' ..tostring( (i+(i%2))/2) });
	end
	for i=1,5 do
   		table.insert( replacements, {'default:grass_'..i,       'air' });
	end
  	table.insert(         replacements, {'default:apple',           'air' });
  	table.insert(         replacements, {'default:cobble',          'default:stone_macadam' });
  	table.insert(         replacements, {'default:obsidian_glass',  'default:glass' });

   -- the default doors from minetest game have been changed since the schematics where built
   -- TODO: the door replacement function needs to be more complex; doesn't really work this way
   else
	table.insert( replacements, {'doors:door_wood_t_1',  'doors:hidden'});
	table.insert( replacements, {'doors:door_wood_b_1',  'doors:door_wood_a'});
	table.insert( replacements, {'doors:door_wood_t_2',  'doors:hidden'});
	table.insert( replacements, {'doors:door_wood_b_2',  'doors:door_wood_b'});
   end

   if( housetype and mg_villages.village_type_data[ housetype ] and mg_villages.village_type_data[ housetype ].replacement_function ) then
	-- apply the replacement function that handles those replacements that are specific
	-- for that village type
	replacements = mg_villages.village_type_data[ housetype ].replacement_function( housetype, pr, replacements );
   end

   -- apply general replacements - global ones and in particular ones that are needed by diffrent
   -- games (MineClone2, RealTest, ...)
   return handle_schematics.apply_global_replacements(replacements)
end




-- mapgen based replacements work best using a table, while minetest.place_schematic(..) based spawning needs a list
mg_villages.get_replacement_table = function( housetype, pr, replacements )

	local rtable = {};
	if( not( replacements )) then
		replacements = mg_villages.get_replacement_list( housetype, pr );
	end
	-- it is very problematic if the torches on houses melt snow and cause flooding; thus, we use a torch that is not hot
	if( mg_villages.USE_DEFAULT_3D_TORCHES == false ) then
		table.insert( replacements, {'default:torch', 'mg_villages:torch'});
	end

	-- make charachoal villages safe from spreading fire
	if( not( mg_villages.use_normal_unsafe_lava )) then
		table.insert( replacements, {'default:lava_source',  'mg_villages:lava_source_tamed'});
		table.insert( replacements, {'default:lava_flowing', 'mg_villages:lava_flowing_tamed'});
	end

	for i,v in ipairs( replacements ) do
		if( v and #v == 2 ) then
			rtable[ v[1] ] = v[2];
		end
	end
        return { table = rtable, list = replacements};
end
