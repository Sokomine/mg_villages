replacements_realtest = {}

-- parameter: replacements, name_in_default, name_in_realtest, to_realtest=true/false
replacements_realtest.stairs = function( repl, def, rt, to_realtest)
	if( to_realtest ) then
		if( def ~= rt ) then
			table.insert( repl, {'default:'..def,   'default:'..rt});
		end
		table.insert( repl, {'stairs:stair_'..def,      'default:'..rt..'_stair'});
		table.insert( repl, {'stairs:slab_'..def,       'default:'..rt..'_slab'});
	else
		if( def ~= rt ) then
			table.insert( repl, {'default:'..rt,    'default:'..def});
		end
		table.insert( repl, {'default:'..rt..'_stair',  'stairs:stair_'..def});
		table.insert( repl, {'default:'..rt..'_stair_upside_down','stairs:stair_'..def});
		-- upside-down-slab
		table.insert( repl, {'default:'..rt..'_slab_r', 'stairs:slab_'..def});
		table.insert( repl, {'default:'..rt..'_slab',   'stairs:slab_'..def});
	end
	return repl;
end

replacements_realtest.replace = function( replacements ) 
	
	local repl = {};
	local to_realtest = false;
	if(     not( minetest.registered_nodes[ 'default:furnace' ]) 
	    and      minetest.registered_nodes[ 'oven:oven' ]) then
		to_realtest = true;
	elseif(      minetest.registered_nodes[ 'default:furnace' ] 
	    and not( minetest.registered_nodes[ 'oven:oven' ])) then
		to_realtest = false;
	else
		-- else no replacements required
		return;
	end

	replacements_realtest.stairs( repl, 'stone',             'stone',              to_realtest );
	replacements_realtest.stairs( repl, 'cobble',            'stone_flat',         to_realtest ); 
	replacements_realtest.stairs( repl, 'stonebrick',        'stone_bricks',       to_realtest );
	replacements_realtest.stairs( repl, 'desert_stone',      'desert_stone',       to_realtest );
	replacements_realtest.stairs( repl, 'desert_cobble',     'desert_stone_flat',  to_realtest );
	replacements_realtest.stairs( repl, 'desert_stonebrick', 'desert_stone_bricks',to_realtest );
	replacements_realtest.stairs( repl, 'brick',             'brick',              to_realtest );

	if( to_realtest ) then
		table.insert( repl, {'default:furnace',          'oven:oven'});
		table.insert( repl, {'default:clay',             'grounds:clay'});
		for i=1,5 do
                	table.insert( repl, {'default:grass_'..i,'air' });
		end
        	table.insert(         repl, {'default:apple',    'air' });
	        table.insert(         repl, {'default:obsidian_glass', 'default:glass' });
	else
		table.insert(         repl, {'oven:oven',        'default:furnace'});
		table.insert(         repl, {'grounds:clay',     'default:clay'});
        end

	for i,v in ipairs( repl ) do
		if( v and v[2] and minetest.registered_nodes[ v[2]] ) then
			local found = false;
			for j,w in ipairs( replacements ) do
				if( w and w[1] and w[1]==v[1] ) then
					w[2] = v[2];
					found = true;
				end
			end
			if( not( found )) then
				table.insert( replacements, {v[1],v[2]} );
			end
		end
	end
	return replacements;
end
		
