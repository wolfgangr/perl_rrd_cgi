#!/usr/bin/perl -w
use strict ;
#  https://metacpan.org/pod/release/LDS/CGI.pm-3.33/CGI.pm
  # CGI script that creates a fill-out form
  # and echoes back its values.

  use CGI qw/:standard/;
  use Data::Dumper ;

  print header,
        start_html('rrd test navigator'),
        h3('rrd test navigator'),
	hr,

	"<table><tr>\n", 
        start_form,

	"<td>", 
	"Start: ",textfield(-name=>'start' ,
		-default=>'e-1d', -size=>3 ),

	"</td>\n<td>",
	"Ende: ",textfield(-name=>'ende' ,
                -default=>'n',  -size=>3 ),

	# "</td>\n<td>", 
	# "What's the combination?", p,
	# checkbox_group(-name=>'words',
	#                -values=>['eenie','meenie','minie','moe'],
	#                -defaults=>['eenie','minie']), p,

	"</td>\n<td>", 
       	"Aufl.: ",
        popup_menu(-name=>'res',
                   -values=>['30','300','3600','86400']),


        "</td>\n<td>",
        "Breite: ",textfield(-name=>'width' ,
                -default=>'400', -size=>1  ),


        "</td>\n<td>",
        "H&ouml;he: ",textfield(-name=>'height' ,
                -default=>'140',  -size=>1   ),
	
        "</td>\n<td>",
	radio_group('jump',['<<','<', '>', '>>', '-',  '0', '+',],
		-default=>'0', ) ,


	"</td>\n<td>",
	submit (-name=>'load', -value=>'Laden'), 

	end_form,
	
	"</td></tr></table>\n",
	hr,
   ;

   if (param()) {
       my $name      = param('name');
       my $keywords  = join ', ',param('words');
       my $color     = param('color');
       print "Your name is",em(escapeHTML($name)),p,
             "The keywords are: ",em(escapeHTML($keywords)),p,
             "Your favorite color is ",em(escapeHTML($color)),
             hr;
   }

print "\n<hr><p></i>\n";
print CGI::Dump();

print "\n<hr>\n<pre>\n";
my $query = new CGI;
print Dumper($query);
print "\n</pre><hr>\n";

