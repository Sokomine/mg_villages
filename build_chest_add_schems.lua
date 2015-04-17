

build_chest_add_to_menu = function( path, add_path  )
	local file,error = io.open( path, "rb")
        if (file == nil) then
                return;
        end

	local text = file:read("*a");
	file:close();
	
	for schem_file_name in string.gmatch(text, "([^\r\n]*)[\r\n]*") do
		if( schem_file_name and schem_file_name ~= "" ) then
			local help = string.split( schem_file_name, '/', true, -1, false);

			local i = #help;
			local found = 1;
			-- search from the end of the file name for the first occourance of "mods" or "worlds"
			-- as that will be the path where we will put it into the menu
			while (i>1 and found==1) do
				if( help[i]=='mods' or help[i]=='worlds' ) then
					found = i;	
				end
				i = i-1;
			end

			local name    = help[#help];
			local length1 = string.len( name );
			local length2 = string.len( schem_file_name );
			-- remove the file name extension
			if(     string.sub( name, -4 )=='.mts' ) then
				name            = string.sub( name,            1, length1-4 );
				schem_file_name = string.sub( schem_file_name, 1, length2-4 );
			elseif( string.sub( name, -3 )=='.we' ) then
				name            = string.sub( name,            1, length1-3 );
				schem_file_name = string.sub( schem_file_name, 1, length2-3 );
			end
			help[#help] = name;
				
			-- build the new menu path
			local menu_path = {'main'};
			for j=(i+1),#help do
				table.insert( menu_path, help[j] );
			end
			schem_file_name = add_path..schem_file_name;
			table.insert( menu_path, schem_file_name );

			build_chest.add_entry(    menu_path );
			build_chest.add_building( schem_file_name, {scm=help[#help], typ='nn'});

		end
	end
end

build_chest_add_to_menu( minetest.get_modpath( minetest.get_current_modname()).."/list_of_schematics.txt", "");
