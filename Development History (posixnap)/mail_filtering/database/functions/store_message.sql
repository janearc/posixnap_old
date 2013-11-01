-- $Id: store_message.sql,v 1.1 2004-02-27 02:14:16 alex Exp $
-- # aja // vim:tw=80:ts=2:noet

-- Store a message for later retreival

create or replace function store_message (
	varchar(256),
	varchar(256),
	varchar(256),
	text
) returns integer as '

	declare
		my_sender varchar(256);
		my_recip  varchar(256);
		my_list   varchar(256);
		my_body   text;
	
	begin
		my_sender := $1;
		my_recip  := $2;
		my_list   := $3;
		my_body   := $4;
	
		if my_list not in (select list_destination from list_definitions) then
			my_list := ''defaultdelivery'';
		end if;

		insert into messages ( sender, recip, list_destination, body )
			values ( my_sender, my_recip, my_list, my_body );

		return 1;
	end;
' language 'plpgsql';
