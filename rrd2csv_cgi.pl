#!/usr/bin/perl
#
# extract data from rrd and write csv data

our $usage = <<"EOF_USAGE";
usage: $0 db.rrd CF
  [-s start][-e end][-r res][-a]  [-V valid-rows ]
  [-f outfile][-x sep][-d delim][-t][-T dttag][-z tz] [-H][-M]   
  [-v #][-h]
EOF_USAGE



our $usage_long = <<"EOF_USAGE_L";
$0:

retrieve data from RRD and output them as CSV to file or STDOUT

$usage 

	for further details, see RRDtool fetch for details
	
	db.rrd	
		rrd file name to retrieve data from

	CF	rrd CF (AVERAGE,MIN,MAX,LAST)

	-s starttime
		transparently forwarded to RRDtool, 
		default NOW - 1 day

	-e endtime
		transparently forwarded to RRDtool,
		default NOW
	
	-r res 
		resolution (seconds per value)
		default is highest available in rrd

	-a align
		adjust starttime to resolution

	-V valid rows
		preselect rows by NaN'niness
		(integer) minimum valid fields i.e not NaN per row
		0 - include all empty (NaN only) rows
		1 - (default ) at least one not-NaN - don't loose any information
		up to num-cols - fine tune information vs data throughput
		negative integers: complement count top down e.g.
		-1 - zero NaN allowed
		-2 - one NaN allowed

		        [-f outfile] [-h] [-H] [-x sep] [-d delim]

	-f output file
		default ist STDOUT if omitted

	-x \;	CSV field separator, default is  ';'

	-d \"	CSV field delimiter, default is ''

	-t	include header tag line

	-T foo	header line time tag, default ist 'time'

	-H	translate unixtime to H_uman readable time
	-M	translate unixtime to M_ySQL timestamps
	-z foo	set timezone, default is 'local'

	-v int	set verbosity level

	-h	print this message

EOF_USAGE_L


# real stuff starting here ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+

# time zone - this is crude, would it be better as option?
# $ENV{"TZ"} = 'local';
# system "setenv TZ local";

# our $timezone = 

use Getopt::Std;
use  RRDs;
use DateTime;
use Data::Dumper  ;



our $debug =0; 	# default, overwritten by -v option

# we need at least a rrd file name and a CF

my $rrdfile = shift @ARGV;
my $cf      = shift @ARGV;

die "$usage" unless $rrdfile;
die "$usage_long" if ( ! ($cf) ) or $rrdfile eq '-h' or $cf eq '-h' ;

my $retval = getopts('s:e:tT:HMx:d:r:af:HMv:V:hz:')  ;
die "$usage" unless ($retval) ;

die "$usage_long" if $opt_h  ;

my $start  = $opt_s  || 'e-1d';
my $end    = $opt_e  || 'n';
my $header = $opt_t;
my $hl_timetag = $opt_T || 'time' ;
my $sep    = $opt_x || ';' ; 
my $delim  = $opt_d ; # || ' ';
my $align  = $opt_a;
my $res    = $opt_r;
my $outfile = $opt_f ;
$debug = $opt_v unless $opt_v eq ''; 

my $valid_rows = 1 ;
unless  ($opt_V eq '') {  $valid_rows = $opt_V ;  }

our $timezone = DateTime::TimeZone->new( name => ( $opt_z ? $opt_z : 'local' ) ) ;

debug_printf (3, "parameter db=%s CF=%s start=%s end=%s resolution=%s align=%d output=%s header=%s sep=%s delim=%s \n",
	$rrdfile, $cf, $start, $end, $res, $align, $outfile, $header , $sep, $delim      );

# collect parameters for database call
@paramlist = ($rrdfile, $cf, '-s', $start, '-e', $end);
push @paramlist, '-a' if $align ;
push @paramlist, ('-r', $res ) if $res ; 

debug_printf (3, "%s\n", join ( ' | ', @paramlist));

# ====== call the database ========
my ($start,$step,$names,$data) = RRDs::fetch (@paramlist);

# nice time formating - for debug and for exercise...
my $dt = DateTime->from_epoch( epoch => $start , time_zone => $timezone  );
debug_printf ( 3, "retrieved, \n start %s step %d, columns %d, rows %d\n\tErr: >%s<\n", 
       	$dt->datetime('_'),
	$step, $#$names, $#$data, RRDs::error);

# pre-process -V option ... valid rows - map the complement format
if ( $valid_rows < 0 ) { $valid_rows = $#$names + $valid_rows +1 ; }

debug_printf (3, "total cols: %d - lower limit for valid Data points per row : %d \n ", $#$names , $valid_rows );

# ---- do your work ----
#
if ( $outfile) {
  open (OF , '>' ,   $outfile)  or die "$! \n could not open $outfile for writing"; 
} else {
  # way to redirect OF to STDOUT
  *OF = *STDOUT;
}

debug_printf ( 3, "opened output file: %s\n", $outfile ); 

# conditional header - see -t option
#
if ($header) { 
   my $titleline = my_join ( $delim, $sep, $hl_timetag , @$names) ;
   print  OF $titleline . "\n";
}

# main loop over data rows, we count by index to keep close to metal
for my $rowcnt (0 .. $#$data ) {
   my $datarow = $$data[ $rowcnt ];			# the real data
   my $rowtime = $start + $rowcnt * $step;		# time is calculated

   # skip for data row's with too many NaN s
   my $defcnt = 0 ;
   foreach ( @$datarow )  {  $defcnt++ if defined $_ }
   next unless ($defcnt >= $valid_rows) ;

   # time string format selection
   my $timestring;
   if ( $opt_M ) {
      # mysql datetime format YYYY-MM-DD HH:MM:SS
      my $dt =  DateTime->from_epoch( epoch => $rowtime ,  time_zone => $timezone );
      $timestring =  sprintf ( "%s %s", $dt->ymd('-') , $dt->hms(':') ) ;
   } elsif ( $opt_H ) {
      # human readable datetime e.g. 22.12.2020-05:00:00 , i.e. dd.mm.yyyy-hh:mm:ss
      my $dt =  DateTime->from_epoch( epoch => $rowtime ,  time_zone => $timezone );
      $timestring =  sprintf ( "%s-%s", $dt->dmy('.') , $dt->hms );
   } else {
     $timestring = sprintf "%s" , $rowtime ;
   }

   my $dataline = my_join ( $delim, $sep, $timestring, @$datarow ) ;
   print  OF $dataline . "\n";

} 

close OF if ( $outfile) ;

exit ;

#=========================================
# debug_print($level, $content)
sub debug_print {
  $level = shift @_;
  print STDERR @_ if ( $level <= $debug) ;
}

sub debug_printf {
  $level = shift @_;
  printf STDERR  @_ if ( $level <= $debug) ;
}

# my_join : extended join with delim and seperators
# my_join ( delim, sep, @stuff )
sub my_join {
  my $delim = shift  @_ ;
  my $sep   = shift  @_ ;
  my $rv  =   return join ( $sep, map { sprintf ( "%s%s%s", $delim, $_ ,$delim) } @_ ) ;
  return $rv ;
}
