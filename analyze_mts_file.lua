
--[[ taken from src/mg_schematic.cpp:
        Minetest Schematic File Format

        All values are stored in big-endian byte order.
        [u32] signature: 'MTSM'
        [u16] version: 3
        [u16] size X
        [u16] size Y
        [u16] size Z
        For each Y:
                [u8] slice probability value
        [Name-ID table] Name ID Mapping Table
                [u16] name-id count
                For each name-id mapping:
                        [u16] name length
                        [u8[] ] name
        ZLib deflated {
        For each node in schematic:  (for z, y, x)
                [u16] content
        For each node in schematic:
                [u8] probability of occurance (param1)
        For each node in schematic:
                [u8] param2
        }

        Version changes:
        1 - Initial version
        2 - Fixed messy never/always place; 0 probability is now never, 0xFF is always
        3 - Added y-slice probabilities; this allows for variable height structures
--]]

handle_schematics = {}

-- taken from https://github.com/MirceaKitsune/minetest_mods_structures/blob/master/structures_io.lua (Taokis Sructures I/O mod)
-- gets the size of a structure file
-- nodenames: contains all the node names that are used in the schematic
-- on_constr: lists all the node names for which on_construct has to be called after placement of the schematic
handle_schematics.analyze_mts_file = function( path )
	local size = { x = 0, y = 0, z = 0, version = 0 }
	local version = 0;

	local file = io.open(path..'.mts', "rb")
	if (file == nil) then
		return nil
	end
--print('[mg_villages] Analyzing .mts file '..tostring( path..'.mts' ));
--if( not( string.byte )) then
--	print( '[mg_villages] Error: string.byte undefined.');
--	return nil;
--end

	-- thanks to sfan5 for this advanced code that reads the size from schematic files
	local read_s16 = function(fi)
		return string.byte(fi:read(1)) * 256 + string.byte(fi:read(1))
	end

	local function get_schematic_size(f)
		-- make sure those are the first 4 characters, otherwise this might be a corrupt file
		if f:read(4) ~= "MTSM" then
			return nil
		end
		-- advance 2 more characters
		local version = read_s16(f); --f:read(2)
		-- the next characters here are our size, read them
		return read_s16(f), read_s16(f), read_s16(f), version
	end

	size.x, size.y, size.z, size.version = get_schematic_size(file)
	
	-- read the slice probability for each y value that was introduced in version 3
	if( size.version >= 3 ) then
		-- the probability is not very intresting for buildings so we just skip it
		file:read( size.y );
	end


	-- this list is not yet used for anything
	local nodenames = {};
	-- this list is needed for calling on_construct after place_schematic
	local on_constr = {};
	-- nodes that require after_place_node to be called
	local after_place_node = {};

	-- after that: read_s16 (2 bytes) to find out how many diffrent nodenames (node_name_count) are present in the file
	local node_name_count = read_s16( file );

	for i = 1, node_name_count do

		-- the length of the next name
		local name_length = read_s16( file );
		-- the text of the next name
		local name_text   = file:read( name_length );

		table.insert( nodenames, name_text );
		-- in order to get this information, the node has to be defined and loaded
		if( minetest.registered_nodes[ name_text ] and minetest.registered_nodes[ name_text ].on_construct) then
			table.insert( on_constr, name_text );
		end
		-- some nodes need after_place_node to be called for initialization
		if( minetest.registered_nodes[ name_text ] and minetest.registered_nodes[ name_text ].after_place_node) then
			table.insert( after_place_node, name_text );
		end
	end

	local rotated = 0;
	local burried = 0;
	local parts = path:split('_');
	if( parts and #parts > 2 ) then
		if( parts[#parts]=="0" or parts[#parts]=="90" or parts[#parts]=="180" or parts[#parts]=="270" ) then
			rotated = tonumber( parts[#parts] );
			burried = tonumber( parts[ #parts-1 ] );
			if( not( burried ) or burried>20 or burried<0) then
				burried = 0;
			end
		end
	end

	-- decompression was recently added; if it is not yet present, we need to use normal place_schematic
	if( minetest.decompress == nil) then
		file.close(file);
		return nil; -- normal place_schematic is no longer supported as minetest.decompress is now part of the release version of minetest
--		return { size = { x=size.x, y=size.y, z=size.z}, nodenames = nodenames, on_constr = on_constr, after_place_node = after_place_node, rotated=rotated, burried=burried, scm_data_cache = nil };
	end

	local compressed_data = file:read( "*all" );
	local data_string = minetest.decompress(compressed_data, "deflate" );
	file.close(file)

	local ids = {};
	local needs_on_constr = {};
	local is_air = 0;
	-- translate nodenames to ids
	for i,v in ipairs( nodenames ) do
		ids[ i ] = minetest.get_content_id( v );
		needs_on_constr[ i ] = false;
		if( minetest.registered_nodes[ v ] and minetest.registered_nodes[ v ].on_construct ) then
			needs_on_constr[ i ] = true;
		end
		if( v == 'air' ) then
			is_air = i;
		end
	end

	local p2offset = (size.x*size.y*size.z)*3;
	local i = 1;
	local scm = {};
	for z = 1, size.z do
	for y = 1, size.y do
	for x = 1, size.x do
		if( not( scm[y] )) then
			scm[y] = {};
		end
		if( not( scm[y][x] )) then
			scm[y][x] = {};
		end
		local id = string.byte( data_string, i ) * 256 + string.byte( data_string, i+1 );
		i = i + 2;
		local p2 = string.byte( data_string, p2offset + math.floor(i/2));
		id = id+1;

		if( id ~= is_air ) then
			scm[y][x][z] = {id, p2}; -- TODO: handle possible meta values contained in another file
		end
	end
	end
	end

	return { size = { x=size.x, y=size.y, z=size.z}, nodenames = nodenames, on_constr = on_constr, after_place_node = after_place_node, rotated=rotated, burried=burried, scm_data_cache = scm };
end



handle_schematics.store_mts_file = function( path, data )

	data.nodenames[ #data.nodenames+1 ] = 'air';

	local file = io.open(path..'.mts', "wb")
	if (file == nil) then
		return nil
	end

	local write_s16 = function( fi, a )
		fi:write( string.char( math.floor( a/256) ));
		fi:write( string.char( a%256 ));	
	end

	data.size.version = 3; -- we only support version 3 of the .mts file format

	file:write( "MTSM" );
	write_s16( file, data.size.version ); 
	write_s16( file, data.size.x );
	write_s16( file, data.size.y );
	write_s16( file, data.size.z );

	
	-- set the slice probability for each y value that was introduced in version 3
	if( data.size.version >= 3 ) then
		-- the probability is not very intresting for buildings so we just skip it
		for i=1,data.size.y do
			file:write( string.char(255) );
		end
	end

	-- set how many diffrent nodenames (node_name_count) are present in the file
	write_s16( file, #data.nodenames );

	for i = 1, #data.nodenames do
		-- the length of the next name
		write_s16( file, string.len( data.nodenames[ i ] ));
		file:write( data.nodenames[ i ] );
	end

	-- this string will later be compressed
	local node_data = "";

	-- actual node data
	for z = 1, data.size.z do
	for y = 1, data.size.y do
	for x = 1, data.size.x do
		local a = data.scm_data_cache[y][x][z];
		if( a and type( a ) == 'table') then
			node_data = node_data..string.char( math.floor( a[1]/256) )..string.char( a[1]%256-1);	
		else
			node_data = node_data..string.char( 0 )..string.char( #data.nodenames-1 );
		end
	end
	end
	end

	-- probability of occurance
	for z = 1, data.size.z do
	for y = 1, data.size.y do
	for x = 1, data.size.x do
		node_data = node_data..string.char( 255 );
	end
	end
	end

	-- param2
	for z = 1, data.size.z do
	for y = 1, data.size.y do
	for x = 1, data.size.x do
		local a = data.scm_data_cache[y][x][z];
		if( a and type( a) == 'table' ) then
			node_data = node_data..string.char( a[2] );	
		else
			node_data = node_data..string.char( 0 );	
		end
	end
	end
	end

	local compressed_data = minetest.compress( node_data, "deflate" );
	file:write( compressed_data );
	file.close(file);
	print('SAVING '..path..'.mts (converted from .we).'); 
end
