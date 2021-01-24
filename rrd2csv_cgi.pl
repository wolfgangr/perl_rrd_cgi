#!/usr/bin/perl
#
# extract data from rrd and write csv data
# TODO transfer from cmdline tool to cgi
#
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


use warnings;
use strict;
use CGI();
use Time::Piece();
# use Data::Dumper::Simple ;
# use Getopt::Std;
use  RRDs;
# use DateTime;
# use Data::Dumper  ;
# use Data::Dumper::Simple  ; conditionally on debug only
use Cwd 'abs_path'   ;


my $debug_default = 3;
my $test_rrd = '/var/lib/collectd/rrd/kellerkind.rosner.lokal/cpu-0/percent-idle.rrd' ;


my $q = CGI->new;
my %q_all_params = $q->Vars ;
our $debug  = (defined $q_all_params{debug}) ?  $q->param('debug')  : $debug_default ;
if ($debug) { use Data::Dumper::Simple ;}


my $rrd =  ($q->param('rrd') ||  $test_rrd ) ;
my $cf = $q->param('CF') || 'AVERAGE' ; 



# die "$usage" unless $rrdfile;
# die "$usage_long" if ( ! ($cf) ) or $rrdfile eq '-h' or $cf eq '-h' ;

# my $retval = getopts('s:e:tT:HMx:d:r:af:HMv:V:hz:')  ;
# die "$usage" unless ($retval) ;
# die "$usage_long" if $opt_h  ;

my $start  = $q->param('start')  || 'e-1d';
my $end    = $q->param('end')  || 'n';
my $header = (defined $q_all_params{ header }) ;
my $hl_timetag =  $q->param('time') || 'time' ;
my $sep    = $q->param('sep')  || ';' ; 
my $delim  = $q->param('delim')  || '';
my $align  = (defined $q_all_params{ align }) ;
my $res    = $q->param('step') || 0  ;
my $outfile = $q->param('out') || ''   ;
# $debug = $opt_v unless $opt_v eq ''; 

# my $valid_rows = 1 ;
# unless  ($opt_V eq '') {  $valid_rows = $opt_V ;  }

my $valid_rows = (defined $q_all_params{ valid_rows })  ? $q->param('valid_rows') : 1 ;


# our $timezone = DateTime::TimeZone->new( name => ( $opt_z ? $opt_z : 'local' ) ) ;

# after this header we may print pretty much anything
print $q->header(-type => 'text/plain',  -charset => 'utf8' );

# my $rrdfile = "noclue";
# debug_printf (3, "parameter db=%s CF=%s start=%s end=%s resolution=%s align=%d output=%s header=%s sep=%s delim=%s \n",
# 	$rrdfile, $cf, $start, $end, $res, $align, $outfile, $header , $sep, $delim      );

print Dumper ($q) if  $debug >=3 ;

# my $rrdfile = abs_path($rrd);
my $rrdfile = `ls $rrd`;
chomp $rrdfile;
print Dumper ($rrd, $rrdfile);

print Dumper ($rrdfile, $cf, $start, $end, $res, $align, $outfile, $header , $sep, $delim      ) if $debug >=3 ;

exit;

# collect parameters for database call
my @paramlist = ($rrdfile, $cf, '-s', $start, '-e', $end);
push @paramlist, '-a' if $align ;
push @paramlist, ('-r', $res ) if $res ; 

debug_printf (3, "%s\n", join ( ' | ', @paramlist));

# ====== call the database ========
my ($rrd_start,$step,$names,$data) ; # = RRDs::fetch (@paramlist); TODO

# nice time formating - for debug and for exercise...
my $dt ; # = DateTime->from_epoch( epoch => $start , time_zone => $timezone  );
# my $step= "dontknow"; 	# TODO
# my $names = "TODO";	# TODO
# my $data  = "TODO";	# TODO

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

my $timezone = 'TODO'; # TODO
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
   # if ( $opt_M ) {   TODO
   if ( 0 ) {
      # mysql datetime format YYYY-MM-DD HH:MM:SS
      my $dt =  DateTime->from_epoch( epoch => $rowtime ,  time_zone => $timezone );
      $timestring =  sprintf ( "%s %s", $dt->ymd('-') , $dt->hms(':') ) ;
   } elsif (1) {   #   ( $opt_H ) {  TODO
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
  my $level = shift @_;
  print  @_ if ( $level <= $debug) ;
}

sub debug_printf {
  my $level = shift @_;
  printf   @_ if ( $level <= $debug) ;
}

# my_join : extended join with delim and seperators
# my_join ( delim, sep, @stuff )
sub my_join {
  my $delim = shift  @_ ;
  my $sep   = shift  @_ ;
  my $rv  =   return join ( $sep, map { sprintf ( "%s%s%s", $delim, $_ ,$delim) } @_ ) ;
  return $rv ;
}
