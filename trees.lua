-- general handling of trees that are to be grown as part of
-- schematics placed in villages and in the flattened/partly
-- flattened area around the village

-- those functions from the mg mod do not have their own namespace
-- (and this is too little to warrant a trees_mg.lua)
if( minetest.get_modpath( 'mg' )) then
	mg_villages.add_savannatree = add_savannatree
	mg_villages.add_pinetree    = add_pinetree
end

-- figure out which tree to grow in RealTest
-- (this is also accessed in mapgen.lua)
mg_villages.sapling_to_tree_realtest = {}
for k,v in pairs(replacements_group['wood'].data) do
	-- if the sapling exists in this game
	if(   minetest.registered_nodes[v[6]]
	  and v[2] == "trees:") then
		-- we are intrested in the tree name
		mg_villages.sapling_to_tree_realtest[v[6]] = "trees:"..v[1]
		mg_villages.sapling_to_tree_realtest[minetest.get_content_id(v[6])] = "trees:"..v[1]
	end
end

-- called from mg_villages.place_villages_via_voxelmanip
mg_villages.grow_trees_voxelmanip = function( vm, trees_to_grow_via_voxelmanip )
	for tree_nr, pos in ipairs( trees_to_grow_via_voxelmanip ) do
		-- print("GROWING "..tostring(pos.path).." at "..minetest.pos_to_string(pos))
		minetest.place_schematic_on_vmanip(vm, {x=pos.x, y=pos.y, z=pos.z}, pos.path, "random", nil, true)
	end
	trees_to_grow_via_voxelmanip = {};
end


-- called from mg_villages.flatten_village_area (randomly height adjusted area),
-- mg_villages.village_area_fill_with_plants (farmland around the village) and
-- mg_villages.place_villages_via_voxelmanip (saplings inside spawned structures, i.e. gardens)
mg_villages.grow_a_tree = function( pos, plant_id, minp, maxp, data, a, cid, pr, snow, trees_to_grow_via_voxelmanip )
	-- the name of the sapling is more practical here than its content_id
	local sapling_name = minetest.get_name_from_content_id(plant_id)
	-- a normal tree; sometimes comes with apples
	if(     sapling_name == "default:sapling") then
		mg_villages.grow_tree(       data, a, pos, math.random(1, 4) == 1, math.random(1,100000), snow)
		return true;
	-- a normal jungletree
	elseif( sapling_name == "default:junglesapling") then
		mg_villages.grow_jungletree( data, a, pos, math.random(1,100000), snow)
		return true;
	-- a pine tree
	elseif( sapling_name == "default:pine_sapling") then
		mg_villages.grow_pinetree(   data, a, pos, snow);
		return true;
	-- an acacia tree; it does not have its own grow function
	elseif( sapling_name == "default:acacia_sapling") then
		data[ a:index( pos.x, pos.y, pos.z )] = plant_id
		table.insert( trees_to_grow_via_voxelmanip, {x=pos.x-4, y=pos.y-1, z=pos.z-4,
			path = minetest.get_modpath("default").."/schematics/acacia_tree_from_sapling.mts"})
		return true;
        -- aspen tree from newer minetest game
	elseif( sapling_name == "default:aspen_sapling") then
		data[ a:index( pos.x, pos.y, pos.z )] = plant_id
		table.insert( trees_to_grow_via_voxelmanip, {x=pos.x-2, y=pos.y-1, z=pos.z-2,
			path = minetest.get_modpath("default").."/schematics/aspen_tree_from_sapling.mts"})
		return true;
	-- a savannatree from the mg mod
	elseif( sapling_name == "mg:savannasapling") then
		mg_villages.add_savannatree(         data, a, pos.x, pos.y, pos.z, minp, maxp, pr) -- TODO: snow
		return true;
	-- a pine tree from the mg mod
	elseif( sapling_name == "mg:pinesapling") then
		mg_villages.add_pinetree(            data, a, pos.x, pos.y, pos.z, minp, maxp, pr) -- TODO: snow
		return true;

	-- trees from MineClone2
	elseif( sapling_name == "mcl_core:sapling") then
		data[ a:index( pos.x, pos.y, pos.z )] = plant_id
		table.insert( trees_to_grow_via_voxelmanip, {x=pos.x-2, y=pos.y-1, z=pos.z-2,
			path = minetest.get_modpath("mcl_core").."/schematics/mcl_core_oak_classic.mts"})
		return true;
	elseif( sapling_name == "mcl_core:darksapling") then
		data[ a:index( pos.x, pos.y, pos.z )] = plant_id
		table.insert( trees_to_grow_via_voxelmanip, {x=pos.x-3, y=pos.y-1, z=pos.z-4,
			path = minetest.get_modpath("mcl_core").."/schematics/mcl_core_dark_oak.mts"})
		return true;
	elseif( sapling_name == "mcl_core:sprucesapling") then
		data[ a:index( pos.x, pos.y, pos.z )] = plant_id
		-- there are three variats of spruce trees in MineClone2
		local r = math.random(1, 3)
		table.insert( trees_to_grow_via_voxelmanip, {x=pos.x-3, y=pos.y-1, z=pos.z-3,
			path = minetest.get_modpath("mcl_core").."/schematics/mcl_core_spruce_"..r..".mts"})
		return true;
	elseif( sapling_name == "mcl_core:acaciasapling") then
		data[ a:index( pos.x, pos.y, pos.z )] = plant_id
		-- there are seven variats of acacia trees in MineClone2
		local r = math.random(1, 7)
		local offset = 0
	        if     r == 2 or r == 3           then offset = -4
	        elseif r == 4 or r == 6 or r == 7 then offset = -3
	        elseif r == 1 or r == 5           then offset = -5
		end
		table.insert( trees_to_grow_via_voxelmanip, {x=pos.x-offset, y=pos.y-1, z=pos.z-offset,
			path = minetest.get_modpath("mcl_core").."/schematics/mcl_core_acacia_"..r..".mts"})
		return true;
	elseif( sapling_name == "mcl_core:junglesapling") then
		data[ a:index( pos.x, pos.y, pos.z )] = plant_id
		-- just normal ones - no huge ones inside a village
		table.insert( trees_to_grow_via_voxelmanip, {x=pos.x-2, y=pos.y-1, z=pos.z-2,
			path = minetest.get_modpath("mcl_core").."/schematics/mcl_core_jungle_tree.mts"})
		return true;
	elseif( sapling_name == "mcl_core:birchsapling") then
		data[ a:index( pos.x, pos.y, pos.z )] = plant_id
		-- just normal ones - no huge ones inside a village
		table.insert( trees_to_grow_via_voxelmanip, {x=pos.x-2, y=pos.y-1, z=pos.z-2,
			path = minetest.get_modpath("mcl_core").."/schematics/mcl_core_birch.mts"})
		return true;
	-- RealTest trees
	elseif( mg_villages.sapling_to_tree_realtest[sapling_name]) then
		data[ a:index( pos.x, pos.y, pos.z )] = plant_id
		mg_villages.grow_realtest_tree(data, a, pos, snow, mg_villages.sapling_to_tree_realtest[sapling_name])
	end
	return false;
end

