#!/usr/bin/perl
#
# extract data from rrd and write csv data
# TODO transfer from cmdline tool to cgi
#
our $usage = <<"EOF_USAGE";
usage: $0?rrd=./path/to/my.rrd[&asdf[&bar=foo[&....
	help debug=        	rrd= CF= start= end= step= valid_rows=
	out= conten_type= header time= sep= delim=  tzoffset= mysqltime= humantime=
EOF_USAGE



our $usage_long = <<"EOF_USAGE_L";
$0:

retrieve data from RRD and output them as CSV to file or browser 

$usage 

	for further details, see RRDtool fetch for details
	and r_ead t_he f_unny s_sourcecode

params implemented (or close to....)
	(may be you have to play with urlescaping)
	
	rrd=db.rrd	
		rrd file name to retrieve data from
		relative to script or absolute in server namespace

	CF=LAST	rrd CF (AVERAGE,MIN,MAX,LAST)
		defaults to AVERAGE

	start=starttime
		transparently forwarded to RRDtool, 
		default NOW - 1 day

	end=endtime
		transparently forwarded to RRDtool,
		default NOW
	
	step=sss 
		resolution (seconds per value)
		default is highest available in rrd

	align
		adjust starttime to resolution

	valid_rows=n
		preselect rows by NaN'niness
		(integer) minimum valid fields i.e not NaN per row
		0 - include all empty (NaN only) rows
		1 - (default ) at least one not-NaN - don't loose any information
		up to num-cols - fine tune information vs data throughput
		negative integers: complement count top down e.g.
		-1 - zero NaN allowed
		-2 - one NaN allowed

	out=output.csf
		default ist send to browser if omitted
		be sure that the server has write permissions

	sep=;	CSV field separator, default is  ';'

	delim=	CSV field delimiter, default is ''

	header	include header tag line

	time=timetag	
		header line time tag, default ist 'time'

	humantime	
		translate unixtime to H_uman readable time

	mysqltime 	
		translate unixtime to MySQL parseable timestamps

	tzoffset [TODO]	
		set timezone offset, default is to use system locale

	help
		print this message

	debug=3
		set verbosity level, levels may be configured in the source

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
my $dt_format = '%F %T' ;

my $q = CGI->new;
my %q_all_params = $q->Vars ;
our $debug  = (defined $q_all_params{debug}) ?  $q->param('debug')  : $debug_default ;
if ($debug) { use Data::Dumper::Simple ;}


my $rrd =  ($q->param('rrd') ||  $test_rrd ) ;
my $cf = $q->param('CF') || 'AVERAGE' ; 

# my $usage = "usage todo";
# my $usage_long = "comprehensive usage todo";


# my_die (' missing parameters ' , $usage) unless %q_all_params ;
my_die (' usage instructions: ' , $usage_long) 
	if (defined $q_all_params{help}  or  defined $q_all_params{keywords}    ) ;

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





# after this header we may print pretty much anything
# print $q->header(-type =>  $ct,  -charset => 'utf8' );

# my $rrdfile = "noclue";
# debug_printf (3, "parameter db=%s CF=%s start=%s end=%s resolution=%s align=%d output=%s header=%s sep=%s delim=%s \n",
# 	$rrdfile, $cf, $start, $end, $res, $align, $outfile, $header , $sep, $delim      );

print Dumper ($q) if  $debug >=3 ;

# my $rrdfile = abs_path($rrd);
my $rrdfile = `ls $rrd`;
chomp $rrdfile;
# print Dumper ($rrd, $rrdfile);

print Dumper ($rrdfile, $cf, $start, $end, $res, $align, $outfile, $header , $sep, $delim      ) if $debug >=3 ;

# collect parameters for database call
my @paramlist = ($rrdfile, $cf, '-s', $start, '-e', $end);
push @paramlist, '-a' if $align ;
push @paramlist, ('-r', $res ) if $res ; 

print  Dumper ( @paramlist ) if $debug >=3 ;

# ====== call the database ========
my ($rrd_start,$step,$names,$data)  = RRDs::fetch (@paramlist); 

my $namlen = $#$names;
my $datlen = $#$data;

my $dt = Time::Piece->new( $rrd_start);
# shall we keep timezoning?
# $dt->tzoffset = $q->param('tzoffset' ) if defined $q_all_params{ 'tzoffset' } ;
my $dt_hr = $dt->strftime($dt_format) ;
print  Dumper ( RRDs::error, $rrd_start,$step, $namlen, $datlen , $dt_hr ) if $debug >=3 ;

# pre-process -V option ... valid rows - map the complement format
# print  Dumper ('before' , $valid_rows);
if ( $valid_rows < 0 ) { $valid_rows = $#$names + $valid_rows +1 ; }
# print  Dumper ('after' , $valid_rows);

# debug_printf (3, "total cols: %d - lower limit for valid Data points per row : %d \n ", $#$names , $valid_rows );

# exit;
# ---- do your work ----
#
if ( $outfile) {
  open (OF , '>' ,   $outfile)  or die "$! \n could not open $outfile for writing"; 
} else {
  # way to redirect OF to STDOUT
  *OF = *STDOUT;
}

#~~~~~~~~~~~~~~~~ cutting edge TOP in boiler plate ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# plot interface recycled from
# https://github.com/wolfgangr/sqlplot/blob/master/sqlplot.cgi

# $gnuplot = "/usr/bin/gnuplot";
my $gnuplot = `which gnuplot`  or my_die ("gnuplot executable not found - installed?")   ;
chomp $gnuplot;
# $tempfile_prefix="/var/www/tmp/sqlplot/plot-";
my $tempfile_prefix="./tmp/sqlplot/plot-";

my $tempfile_body = $tempfile_prefix . time; 
my $temppng  = $tempfile_body . '.png';
my $tempdata = $tempfile_body . '.data';
my $templog  = $tempfile_body . '.log';



my $command;

my $testcmd= <<ENDOFCOMMAND;
set term png
set output "$temppng"
test
ENDOFCOMMAND


if ( defined $q_all_params{test} ) {
# if (1) {
	$command = $testcmd ;
} else {
	my @defcol =('eeeeee','000000','000000',
	      '0000ff','ff0000','44ff44','ffff00','ff00ff','44ffff');
	$command= "set term png";


	for my $i ('b','e','a',(1..9)) {
		my $tmp = shift(@defcol);
		if ($q->param("color$i")) { $tmp =$q->param("color$i");}
			# fixme#####
			#  see https://sourceforge.net/p/gnuplot/bugs/1155/
			# they changed the color format :-(
			# if ($tmp) { $command .= " x$tmp"; }
	}
	$command .= "\n";
	$command .="set output \"$temppng\"\n";
	$command .= "set timestamp \"\%d.\%m.\%Y \%H:\%M\"\n";
	$command .= "set ylabel \"FOO\"\n";
	$command .= "set title \"PIPAPO\" \n";


	if ( defined $q_all_params{ grid } ) {
		$command .= "set grid\n";
	}


	$command .= "set style data lines\n";
	$command .= "set xlabel \"tralala\"\n";


	# $command .= "plot sin(x)";
	$command .= <<"EOFPLOT" ;	
plot '-', '-' , '-' axes x2y1
1 1
1 19
19 19
19 1
2  2
e
1     1
2     4
3     9
4    16
e
5    25
6    36
7    49
8    64
9    81
10  100
e
EOFPLOT

	$command .="\n";

	# my_die ( Dumper ($q)) ;
	# my_die ( $command , "DEBUG");
	# my_die ("hit the ground", "================ GAME OVER ==================");
}


# wrosner@cleo3:~$ cat /var/www/tmp/sqlplot/plot-1487902327.data
# 76 76 76 2016-12-30 17:00:00
# 76 77.3077 78 2016-12-30 18:00:00
# 76 76.9091 78 2016-12-30 19:00:00
# 79 81.3684 84 2016-12-30 20:00:00
# 84 84.5152 85 2016-12-30 21:00:00


open ( GNUPLOT, "| $gnuplot > $templog 2>&1" ) or my_die ("cannot open gnuplot")   ;
print GNUPLOT $command    or my_die  ("cannot send data to gnuplot") ;
close GNUPLOT || gnuploterror($command, $templog);

print "Content-type: image/png\n\n";
print `cat -u $temppng`;   

exit;   # leave the stuff for debugging

unlink $temppng;        # don't check for an error any more
unlink $tempdata;
unlink $templog;


exit;

#~~~~~~~~~~~~~~~~ cutting edge BOTTOM in boiler plate ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# debug_printf ( 3, "opened output file: %s\n", $outfile );

# conditional header - see -t option
#
if ($header) {
   my $titleline = my_join ( $delim, $sep, $hl_timetag , @$names) ;
   print  OF $titleline . "\n";
}


# exit;
# my $timezone = main loop over data rows, we count by index to keep close to metal
for my $rowcnt (0 .. $#$data ) {
   my $datarow = $$data[ $rowcnt ];			# the real data
   my $rowtime = $rrd_start + $rowcnt * $step;		# time is calculated

   # skip for data row's with too many NaN s
   my $defcnt = 0 ;
   foreach ( @$datarow )  {  $defcnt++ if defined $_ }
   next unless ($defcnt >= $valid_rows) ;

   # time string format selection
   my $timestring;

   if ( defined $q_all_params{mysqltime} ) {
      my $dtr = Time::Piece->new($rowtime); 
      # mysql datetime format YYYY-MM-DD HH:MM:SS
      $timestring =  sprintf ( "%s %s", $dtr->ymd , $dt->hms ) ;
   } elsif ( defined $q_all_params{humantime} ) {   #   (  ) {  
      # human readable datetime e.g. 22.12.2020-05:00:00 , i.e. dd.mm.yyyy-hh:mm:ss
      my $dtr = Time::Piece->new($rowtime);
      $timestring =  sprintf ( "%s-%s", $dtr->dmy('.') , $dtr->hms );
   } else {
     $timestring = sprintf "%s" , $rowtime ;
   }

   my $dataline = my_join ( $delim, $sep, $timestring, @$datarow ) ;
   print  OF $dataline . "\n";
} 

close OF if ( $outfile) ;

exit ;

#=========================================

# my_join : extended join with delim and seperators
# my_join ( delim, sep, @stuff )
sub my_join {
  my $delim = shift  @_ ;
  my $sep   = shift  @_ ;
  my $rv  =   return join ( $sep, map { sprintf ( "%s%s%s", $delim, $_ ,$delim) } @_ ) ;
  return $rv ;
}

# resemble "die", supply ($message $usage)
sub my_die {
	my ($msg, $usage) = @_ ;
	print $q->header(-type =>  'text/html',  -charset => 'utf8' );
	print "<html><pre>";
	print "\n$msg\n";
	print "============================================================" . "\n";
	print $usage ;
	print "</pre></html>";
	exit;

}


sub gnuploterror {

  my ($command, $logfile) = @_;

  print "Content-type: text/html\n\n";
  print "<html><head><title>Gnuplot Error </title></head><body>\n";
  print "<h1>Gnuplot Error:</h1>";

  print "<h3>gnuplot reported:</h3>\n"; 
  print "<pre>\n";
  print  `cat -u $logfile`;
  print "</pre>\n";

  print "<h1>gnuplot command was:</h1>\n";
  print "<pre>\n";
  print  $command;
  print "</pre>\n";

  print "</body></html>";

  # $dbh->disconnect;

  exit;
}



