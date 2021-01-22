#!/usr/bin/perl
#
# check lastrun of selected rrd
# optional first param: grace time
# cycle over rest
# status: initial draft
#
# usage 
# rrdtest.pl [gracetime] foo.rrd [ bar.rrd [ ... ]]
#
# shall report to user and to shell if everything is ok
# i e all rrd last updates are younger than gracetime

our $rrdtool = `which rrdtool   `;
our $dtformat = '+\'%F %T\'' ; # datetime format string for console `date`
our $now = mynow() ;

my $firstparam = $ARGV[0] ;

if ( $firstparam   =~ /^\d+$/ ) {
	### printf "%s looks like a number\n", $firstparam ;
	$gracetime = shift @ARGV  ;
} else {
	###  printf "%s is not a number \n", $firstparam ;
	$gracetime = 60 ;
}

# info header line
printf "===    gracetime: %s    =    now: %s    =    diff: %s    ===\n", 
	$gracetime , mydatetime($now) , mydatetime($now - $gracetime ) ;

# ~~~~ loop over rrds ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+

my $errcnt = 0;

foreach $arg (@ARGV ) { 
	### printf "processing %s ", $arg ;
	my $output =`rrdtool lastupdate $arg ` ;
	### print "~~~~~~~~~~~~~~~~~~~~\n";
	### print $output;
	# die "looks like $arg is not a nice rrd " unless $output;
	unless ($output) {
		# no need to kilroy at STDERR - rrdtool complains there
		print "\tlooks like $arg is not a nice rrd " ;
		$errcnt ++ ;
		next;
	}
	
	my @lines = split ("\n", $output);
	# print "has $#lines lines \n";
	if ( $#lines != 2) {
		# print 
		print STDERR "\tunexpected output format\n$output\n " ;
		$errcnt ++ ;
		next;
	}
	
	# assemble the user friendly output:
	# printf "== %s == | %s\n", $arg, $lines[0]; # db name in top left, col headers follow
	
	unless ( $lines[2] =~ /^(\d{10,}):\s*(.*)$/ ) {
		print STDERR "\tunexpected second line in output\n$lines[2]\n " ;
		$errcnt ++ ;
		next;
	}
	# if succesful 'til here, we have the 2nd line splitted in the regexp backrefs	
	my $restofline = $2;

	my $lastupdate = $1 ;
	my $datetimestr = mydatetime($lastupdate) ;
	my $lagtime = $now - $lastupdate ;

	my $okstring;
	if ($lagtime > $gracetime ) {
		$okstring =  sprintf "!!! (%ds)", $lagtime ;
		$errcnt ++ ;
	} else {
		$okstring = sprintf "OK  (%ds)", $lagtime ;
	}

	# render the user friendly part
	printf "--- [ %s ] ---------------------------------  \n\t%s \t| %s\n", 
		$arg, $okstring,  $lines[0]; # db name in top left, col headers follow
	printf "%s  \t| \t%s \n",  $datetimestr, $restofline ;
}
print " =============== DONE - errors: $errcnt ==============\n";

# inform the caller
exit ( $errcnt ? 1 : 0 )  ;

# ======================================
sub mydatetime {
  my $arg = shift;
  my $rv =`date -d \@$arg $dtformat` ;
  chomp $rv;
  return $rv ;
}

sub mynow {
  my $rv = `date \+\%s`;
  chomp $rv;
  return $rv ;

}
