
-- get the id of the village pos lies in (or nil if outside of villages)
mg_villages.get_town_id_at_pos = function( pos )
	for id, v in pairs( mg_villages.all_villages ) do
		if(   ( math.abs( pos.x - v.vx ) < v.vs )
		  and ( math.abs( pos.z - v.vz ) < v.vs )
		  and ( math.abs( pos.y - v.vh ) < 40 )) then
			return id;
		end
	end
	return nil;
end

local old_is_protected = minetest.is_protected
minetest.is_protected = function(pos, name)

	if( mg_villages.get_town_id_at_pos( pos )) then
		return true;
	end
	return old_is_protected(pos, name);
end             

minetest.register_on_protection_violation( function(pos, name)
	local found = mg_villages.get_town_id_at_pos( pos );
	if( not( found ) or not( mg_villages.all_villages[ found ]))  then
		minetest.chat_send_player( name, 'Error: This area does not belong to a village.');
		return;
	end
	-- TODO: use real village name
	minetest.chat_send_player( name, "You are inside of the area of village \'"..tostring( found ).."\'. The inhabitants do not allow you any modifications.");
end );

-- TODO: add a limited griefing liscence/buying of houses or plots for players
