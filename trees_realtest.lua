-- this is taken from the function trees.make_tree in the trees
-- mod in RealTest - modified so that it can work with VoxelManip
-- instead of set/get_node
-- TODO: handle snow
mg_villages.grow_realtest_tree = function(data, a, pos, snow, tree)
	local tree = realtest.registered_trees[tree]
	if(not(tree)) then
		return
	end
	local c_air       = minetest.get_content_id("air")
	local c_ignore    = minetest.get_content_id("ignore")
	local c_sapling   = minetest.get_content_id(tree.name.."_sapling")
	local c_trunk     = minetest.get_content_id(tree.name.."_trunk")
	local c_trunk_top = minetest.get_content_id(tree.name.."_trunk_top")
	local c_leaves    = minetest.get_content_id(tree.name.."_leaves")
	local height = tree.height()
	for i = 0,height-1 do
		local vi = a:index(pos.x, pos.y+i, pos.z)
		if(data[vi] == c_air or data[vi] == c_ignore or data[vi] == c_sapling) then
			data[vi] = c_trunk
		end
	end
	local vi = a:index(pos.x, pos.y+height, pos.z)
	if(data[vi] == c_air or data[vi] == c_ignore) then
		data[vi] = c_trunk_top
	end
	for i = 1,#tree.leaves do
		local vi = a:index(pos.x+tree.leaves[i][1], pos.y+height+tree.leaves[i][2], pos.z+tree.leaves[i][3])
		if(data[vi] == c_air or data[vi] == c_ignore) then
			data[vi] = c_leaves
		end
	end
end
