#!/usr/bin/perl


print <<"EOFHEAD";
--height=800
--interlaced
--left-axis-format=%1.2lf
--y-grid=0.005:10
--alt-autoscale
EOFHEAD

# DEF:w=/home/wrosner/chargery/rrd//cells.rrd:U01:AVERAGE
for  (1..22) {
  printf "DEF:U%02d=/home/wrosner/chargery/rrd//cells.rrd:U%02d:AVERAGE\n", $_, $_  ;  
}

# LINE1:w#808080:U01 AVERAGE \
for  (1..22) {
  
  printf "LINE1:U%02d#%s:cell %02d\n", $_, colorcode($_) , $_ ;
}

exit ;

# ~~~~~~~~~~~~~~~~~~~~~
#
# assign colorcode systematically
sub colorcode {
  my $param = shift ;
  $param += 1;

  my ($d, $r ) = mymodulo ($param, 3) ;
  my $res = sprintf "%02x", $r * 0x7f ;

  ($d, $r ) = mymodulo ($d, 3) ;
  $res .= sprintf "%02x", $r * 0x7f ;

  ($d, $r ) = mymodulo ($d, 3) ;
  $res .= sprintf "%02x", $r * 0x7f ;

  return $res ;
}

# moduolo div returning both mod an remainder
sub mymodulo {
  my ($a, $b) = @_;
  my $mod = $a % $b ;
  # $a -= ($b * $mod);
  return ( ($a - $mod) / $b, $mod  );
}

