#!/usr/bin/perl
use strict;
use CGI qw/:standard/;

if (1) { 
print header();
print start_html(-title => 'Frame test mit perl CGI');
# print h1('ist der Frame da auch noch da?');
# print end_html();

} else {	
print "Content-Type: text/html\n\n";
print "<html>\n";
print "<head><title>Ei wo isser denn</title></head>\n";
print "<body>\n";
}

print "<h1>...dieser dumme Frame?</h1>\n";
print "<hr>\n";

# my $furl ="http://kellerkind.rosner.lokal/pl_cgi/test-frame.pl";
# my $furl ="/pl_cgi/test-frame.pl";
# my $furl ="http://kellerkind.rosner.lokal/pl_cgi/guntamatic_render/current-state.pl";
my $furl ="./guntamatic_render/current-state.pl";


printf <<"EOF_FRAME" , $furl, $furl ;
<iframe src="%s" height="300" width="600"  name="status Variablen">
  <p>Ihr Browser kann leider keine eingebetteten Frames anzeigen:
  Sie können die eingebettete Seite über den folgenden Verweis aufrufen: 
  <a href="%s">SELFHTML</a>
  </p>
</iframe>
EOF_FRAME


print "<hr>\n";
print "hier?\n";
print "</body>\n";
print "</html>\n";

