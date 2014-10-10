

file_read_test = function( path )

	local file = io.open(path..'.mts', "r")
	if (file == nil) then
		print('No file found.');
		return nil
	end

	local anz = 0;
	local b   = 0;
	while( b and b ~= nil ) do
		-- the text of the next name
		b   = file:read( 1 );
                anz = anz+1;
	end
	print( tostring( anz )..' bytes read.');
end

file_read_test( './schems/c_library');
