#!/usr/bin/perl
use strict;
use CGI qw/:standard/;

print header();
print start_html(-title => 'Testpage No2');
print h1('Test 2');
print end_html();
