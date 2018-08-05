-- TODO: refill chest after some time?
-- TODO: alert NPC that something was taken

handle_schematics.random_chest_content = {};

-- add random chest content
local ADD_RCC = function( data )
	if( data and #data>3 and ( minetest.registered_nodes[ data[1] ] or minetest.registered_items[ data[1] ]) ) then
		data.chest_default = 1;
		table.insert( handle_schematics.random_chest_content, data );
	end
end

-- things that can be found in private, not locked chests belonging to npc
-- contains tables of the following structure: { node_name, probability (in percent, 100=always, 0=never), max_amount, repeat (for more than one stack) }

ADD_RCC({"default:pick_stone",             10,  1, 3, farm_tiny=1, farm_full=1, shed=1, lumberjack=1, hut=1, chest_work=1, lumberjack=1 }); 
ADD_RCC({"default:pick_steel",              5,  1, 2, forge=1 }); 
ADD_RCC({"default:pick_mese",               2,  1, 2, forge=1, lumberjack=1 }); 
ADD_RCC({"default:shovel_stone",            5,  1, 3, farm_tiny=1, farm_full=1, shed=1, lumberjack=1, hut=1, chest_work=1 }); 
ADD_RCC({"default:shovel_steel",            5,  1, 2, forge=1 }); 
ADD_RCC({"default:axe_stone",               5,  1, 3, farm_tiny=1, farm_full=1, chest_work=1, lumberjack=1 }); 
ADD_RCC({"default:axe_steel",               5,  1, 2, forge=1, lumberjack=1 }); 
ADD_RCC({"default:sword_wood",              1,  1, 3, guard=1, ship=1 });
ADD_RCC({"default:sword_stone",             1,  1, 3, guard=1 });
ADD_RCC({"default:sword_steel",             1,  1, 3, forge=1, guard=1, ship=1 });

ADD_RCC({"default:stick",                  20, 40, 2, church=1, library=1, chest_private=1, shelf=5, shed=1, lumberjack=1, hut=1, ship=1 });
ADD_RCC({"default:torch",                  50, 10, 4, church=1, library=1, chest_private=1, shelf=1, shed=1, lumberjack=1, hut=1, ship=1 });

ADD_RCC({"default:book",                   60,  1, 1, church=1, library=1, ship=1 });
ADD_RCC({"default:book",                   90,  1,12, chest_bookshelf=1, ship=1 });

ADD_RCC({"default:paper",                  60,  6, 4, church=1, library=1, ship=1 });
ADD_RCC({"default:apple",                  50, 10, 2, chest_storage=4, chest_private=1, shelf=5, ship=1});
ADD_RCC({"default:ladder",                 20,  1, 2, church=1, library=1, shed=1, lumberjack=1, hut=1, ship=1 });
        
ADD_RCC({"default:coal_lump",              80, 30, 1, forge=1, shed=1, lumberjack=1, hut=1, ship=1});
ADD_RCC({"default:steel_ingot",            30,  4, 2, forge=1, ship=1 });
ADD_RCC({"default:mese_crystal_fragment",  10,  3, 1, forge=1, chest_storage=1, ship=1 });

ADD_RCC({"bucket:bucket_empty",            10,  3, 2, chest_work=1, forge=1, shed=1, hut=1, ship=1 });
ADD_RCC({"bucket:bucket_water",             5,  3, 2, chest_work=1, forge=1 });
ADD_RCC({"bucket:bucket_lava",              3,  3, 2, forge=1 });

ADD_RCC({"vessels:glass_bottle",           10, 10, 2, church=1, library=1, shelf=1, ship=1 });
ADD_RCC({"vessels:drinking_glass",         20,  2, 1, church=1, library=1, shelf=1, ship=1 });
ADD_RCC({"vessels:steel_bottle",           10,  1, 1, church=1, library=1, shelf=1 });

ADD_RCC({"wool:white",                     60,  8, 2, church=1, library=1, ship=1 });


-- that someone will hide valuable ingots in chests that are not locked is fairly unrealistic; thus, those items are rare
ADD_RCC({"moreores:gold_ingot",             1,  2, 1 });
ADD_RCC({"moreores:silver_ingot",           1,  2, 1 });
ADD_RCC({"moreores:copper_ingot",          30, 10, 1 });
ADD_RCC({"moreores:tin_ingot",              1,  5, 1 });
ADD_RCC({"moreores:bronze_ingot",           1,  1, 1 });
ADD_RCC({"moreores:mithril_ingot",          1,  1, 1 });

-- candles are a very likely content of chests
ADD_RCC({"candles:candle",                 80, 12, 2, church=1, library=1, chest_private=1, ship=1 });
ADD_RCC({"candles:candelabra_steel",        1,  1, 1, church=1, library=1, chest_private=1, ship=1 });
ADD_RCC({"candles:candelabra_copper",       1,  1, 1, church=1, library=1, chest_private=1, ship=1 });
ADD_RCC({"candles:honey",                  50,  2, 1 });

-- our NPC have to spend their free time somehow...also adds food variety
ADD_RCC({"fishing:pole",                   60,  1, 1 });

-- ropes are always useful
if( minetest.get_modpath("ropes") ~= nil ) then
	ADD_RCC({"ropes:rope",                     60,  5, 2, chest_work=1, shelf=1, chest_storage=1, ship=1 });
elseif( minetest.get_modpath("farming") ~= nil ) then
	ADD_RCC({"farming:string",                 60,  5, 2, church=1, library=1, chest_work=1, shelf=1, chest_storage=1, ship=1 });
elseif( minetest.get_modpath("moreblocks") ~= nil ) then
	ADD_RCC({"moreblocks:rope",                60,  5, 2, chest_work=1, shelf=1, chest_storage=1, ship=1 });
end


ADD_RCC({'bees:bottle_honey',              50, 4, 1, beekeeper=3, tavern=1, inn=1, chest_storage=1 });
ADD_RCC({'bees:extractor',                 80, 1, 2, beekeeper=1 });
ADD_RCC({'bees:frame_empty',               50, 2, 5, beekeeper=1 });
ADD_RCC({'bees:frame_full',                80, 1, 1, beekeeper=1 });
ADD_RCC({'bees:grafting_tool',             50, 1, 3, beekeeper=1 });
ADD_RCC({'bees:hive_industrial',          100, 1, 1, beekeeper=1 });
ADD_RCC({'bees:honey_comb',                50, 2, 2, beekeeper=1 });
ADD_RCC({'bees:queen_bee',                 50, 2, 3, beekeeper=1 });
ADD_RCC({'bees:smoker',                    80, 1, 2, beekeeper=1 });
ADD_RCC({'bees:wax',                       80, 3, 3, beekeeper=1 });

ADD_RCC({'bushes:blackberry',              80, 20,  4, bakery=1 });
ADD_RCC({'bushes:blackberry_pie_cooked',   80, 12,  4, bakery=1 });
ADD_RCC({'bushes:blueberry',               80, 20,  4, bakery=1 });
ADD_RCC({'bushes:blueberry_pie_cooked',    80, 12,  4, bakery=1 });
ADD_RCC({'bushes:gooseberry',              80, 20,  4, bakery=1 });
ADD_RCC({'bushes:gooseberry_pie_cooked',   80, 12,  4, bakery=1 });
ADD_RCC({'bushes:raspberry',               80, 20,  4, bakery=1 });
ADD_RCC({'bushes:raspberry_pie_cooked',    80, 12,  4, bakery=1 });
ADD_RCC({'bushes:mixed_berry_pie_cooked',  80, 12,  4, bakery=1 });
ADD_RCC({'bushes:sugar',                   80, 99,  5, bakery=1, shelf=1, ship=1 });

ADD_RCC({'carts:cart',                     80,  1,  2, miner=1});

ADD_RCC({'castle:battleaxe',               50,  1,  1, guard=1, forge=1, ship=1 });
ADD_RCC({'castle:ropebox',                 50,  2,  2, guard=1, ship=1 });
ADD_RCC({'castle:ropes',                   50,  1,  1, guard=2, chest_private=1, chest_work=2, ship=1 });
ADD_RCC({'castle:shield',                  50,  1,  1, guard=1, ship=1 });
ADD_RCC({'castle:shield_2',                50,  1,  1, guard=1, ship=1 });
ADD_RCC({'castle:shield_3',                50,  1,  1, guard=1, ship=1 });

ADD_RCC({'cottages:anvil',                 80,  1,  2, forge=1 });

ADD_RCC({'currency:minegeld',              80, 10,  2, chest_private=1, chest_work=1, ship=1 }); -- TODO: could be in any chest with a certain chance

ADD_RCC({'farming:hoe_stone',              80,  1,  2, farm_tiny=2, farm_full=2, chest_work=2 });

ADD_RCC({'homedecor:beer_mug',             50,  1,  2, tavern=5, inn=3, ship=1});
ADD_RCC({'homedecor:book_blue',            50,  1,  2, church=1, library=1, chest_private=1, ship=1});
ADD_RCC({'homedecor:book_red',             50,  1,  2, church=1, library=1, chest_private=1, ship=1});
ADD_RCC({'homedecor:book_green',           50,  1,  2, church=1, library=1, chest_private=1, ship=1});
ADD_RCC({'homedecor:bottle_brown',         50,  1,  2, tavern=3, inn=3, chest_private=1, ship=1});
ADD_RCC({'homedecor:bottle_green',         50,  1,  2, tavern=3, inn=3, chest_private=1, ship=1});
ADD_RCC({'homedecor:calendar',             50,  1,  1, church=1, library=1, chest_private=1, chest_work=1, chest_storage=1, ship=1});
ADD_RCC({"homedecor:candle",               50,  2,  1, church=2, library=1, chest_private=1, chest_work=1, chest_storage=1, ship=1 });
ADD_RCC({"homedecor:candle_thin",          50,  2,  1, church=1, library=1, chest_private=1, chest_work=1, chest_storage=1, ship=1 });
ADD_RCC({"homedecor:copper_pans",          80,  1,  1, chest_work=1, ship=1 });
ADD_RCC({"homedecor:dardboard",            50,  1,  1, tavern=1});
ADD_RCC({"homedecor:oil_extract",          80,  1,  3, church=1, library=1, chest_private=1, chest_work=1, chest_storage=1, ship=1 });
ADD_RCC({"homedecor:oil_lamp",             50,  2,  1, church=1, library=1, chest_private=1, chest_work=1, chest_storage=1, ship=1 });
ADD_RCC({"homedecor:torch_wall",           50,  2,  1, church=1, library=1, chest_private=1, chest_work=1, chest_storage=1, ship=1 });

ADD_RCC({"locks:key",                      50,  2,  1, chest_private=1, chest_work=1, chest_storage=1, forge=1, ship=1 });
ADD_RCC({"locks:keychain",                 50,  2,  1, chest_private=1, chest_work=1, chest_storage=1, forge=1, ship=1 });

ADD_RCC({"moretrees:coconut_milk",         80,  5,  2, tavern=1, inn=1, ship=1 });
ADD_RCC({"moretrees:raw_coconut",          80,  5,  2, tavern=1, inn=1, ship=1 });
ADD_RCC({"moretrees:pine_nuts",            80, 99,  1, tavern=1, inn=1, chest_storage=3, ship=1 });
ADD_RCC({"moretrees:spruce_nuts",          80, 99,  1, tavern=1, inn=1, chest_storage=3, ship=1 });

ADD_RCC({"quartz:quartz_crystal",          80,  1,  1, library=1, ship=1 });

ADD_RCC({"screwdriver:screwdriver",        80,  1,  1, chest_work=1 });

ADD_RCC({"unified_inventory:bag_large",    80,  1,  1, chest_private=1, chest_storage=2 });
ADD_RCC({"unified_inventory:bag_medium",   80,  1,  1, chest_private=1, chest_storage=2 });
ADD_RCC({"unified_inventory:bag_small",    80,  1,  1, tavern=1, inn=1, chest_work=1, chest_private=1, ship=1 });


handle_schematics.fill_chests = function( chest_positions, pr, building_typ )
	if( not( chest_positions ) or not( chest_positions[1]) or not( chest_positions[1].x)) then
		return;
	end
	if( not( pr)) then
		pr = PseudoRandom(chest_positions[1].x * chest_positions[1].y);
	end
	for _,chest_data in ipairs( chest_positions ) do
		handle_schematics.fill_chest_random( chest_data, pr, building_typ );
	end
end


-- get some random content for a chest
handle_schematics.fill_chest_random = function( pos, pr, building_data_typ )

	local meta = minetest.get_meta( pos );
	local inv  = meta:get_inventory();

	if( not( inv )) then
		local node = minetest.get_node( pos );
		if( node
		  and node.name
		  and minetest.registered_nodes[ node.name ]
		  and minetest.registered_nodes[ node.name ].on_construct ) then
			minetest.registered_nodes[ node.name ].on_construct({x=pos.x, y=pos.y, z=pos.z});
			meta = minetest.get_meta( pos );
			inv = meta:get_inventory();
		end
		if( not( inv )) then
			print("[handle_schematics, fill_chest] ERROR: Failed to get inventory for filling of chest-like item at "..minetest.serialize(pos));
			return;
		end
	end
	-- bookshelves use "books" instead of "main" for their inventory
	local inv_source = 'main';
	-- which kind of content might be expected for this particular chest?
	local typ = minetest.get_name_from_content_id( pos.typ );
	if( pos.typ_name ) then
		typ = pos.typ_name;
	end
	if(     typ == 'default:bookshelf') then
		typ = 'chest_bookshelf';
		inv_source = 'books';
	elseif( typ == 'default:chest') then
		typ = 'chest_default';
	elseif( not( typ ) or (typ ~= 'cottages:shelf' and typ ~= 'cottages:chest_work' and typ ~= 'cottages:chest_storage' and typ ~= 'cottages:chest_private')) then
		typ = building_data_typ;
	else
		typ = string.sub( typ, 10 );
	end
	local typ2 = nil;
	if( (typ == 'chest_work' or typ == 'chest_default') and building_data_typ ) then
		typ2 = building_data_typ;
	end
	if( not( typ ) or typ=='' ) then
		print("[handle_schematics, fill_chest] ERROR: UNKOWN typ for chest at "..minetest.serialize(pos));
		return;
	end
	local inv_size = inv:get_size( inv_source );
	handle_schematics.fill_one_chest_random( pos, pr, typ, typ2, inv, inv_size, inv_source);
end


-- pos: position (x,y,z) of the chest that is to be filled
-- pr: pseudo-random number generator
-- typ: typ of the chest (i.e. chest_work, chest_default, chest_bookshelf, ...)
-- typ2: if the typ is chest_work, typ2 will contain the type of the building
-- inv: the inventory that is to be filled
-- inv_size: the size of the inventory that is to be filled
handle_schematics.fill_one_chest_random = function( pos, pr, typ, typ2, inv, inv_size, inv_source)

	local count;
	for i,v in ipairs( handle_schematics.random_chest_content ) do

		-- repeat this many times
		for count=1, v[ 4 ] do

			-- to avoid too many things inside a chest, lower probability
			if(     count<30 -- make sure it does not get too much and there is still room for a new stack
			 and (v[ typ ] or (typ2 and v[ typ2 ]))
			 and inv_size and inv_size > 0 and v[ 2 ] > pr:next( 1, 200 )) then
	
				--inv:add_item('main', v[ 1 ].." "..tostring( math.random( 1, tonumber(v[ 3 ]) )));
				-- add itemstack at a random position in the chests inventory 
				inv:set_stack( inv_source, pr:next( 1, inv_size), v[ 1 ].." "..tostring( pr:next( 1, tonumber(v[ 3 ]) )) );
				count = count+1;
			end
		end
	end
end

--[[
--the old code used by Nores mg mapgen
		for _, n in pairs(village.to_add_data.extranodes) do

--			minetest.set_node(n.pos, n.node)
			if n.meta ~= nil then


				meta = minetest.get_meta(n.pos)
				meta:from_table(n.meta)
				if n.node.name == "default:chest" then
					local inv = meta:get_inventory()
					local items = inv:get_list("main")
					for i=1, inv:get_size("main") do
						inv:set_stack("main", i, ItemStack(""))
					end
					local numitems = pr:next(3, 20) 
					for i=1,numitems do
						local ii = pr:next(1, #items) 
						local prob = items[ii]:get_count() % 2 ^ 8
						local stacksz = math.floor(items[ii]:get_count() / 2 ^ 8)
						if pr:next(0, prob) == 0 and stacksz>0 then
							stk = ItemStack({name=items[ii]:get_name(), count=pr:next(1, stacksz), wear=items[ii]:get_wear(), metadata=items[ii]:get_metadata()})
							local ind = pr:next(1, inv:get_size("main"))
							while not inv:get_stack("main",ind):is_empty() do
								ind = pr:next(1, inv:get_size("main"))
							end
							inv:set_stack("main", ind, stk)
						end
					end
				end
			end
		end

--]]
