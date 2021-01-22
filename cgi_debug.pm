# debug with continued laoding
sub debug {
  print    "\n<pre><code>\n";
  print  Dumper ( @_) ; 
  print "\</code></pre>\n";
}

# final die like debug
sub DEBUG {
    print header ;
    print start_html('### DEBUG ###');
    print debug ( @_) ;
    print end_html ;
  exit; # is it bad habit to exit from a sum??  
}

1;
