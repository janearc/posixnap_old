#!/opt/ruby/bin/ruby 

require "dbi"
require "cgi"

dbh = DBI.connect("dbi:Pg:botdb", "alex", "")
cgi = CGI.new("html3")

# sth = dbh.prepare("select * from config")
# sth.execute()

cgi.out{
	cgi.head{ "\n" + cgi.title{"last 20 quips"} }+
	cgi.body{
		p "<table>"
		dbh.select_all('select who, quip from log order by stamp desc limit 20') do | row |
			p "<tr>"
			row.each do | r |
				p "<td>"
				p r
				p "</td>"
			end
			p "</tr>"
		end
		p "</table>"
	}
}

dbh.disconnect

# $Id: tabledump.rb,v 1.1 2004-03-14 00:49:34 alex Exp $
# aja // vim:tw=80:ts=2:noet
