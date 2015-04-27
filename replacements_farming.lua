                                
replacements_group['farming'] = {}

-- this contains a list of all found/available nodenames that may act as a replacement frming nodes
replacements_group['farming'].found = {};
-- contains a list of *all* known farming names - even of mods that may not be installed
replacements_group['farming'].all   = {};

-- contains information about how a particular node is called if a particular farming mod is used;
replacements_group['farming'].data  = {};

-- names of traders for the diffrent fruits
replacements_group['farming'].traders = {};


replacements_group['farming'].replace_material = function( replacements, old_material, new_material )

	if(  not( old_material ) or not( replacements_group['farming'].data[ old_material ])
	  or not( new_material ) or not( replacements_group['farming'].data[ new_material ])
	  or old_material == new_material ) then
		return replacements;
	end

	local old_nodes = replacements_group['farming'].data[ old_material ];
	local new_nodes = replacements_group['farming'].data[ new_material ];
	for i=1,#old_nodes do
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
		-- default to the last growth stage
		elseif( i>#new_nodes and minetest.registered_nodes[ new_nodes[ #new_nodes ]]) then
			table.insert( replacements, { old, new_nodes[ #new_nodes ] });
		end
	end
	return replacements;		
end


---------------------
-- internal functions
---------------------
replacements_group['farming'].add_material = function( fruit, fruit_item, prefix, seperator, postfix  )

	local is_loaded = false;
	if(     minetest.registered_items[ fruit_item ] 
	    and minetest.registered_nodes[ prefix..fruit..seperator.."1"..postfix ] ) then
		is_loaded = true;
		table.insert( replacements_group['farming'].found, fruit_item );
	end
	table.insert( replacements_group['farming'].all, fruit_item );

	local data = {};
	-- handle seeds
	if(     minetest.registered_items[ prefix..fruit..'_seed' ]) then
		data[1] = prefix..fruit..'_seed';
	elseif( minetest.registered_items[ prefix..fruit..'seed' ]) then
		data[1] = prefix..fruit..'seed';
	else
		data[1] = fruit_item;
	end
	for i=1,8 do
		local node_name = prefix..fruit..seperator..tostring(i)..postfix;
		if( is_loaded and minetest.registered_nodes[ node_name ]) then
			table.insert( data, node_name );
		-- if the mod is not loaded, we do not know how many growth stages it has;
		-- in order to be on the safe side, store them all
		elseif( not( is_loaded )) then
			table.insert( data, node_name );
		end
	end
	-- the last plant stage (the one that gives the fruit) usually has no number
	local node_name = prefix..fruit;
	if( is_loaded and minetest.registered_nodes[ node_name ]) then
		table.insert( data, node_name );
	elseif( not( is_loaded )) then
		table.insert( data, node_name );
	end
	replacements_group['farming'].data[ fruit_item ] = data;

	-- farming nodes do not count as ground (except for soil - which is not handled here)
	if( mg_villages and mg_villages.node_is_ground ) then
		for _,v in ipairs( data ) do
			mg_villages.node_is_ground[ v ] = false;
		end
	end

	if( is_loaded and mobf_trader and mobf_trader.add_trader ) then

		-- TODO: use replacements for the payments where needed
		local goods = {
			{ fruit_item.." 1",   "default:coal_lump 3",    "default:wood 8"},
			{ fruit_item.." 10",  "default:steel_ingot 2",  "default:chest_locked 1"}};
		if( fruit_item ~= data[1] ) then
			table.insert( goods, { data[1].." 1", "farming:scarecrow", "farming:scarecrow_light 1"});
			table.insert( goods, { data[1].." 2", "default:dirt 20", "default:bucket_water", "default:steel_ingot 4", "default:leaves 99" });
		end
		table.insert( goods, {"farming:hoe_wood 1","default:wood 10", "default:cobble 10"});
		
		mobf_trader.add_trader( mobf_trader.npc_trader_prototype,
			"farmer growing "..fruit.."s", -- not always the right grammatical form
			fruit.."_farmer_v",
			goods,
			{ "farmer" },
			""
			);

		replacements_group['farming'].traders[ fruit_item ] = fruit..'_farmer_v';
	end
end




-- create a list of all available fruit types
replacements_group['farming'].construct_farming_type_list = function()

	-- farming from minetest_game
	replacements_group['farming'].add_material( 'wheat',  'farming:wheat',                   'farming:', '_', '' );
	replacements_group['farming'].add_material( 'cotton', 'farming:cotton',                  'farming:', '_', '' );

	-- RealTest
	replacements_group['farming'].add_material( 'flax',   'farming:string',                  'farming:', '_', '' );
	replacements_group['farming'].add_material( 'spelt',  'farming:wheat',                   'farming:', '_', '' );
	replacements_group['farming'].add_material( 'soy',    'farming:soy',                     'farming:', '_', '' );


	-- diffrent versions of farming_plus:
	--    PilzAdam:  https://forum.minetest.net/viewtopic.php?t=2787
	--    TenPlus1:  https://forum.minetest.net/viewtopic.php?t=9019
	--    MTDad:     https://forum.minetest.net/viewtopic.php?t=10187
	local fruits = { 'strawberry', 'raspberry',
			'carrot', 'rhubarb', 'cucumber',
			'pumpkin', 'melon',
			'orange', 'lemon', 'peach', 'walnut',
			'potato','potatoe', -- diffrent mods spell them diffrently
			'tomato', 'corn'
			};
	for i,fruit in ipairs( fruits ) do
		if(     minetest.registered_nodes[ 'farming_plus:'..fruit ]
		    and minetest.registered_nodes[ 'farming_plus:'..fruit..'_1' ]
		    and minetest.registered_items[ 'farming_plus:'..fruit..'_item' ] ) then
			replacements_group['farming'].add_material( fruit, 'farming_plus:'..fruit..'_item',   'farming_plus:', '_', '' );
		end
	end
	-- coffee beans from farming_plus/farming_plusplus
	replacements_group['farming'].add_material( 'coffee', 'farming_plus:coffee_beans',       'farming_plus:', '_', '' );

	-- Docfarming: https://forum.minetest.net/viewtopic.php?t=3948 
	fruits = {'carrot','corn','potato','raspberry'};
	for i,fruit in ipairs( fruits ) do
		replacements_group['farming'].add_material( fruit, 'docfarming:'..fruit,         'docfarming:', '', '' );
	end
end

-- create the list of known farming fruits
replacements_group['farming'].construct_farming_type_list();
