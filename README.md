# perl_rrd_cgi
## boilerplate approach for simple rrd browsing on http
### Rationale
Understand RRD, if you want to understand what follows.  
https://oss.oetiker.ch/rrdtool/  
Somewhat more flexible than rrdcgi,  
but less overhead and opacity layers than other +- well known heavyly bloated frameworks.  
In the end, PERL is a turing complete programming language, and HTML may be quite close to it.  
So, who needs more?  
Anyway, it seems to do some job for me.  
Whether it may do anything good for anybody else? No clue.  

### Concept
Have a Navigation bar where you can change the timeframe on display in the browser without much hazzle.  
List of charts are hardcoded in the scripts as perl arrays like here:  
https://github.com/wolfgangr/perl_rrd_cgi/blob/03e9b2c4793ea0ad47766315c396a692e221de1d/chargery.pl#L15  
Use ordinary rrdgraph definition syntax, where you just (may) omit the parameters added from the navigator  
(start, end, interval, width, heigth, base...)  

### content 
    test-navigator.pl
The real boilerplate, may not resemble the last debug status  

    chargery.pl
The first skript I kept using for some days now.  
Maybe it provides more maturity even if used as a boilerplate only.  

    *.rrd-graph
The templates used to produce the charts on the fly.
Volatile parts are added on top from the perl navigator envelope.  
Looks like I may overwrite them - the last occurance of some rrdgraph option seems to win.  
I've tried it with `--height=800` in `BMS-Ucells.rrd-graph`, since this is a chart with 22 lines that simply does not make sense if scaled down.  
rrd seems to be quite picky about surplus whitespace.  
Good idea to avoid them, particlarly at the end of a line.  
No need for any trailing slashes or similiar.  
I tried to forward all errors to the browser for efficient debugging.  
When I get a "500 internal server error", I call the script from the command line. Helped most of the time to find the cause.  

     BMS-Ucells.pl
Ucells is a rrd with 22 +- identical fields (in this case: cell voltages read from a battery management system)  
Generating the graph definition file by a script may have some advantages duroing setup, debug and development.  
Not required for ordinary data browsing.  
  
other `*.pl` files: just silly test scripts - as far as I can remember...



