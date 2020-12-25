#!/usr/bin/perl -w
use strict ;
#  https://metacpan.org/pod/release/LDS/CGI.pm-3.33/CGI.pm
  # CGI script that creates a fill-out form
  # and echoes back its values.

use CGI qw/:standard/;
use Data::Dumper ;
use RRDs ;

our $dtformat = '+\'%d.%m.%Y %T\'' ; # datetime format string for console `date`

# calculate interval:
# try to parse rrd AT notation
# - if 2 of (start / end / int ) are given, calcuate the third
# - if 3 are given, ignore int
# - if only start is given, assume end as now and calc int
# - if end is given, asume int as 1 day
# - if only int is given, assume end as now
# - if nothing is given, assume end as now and int as 1d


my ( $frm_start, $frm_end, $fmt_intvl  ) ;

if (param('start') and param('end')) {
  $frm_start = param('start')  ;
  $frm_end   = param('end')  ;

  } else {
    $fmt_intvl = param('intvl') || '1d';

  } elsif (   param('start') and ! param('end')) {
    $frm_start = param('start')  ;
    #if ( param('intvl')) {
    $frm_end = sprintf "s+%s", param('intvl') ;
    # else {
    #$frm_end = 's+1d' ;
  }

  } elsif ( ! param('start') and   param('end')) {
    $frm_end   = param('end')  ;
    # if ( param('intvl')) {
    $frm_start = sprintf "e-%s", param('intvl') ;
    # } else {
    # $frm_start = "e-1d" ;
  }  

  } elsif ( ! param('start') and ! param('end')) {
    $frm_end = 'n' ;
    # if ( param('intvl')) {
    $frm_start = sprintf "e-%s", param('intvl') ;
    #} else {
    # $frm_start = "e-1d" ;
  }

   #} else  {
   # should never be here
   # DEBUG ( sprintf ( "unprocessed case start=>|%s|<  end=>|%s|<  intvl=>|%s|< ", param('start') , param('end') , param('intvl') ) );
}

my ($numstart, $numend) = RRDs::times($frm_start, $frm_end);
my $interval = $numend - $numstart;
my $frm_intvl =  param('intvl') || $interval ; # keep frm or set to seconds if missing



#~~~~~~~~~~~~~~~~~


if ( param('shift_ll')) {
   $frm_end = ($numend -= $interval);
   $frm_start = ($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('shift_l')) {
   $frm_end = ($numend -= $interval / 2 );
   $frm_start = ($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('shift_rr')) {
   $frm_end = ($numend += $interval);
   $frm_start = ($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('shift_r')) {
   $frm_end = ($numend += $interval / 2 );
   $frm_start = ($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('zoom_out')) {
   $frm_end = ($numend += $interval / 2 );
   $interval *= 2 ;
   $frm_start = ($numstart = $numend - $interval);
   $frm_intvl = $interval;
} elsif ( param('zoom_in')) {
   $frm_end = ($numend -= $interval / 4 );
   $interval /= 2 ;
   $frm_start = ($numstart = $numend - $interval);
   $frm_intvl = $interval;

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
