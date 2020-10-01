
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



-- Taokis houses from structure i/o
mg_villages.replacements_taoki = function( housetype, pr, replacements )
      -- the main body of the houses in the .mts files is made out of wood
      -- TODO: if a wood is selected, use that for the trees as well
      local wood_type = mg_villages.replace_materials( replacements, pr,
		{'default:wood'},
		{''},
		{'default:wood', 'default:junglewood', 'default:pine_wood', 'default:acacia_wood', 'default:aspen_wood', 'mg:pinewood', 'mg:savannawood',
		'default:clay', 'default:brick', 'default:sandstone', 
		'default:stonebrick', 'default:desert_stonebrick','default:sandstonebrick', 'default:sandstone','default:stone','default:desert_stone',
		'default:coalblock','default:steelblock','default:goldblock', 'default:bronzeblock', 'default:copperblock', 'wool:white',
		'default:stone_flat', 'default:desert_stone_flat', -- realtest
		'darkage:adobe', 'darkage:basalt', 'darkage:basalt_cobble', 'darkage:chalk',
		'darkage:gneiss', 'darkage:gneiss_cobble', 'darkage:marble', 'darkage:marble_tile',
		'darkage:mud', 'darkage:ors', 'darkage:ors_cobble',
		'darkage:schist', 'darkage:serpentine', 'darkage:shale', 'darkage:silt', 'darkage:slate',
		'mapgen:mese_stone', 'mapgen:soap_stone',
		'default:wood',
		'default:silver_sandstone',
		'default:silver_sandstone_block',
		'default:silver_sandstone_brick',
		'default:desert_sandstone_block',
		'default:desert_sandstone_brick',
	}, 'default:wood');

      -- tree trunks are seldom used in these houses; let's change them anyway
      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)

      -- all this comes in variants for stairs and slabs as well
      mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_stonebrick',  'stairs:slab_stonebrick', 'default:stonebrick'},
		{'stairs:stair_',            'stairs:slab_',           'default:'          },
		handle_schematics.stonebrick_stair_replacements,
		'stonebrick');

      -- decorative slabs above doors etc.
      mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_wood'},
		{'stairs:stair_'},
		handle_schematics.wood_stair_replacements,
		'wood');

      -- brick roofs are a bit odd; but then...
      -- all three shapes of roof parts have to fit together
      mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_brick',  'stairs:slab_brick', 'default:brick'},
		{'stairs:stair_',       'stairs:slab_',      'default:'     },
		handle_schematics.brick_stair_replacements,
		'brick' );

      return replacements;
 end


mg_villages.replacements_nore = function( housetype, pr, replacements )

      mg_villages.replace_materials( replacements, pr,
--		{'default:stonebrick'},
--		{'default:'},
		{'stairs:stair_stonebrick',  'stairs:slab_stonebrick', 'default:stonebrick'},
		{'stairs:stair_',       'stairs:slab_',      'default:'     },
		handle_schematics.stonebrick_stair_replacements,
		'stonebrick');

      -- obsidian glass looks nice as well
      if( pr:next(1,3)==1 and minetest.registered_nodes['default:obsidian_glass']) then
         table.insert( replacements, {'default:glass', 'default:obsidian_glass'});
      end

      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)
      return replacements;
end


mg_villages.replacements_lumberjack = function( housetype, pr, replacements )
      if( not( minetest.get_modpath('bell' ))) then
         table.insert( replacements, {'bell:bell',               'default:goldblock' });
      end

      -- replace the wood - those are lumberjacks after all
      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)
      -- roof is also replaced
      local roof = mg_villages.get_group_replacement( 'roof', pr )
      roof = handle_schematics.replace_material( replacements, 'roof', 'cottages:roof_connector_straw', roof)

      return replacements;
end


mg_villages.replacements_logcabin = function( housetype, pr, replacements )

      -- the logcabins are mostly built out of wooden slabs; they also have doors
      -- and fences and the like
      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)
      -- for logcabins, wood is the most likely type of roof material
      local roof = mg_villages.get_group_replacement( 'roof', pr )
      roof = handle_schematics.replace_material( replacements, 'roof', 'cottages:roof_connector_straw', roof)

      -- TODO: adjust the replacements - we've already found out which type of roof to use
      local roof_type = mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_cobble',      'stairs:slab_cobble' },
		{'cottages:roof_connector_', 'cottages:roof_flat_' },
		{'straw', 'wood',  'wood', 'wood', 'reet', 'slate', 'red', 'brown', 'black'},
		'' );
      -- some houses have junglewood roofs
      if( roof_type ) then
         table.insert( replacements, {'stairs:stair_junglewood',          'cottages:roof_connector_'..roof_type });
         table.insert( replacements, {'stairs:slab_junglewood',           'cottages:roof_flat_'..roof_type });
         table.insert( replacements, {'cottages:roof_connector_wood',     'cottages:roof_connector_'..roof_type });
         table.insert( replacements, {'cottages:roof_flat_wood',          'cottages:roof_flat_'..roof_type });
      -- realtest does not have normal stairs
      elseif( mg_villages.realtest_trees ) then
         table.insert( replacements, {'stairs:stair_junglewood',          'trees:aspen_planks_stair' });
         table.insert( replacements, {'stairs:slab_junglewood',           'trees:aspen_planks_slab' });
      end

	-- replace the floor with another type of wood (looks better than the same type as above)
	local wood_floor = mg_villages.get_group_replacement( 'wood', pr )
	if(wood_floor ~= "default:junglewood") then
		table.insert( replacements, {'default:junglewood', wood_floor });
	end

      return replacements;
end


mg_villages.replacements_chateau = function( housetype, pr, replacements )

      if( minetest.get_modpath( 'cottages' )) then
         local roof = mg_villages.get_group_replacement( 'roof', pr )
         roof = handle_schematics.replace_material( replacements, 'roof', 'cottages:roof_connector_straw', roof)
      else
         mg_villages.replace_materials( replacements, pr,
		-- all three shapes of roof parts have to fit together
		{ 'cottages:roof_straw',    'cottages:roof_connector_straw',   'cottages:roof_flat_straw' },
		{ 'stairs:stair_',          'stairs:stair_',                   'stairs:slab_'},
		{'cobble', 'stonebrick', 'desert_cobble', 'desert_stonebrick', 'stone'},
		'stonebrick');
         table.insert( replacements, { 'cottages:glass_pane', 'default:glass' });
      end


      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)

      if( mg_villages.realtest_trees ) then
         -- replace the floor with another type of wood (looks better than the same type as above)
         mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_junglewood',  'stairs:slab_junglewood', 'default:junglewood'},
		{'stairs:stair_',            'stairs:slab_',           'default:'     },
		{ 'default:wood' },
		'wood' );
      end


      local mfs2 = mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_cobble',  'stairs:slab_cobble', 'default:cobble'},
		{'stairs:stair_',        'stairs:slab_',       'default:'      },
		handle_schematics.stonebrick_stair_replacements,
		'cobble');

      return replacements;
end


mg_villages.replacements_tent = function( housetype, pr, replacements )
      table.insert( replacements, { "glasspanes:wool_pane",  "cottages:wool_tent" });
      table.insert( replacements, { "default:gravel",        "default:sand"       });
      -- realtest needs diffrent fence posts and doors
      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)
      return replacements;
end


mg_villages.replacements_grasshut = function( housetype, pr, replacements )
      table.insert( replacements, {'moreblocks:fence_jungle_wood',     'default:fence' });
      if( pr:next( 1, 4) == 1 ) then
         table.insert( replacements, {'dryplants:reed_roof',              'cottages:roof_straw'});
         table.insert( replacements, {'dryplants:reed_slab',              'cottages:roof_flat_straw' });
         table.insert( replacements, {'dryplants:wetreed_roof',           'cottages:roof_reet' });
         table.insert( replacements, {'dryplants:wetreed_slab',           'cottages:roof_flat_reet' });
      else -- replace the straw and cobble one of the huts uses
         table.insert( replacements, {'cottages:straw',                   'dryplants:wetreed' });
         table.insert( replacements, {'stairs:slab_cobble',               'dryplants:reed_slab' });
      end
--[[ does not look nice
      if( pr:next( 1, 4) == 1 ) then
         table.insert( replacements, {'dryplants:wetreed_roof_corner',    'default:wood' });
         table.insert( replacements, {'dryplants:wetreed_roof_corner_2',  'default:junglewood' });
      end
--]]
      if( not( minetest.get_modpath( 'cavestuff' ))) then
         table.insert( replacements, {'cavestuff:desert_pebble_2',        'default:slab_desert_stone' });
      end
   
      table.insert( replacements, {'default:desert_sand', 'default:dirt_with_grass' });

      -- not really much wood there - still, doors, slabs and chests may exist
      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)
      return replacements;
end


mg_villages.replacements_claytrader = function( housetype, pr, replacements )
      -- the walls of the clay trader houses are made out of brick
      mg_villages.replace_materials( replacements, pr,
		{ 'stairs:stair_brick', 'stairs:slab_brick', 'default:brick' }, -- default_materials
		{ 'stairs:stair_',      'stairs:slab_',      'default:'      }, -- prefixes (for new materials)
		handle_schematics.brick_stair_replacements,
		'brick' ); -- original material
	
      -- material for the floor
      mg_villages.replace_materials( replacements, pr,
		{'default:stone'},
		{'default:'},
		handle_schematics.stonebrick_stair_replacements,
		'stone');

      -- the clay trader homes come with stone stair roofs; slabs are used in other places as well (but those replacements here are ok)
      mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_stone',       'stairs:slab_stone' },
		{'cottages:roof_connector_', 'cottages:roof_flat_' },
		{'straw', 'straw', 'straw', 'straw', 'straw',
			   'reet', 'reet', 'reet',
			   'slate', 'slate',
                           'wood',  'wood',  
                           'red',
                           'brown',
                           'black'},
		'');

      -- hills and pits that contain the materials clay traders dig for
      mg_villages.replace_materials( replacements, pr,
		{'default:stone_with_coal'},
		{'default:'},
		{'sand', 'sandstone', 'clay'},
		'');

      -- mostly for doors
      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)
      if( mg_villages.realtest_trees ) then
         table.insert( replacements, {'default:clay', 'default:dirt_with_clay'});
         local mfs2 = mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_cobble',  'stairs:slab_cobble', 'default:cobble'},
		{'stairs:stair_',        'stairs:slab_',       'default:'      },
		{ 'stone' }, -- will be replaced by mg_villages.realtest_stairs
		'sandstone');
      end
      return replacements;
end


mg_villages.replacements_charachoal = function( housetype, pr, replacements )
      -- mostly for doors
      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)
      if( mg_villages.realtest_trees ) then
         table.insert( replacements, {'stairs:slab_loam',     'cottages:loam'});
         table.insert( replacements, {'stairs:stair_loam',    'cottages:loam'});
      end
      return replacements;
end


-- wells can get the same replacements as the sourrounding village; they'll get a fitting roof that way
mg_villages.replacements_medieval = function( housetype, pr, replacements )

   if( not( minetest.get_modpath('bell' ))) then
      table.insert( replacements, {'bell:bell',               'default:goldblock' });
   end

   -- glass that served as a marker got copied accidently; there's usually no glass in cottages
   table.insert( replacements, {'default:glass',           'air'});
   -- some plants started growing while the buildings where saved - eliminate them
   table.insert( replacements, {'junglegrass:medium',      'air'});
   table.insert( replacements, {'junglegrass:short',       'air'});
   table.insert( replacements, {'poisonivy:seedling',      'air'});

-- TODO: sometimes, half_door/half_door_inverted gets rotated wrong
--   table.insert( replacements, {'cottages:half_door',      'cottages:half_door_inverted'});
--   table.insert( replacements, {'cottages:half_door_inverted', 'cottages:half_door'});

   -- some poor cottage owners cannot afford glass
   if( pr:next( 1, 2 ) == 2 ) then
--      table.insert( replacements, {'cottages:glass_pane',    'default:fence_wood'});
      local gp = mg_villages.replace_materials( replacements, pr,
	{'cottages:glass_pane'},
	{''},
	{'xpanes:pane', 'default:glass', 'default:obsidian_glass', 'default:fence_wood',
	 'darkage:medieval_glass', 'darkage:iron_bars', 'darkage:iron_grille', 'darkage:wood_bars',
	 'darkage:wood_frame', 'darkage:wood_grille'},
	'cottages:glass_pane');
   end

   -- 'glass' is admittedly debatable; yet it may represent modernized old houses where only the tree-part was left standing
   -- loam and clay are mentioned multiple times because those are the most likely building materials in reality
   local materials = {'cottages:loam', 'cottages:loam', 'cottages:loam', 'cottages:loam', 'cottages:loam', 
                      'default:clay',  'default:clay',  'default:clay',  'default:clay',  'default:clay',
                      'default:wood','default:junglewood', 'default:pine_wood', 'default:acacia_wood', 'default:aspen_wood', 'default:sandstone',
                      'default:desert_stone','default:brick','default:cobble','default:stonebrick',
                      'default:desert_stonebrick','default:sandstonebrick','default:stone',
                      'mg:savannawood', 'mg:savannawood', 'mg:savannawood', 'mg:savannawood',
                      'mg:pinewood',    'mg:pinewood',    'mg:pinewood',    'mg:pinewood',
		'default:stone_flat', 'default:desert_stone_flat', -- realtest
		'darkage:adobe', 'darkage:basalt', 'darkage:basalt_cobble', 'darkage:chalk',
		'darkage:gneiss', 'darkage:gneiss_cobble', 'darkage:marble', 'darkage:marble_tile',
		'darkage:mud', 'darkage:ors', 'darkage:ors_cobble', 'darkage:reinforced_chalk',
		'darkage:reinforced_wood', 'darkage:reinforced_wood_left', 'darkage:reinforced_wood_right',
		'darkage:schist', 'darkage:serpentine', 'darkage:shale', 'darkage:silt', 'darkage:slate',
		'darkage:slate_cobble', 'darkage:slate_tile', 'darkage:stone_brick',
		'default:silver_sandstone',
		'default:silver_sandstone_block',
		'default:silver_sandstone_brick',
		'default:desert_sandstone_block',
		'default:desert_sandstone_brick',
		'mapgen:mese_stone', 'mapgen:soap_stone'};

   -- what is sandstone (the floor) may be turned into something else
   local mfs = mg_villages.replace_materials( replacements, pr,
	{'default:sandstone'},
	{''},
	materials,
	'default:sandstone');
   if( mg_villages.realtest_trees ) then
       table.insert( replacements, {'stairs:slab_sandstone',   'default:stone_slab'});
       local mfs2 = mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_sandstone',  'stairs:slab_sandstone', 'default:sandstone'},
		{'stairs:stair_',           'stairs:slab_',          'default:'         },
		{ 'stone' }, -- will be replaced by mg_villages.realtest_stairs
		'sandstone');
   elseif( mfs and mfs ~= 'default:sandstone' ) then

      if( mfs == 'cottages:loam' or mfs == 'default:clay' or mfs == 'mg:savannawood' or mfs == 'mg:pinewood') then
         mfs = 'default:wood';
      elseif( mfs =='default:sandstonebrick' or mfs == 'default:desert_stone' or mfs == 'default:desert_stonebrick'
              or not( minetest.registered_nodes[ 'stairs:slab_'..string.sub( mfs, 9 )] )) then
         mfs = '';
      end

      if( mfs and mfs ~= '' ) then      
         -- realtest needs special treatment
         table.insert( replacements, {'stairs:slab_sandstone',   'stairs:slab_'..string.sub( mfs, 9 )});
      end
   end
   -- except for the floor, everything else may be glass
   table.insert( materials, 'default:glass' );

   -- choose a random wood type; even if the wood as such may not be used, it is important
   -- to set this so that a suitable wooden door, fences etc. can be selected for games
   -- like MineClone2 and RealTest;
   -- the houses use the wood for the floors
   local wood = mg_villages.get_group_replacement( 'wood', pr )
   wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)

   -- TODO: the lower, upper or both parts of the house *may* be made out of that wood above

   -- bottom part of the house (usually ground floor from outside)
   local replace_clay = mg_villages.replace_materials( replacements, pr,
	{'default:clay'},
	{''},
	materials,
	'default:clay');
 
   -- upper part of the house (may be the same as the material for the lower part)
   local replace_loam = mg_villages.replace_materials( replacements, pr,
	{'cottages:loam'},
	{''},
	materials,
	'cottages:loam');


   -- replace cobble; for these nodes, a stony material is needed (used in wells as well)
   -- mossycobble is fine here as well
   local mcs = mg_villages.replace_materials( replacements, pr,
		{'default:cobble'},
		{'default:'},
		handle_schematics.stonebrick_stair_replacements,
		'cobble');
   -- set a fitting material for the slabs; mossycobble uses the default cobble slabs
   if( mg_villages.realtest_trees ) then
      local mcs2 = mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_cobble',  'stairs:slab_cobble', 'default:cobble'},
		{'stairs:stair_',        'stairs:slab_',       'default:'          },
		{ 'stone' }, -- will be replaced by mg_villages.realtest_stairs
		'cobble');
      table.insert( replacements, {'moreblocks:slab_cobble',   'default:'..mcs..'_slab'});
   elseif( mcs ~= 'mossycobble' and mcs ~= 'cobble') then

      -- if no slab exists, use sandstone slabs
      if( not( mcs ) or not( minetest.registered_nodes[ 'stairs:slab_'..mcs ])) then
         mcs = 'sandstone';
      end
      table.insert( replacements, {'stairs:slab_cobble',      'stairs:slab_'..mcs});
      table.insert( replacements, {'moreblocks:slab_cobble',  'stairs:slab_'..mcs});
   else
      table.insert( replacements, {'moreblocks:slab_cobble',  'stairs:slab_'..mcs});
   end
 
   -- straw is the most likely building material for roofs for historical buildings
   -- however, the other roof types are fine, and we can use them as well
   local roof = mg_villages.get_group_replacement( 'roof', pr )
   roof = handle_schematics.replace_material( replacements, 'roof', 'cottages:roof_connector_straw', roof)
   return replacements;
end


mg_villages.replacements_tower = function( housetype, pr, replacements )
      -- replace the wood - this is needed in particular for the fences
      local wood = mg_villages.get_group_replacement( 'wood', pr )
      wood = handle_schematics.replace_material( replacements, 'wood', nil, wood)

      mg_villages.replace_materials( replacements, pr,
                {'stairs:stair_cobble',  'stairs:slab_cobble', 'default:cobble'},
                {'stairs:stair_',         'stairs:slab_',      'default:'     },
		handle_schematics.stonebrick_stair_replacements,
                'stonebrick');

      return replacements;
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
