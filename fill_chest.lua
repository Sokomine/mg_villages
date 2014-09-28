-- TODO: refill chest after some time?
-- TODO: alert NPC that something was taken

mg_villages.random_chest_content = {};

-- things that can be found in private, not locked chests belonging to npc
-- contains tables of the following structure: { node_name, probability (in percent, 100=always, 0=never), max_amount, repeat (for more than one stack) }
mg_villages.random_chest_content = {
	{"default:pick_stone",             10,  1, 3 }, 
	{"default:pick_steel",              5,  1, 2 }, 
	{"default:pick_mese",               2,  1, 2 }, 
	{"default:shovel_stone",            5,  1, 3 }, 
	{"default:shovel_steel",            5,  1, 2 }, 
	{"default:axe_stone",               5,  1, 3 }, 
	{"default:axe_steel",               5,  1, 2 }, 
	{"default:sword_stone",             1,  1, 3 }, 
	{"default:sword_steel",             1,  1, 3 }, 
	{"default:stick",                  20, 40, 2 }, 
	{"default:torch",                  50, 10, 4 }, 

	{"default:book",                   60,  1, 2 },
	{"default:paper",                  60,  6, 4 },
	{"default:apple",                  50, 10, 2 },
	{"default:ladder",                 20,  1, 2 },
        
	{"default:coal_lump",              80, 30, 1 },
	{"default:steel_ingot",            30,  4, 2 },
	{"default:mese_crystal_fragment",  10,  3, 1 },

	{"bucket:bucket_empty",            10,  3, 2 },
	{"bucket:bucket_water",             5,  3, 2 },
	{"bucket:bucket_lava",              3,  3, 2 },

	{"vessels:glass_bottle",           10, 10, 2 },
	{"vessels:drinking_glass",         20,  2, 1 },
	{"vessels:steel_bottle",           10,  1, 1 },

	{"wool:white",                     60,  8, 2 },
}


-- that someone will hide valuable ingots in chests that are not locked is fairly unrealistic; thus, those items are rare
if( minetest.get_modpath("moreores") ~= nil ) then
   table.insert( mg_villages.random_chest_content, {"moreores:gold_ingot",             1,  2, 1 } );
   table.insert( mg_villages.random_chest_content, {"moreores:silver_ingot",           1,  2, 1 } );
   table.insert( mg_villages.random_chest_content, {"moreores:copper_ingot",          30, 10, 1 } );
   table.insert( mg_villages.random_chest_content, {"moreores:tin_ingot",              1,  5, 1 } );
   table.insert( mg_villages.random_chest_content, {"moreores:bronze_ingot",           1,  1, 1 } );
   table.insert( mg_villages.random_chest_content, {"moreores:mithril_ingot",          1,  1, 1 } );
end

-- candles are a very likely content of chests
if( minetest.get_modpath("candles") ~= nil ) then
   table.insert( mg_villages.random_chest_content, {"candles:candle",                 80, 12, 2 } );
   table.insert( mg_villages.random_chest_content, {"candles:candelabra_steel",        1,  1, 1 } );
   table.insert( mg_villages.random_chest_content, {"candles:candelabra_copper",       1,  1, 1 } );
   table.insert( mg_villages.random_chest_content, {"candles:honey",                  50,  2, 1 } );
end

-- our NPC have to spend their free time somehow...also adds food variety
if( minetest.get_modpath("fishing") ~= nil ) then
   table.insert( mg_villages.random_chest_content, {"fishing:pole",                   60,  1, 1 } );
end

-- ropes are always useful
if( minetest.get_modpath("ropes") ~= nil ) then
   table.insert( mg_villages.random_chest_content, {"ropes:rope",                     60,  5, 2 } );
elseif( minetest.get_modpath("farming") ~= nil ) then
   table.insert( mg_villages.random_chest_content, {"farming:string",                 60,  5, 2 } );
elseif( minetest.get_modpath("moreblocks") ~= nil ) then
   table.insert( mg_villages.random_chest_content, {"moreblocks:rope",                60,  5, 2 } );
end

-- TODO: food mod



-- get some random content for a chest
mg_villages.fill_chest_random = function( pos, pr, building_nr, building_typ )

	local meta = minetest.env:get_meta( pos );
	local inv  = meta:get_inventory();

	local count = 0;

	local inv_size = inv:get_size('main');
	for i,v in ipairs( mg_villages.random_chest_content ) do

		-- repeat this many times
		for count=1, v[ 4 ] do

			-- to avoid too many things inside a chest, lower probability
			if(     count<30 -- make sure it does not get too much and there is still room for a new stack
			 and inv_size and inv_size > 0 and v[ 2 ] > pr:next( 1, 200 )) then
	
				--inv:add_item('main', v[ 1 ].." "..tostring( math.random( 1, tonumber(v[ 3 ]) )));
				-- add itemstack at a random position in the chests inventory 
				inv:set_stack( 'main', pr:next( 1, inv:get_size( 'main' )), v[ 1 ].." "..tostring( pr:next( 1, tonumber(v[ 3 ]) )) );
				count = count+1;
			end
		end
	end
end

--[[ -- TODO
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
