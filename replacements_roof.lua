                                
replacements_group['roof'] = {}

-- this contains a list of all found/available nodenames that may act as a replacement frming nodes
replacements_group['roof'].found = {};
-- contains a list of *all* known roof names - even of mods that may not be installed
replacements_group['roof'].all   = {};

-- contains information about how a particular node is called if a particular roof mod is used;
replacements_group['roof'].data  = {};


replacements_group['roof'].replace_material = function( replacements, old_material, new_material )

	if(  not( old_material ) or not( replacements_group['roof'].data[ old_material ])
	  or not( new_material ) or not( replacements_group['roof'].data[ new_material ])
	  or old_material == new_material ) then
		return replacements;
	end

	local old_nodes = replacements_group['roof'].data[ old_material ];
	local new_nodes = replacements_group['roof'].data[ new_material ];
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
		end
	end
	return replacements;		
end


---------------------
-- internal functions
---------------------
replacements_group['roof'].add_material = function( nodelist )

	local is_loaded = false;
	if(  minetest.registered_items[ nodelist[1] ] ) then
		is_loaded = true;
		table.insert( replacements_group['roof'].found, nodelist[1] );
	end
	table.insert( replacements_group['roof'].all, nodelist[1]);

	replacements_group['roof'].data[ nodelist[1] ] = nodelist;
end




-- create a list of all available fruit types
replacements_group['roof'].construct_roof_type_list = function()

	-- roof from cottages
	local roofs = {'straw', 'reet',  'wood', 'slate', 'red', 'brown', 'black'};
	for i,v in ipairs( roofs ) do
		replacements_group['roof'].add_material( {
			'cottages:roof_connector_'..v,
			'cottages:roof_flat_'..v,
			'',  -- no full block available
			'cottages:roof_'..v
			} );
	end

	
	-- from dryplants
	roofs = {'reed', 'wetreed'};
	for i,v in ipairs( roofs ) do
		replacements_group['roof'].add_material( {
			'dryplants:'..v..'_roof',
			'dryplants:'..v..'_slab',
			'dryplants:'..v,
			'dryplants:'..v..'_roof',
			'dryplants:'..v..'_roof_corner',
			'dryplants:'..v..'_roof_corner_2'
			} );
	end
	-- roof from homedecor
	roofs = {'wood', 'terracotta', 'asphalt', 'glass'};
	for i,v in ipairs( roofs ) do
		replacements_group['roof'].add_material( {
			'homedecor:shingle_side_'..v,
			'homedecor:shingles_'..v,
			'',
			'homedecor:shingles_'..v,
			'homedecor:shingle_inner_corner_'..v,
			'homedecor:shingle_outer_corner_'..v,
			} );
	end

	replacements_group['roof'].data[ 'homedecor:shingle_side_glass'  ][2] = 'homedecor:skylight';
	replacements_group['roof'].data[ 'homedecor:shingle_side_glass'  ][4] = 'homedecor:skylight';
	replacements_group['roof'].data[ 'homedecor:shingle_side_asphalt'][3] = 'streets:asphalt';

	-- TODO: slopes from technic or other slopes mods?
end

-- create the list of known roof fruits
replacements_group['roof'].construct_roof_type_list();
