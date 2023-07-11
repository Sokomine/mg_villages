------------------------------------------
-- We need there steps:
-- 0. Add replacement functions (optional)
-- 1. Add village types
-- 2. Add buildings (schematics)
------------------------------------------

-----------------------------------
-- 0. Add replacement functions ---
-----------------------------------

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
      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)

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

      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)
      return replacements;
end


mg_villages.replacements_lumberjack = function( housetype, pr, replacements )
      if( not( minetest.get_modpath('bell' ))) then
         table.insert( replacements, {'bell:bell',               'default:goldblock' });
      end

      -- replace the wood - those are lumberjacks after all
      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)
      -- roof is also replaced
      local roof = mg_villages.do_group_replacement( replacements, pr, 'roof', nil)
      return replacements;
end


mg_villages.replacements_logcabin = function( housetype, pr, replacements )

      -- the logcabins are mostly built out of wooden slabs; they also have doors
      -- and fences and the like
      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)
      -- for logcabins, wood is the most likely type of roof material
      local roof = mg_villages.do_group_replacement( replacements, pr, 'roof', nil)

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
         local roof = mg_villages.do_group_replacement( replacements, pr, 'roof', nil)
      else
         mg_villages.replace_materials( replacements, pr,
		-- all three shapes of roof parts have to fit together
		{ 'cottages:roof_straw',    'cottages:roof_connector_straw',   'cottages:roof_flat_straw' },
		{ 'stairs:stair_',          'stairs:stair_',                   'stairs:slab_'},
		{'cobble', 'stonebrick', 'desert_cobble', 'desert_stonebrick', 'stone'},
		'stonebrick');
         table.insert( replacements, { 'cottages:glass_pane', 'default:glass' });
      end


      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)

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
      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)
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
      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)
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
      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)
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
      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)
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
   local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)

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
   local roof = mg_villages.do_group_replacement( replacements, pr, 'roof', nil)
   return replacements;
end


mg_villages.replacements_tower = function( housetype, pr, replacements )
      -- replace the wood - this is needed in particular for the fences
      local wood = mg_villages.do_group_replacement( replacements, pr, 'wood', nil)

      mg_villages.replace_materials( replacements, pr,
                {'stairs:stair_cobble',  'stairs:slab_cobble', 'default:cobble'},
                {'stairs:stair_',         'stairs:slab_',      'default:'     },
		handle_schematics.stonebrick_stair_replacements,
                'stonebrick');

      return replacements;
end

---------------------------
-- 1. Add village types ---
---------------------------

--  DOCUMENTATION: mg_villages.village_type_data has entries in the following form:
--      key = { data values }   with key beeing the name of the village type
--  meaning of the data values:
--      min, max: the village size will be choosen randomly between these two values;
--                the actual village will have a radius about twice as big (including sourrounding area)
--      space_between_buildings=2  How much space is there between the buildings. 1 or 2 are good values.
--                The higher, the further the buildings are spread apart.
--      mods = {'homedecor','moreblocks'} List of mods that are required for the buildings of this village type.
--                List all the mods the blocks used by your buildings which are not in default.
--      texture = 'wool_white.png'        Texture used to show the location of the village when using the
--                vmap  command.
--      name_prefix = 'Village ',
--      name_postfix = ''                 When creating village names for single houses which are spawned outside
--                of villages, the village name will consist of  name_prefix..village_name..name_postfix
--	sapling_divisor = 1	Villages are sourrounded by a flat area that may contain trees. Increasing this
--				value decreses the mount of trees placed.
--	plant_type = 'farming:wheat_8'  Type of plant that is placed around villages.
--	plant_frequency = 1	The higher this value is, the less plants are placed.


local village_type_data_list = {
	nore         = { min = 20, max = 40,   space_between_buildings=1, mods={},            texture = 'default_stone_brick.png',
			 replacement_function = mg_villages.replacements_nore },
	taoki        = { min = 30, max = 70,   space_between_buildings=1, mods={},            texture = 'default_brick.png' ,
			 sapling_divisor =  5, plant_type = 'farming:cotton_8',    plant_frequency = 1,
			 replacement_function = mg_villages.replacements_taoki },
	medieval     = { min = 25, max = 60,   space_between_buildings=2, mods={'cottages'},  texture = 'cottages_darkage_straw.png', -- they often have straw roofs
			 sapling_divisor = 10, plant_type = 'farming:wheat_8',     plant_frequency = 1,
			 replacement_function = mg_villages.replacements_medieval,
			roadsize_list = {2,3,4,5,6},
--			road_materials = {'default:cobble','default:gravel','default:stonebrick','default:coalblock'},
			}, --roadsize_list = {1,1,2,3,4} },
	charachoal   = { min = 10, max = 15,   space_between_buildings=1, mods={'cottages'},  texture = 'default_coal_block.png',
			 replacement_function = mg_villages.replacements_charachoal },
	lumberjack   = { min = 10, max = 30,   space_between_buildings=1, mods={'cottages'},  texture = 'default_tree.png', name_prefix = 'Camp ',
			 sapling_divisor =  1, plant_type = 'default:junglegrass', plant_frequency = 24,
			 replacement_function = mg_villages.replacements_lumberjack },
	claytrader   = { min = 10, max = 20,   space_between_buildings=1, mods={'cottages'},  texture = 'default_clay.png',
			 replacement_function = mg_villages.replacements_claytrader },
	logcabin     = { min = 15, max = 30,   space_between_buildings=1, mods={'cottages'},  texture = 'default_wood.png',
			 replacement_function = mg_villages.replacements_logcabin },
	grasshut     = { min = 10, max = 40,   space_between_buildings=1, mods={'dryplants'}, texture = 'dryplants_reed.png',
			 replacement_function = mg_villages.replacements_grasshut },
	tent         = { min =  5, max = 20,   space_between_buildings=2, mods={'cottages'},  texture = 'wool_white.png', name_preifx = 'Tent at',
			 replacement_function = mg_villages.replacements_tent },

	-- these sub-types may occour as single houses placed far from villages
	tower        = { only_single = 1, name_prefix = 'Tower at ',      mods={'cottages'},  texture = 'default_mese.png',
			 replacement_function = mg_villages.replacements_tower },
	chateau      = { only_single = 1, name_prefix = 'Chateau ',                           texture = 'default_gold_block.png',
			 replacement_function = mg_villages.replacements_chateau },
	forge        = { only_single = 1, name_prefix = 'Forge at '},
	tavern       = { only_single = 1, name_prefix = 'Inn at '},
	well         = { only_single = 1, name_prefix = 'Well at ',
			 replacement_function = mg_villages.replacements_medieval },
	trader       = { only_single = 1, name_prefix = 'Trading post ' },
	sawmill      = { only_single = 1, name_prefix = 'Sawmill at ' },
	farm_tiny    = { only_single = 1, name_prefix = 'House '},
	farm_full    = { only_single = 1, name_prefix = 'Farm '},
	single       = { only_single = 1, name_prefix = 'House '}, -- fallback
}

-- NOTE: Most values of village types added with mg_villages.add_village_type can still be changed later on by
--       changing the global variable mg_villages.village_type_data[ village_type ]
--       Village types where one or more of the required mods (listed in v.mods) are missing will not be
--       available.
-- You can add your own village type by i.e. calling
--         mg_villages.add_village_type( 'town', { min = 10, max = 30, space_between_buildings = 2, mods = {'moreblocks','homedecor'}, texture='default_diamond_block.png'} );
--   This will add a new village type named 'town', which will only be available if the mods moreblocks and homedecor are installed.
--   It will show the texture of the diamond block when showing the position of a village of that type in the map displayed by the /vmap command.


-- add our village types
for k,v in pairs( village_type_data_list ) do
	mg_villages.add_village_type( k, v )
end
-- just to show that this local list is no longer needed
village_type_data_list = nil


------------------------------------
-- 2. Add buildings (schematics) ---
------------------------------------

--  scm="bla"		Name of the file that holds the buildings' schematic. Supported types: .we and .mts (omit the extension!)
--  sizex, sizez, ysize: obsolete
--  yoff=0		how deep is the building burried?
--  pervillage=1	Never generate more than this amount of this building and this type (if set) of building per village.
--  axis=1		Building needs to be mirrored along the x-axis instead of the z-axis because it is initially rotated
--  inh=2  		maximum amount of inhabitants the building may hold (usually amount of beds present)
--			if set to i.e. -1, this indicates that a mob is WORKING, but not LIVING here 
--   we_origin		Only needed for very old .we files (savefile format version 3) which do not start at 0,0,0 but have an offset.
--  price               Stack that has to be paid in order to become owner of the plot the building stands on and the building;
--                      overrides mg_villages.prices[ building_typ ].
--  guests		Negative value, i.e. -2: 2 of the beds will belong to the family working here; the rest will be guests.
--                      For building type "chateau", guest names the number of servants/housemaids instead of guests.


local buildings = {

-- the houses the mod came with
	{yoff= 0, scm="house_1_0",                          typ='house',    weight={nore=1,   single=2   }, inh=4},
	{yoff= 0, scm="wheat_field",                        typ='field',    weight={nore=1   }, inh=-1},
	{yoff= 0, scm="cotton_field",                       typ='field',    weight={nore=1   }, inh=-1},
	{yoff= 1, scm="lamp", no_rotate=true,               typ='lamp',     weight={nore=1/5 }},
	{yoff=-5, scm="well", no_rotate=true, pervillage=1, typ='well',     weight={nore=1   }},
	{yoff= 0, scm="fountain", pervillage=3,             typ='fountain', weight={nore=1/4 },             axis=1},
	{yoff= 0, scm="small_house_1_0",                    typ='house',    weight={nore=1,   single=2   }, inh=2},
	{yoff= 0, scm="house_with_garden_1_0",              typ='house',    weight={nore=1,   single=2   }, inh=3},
	{yoff= 0, scm="church_1_0",           pervillage=1, typ='church',   weight={nore=1   },             inh=-1},
	{yoff= 0, scm="tower_1_0",                          typ='tower',    weight={nore=1/7, single=1   }, inh=-1},
	{yoff= 0, scm="forge_1_0",            pervillage=2, typ='forge',    weight={nore=1,   single=1/3 }, inh=-1},
	{yoff= 0, scm="library_1_0",          pervillage=2, typ='library',  weight={nore=1               }, inh=-1},
	{yoff= 0, scm="inn_1_0",              pervillage=4, typ='inn',      weight={nore=1/2, single=1/3 }, inh=-1, guests=-2}, -- has room for 4 guests
	{yoff= 0, scm="pub_1_0",              pervillage=2, typ='tavern',   weight={nore=1/3, single=1/3 }, inh=-1},


-- log cabins by Sokomine (requiring cottages, glasspanes)
	{yoff= 0, scm="logcabin1",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=2, typ='hut'},
	{yoff= 0, scm="logcabin2",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=2, typ='hut'},
	{yoff= 0, scm="logcabin3",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=3, typ='hut'},
	{yoff= 0, scm="logcabin4",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=3, typ='hut'},
	{yoff= 0, scm="logcabin5",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=1, typ='hut'},
	{yoff= 0, scm="logcabin6",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=1, typ='hut'},
	{yoff= 0, scm="logcabin7",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=2, typ='hut'},
	{yoff= 0, scm="logcabin8",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=2, typ='hut'},
	{yoff= 0, scm="logcabin9",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=1, typ='hut'},
	{yoff= 0, scm="logcabin10",   orients={2}, weight={logcabin=1,   single=1},         inh=3, typ='hut'},
	{yoff= 0, scm="logcabin11",   orients={1}, weight={logcabin=1,   single=1},         inh=6, typ='hut'},
	{yoff= 0, scm="logcabinpub1", orients={1}, weight={logcabin=1/6, single=1}, pervillage=1, typ='tavern', axis=1, inh=1, guests=-2}, -- +5 guests
	{yoff= 0, scm="logcabinpub2", orients={1}, weight={logcabin=1/6, single=1}, pervillage=1, typ='tavern', axis=1, inh=2, guests=-3}, -- +8 guests
	{yoff= 0, scm="logcabinpub3", orients={1}, weight={logcabin=1/6, single=1}, pervillage=1, typ='tavern', axis=1, inh=2, guests=-4}, -- +12 guest

-- grass huts (requiring cottages, dryplants, cavestuff/undergrowth, plantlife)
	{yoff= 0, scm="grasshut1_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshut2_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='townhall'}, -- community hut for meetings
	{yoff= 0, scm="grasshut3_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshut4_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshut5_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshut6_1_90", weight={            single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshutcenter_1_90", pervillage=1, weight={grasshut=2}, nomirror=1, typ = 'tavern'}, -- open meeting place

-- for the buildings below, sizex, sizez and ysize are read from the file directly;

-- schematics from Sokomines villages mod (requires cottages)
	{scm="church_1",        yoff= 0, orients={0}, farming_plus=0, avoid='', typ='church',    weight={medieval=4            }, pervillage=1,   inh=-1},    
--	{scm="church_2_twoelk", yoff= 0, orients={0}, farming_plus=0, avoid='', typ='church',    weight={medieval=4}, pervillage=1},    
	{scm="forge_1",         yoff= 0, orients={0}, farming_plus=0, avoid='', typ='forge',     weight={medieval=2,   single=1/2}, pervillage=1,   inh=-1},
	{scm="mill_1",          yoff= 0, orients={0}, farming_plus=0, avoid='', typ='mill',      weight={medieval=2            }, pervillage=1,   inh=-1},
	{scm="watermill_1",     yoff=-3, orients={1}, farming_plus=0, avoid='', typ='mill',      weight={medieval=2            }, pervillage=1,   inh=-2},
	{scm="hut_1",           yoff= 0, orients={0}, farming_plus=0, avoid='', typ='hut',       weight={medieval=1,   single=1  },                 inh=1},
	{scm="hut_2",           yoff= 0, orients={0}, farming_plus=0, avoid='', typ='hut',       weight={medieval=1,   single=1  },                 inh=2},
	{scm="farm_full_1",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=2},
	{scm="farm_full_2",     yoff= 0, orients={1}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=5},
	{scm="farm_full_3",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=5},
	{scm="farm_full_4",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=8},
	{scm="farm_full_5",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=5},
	{scm="farm_full_6",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=5},
	{scm="farm_tiny_1",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=2},
	{scm="farm_tiny_2",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=6},
	{scm="farm_tiny_3",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=4},
	{scm="farm_tiny_4",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=4},
	{scm="farm_tiny_5",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=4},
	{scm="farm_tiny_6",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=4},
	{scm="farm_tiny_7",     yoff= 0, orients={3}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=7},
	{scm="taverne_1",       yoff= 0, orients={0}, farming_plus=1, avoid='', typ='tavern',    weight={medieval=1/2, single=1  }, pervillage=1, inh=6, guests=-3},  -- 19 beds: 10 guest, 3 worker, 6 family
	{scm="taverne_2",       yoff= 0, orients={0}, farming_plus=0, avoid='', typ='tavern',    weight={medieval=1/2, single=1/3}, pervillage=1, inh=2},  -- no guests
	{scm="taverne_3",       yoff= 0, orients={0}, farming_plus=0, avoid='', typ='tavern',    weight={medieval=1/2, single=1/3}, pervillage=1, inh=2},  -- no guests
	{scm="taverne_4",       yoff= 0, orients={0}, farming_plus=0, avoid='', typ='tavern',    weight={medieval=1/2, single=1/3}, pervillage=1, inh=1},  -- no guests

	{scm="well_1",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_2",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_3",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_4",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_5",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_6",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_7",          yoff= -1, orients={0}, farming_plus=0, avoid='well', typ='well', weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_8",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},

	{scm="allmende_3_90",   yoff=-2, orients={0}, farming_plus=0, avoid='', typ='allmende',  weight={medieval=3,taoki=3,nore=3,logcabin=1,grasshut=1}, pervillage=1},

	{scm="tree_place_1",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_2",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_3",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_4",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_5",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_6",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_7",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_8",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_9",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_10",   yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},

	{scm="wagon_1",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_2",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_3",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_4",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_5",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_6",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_7",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_8",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_9",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_10",        yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_11",        yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_12",        yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},

	{scm="bench_1",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='bench',  weight={medieval=1/12}, nomirror=1},
	{scm="bench_2",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='bench',  weight={medieval=1/12}, nomirror=1},
	{scm="bench_3",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='bench',  weight={medieval=1/12}, nomirror=1},
	{scm="bench_4",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='bench',  weight={medieval=1/12}, nomirror=1},

	{scm="shed_1",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_2",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_3",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_5",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_6",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_7",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_8",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_9",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_10",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_11",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_12",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='stable',  weight={medieval=1/10}},

	{scm="weide_1",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_2",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_3",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_4",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_5",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_6",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},

	{scm="field_1",         yoff=-2, orients={0,1,2,3}, farming_plus=0, avoid='field',   typ='field',    weight={medieval=1/6}, pervillage=8},
	{scm="field_2",         yoff=-2, orients={0,1,2,3}, farming_plus=0, avoid='field',   typ='field',    weight={medieval=1/6}, pervillage=8},
	{scm="field_3",         yoff=-2, orients={0,1,2,3}, farming_plus=0, avoid='field',   typ='field',    weight={medieval=1/6}, pervillage=8},
	{scm="field_4",         yoff=-2, orients={0,1,2,3}, farming_plus=0, avoid='field',   typ='field',    weight={medieval=1/6}, pervillage=8},

	-- hut and hills for charachoal burners; perhaps they could live together with lumberjacks?
	{scm="charachoal_hut",  yoff= 0, orients={0,1,2},   farming_plus=0, avoid='', typ='hut',  weight={charachoal=1, single=5}, inh=2, nomirror=1},
	{scm="charachoal_hill", yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='hut',  weight={charachoal=2          }, inh=-1, nomirror=1},

	-- lumberjacks; they require the cottages mod
	{scm="lumberjack_1",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=3},
	{scm="lumberjack_2",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=4},
	{scm="lumberjack_3",        yoff= 1, orients={1,2,3}, avoid='', typ='lumberjack', weight={lumberjack=1, single=3},         inh=3},
	{scm="lumberjack_4",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=4},
	{scm="lumberjack_5",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=9},
	{scm="lumberjack_6",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=5},
	{scm="lumberjack_7",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=5},
	{scm="lumberjack_8",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=9},
	{scm="lumberjack_9",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=5},
	{scm="lumberjack_10",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_11",       yoff= 0, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_12",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=3},
	{scm="lumberjack_13",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=3},
	{scm="lumberjack_14",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_15",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_16",       yoff= 0, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_school",   yoff= 1, orients={1},     avoid='', typ='school',     weight={lumberjack=2          }, axis=1, inh=1},
	{scm="lumberjack_stable",   yoff= 0, orients={3},     avoid='', typ='horsestable',     weight={lumberjack=1, single=3}, axis=1, inh=-1},
	{scm="lumberjack_pub_1",    yoff= 1, orients={1},     avoid='', typ='tavern',     weight={lumberjack=3, single=1}, pervillage=1, axis=1, inh=-1},
	{scm="lumberjack_church_1", yoff= 1, orients={1},     avoid='', typ='church',     weight={lumberjack=3}, pervillage=1, axis=1, inh=-1},
	{scm="lumberjack_hotel_1",  yoff= 1, orients={0},     avoid='', typ='inn',        weight={lumberjack=1, single=1}, axis=1,               inh=16, guests=-1}, -- all but one of the 16 are guests
	{scm="lumberjack_shop_1",   yoff= 1, orients={1},     avoid='', typ='shop',       weight={lumberjack=1}, pervillage=1, axis=1, inh=-1},
	{scm="lumberjack_sawmill_1",yoff=-7, orients={1},     avoid='', typ='sawmill',    weight={lumberjack=2, single=1}, pervillage=1, axis=1, inh=-1},


--	{scm="cow_trader_1",    yoff= 0, orients={4}, avoid='', typ='trader',     weight={lumberjack=1}},

	-- clay traders depend on cottages as well
	{scm="trader_clay_1",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3}, axis=1, inh=1}, -- poor guy who has to live in that small thing
	{scm="trader_clay_2",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3}, axis=1, inh=1}, -- not that he'll live very comftable there...
	{scm="trader_clay_3",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3},         inh=2},
	{scm="trader_clay_4",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3},         inh=2},
	{scm="trader_clay_5",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3}, axis=1, inh=2},

	{scm="clay_pit_1",      yoff=-3, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},
	{scm="clay_pit_2",      yoff=-1, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},
	{scm="clay_pit_3",      yoff=-6, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},
	{scm="clay_pit_4",      yoff= 0, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},
	{scm="clay_pit_5",      yoff= 1, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},


   -- Houses from Taokis Structure I/O Mod (see https://forum.minetest.net/viewtopic.php?id=5524)
	{scm="default_town_farm",          yoff= -1, orients={1}, farming_plus=0, avoid='',     typ='field',  weight={taoki=1,   single=1}, axis=1},
	{scm="default_town_house_large_1", yoff= -4, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1/4, single=1}, axis=1, inh=10},
	{scm="default_town_house_large_2", yoff= -4, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1/4, single=1}, axis=1, inh=8},
	{scm="default_town_house_medium",  yoff= -4, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1/2, single=1}, axis=1, inh=6},
	{scm="default_town_house_small",   yoff= -4, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1,   single=1},   axis=1, inh=4},
	{scm="default_town_house_tiny_1",  yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1,   single=1},   axis=1, inh=3},
	{scm="default_town_house_tiny_2",  yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1,   single=1},   axis=1, inh=3},
	{scm="default_town_house_tiny_3",  yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1,   single=1},   axis=1, inh=2},
	{scm="default_town_park",          yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='park',   weight={taoki=1            },   axis=1},
	{scm="default_town_tower",         yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='tower',  weight={taoki=1/6, single=1}, axis=1, inh=-1},
	{scm="default_town_well",          yoff= -6, orients={1}, farming_plus=0, avoid='',     typ='well',   weight={taoki=1/4          }, axis=1},
	{scm="default_town_fountain",      yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='fountain',weight={taoki=1/4          }, axis=1},
	-- the hotel seems to be only the middle section of the building; it's build for another spawning algorithm
--	{scm="default_town_hotel",         yoff= -1, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1/5}},

	{scm="tent_tiny_1",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1,   single=1},   inh=1},
	{scm="tent_tiny_2",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1,   single=1},   inh=1},
	{scm="tent_big_1",                 yoff=0, orients={1}, farming_plus=0, avoid='',        typ='shop',    weight={tent=1,   single=1}},           -- no sleeping place
	{scm="tent_big_2",                 yoff=0, orients={3}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1,   single=1},   inh=2},
	{scm="tent_medium_1",              yoff=0, orients={1}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1/2, single=1}, inh=3},
	{scm="tent_medium_2",              yoff=0, orients={3}, farming_plus=0, avoid='',        typ='shed',    weight={tent=1/2, single=1}, inh=3},
	{scm="tent_medium_3",              yoff=0, orients={1}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1/2, single=1}, inh=3},
	{scm="tent_medium_4",              yoff=0, orients={1}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1/2, single=1}, inh=3},
	{scm="tent_open_1",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='pub',    weight={tent=1/5}},
	{scm="tent_open_2",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='shed',    weight={tent=1/5}},
	{scm="tent_open_3",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='shop',    weight={tent=1/5}},
	{scm="tent_open_big_1",            yoff=0, orients={3}, farming_plus=0, avoid='',        typ='pub',     weight={tent=1/5}},
	{scm="tent_open_big_2",            yoff=0, orients={3}, farming_plus=0, avoid='',        typ='church',  weight={tent=1/5}},
	{scm="tent_open_big_3",            yoff=0, orients={3}, farming_plus=0, avoid='',        typ='townhall',    weight={tent=5}, pervillage=1},

	{scm="hochsitz_1",                 yoff=0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='tower',    weight={tower=1, single=1/3}, nomirror=1},
	{scm="hochsitz_2",                 yoff=0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='tower',    weight={tower=1, single=1/3}, nomirror=1},
	{scm="hochsitz_3",                 yoff=0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='tower',    weight={tower=1, single=1/3}, nomirror=1},
	{scm="hochsitz_4",                 yoff=0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='tower',    weight={tower=1, single=1/3}, nomirror=1},

	{scm="chateau_without_garden",     yoff=-1,orients={0,1,2,3}, farming_plus=0, avoid='', typ='chateau',  weight={chateau=1,single=8}, pervillage=1, inh=8, guests=-6}, -- 6 family members of the landlord's family; rest are servants

	{scm="baking_house_1",             yoff=0, orients={0}, farming_plus=0, avoid='', typ='bakery', weight={medieval=1/4}, pervillage=1, inh=-1},
	{scm="baking_house_2",             yoff=0, orients={0}, farming_plus=0, avoid='', typ='bakery', weight={medieval=1/4}, pervillage=1, inh=-1},
	{scm="baking_house_3",             yoff=0, orients={0}, farming_plus=0, avoid='', typ='bakery', weight={medieval=1/4}, pervillage=1, inh=-1},
	{scm="baking_house_4",             yoff=0, orients={0}, farming_plus=0, avoid='', typ='bakery', weight={medieval=1/4}, pervillage=1, inh=-1},

	{scm="empty_1", yoff=0, typ='empty', inh=0, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},
	{scm="empty_2", yoff=0, typ='empty', inh=1, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},
	{scm="empty_3", yoff=0, typ='empty', inh=1, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},
	{scm="empty_4", yoff=0, typ='empty', inh=1, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},
	{scm="empty_5", yoff=0, typ='empty', inh=1, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},

	{scm="house_medieval_fancy_1_90", yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  }, inh=6},
	{scm="cow_shed_1_270",            yoff= 0, orients={0}, farming_plus=0, avoid='', typ='stable',      weight={medieval=1/4, single=1  }, inh=-1},
	{scm="shed_with_forge_v2_1_0",    yoff= 0, orients={0}, farming_plus=0, avoid='', typ='forge',     weight={medieval=1,single=1/2}, inh=1},

	{scm="empty_16x32_2_90", typ='empty', inh=1, pervillage=4,
			weight={nore=2,taoki=2,medieval=2,charachoal=2,lumberjack=2,claytrader=2,logcabin=2,canadian=2,grasshut=2,tent=2}},
	{scm="empty_32x32_2_90", typ='empty', inh=1, pervillage=4,
			weight={nore=2,taoki=2,medieval=2,charachoal=2,lumberjack=2,claytrader=2,logcabin=2,canadian=2,grasshut=2,tent=2}},

	-- some new grasshut variants
	{scm="grasshut7_1_90",      weight={grasshut=1,   single=1}, nomirror=1, typ='hut'},
	{scm="grasshut8_1_90",      weight={grasshut=1,   single=1}, nomirror=1, typ='hut'},
	{scm="grasshut9_1_90",      weight={grasshut=1,   single=1}, nomirror=1, typ='hut'},
	{scm="grasshut_pub_1_90",   weight={grasshut=1/4, single=1}, nomirror=1, typ='pub'},
	{scm="grasshut_hotel_1_90", weight={grasshut=1/4, single=1}, nomirror=1, typ='inn'},
	{scm="grasshut_shop_1_90",  weight={grasshut=1,   single=1}, nomirror=1, typ='shop'},
	{scm="grasshutwell_8_90",   weight={grasshut=1,   single=1}, nomirror=1, typ='well'},
}


-- import all the buildings
local mts_path = mg_villages.modpath.."/schems/"
-- determine the size of the given houses and other necessary values
for i,v in ipairs( buildings ) do
	v.mts_path = mts_path
	mg_villages.add_building( v, i )
end
-- just to show that this local list is no longer needed
buildings = nil
