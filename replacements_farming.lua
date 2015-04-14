                                
replacements_farming = {}

-- this contains a list of all found/available nodenames that may act as a replacement frming nodes
replacements_farming.found = {};
-- contains a list of *all* known farming names - even of mods that may not be installed
replacements_farming.all   = {};

-- contains information about how a particular node is called if a particular farming mod is used;
replacements_farming.data  = {};


replacements_farming.replace_fruit = function( replacements, old_material, new_material )

	if(  not( old_material ) or not( replacements_farming.data[ old_material ])
	  or not( new_material ) or not( replacements_farming.data[ new_material ])
	  or old_material == new_material ) then
		return replacements;
	end

	local old_nodes = replacements_farming.data[ old_material ];
	local new_nodes = replacements_farming.data[ new_material ];
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
replacements_farming.add_fruit_type = function( fruit, fruit_item, prefix, seperator, postfix  )

	table.insert( replacements_farming.found, fruit_item );

	local data = {};
	for i=1,8 do
		local node_name = prefix..fruit..seperator..tostring(i)..postfix;
		if( minetest.registered_nodes[ node_name ]) then
			table.insert( data, node_name );
		end
	end
	-- the last plant stage (the one that gives the fruit) usually has no number
	local node_name = prefix..fruit;
	if( minetest.registered_nodes[ node_name ]) then
		table.insert( data, node_name );
	end
	replacements_farming.data[ fruit_item ] = data;
end




-- create a list of all available fruit types
replacements_farming.construct_farming_type_list = function()
	local fruits = {'carrot','coffee','corn','cucumber','lemon','melon','orange','peach',
			'potato','potatoe', -- diffrent mods spell them diffrently
			'pumpkin','raspberry','rhubarb','strawberry','tomato','walnut',
			-- docfarming
			'corn',
			-- from default
			'cotton','wheat',
			-- from realtest
			'flax','spelt','soy'};

	for i,fruit in ipairs( fruits ) do
		-- diffrent versions of farming_plus:
		-- PilzAdam:  https://forum.minetest.net/viewtopic.php?t=2787
		-- TenPlus1:  https://forum.minetest.net/viewtopic.php?t=9019
		-- MTDad:     https://forum.minetest.net/viewtopic.php?t=10187
		if(     minetest.registered_nodes[ 'farming_plus:'..fruit ]
		    and minetest.registered_nodes[ 'farming_plus:'..fruit..'_1' ]
		    and minetest.registered_items[ 'farming_plus:'..fruit..'_item' ] ) then
			replacements_farming.add_fruit_type( fruit, 'farming_plus:'..fruit..'_item',   'farming_plus:', '_', '' );

		elseif( minetest.registered_nodes[ 'farming_plus:'..fruit ]
		    and minetest.registered_nodes[ 'farming_plus:'..fruit..'_1' ]
		    and minetest.registered_items[ 'farming_plus:'..fruit..'_beans' ] ) then
			table.insert( replacements_farming.found, 'farming_plus:'..fruit..'_beans'  );
			replacements_farming.add_fruit_type( fruit, 'farming_plus:'..fruit..'_beans',  'farming_plus:', '_', '' );
                                                                      
		-- Docfarming: https://forum.minetest.net/viewtopic.php?t=3948 
		elseif( minetest.registered_items[ 'docfarming:'  ..fruit ]
		    and minetest.registered_nodes[ 'docfarming:'  ..fruit..'1' ]) then
			replacements_farming.add_fruit_type( fruit, 'docfarming:'..fruit,              'docfarming:', '', '' );

		-- farming from default; also covers soy from RealTest
		elseif( minetest.registered_items[ 'farming:'     ..fruit ]
		    and minetest.registered_nodes[ 'farming:'     ..fruit..'_1' ]) then
			replacements_farming.add_fruit_type( fruit, 'farming:'..fruit,                 'farming:', '_', '' );

		-- RealTest
		elseif( fruit=='flax'
		    and minetest.registered_items[ 'farming:string' ]
		    and minetest.registered_nodes[ 'farming:'     ..fruit..'_1' ]) then
			replacements_farming.add_fruit_type( fruit, 'farming:string',                  'farming:', '_', '' );

		elseif( fruit=='spelt'
		    and minetest.registered_items[ 'farming:wheat' ]
		    and minetest.registered_nodes[ 'farming:'     ..fruit..'_1' ]) then
			replacements_farming.add_fruit_type( fruit, 'farming:wheat',                   'farming:', '_', '' );

		elseif( fruit=='soy'
		    and minetest.registered_items[ 'farming:soy' ]
		    and minetest.registered_nodes[ 'farming:'     ..fruit..'_1' ]) then
			replacements_farming.add_fruit_type( fruit, 'farming:soy',                     'farming:', '_', '' );
		end
	end
end

-- create the list of known farming fruits
replacements_farming.construct_farming_type_list();
