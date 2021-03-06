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


use strict;
use warnings;

use Time::Piece;
use CGI; 
require './cgi_debug.pm' ;
# use Data::Dumper::Simple ;
use Data::Dumper ; # qw(Dump);

my $rrdtool = `which rrdtool   `;

my $dtformat = '%F - %T' ; # datetime format string for console `date`
# our $now = mynow() ;

my $q = CGI->new;
 

my $gracetime = $q->param('gracetime') || 60 ;
my $reload= $q->param('reload') ||  10;
my @rrds = $q->multi_param('rrd') ; # can I have multi params on the GET url?

# my $now = time();

# sanity checker for rrd adress
# ^\~?\S+\.rrd$
# - no whitespace
# - end .rrd
# may start with ~

my @rrdlist = 
	map { chomp ; $_ }  
	map { split "\n",  `ls -1 $_`  } 
	grep { /^\~?\S+\.rrd$/ } 
	@rrds ;


	# try best with time arithmetic
my $tp_now = Time::Piece->new() ;
my $now =  $tp_now->epoch ;
my $tp_grace = Time::Piece->new($now - $gracetime); 
my $tmdebug = sprintf "===    gracetime: %s    =    now: %s    =    diff: %s    ===\n",
	 $tp_grace->strftime($dtformat),  $tp_now->strftime($dtformat), $gracetime;

# DEBUG( $now, \@rrds, \@rrdlist , $gracetime, $reload  , $tmdebug, $tmdebug  );


# ======= are we done now??

print CGI::header ;
print CGI::start_html('test output');
print    "\n<pre><code>\n";


my $errcnt = 0;

foreach my $arg (@rrdlist ) { 
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
	# my $datetimestr = mydatetime($lastupdate) ;
	 my $datetimestr = '### still TODO ###' ; 
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
# exit ( $errcnt ? 1 : 0 )  ;

print "</code></pre>\n";
print CGI::end_html ;

exit ;

# ======================================
