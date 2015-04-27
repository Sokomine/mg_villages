replacements_group['wood'] = {}

-- this contains a list of all found/available nodenames that may act as a replacement for default:wood
replacements_group['wood'].found = {};
-- contains a list of *all* known wood names - even of mods that may not be installed
replacements_group['wood'].all   = {};

-- contains information about how a particular node is called if a particular wood is used;
replacements_group['wood'].data  = {};

-- names of traders for the diffrent wood types
replacements_group['wood'].traders = {};


------------------------------------------------------------------------------
-- external function; call it in order to replace old_wood with new_wood;
-- other nodes (trees, saplings, fences, doors, ...) are replaced accordingly,
-- depending on what new_wood has to offer
------------------------------------------------------------------------------
replacements_group['wood'].replace_material = function( replacements, old_wood, new_wood )

	if(  not( old_wood ) or not( replacements_group['wood'].data[ old_wood ])
	  or not( new_wood ) or not( replacements_group['wood'].data[ new_wood ])
	  or old_wood == new_wood ) then
		return replacements;
	end

	local old_nodes = replacements_group['wood'].data[ old_wood ];
	local new_nodes = replacements_group['wood'].data[ new_wood ];
	for i=3,#old_nodes do
		local old = old_nodes[i];
		local new = old;
		if( i<=#new_nodes and new_nodes[i] and minetest.registered_nodes[ new_nodes[i]] ) then
			new = new_nodes[i];
			local found = false;
			for i,v in ipairs(replacements) do
				if( v and v[1]==old ) then
					v[2] = new;
					found = true;
				end
			end
			if( not( found )) then
				table.insert( replacements, { old, new });
			end
		end
	end
	return replacements;		
end


---------------------
-- internal functions
---------------------
-- wood (and its corresponding tree trunk) is a very good candidate for replacement in most houses
-- helper function for replacements_group['wood'].get_wood_type_list
replacements_group['wood'].add_material = function( candidate_list, mod_prefix, w_pre, w_post, t_pre, t_post, l_pre, l_post,
					s_pre, s_post, stair_pre, stair_post, slab_pre, slab_post,
					fence_pre, fence_post, gate_pre, gate_post )
	if( not( candidate_list )) then
		return;
	end
	for _,v in ipairs( candidate_list ) do
		local is_loaded = false;
		local wood_name = mod_prefix..w_pre..v..w_post;
		-- create a complete list of all possible wood names
		table.insert( replacements_group['wood'].all, wood_name );
		-- create a list of all *installed* wood types
		if( minetest.registered_nodes[ wood_name ]) then
			table.insert( replacements_group['wood'].found, wood_name );
			is_loaded = true;
		end
			
		-- there is no check if the node names created here actually exist
		local data = { v,                             -- 1. base name of the node
				mod_prefix,                   -- 2. mod name
				wood_name,                    -- 3. replacement for default:wood
				mod_prefix..t_pre..v..t_post, -- 4.     "  "    for default:tree
				mod_prefix..l_pre..v..l_post, -- 5.     "  "    for default:leaves
				mod_prefix..s_pre..v..s_post, -- 6.     "  "    for default:sapling
				stair_pre..v..stair_post,     -- 7.     "  "    for stairs:stair_wood
				slab_pre..v..slab_post,       -- 8.     "  "    for stairs:slab_wood
				fence_pre..v..fence_post,     -- 9.     "  "    for default:fence_wood
				gate_pre..v..gate_post..'_open',  -- 10.  "  "    for cottages:gate_open
				gate_pre..v..gate_post..'_closed',-- 11.  "  "    for cottages:gate_closed
		};

		-- normal wood does have a number of nodes which might get replaced by more specialized wood types
		if( mod_prefix=='default:' and v=='' ) then
			local w = 'wood';
			data[10] = 'cottages:gate_open';
			data[11] = 'cottages:gate_closed';
			data[12] = 'default:ladder';
			data[13] = 'doors:door_'..w..'_t_1';
			data[14] = 'doors:door_'..w..'_t_2';
			data[15] = 'doors:door_'..w..'_b_1';
			data[16] = 'doors:door_'..w..'_b_2';
			data[17] = 'default:bookshelf';
			data[18] = 'default:chest';
			data[19] = 'default:chest_locked';
			data[20] = 'stairs:stair_'..w..'upside_down';
			data[21] = 'stairs:slab_'..w..'upside_down';
			data[22] = 'doors:trapdoor_open';
			data[23] = 'doors:trapdoor';
		-- realtest has some further replacements
		elseif( mod_prefix=='trees:' and w_post=='_planks' and t_post=='_log' ) then
			data[12] = 'trees:'..v..'_ladder';
			data[13] = 'doors:door_'..v..'_t_1';
			data[14] = 'doors:door_'..v..'_t_2';
			data[15] = 'doors:door_'..v..'_b_1';
			data[16] = 'doors:door_'..v..'_b_2';
			data[17] = 'decorations:bookshelf_'..v;
			data[18] = 'trees:'..v..'_chest';
			data[19] = 'trees:'..v..'_chest_locked';
			data[20] = 'trees:'..v..'_planks_stair_upside_down';
			data[21] = 'trees:'..v..'_planks_slab_upside_down';
			data[22] = 'hatches:'..v..'_hatch_opened_top';
			data[23] = 'hatches:'..v..'_hatch_opened_bottom';
		end
		replacements_group['wood'].data[ wood_name ] = data;

		-- none of the wood nodes counts as ground
		if( mg_villages and mg_villages.node_is_ground ) then
			for _,v in ipairs( data ) do
				mg_villages.node_is_ground[ v ] = false;
			end
		end


		if( is_loaded and mobf_trader and mobf_trader.add_trader ) then
			-- TODO: check if all offered payments exist
			local goods = {
				{ data[3].." 4",    "default:dirt 24",       "default:cobble 24"},
				{ data[4].." 4",    "default:apple 2",       "default:coal_lump 4"},
				{ data[4].." 8",    "default:pick_stone 1",  "default:axe_stone 1"},
				{ data[4].." 12",   "default:cobble 80",     "default:steel_ingot 1"},
				{ data[4].." 36",   "bucket:bucket_empty 1", "bucket:bucket_water 1"},
				{ data[4].." 42",   "default:axe_steel 1",   "default:mese_crystal 4"},

				{ data[6].." 1",    "default:mese 10",       "default:steel_ingot 48"},
				-- leaves are a cheaper way of getting saplings
				{ data[5].." 10",   "default:cobble 1",      "default:dirt 2"}
			};

			mobf_trader.add_trader( mobf_trader.npc_trader_prototype,
				"Trader of "..( v or "unknown" ).." wood",
				v.."_wood_v",
				goods,
				{ "lumberjack" },
				""
				);

	                replacements_group['wood'].traders[ wood_name ] = v..'_wood_v';
		end
	end
end

-- TODO: there are also upside-down variants sometimes
-- TODO: moreblocks - those may be installed and offer further replacements

-- create a list of all available wood types
replacements_group['wood'].construct_wood_type_list = function()

	-- https://github.com/minetest/minetest_game
	-- default tree and jungletree; no gates available
	replacements_group['wood'].add_material( {'', 'jungle' },     'default:', '','wood','', 'tree',  '','leaves',  '','sapling',
		'stairs:stair_', 'wood', 'stairs:slab_', 'wood',   'default:fence_','wood',  'NONE', '' );
	-- default:pine_needles instead of leaves; no gates available
	replacements_group['wood'].add_material( {'pine' },           'default:', '','wood','', 'tree',  '','_needles','','_sapling',
		'stairs:stair_', 'wood', 'stairs:slab_', 'wood',   'default:fence_','wood',  'NONE','' );

	-- https://github.com/Novatux/mg
	-- trees from nores mapgen
	replacements_group['wood'].add_material( {'savanna', 'pine' },'mg:',     '','wood','', 'tree',  '','leaves',  '','sapling',
		'stairs:stair_','wood',  'stairs:slab_','wood',    'NONE','',  'NONE','');


	-- https://github.com/VanessaE/moretrees
	-- minus the jungletree (already in default)
	local moretrees_treelist = {"beech","apple_tree","oak","sequoia","birch","palm","spruce","pine","willow","acacia","rubber_tree","fir" };
	replacements_group['wood'].add_material( moretrees_treelist,  'moretrees:', '', '_planks', '','_trunk', '','_leaves','','_sapling',
		'moretrees:stair_','_planks', 'moretrees:slab_','_planks',   'NONE','',  'NONE','');
	

	-- https://github.com/tenplus1/ethereal
	-- ethereal does not have a common naming convention for leaves
	replacements_group['wood'].add_material( {'acacia','redwood'},'ethereal:',  '','_wood',   '','_trunk', '','_leaves', '','_sapling',
		'stairs:stair_','_wood', 'stairs:slab_','_wood',   'ethereal:fence_','',     'ethereal:','gate');
	-- frost has another sapling type...
	replacements_group['wood'].add_material( {'frost'},           'ethereal:',  '','_wood',   '','_tree', '','_leaves', '','_tree_sapling',
		'stairs:stair_','_wood', 'stairs:slab_','_wood',   'ethereal:fence_','wood', 'ethereal:','woodgate' );
	-- those tree types do not use typ_leaves, but typleaves instead...
	replacements_group['wood'].add_material( {'yellow'},          'ethereal:',  '','_wood',   '','_trunk', '','leaves',  '','_tree_sapling',
		'stairs:stair_','_wood', 'stairs:slab_','_wood',   'ethereal:fence_','wood', 'ethereal:','gate' );
	-- banana has a diffrent fence type....
	replacements_group['wood'].add_material( {'banana'},          'ethereal:',  '','_wood',   '','_trunk', '','leaves',  '','_tree_sapling',
		'stairs:stair_','_wood', 'stairs:slab_','_wood',   'ethereal:fence_', '',    'ethereal:','gate' );
	-- palm has another name for the sapling again...
	replacements_group['wood'].add_material( {'palm'},            'ethereal:',  '','_wood',   '','_trunk', '','leaves',  '','_sapling',
		'stairs:stair_','_wood', 'stairs:slab_','_wood',   'ethereal:fence_', '',    'ethereal:','gate' );
	-- the leaves are called willow_twig here...
	replacements_group['wood'].add_material( {'willow'},          'ethereal:',  '','_wood',   '','_trunk', '','_twig',   '','_sapling',
		'stairs:stair_','_wood', 'stairs:slab_','_wood',   'ethereal:fence_', '',    'ethereal:','gate' );
	-- mushroom has its own name; it works quite well as a wood replacement; the red cap is used as leaves
	-- the stairs are also called slightly diffrently (end in _trunk instead of _wood)
	replacements_group['wood'].add_material( {'mushroom'},        'ethereal:',  '','_pore',   '','_trunk', '','',        '','_sapling',
		'stairs:stair_','_trunk', 'stairs:slab_','_trunk', 'ethereal:fence_', '',    'ethereal:','gate' );

	
	-- https://github.com/VanessaE/realtest_game
	local realtest_trees = {'ash','aspen','birch','maple','chestnut','pine','spruce'};
	replacements_group['wood'].add_material( realtest_trees,      'trees:',     '','_planks', '','_log',   '','_leaves', '','_sapling',
		'trees:','_planks_stair', 'trees:','_planks_slab', 'fences:','_fence',    'NONE','' );

	
	-- https://github.com/Gael-de-Sailly/Forest
	local forest_trees = {'oak','birch','willow','fir','mirabelle','cherry','plum','beech','ginkgo','lavender'};
	replacements_group['wood'].add_material( forest_trees,        'forest:',    '', '_wood',  '','_tree',  '','_leaves', '','_sapling',
		'stairs:stair_','_wood',  'stairs:slab_','_wood',    'NONE','',            'NONE',''        );

	-- https://github.com/bas080/trees
	replacements_group['wood'].add_material( {'mangrove','palm','conifer'},'trees:',  'wood_','',   'tree_','',  'leaves_','', 'sapling_','', 
		'stairs:stair_','_wood',  'stairs:slab_','_wood',    'NONE','',            'NONE',''        );


	-- https://github.com/PilzAdam/farming_plus
	-- TODO: this does not come with its own wood... banana and cocoa trees (only leaves, sapling and fruit)
	-- TODO:      farming_plus:TREETYP_sapling   farming_plus:TREETYP_leaves   farming_plus:TREETYP 
	-- TODO: in general: add fruits as replacements for apples
end

-- actually construct the data structure once
replacements_group['wood'].construct_wood_type_list();

