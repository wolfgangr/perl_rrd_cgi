#!/usr/bin/perl -w
use strict ;
#  https://metacpan.org/pod/release/LDS/CGI.pm-3.33/CGI.pm
  # CGI script that creates a fill-out form
  # and echoes back its values.

  use CGI qw/:standard/;
  use Data::Dumper ;
  use RRDs ;

# calculate interval:
# try to parse rrd AT notation
# - if 2 of (start / end / int ) are given, calcuate the third
# - if 3 are given, ignore int
  # - if only start is given, assume end as now and calc int
  # - if end is given, asume int as 1 day
  # - if only int is given, assume end as now
  # - if nothing is given, assume end as now and int as 1d
  # RRDs::times(start, end)


  print header,
        start_html('rrd test navigator'),
        h3('rrd test navigator'),
	hr,


	"<table><tr>\n", 
        start_form,

	"<td>", 
	"ab:",textfield(-name=>'start' ,
		-default=>'e-1d', -size=>3 ),

	"</td>\n<td>",
	"bis:",textfield(-name=>'end' ,
                -default=>'n',  -size=>3 ),

        "</td>\n<td>",
        "Int:",textfield(-name=>'intvl' ,
                -default=>'',  -size=>3 ),


	# "</td>\n<td>", 
	# "What's the combination?", p,
	# checkbox_group(-name=>'words',
	#                -values=>['eenie','meenie','minie','moe'],
	#                -defaults=>['eenie','minie']), p,

	"</td>\n<td>", "|</td><td>Res:" ,
 
        popup_menu(-name=>'res',  -size=>1 ,
                   -values=>['30','300','3600','86400']),

	# "</td>\n<td>", " for | bar",
	# submit( -name=>'zoom', -value=>'x', -size=>1   ),	   

        "</td>\n<td>",
        "B:",textfield(-name=>'width' ,
                -default=>'400', -size=>1  ),


        "</td>\n<td>",
        "H:",textfield(-name=>'height' ,
                -default=>'140',  -size=>1   ),
	
	# "</td>\n<td>",
	# radio_group('jump',['<<','<', '>', '>>', '-',  '0', '+',],
	#	-default=>'0', ) ,

	"</td>\n<td>", "|</td><td>" , 
	   submit( -name=>'shift_ll', -value=>'<<', -size=>1   ),
        "</td>\n<td>",
           submit( -name=>'shift_l', -value=>'<', -size=>1   ),
        "</td>\n<td>",
           submit( -name=>'shiftr_r', -value=>'>', -size=>1   ),
        "</td>\n<td>",
           submit( -name=>'shift_rr', -value=>'>>', -size=>1   ),
        "</td>\n<td>", "|</td><td>" ,

           submit( -name=>'zoom_out', -value=>'-', -size=>1   ),
        "</td>\n<td>",
           submit( -name=>'zoom_in', -value=>'+', -size=>1   ),
        "</td>\n<td>", "|</td><td>" ,

           defaults ( -value=>'res', -size=>1   ),

	"</td>\n<td>",
	submit (-name=>'load', -value=>'Laden'), 

	end_form,
	
	"</td></tr></table>\n",
	# hr,
   ;
# ~~~~~~~~~~ rrd time debug

my ($numstart, $numend) = RRDs::times(param('start'), param('end'));
my $interval = $numend - $numstart;

print "\n<hr><p>\n<pre><code>\n";

printf "rrd times start %s -> %d = %s<br>\n" , param('start') , $numstart, '' ;
printf "rrd times end   %s -> %d = %s<br>\n" , param('end'), $numend , '' ;
printf "rrd times interval %s -> %d s<br>\n" , param('intvl'), $interval;

print "\n</code></pre>\n";

# end %d interval: %d"

# ~~~~~~~~ simple variable dump
print "\n<hr><p>\n";
print CGI::Dump();

# ~~~~ full CGI object dump
print "\n<hr>\n<pre><code>\n";
my $query = new CGI;
print Dumper($query);
print "\n</code></pre><hr>\n";

print end_html, "\n";
