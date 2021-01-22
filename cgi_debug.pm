# debug with continued laoding
#
# our $q;
sub debug {
  print    "\n<pre><code>\n";
  print ( Data::Dumper->Dump( \@_)) ; 
  print "</code></pre>\n";
}

# final die like debug
sub DEBUG {
    print CGI::header ;
    print CGI::start_html('### DEBUG ###');
    print debug ( @_) ;
    print CGI::end_html ;
  exit ''; # is it bad habit to exit from a sum??  
}

1;
