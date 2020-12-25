#!/usr/bin/perl -w
use strict ;
#  https://metacpan.org/pod/release/LDS/CGI.pm-3.33/CGI.pm
  # CGI script that creates a fill-out form
  # and echoes back its values.

use CGI qw/:standard/;
use Data::Dumper ;
use RRDs ;

our $dtformat = '+\'%d.%m.%Y %T\'' ; # datetime format string for console `date`
our $RRDdtf = "+\'%d.%m.%Y %H:%M\'" ; # RRD does not like seconds here 
# calculate interval:
# try to parse rrd AT notation
# - if 2 of (start / end / int ) are given, calcuate the third
# - if 3 are given, ignore int
# - if only start is given, assume end as now and calc int
# - if end is given, asume int as 1 day
# - if only int is given, assume end as now
# - if nothing is given, assume end as now and int as 1d


my ( $frm_start, $frm_end, $frm_intvl  ) ;

if (param('start') and param('end')) {
  $frm_start = param('start')  ;
  $frm_end   = param('end')  ;

} else  {
    $frm_intvl = param('intvl') || '1d';

  if (   param('start') and ! param('end')) {
    $frm_start = param('start')  ;
    $frm_end = sprintf "s+%s", $frm_intvl ;

  } else {  
    $frm_start = sprintf "e-%s", $frm_intvl ;
    $frm_end   = param('end')  || 'n' ;
  }
}

# still weird cases not catched:
# - circular reference 
# - in case of overdefined conflicting vars: 'intvl' is kept in form
# but processing 

my ($numstart, $numend) = RRDs::times($frm_start, $frm_end);
my $rrds_err = RRDs::error;

if ($rrds_err) {  
  if ( $rrds_err =~ /start and end times cannot be specified relative to each other/ ) {
	  # DEBUG ("to do: resolve circular definition");
	  # $frm_start = 'e-1d';
    $frm_end = 'n';
    ($numstart, $numend) = RRDs::times($frm_start, $frm_end);
  } else {
    # report other parsing and conversion errors
    DEBUG ( sprintf '  RRD reportet error "%s" %s start->|%s|<   end->|%s|<  ', 
	    RRDs::error, "\n", $frm_start, $frm_end) ;
  }
} 

my $interval = $numend - $numstart;
$frm_intvl =  $frm_intvl || param('intvl') || $interval ; # keep frm or set to seconds if missing

unless ($interval) {
 # should not be here, if RRD is working as expected
 DEBUG ( sprintf ( "unprocessed case start=>|%s|<  end=>|%s|<  intvl=>|%s|< "
		 . " numstart=>|%s|,  numend=>|%s|, interval=>|%s| ",
		 param('start') , param('end') , param('intvl'),  
		 $numstart, $numend , $interval
	 ) );
}

#~~~~~~~~~~~~~~~~~

my $recalc =0;
if ( param('shift_ll')) {
   $frm_end =  rrddatetime($numend -= $interval);
   $frm_start = rrddatetime($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('shift_l')) {
   $frm_end = rrddatetime($numend -= $interval / 2 );
   $frm_start = rrddatetime($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('shift_rr')) {
   $frm_end = rrddatetime($numend += $interval);
   $frm_start = rrddatetime($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('shift_r')) {
   $frm_end = rrddatetime($numend += $interval / 2 );
   $frm_start = rrddatetime($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('zoom_out')) {
   $frm_end = rrddatetime($numend += $interval / 2 );
   $interval *= 2 ;
   $frm_start = rrddatetime($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('zoom_in')) {
   $frm_end = rrddatetime($numend -= $interval / 4 );
   $interval /= 2 ;
   $frm_start = rrddatetime($numstart = $numend - $interval);
   $frm_intvl = $interval;

}

# rrd does not seem to like human readable second formats?
if (0) {
  $frm_start = mydatetime($numstart) ;
  $frm_end   = mydatetime($numstart) ;
  $frm_intvl = mytimediff2str ($interval);
}

# ====================================== start HTML rendering ==================================================
STARTHTML:
print header,
        start_html('rrd test navigator'),
        h3('rrd test navigator'),
	hr,


	"<table>" , start_form , "<tr>\n", 
	# start_form,
        "\n<td>" ,
        submit (-name=>'load', -value=>'Laden'),
       "</td>\n",

	;

printf '<td>ab:<input  type="text" name="start" value="%s" size="7" /></td>' , $frm_start ;
printf '<td>bis:<input type="text" name="end"   value="%s" size="7" /></td>' , $frm_end   ;
printf '<td>Int:<input type="text" name="intvl" value="%s" size="7" /></td>' , $frm_intvl  ;

print
	# "\n<td>", "|</td><td>" ,
	# submit (-name=>'load', -value=>'Laden'), 
        # "</td>\n<td>",
	# defaults ( -value=>'>|<', -size=>1   ),

	"\n<td>", "|</td><td>" , 
	   submit( -name=>'shift_ll', -value=>'<<', -size=>1   ),
        "</td>\n<td>",
           submit( -name=>'shift_l', -value=>'<', -size=>1   ),
        "</td>\n<td>",
           submit( -name=>'shift_r', -value=>'>', -size=>1   ),
        "</td>\n<td>",
           submit( -name=>'shift_rr', -value=>'>>', -size=>1   ),
        "</td>\n<td>", "|</td><td>" ,

           submit( -name=>'zoom_out', -value=>'-', -size=>1   ),
        "</td>\n<td>",
           submit( -name=>'zoom_in', -value=>'+', -size=>1   ),
        "</td>\n<td>",
	   defaults ( -value=>'>|<', -size=>1   ),
        "</td>\n<td>", "|</td>" ,

	"<td>Res:" ,
        popup_menu(-name=>'res',  -size=>1 ,
                   -values=>['30','300','3600','86400']),

        "</td>\n<td>",
        "B:",textfield(-name=>'width' ,
                -default=>'400', -size=>1  ),
        "</td>\n<td>",
        "H:",textfield(-name=>'height' ,
                -default=>'140',  -size=>1   ),
	
	# end_form,
	
	"</td></tr>" , end_form, , "</table>\n",
	# end_form,

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
  my $dtf = shift;
  $dtf = $dtformat unless $dtf ;
  my $rv =`date -d \@$arg $dtf` ;
  chomp $rv;
  return $rv ;
}

sub rrddatetime {
  my $arg = shift;
  return mydatetime ($arg , $RRDdtf) ;
}

# converts number of seconds to human readable format
sub mytimediff2str {
  my $seconds = shift;

  my ($d, $r ) = mymodulo ($seconds, 60);
  my $res = sprintf "%ds", $r;
  return $res unless $d;

  ($d, $r ) = mymodulo ($d, 60);
  $res = sprintf "%dm, %s", $r, $res;
  return $res unless $d;

  ($d, $r ) = mymodulo ($d, 24 );
  $res = sprintf "%dhr, %s", $r, $res;
  return $res unless $d;

  ($d, $r ) = mymodulo ($d, 7);
  $res = sprintf "%dd, %s", $r, $res;
  return $res unless $d;

  $res = sprintf "%dw, %s", $d, $res;
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
