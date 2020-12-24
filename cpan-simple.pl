#!/usr/bin/perl -w
use strict ;
#  https://metacpan.org/pod/release/LDS/CGI.pm-3.33/CGI.pm
  # CGI script that creates a fill-out form
  # and echoes back its values.

  use CGI qw/:standard/;
  print header,
        start_html('A Simple Example'),
        h1('A Simple Example'),
        start_form,
        "What's your name? ",textfield('name'),p,
        "What's the combination?", p,
        checkbox_group(-name=>'words',
                       -values=>['eenie','meenie','minie','moe'],
                       -defaults=>['eenie','minie']), p,
        "What's your favorite color? ",
        popup_menu(-name=>'color',
                   -values=>['red','green','blue','chartreuse']),p,
        submit,
        end_form,
        hr;

   if (param()) {
       my $name      = param('name');
       my $keywords  = join ', ',param('words');
       my $color     = param('color');
       print "Your name is",em(escapeHTML($name)),p,
             "The keywords are: ",em(escapeHTML($keywords)),p,
             "Your favorite color is ",em(escapeHTML($color)),
             hr;
   }
