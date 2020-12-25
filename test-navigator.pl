#!/usr/bin/perl -w
use strict ;
#  https://metacpan.org/pod/release/LDS/CGI.pm-3.33/CGI.pm
  # CGI script that creates a fill-out form
  # and echoes back its values.

use CGI qw/:standard/;
use Data::Dumper ;
use RRDs ;

our $dtformat = '+\'%d.%m.%Y - %T\'' ; # datetime format string for console `date`

# calculate interval:
# try to parse rrd AT notation
# - if 2 of (start / end / int ) are given, calcuate the third
# - if 3 are given, ignore int
# - if only start is given, assume end as now and calc int
# - if end is given, asume int as 1 day
# - if only int is given, assume end as now
# - if nothing is given, assume end as now and int as 1d
# RRDs::times(start, end)

# our $query = new CGI;
#our @param = $query->param;

# DEBUG($query, @param);
# my $param;

# = "e-1d"  unless (defined $$param{'start'} ) ;
# = "n"  unless (defined $$param{'end'} ) ;


my $frm_start = param('start') || 'e-1d' ;
my $frm_end   = param('end') || 'n'  ;
my $frm_intvl = param('intvl') ;
 DEBUG(  $frm_start, $frm_end , $frm_intvl ) ;
my ($numstart, $numend) = RRDs::times($frm_start, $frm_end);
my $interval = $numend - $numstart;

if (0 ) { 
# if ( param('shift_ll')) {
   $frm_end = $numend -= $interval;
   $frm_start = $numstart = $numend - $interval;
   $frm_intvl = $interval;
}

# ====================================== start HTML rendering ==================================================
STARTHTML:
  print header,
        start_html('rrd test navigator'),
        h3('rrd test navigator'),
	hr,


	"<table><tr>\n", 
        start_form,

	"<td>", 
	"ab:",textfield(-name=>'start' ,
		-default=>'e-1' , -size=>3 ),

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

# my ($numstart, $numend) = RRDs::times(param('start'), param('end'));
# my $interval = $numend - $numstart;

STARTDEBUG:

print "\n<hr><pre><code>\n";

printf "rrd times start %s -> %d = %s<br>\n" , $frm_start , $numstart, mydatetime($numstart,) ;
printf "rrd times end   %s -> %d = %s<br>\n" , $frm_end ,    $numend  , mydatetime($numend) ;
printf "rrd times interval %s -> %d s = %s<br>\n" , $frm_intvl , $interval, mytimediff2str($interval);

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


ENDHTML:
print end_html, "\n";


exit;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub mydatetime {
  my $arg = shift;
  my $rv =`date -d \@$arg $dtformat` ;
  chomp $rv;
  return $rv ;
}

# converts number of seconds to human readable format
sub mytimediff2str {
  my $seconds = shift;

  my ($d, $r ) = mymodulo ($seconds, 60);
  my $res = sprintf "%d sec", $r;
  return $res unless $d;

  ($d, $r ) = mymodulo ($d, 60);
  $res = sprintf "%d min, %s", $r, $res;
  return $res unless $d;

  ($d, $r ) = mymodulo ($d, 24 );
  $res = sprintf "%d hr, %s", $r, $res;
  return $res unless $d;

  ($d, $r ) = mymodulo ($d, 7);
  $res = sprintf "%d days, %s", $r, $res;
  return $res unless $d;

  $res = sprintf "%d weeks, %s", $d, $res;
  return $res;
}

# moduolo div returning both mod an remainder
sub mymodulo {
  my ($a, $b) = @_;
  my $mod = $a % $b ;
  # $a -= ($b * $mod);
  return ( ($a - $mod) / $b, $mod  );
} 

#
sub DEBUG {
  print header,
  start_html('### DEBUG ###'),
  "\n<pre><code>\n",
  Dumper ( @_), 
  "\</code></pre>\n",
  end_html
  ;

  exit; # is it bad habit to exit from a sum??	
}
