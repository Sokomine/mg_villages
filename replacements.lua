

-- only the function mg_villages.get_replacement_table(..) is called from outside this file

mg_villages.replace_materials = function( replacements, pr, original_materials, prefixes, materials, old_material )
	
	local known_materials = {};
	local wood_found = false;
	-- for all alternate materials
	for i,m in ipairs( materials ) do
		-- check if that material exists for each supplied prefix
		for j,p in ipairs( prefixes ) do
			if( minetest.registered_nodes[ p..m ] ) then
				table.insert( known_materials, m );
				-- if wood is present, later on try moretrees wood as well
				if( 'default:wood' == m ) then
					wood_found = true;
				end
			end
		end	
	end

	-- nothing found which could be used
	if( #known_materials < 1 ) then
		return;
	end
	
	-- support wooden planks from moretrees
	if( wood_found and moretrees and moretrees.treelist ) then
		for _,v in ipairs( moretrees.treelist ) do
			if( minetest.registered_nodes[ "moretrees:"..v[1].."_planks"] ) then
				table.insert( known_materials, "moretrees:"..v[1].."_planks" );
			end	
		end
	end
		
	local new_material  = known_materials[ pr:next( 1, #known_materials )]; 

	-- no replacement necessary if we did choose the same material as before
	if( new_material == old_material or old_material == (prefixes[1]..new_material)) then
		return old_material;
	end

	for i,v in ipairs( prefixes ) do
		table.insert( replacements, { original_materials[ i ], v..new_material } );
	end
	return new_material;
end

-- replace the tree trunk as well so that it fits to the wood type
mg_villages.replace_tree_trunk = function( replacements, wood_type )
	if(     wood_type == 'default:junglewood' ) then
		table.insert( replacements, {'default:tree',  'default:jungletree'});
	elseif( wood_type == 'mg:savannawood' ) then
		table.insert( replacements, {'default:tree',  'mg:savannatree'});
	elseif( wood_type == 'mg:pinewood' ) then
		table.insert( replacements, {'default:tree',  'mg:pinetree'});
 	elseif( moretrees and moretrees.treelist ) then
		for _,v in ipairs( moretrees.treelist ) do
			if( wood_type == "moretrees:"..v[1].."_planks" ) then
				table.insert( replacements, {'default:tree', "moretrees:"..v[1].."_trunk"});
			end
		end
	else
		return nil;
	end
	return wood_type;
-- TODO if minetest.get_modpath("moreblocks") and moretrees.enable_stairsplus the
end


-- if buildings are made out of a certain wood type, people might expect trees of that type nearby
mg_villages.replace_saplings = function( replacements, wood_type )
	if(     wood_type == 'default:junglewood' ) then
		table.insert( replacements, {'default:sapling',  'default:junglesapling'});
	elseif( wood_type == 'mg:savannawood' ) then
		table.insert( replacements, {'default:sapling',  'mg:savannasapling'});
	elseif( wood_type == 'mg:pinewood' ) then
		table.insert( replacements, {'default:sapling',  'mg:pinesapling'});
 	elseif( moretrees and moretrees.treelist ) then
		for _,v in ipairs( moretrees.treelist ) do
			if( wood_type == "moretrees:"..v[1].."_planks" ) then
				table.insert( replacements, {'default:sapling', "moretrees:"..v[1].."_sapling_ongen"});
			end
		end
	end
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

   -- Taokis houses from structure i/o
   if( housetype == 'taoki' ) then  

      -- the main body of the houses in the .mts files is made out of wood
      local wood_type = mg_villages.replace_materials( replacements, pr,
		{'default:wood'},
		{''},
		{'default:wood', 'default:junglewood', 'mg:pinewood', 'mg:savannawood',
		'default:clay', 'default:brick', 'default:sandstone', 
		'default:stonebrick', 'default:desert_stonebrick','default:sandstonebrick', 'default:sandstone','default:stone','default:desert_stone',
		'default:coalblock','default:steelblock','default:goldblock', 'default:bronzeblock', 'default:copperblock', 'wool:white'},
		'default:wood');
      -- tree trunks are seldom used in these houses; let's change them anyway
      mg_villages.replace_tree_trunk( replacements, wood_type );
		
      -- all this comes in variants for stairs and slabs as well
      mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_stonebrick',  'stairs:slab_stonebrick', 'default:stonebrick'},
		{'stairs:stair_',            'stairs:slab_',           'default:'          },
		{ 'stonebrick', 'stone', 'sandstone', 'cobble'},
		'stonebrick');

      -- decorative slabs above doors etc.
      mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_wood'},
		{'stairs:stair_'},
		{'stonebrick', 'stone', 'sandstone', 'cobble', 'wood', 'junglewood' },
		'wood');

      -- brick roofs are a bit odd; but then...
      -- all three shapes of roof parts have to fit together
      mg_villages.replace_materials( replacements, pr,
		{'stairs:stair_brick',  'stairs:slab_brick', 'default:brick'},
		{'stairs:stair_',       'stairs:slab_',      'default:'     },
		{ 'brick', 'stone', 'cobble', 'stonebrick', 'wood', 'junglewood', 'sandstone' },
		'brick' );

      return replacements;
   end


   if( housetype == 'nore' ) then

      mg_villages.replace_materials( replacements, pr,
		{'stonebrick'},
		{'default:'},
		{'stonebrick', 'desert_stonebrick','sandstonebrick', 'sandstone','stone','desert_stone'},
		'stonebrick');

      -- replace the wood as well
      local wood_type = mg_villages.replace_materials( replacements, pr,
		{'default:wood'},
		{''},
		{ 'default:wood', 'default:junglewood', 'mg:savannawood', 'mg:pinewood' },
		'default:wood');
      mg_villages.replace_tree_trunk( replacements, wood_type );
      mg_villages.replace_saplings(   replacements, wood_type );

      if( pr:next(1,3)==1 ) then
         table.insert( replacements, {'default:glass', 'default:obsidian_glass'});
      end

      return replacements;
   end


   if( housetype == 'lumberjack' ) then

      -- replace the wood - those are lumberjacks after all
      local wood_type = mg_villages.replace_materials( replacements, pr,
		{'default:wood'},
		{''},
		{ 'default:wood', 'default:junglewood', 'mg:savannawood', 'mg:pinewood' },
		'default:wood');
      mg_villages.replace_tree_trunk( replacements, wood_type );
      mg_villages.replace_saplings(   replacements, wood_type );

      return replacements;
   end


   if( housetype == 'canadian' ) then

      table.insert( replacements, {'4seasons:slimtree_wood', 'default:fence_wood'});
      if( true) then return replacements; end -- TODO
      -- remove inner corners, wallpapers etc.
      local to_air = { 38, 36, 68, 66, 69, 67, 77, 47, 44, 43, 37, 75, 45, 65, 71, 76, 46 };
      for _,v in ipairs( to_air ) do
         table.insert( replacements, {'hdb:'..tostring( v )..'_ic',  'air' });
      end
 
      to_air = { 49, 50, 52, 72, 73, 74 };
      for _,v in ipairs( to_air ) do
         table.insert( replacements, {'hdb:'..tostring( v )..'_edge',  'air' });
      end
 
      to_air = { 49, 50, 52, 72, 73, 74 };
      for _,v in ipairs( to_air ) do
         table.insert( replacements, {'hdb:'..tostring( v )..'_edgeic',  'air' });
      end

      -- thin slabs for covering walls
      to_air = { 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 65, 66, 67, 68, 69, 71, 72, 73, 74, 75, 76, 77 };
      for _,v in ipairs( to_air ) do
         table.insert( replacements, {'hdb:'..tostring( v ),  'air' });
      end

     -- these contain the majority of nodes used (junglewood is too dark)
      local materials = {'default:wood', 'mg:pinewood', 'mg:savannawood',
		'default:clay', 'default:brick', 'default:sandstone', 
		'default:stonebrick', 'default:desert_stonebrick','default:sandstonebrick', 'default:sandstone','default:stone','default:desert_stone',
		'default:coalblock','default:steelblock'};

--      local change_groups = { {49, 16, 29, 33, 82, 8}, {19,  4, 83,  2}, { 5, 80, 35, 36, 3}, {10, 31}, {28, 78}, { 6, 52, 1}, {7}};
      local change_groups = { {16, 29, 33, 82, 8}, {19,  4, 83,  2}, { 5, 80, 35, 3}, {10, 31}, {28, 78, 27}, { 6, 1}, {7}, {30,25,81,79},{64}};
      for _,cg in ipairs( change_groups ) do

         local m1 = materials[ pr:next( 1, #materials )];
         for j,v in ipairs( cg ) do
            table.insert( replacements, {'hdb:'..tostring( v ), m1 });
         end
      end

      -- hdb:9_lh and hdb:86_lh are slabs
      local materials_slab = {'stonebrick', 'stone', 'sandstone', 'cobble' };
      local slab_group = {33,58};
      for _, c in ipairs( slab_group ) do 
         local ms = materials_slab[ pr:next( 1, #materials_slab )];
         table.insert( replacements, { 'hdb:'..tostring(c)..'_lh',     'stairs:slab_'..ms });
         table.insert( replacements, { 'hdb:'..tostring(c),            'default:'..ms });
      end

      return replacements;
   end


   if( housetype == 'logcabin' ) then

      -- for logcabins, wood is the most likely type of roof material
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
      end
      return replacements;
   end


   if( housetype == 'grasshut' ) then

      table.insert( replacements, {'moreblocks:fence_jungle_wood',     'default:fence' });
      table.insert( replacements, {'dryplants:reed_roof',              'cottages:roof_straw'});
      table.insert( replacements, {'dryplants:reed_slab',              'cottages:roof_flat_straw' });
      table.insert( replacements, {'dryplants:wetreed_roof',           'cottages:roof_reet' });
      table.insert( replacements, {'dryplants:wetreed_slab',           'cottages:roof_flat_reet' });
      table.insert( replacements, {'dryplants:wetreed_roof_corner',    'default:wood' });
      table.insert( replacements, {'dryplants:wetreed_roof_corner_2',  'default:junglewood' });
      table.insert( replacements, {'cavestuff:desert_pebble_2',        'default:slab_cobble' });
   
      return replacements;
   end


   if( housetype == 'claytrader' ) then
      -- the walls of the clay trader houses are made out of brick
      mg_villages.replace_materials( replacements, pr,
		{ 'stairs:stair_brick', 'stairs:slab_brick', 'default:brick' }, -- default_materials
		{ 'stairs:stair_',      'stairs:slab_',      'default:'      }, -- prefixes (for new materials)
		{ 'brick', 'stone', 'sandstone', 'sandstonebrick', 'desert_stone', 'desert_cobble', 'desert_stonebrick' }, -- new materials
		'brick' ); -- original material
	
      -- material for the floor
      mg_villages.replace_materials( replacements, pr,
		{'default:stone'},
		{'default:'},
		{ 'brick', 'stone', 'sandstone', 'sandstonebrick', 'clay', 'desert_stone', 'desert_cobble', 'desert_stonebrick' },
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

      return replacements;
   end


   -- wells can get the same replacements as the sourrounding village; they'll get a fitting roof that way
   if( housetype ~= 'medieval' and housetype ~= 'well' and housetype ~= 'cottages') then
      return replacements;
   end

   table.insert( replacements, {'bell:bell',               'default:goldblock' });

   -- glass that served as a marker got copied accidently; there's usually no glass in cottages
   table.insert( replacements, {'default:glass',           'air'});

-- TODO: sometimes, half_door/half_door_inverted gets rotated wrong
--   table.insert( replacements, {'cottages:half_door',      'cottages:half_door_inverted'});
--   table.insert( replacements, {'cottages:half_door_inverted', 'cottages:half_door'});

   -- some poor cottage owners cannot afford glass
   if( pr:next( 1, 2 ) == 2 ) then
      table.insert( replacements, {'cottages:glass_pane',    'default:fence_wood'});
   end

   -- 'glass' is admittedly debatable; yet it may represent modernized old houses where only the tree-part was left standing
   -- loam and clay are mentioned multiple times because those are the most likely building materials in reality
   local materials = {'cottages:loam', 'cottages:loam', 'cottages:loam', 'cottages:loam', 'cottages:loam', 
                      'default:clay',  'default:clay',  'default:clay',  'default:clay',  'default:clay',
                      'default:wood','default:junglewood','default:sandstone',
                      'default:desert_stone','default:brick','default:cobble','default:stonebrick',
                      'default:desert_stonebrick','default:sandstonebrick','default:stone',
                      'mg:savannawood', 'mg:savannawood', 'mg:savannawood', 'mg:savannawood',
                      'mg:pinewood',    'mg:pinewood',    'mg:pinewood',    'mg:pinewood' };

   -- what is sandstone (the floor) may be turned into something else
   local mfs = mg_villages.replace_materials( replacements, pr,
	{'default:sandstone'},
	{''},
	materials,
	'default:sandstone');
   if( mfs and mfs ~= 'default:sandstone' ) then

      if( mfs == 'cottages:loam' or mfs == 'default:clay' or mfs == 'mg:savannawood' or mfs == 'mg:pinewood') then
         mfs = 'default:wood';
      elseif( mfs =='default:sandstonebrick' or mfs == 'default:desert_stone' or mfs == 'default:desert_stonebrick'
              or not( minetest.registered_nodes[ 'stairs:slab_'..string.sub( mfs, 9 )] )) then
         mfs = '';
      end

      if( mfs and mfs ~= '' ) then      
         table.insert( replacements, {'stairs:slab_sandstone',   'stairs:slab_'..string.sub( mfs, 9 )});
      end
   end
   -- except for the floor, everything else may be glass
   table.insert( materials, 'default:glass' );

   local uses_wood = false;
   -- bottom part of the house (usually ground floor from outside)
   local replace_clay = mg_villages.replace_materials( replacements, pr,
	{'default:clay'},
	{''},
	materials,
	'default:clay');
   if( replace_clay and replace_clay ~= 'default:clay' ) then
      uses_wood = mg_villages.replace_tree_trunk( replacements, replace_clay );
      mg_villages.replace_saplings(               replacements, replace_clay );
   end
 
   -- upper part of the house (may be the same as the material for the lower part)
   local replace_loam = mg_villages.replace_materials( replacements, pr,
	{'cottages:loam'},
	{''},
	materials,
	'cottages:loam');
   -- if the bottom was not replaced by wood, perhaps the top is
   if( not( uses_wood ) and replace_loam ) then
         mg_villages.replace_tree_trunk( replacements, replace_loam );
         mg_villages.replace_saplings(   replacements, replace_loam );
   end


   -- replace cobble; for these nodes, a stony material is needed (used in wells as well)
   -- mossycobble is fine here as well
   local mcs = mg_villages.replace_materials( replacements, pr,
		{'default:cobble'},
		{'default:'},
		{'sandstone', 'desert_stone', 'desert_cobble',
                      'cobble',      'cobble',
                      'stonebrick',  'stonebrick', 'stonebrick', -- more common than other materials
                      'mossycobble', 'mossycobble','mossycobble',
                      'stone',       'stone',
                      'desert_stonebrick','sandstonebrick'},
		'cobble');
   -- set a fitting material for the slabs; mossycobble uses the default cobble slabs
   if( mcs ~= 'mossycobble' and mcs ~= 'cobble') then

      -- if no slab exists, use sandstone slabs
      if( not( minetest.registered_nodes[ 'stairs:slab_'..mcs ])) then
         mcs = 'sandstone';
      end
      table.insert( replacements, {'stairs:slab_cobble',      'stairs:slab_'..mcs});
   end
 

   -- straw is the most likely building material for roofs for historical buildings
   mg_villages.replace_materials( replacements, pr,
		-- all three shapes of roof parts have to fit together
		{ 'cottages:roof_straw',    'cottages:roof_connector_straw',   'cottages:roof_flat_straw' },
		{ 'cottages:roof_',         'cottages:roof_connector_',        'cottages:roof_flat_'},
		{'straw', 'straw', 'straw', 'straw', 'straw',
			   'reet', 'reet', 'reet',
			   'slate', 'slate',
                           'wood',  'wood',  
                           'red',
                           'brown',
                           'black'},
		'straw');

   return replacements;
end


-- Translate replacement function from above (which aims at place_schematic) for the villages in Nores mapgen
mg_villages.get_replacement_ids = function( housetype, pr )

	local replace = {};
	local replacements = mg_villages.get_replacement_list( housetype, pr );
	for i,v in ipairs( replacements ) do
		if( v and #v == 2 ) then
			replace[ minetest.get_content_id( v[1] )] = minetest.get_content_id( v[2] );
		end
	end
	return replace;
end



-- mapgen based replacements work best using a table, while minetest.place_schematic(..) based spawning needs a list
mg_villages.get_replacement_table = function( housetype, pr, replacements )

	local rtable = {};
	local ids    = {};
	if( not( replacements )) then
		replacements = mg_villages.get_replacement_list( housetype, pr );
	end
	for i,v in ipairs( replacements ) do
		if( v and #v == 2 ) then
			rtable[ v[1] ] = v[2];
			ids[ minetest.get_content_id( v[1] )] = minetest.get_content_id( v[2] );
		end
	end
        return { table = rtable, list = replacements, ids = ids };
end
