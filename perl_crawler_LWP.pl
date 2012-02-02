#
# Copyright (C) 2012 Le Vu Hiep
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.


#!/usr/bin/perl
use strict;
use warnings;
use HTML::Entities;
use Encode;
require LWP::UserAgent;
use LWP::Simple;
require HTTP::Request;
use HTTP::Cookies;
use diagnostics;
use Switch;

##########################Networking section########################
my $UA = LWP::UserAgent->new;
my $cookies = HTTP::Cookies->new();
# capturing your cookies for yahoo domain after login and put it into <cookie_here> as a parameter for set_cookie(), which only requires if the blog visibility set to PRIVATE. My former blog on 360 plus is set private so I need to implement this function, you may try any value(?) or some yahoo cookies values when connect to a public blog.
$cookies->set_cookie(0,'Y', '<cookie_here>','/','yahoo.com',80,0,0,86400,0);
$UA->cookie_jar($cookies);
my $id = 1;
## Start Lopping;
## assign your yahoo id to the var yid.
my $yid= '';
## adjust the maximum id number of the article, this could be done by looking at your address bar when you are reading the lastest article
#my $max_id = ;
for($id = 1;$id <$max_id;$id++) {
	my $url = 'http://vn.360plus.yahoo.com/'.$yid.'/article?mid='.$id;
	my $req = HTTP::Request->new(GET => $url);
	my $res = $UA->request($req);

#print $res->code;

# Get the HTML content from the blog.
	my $Content = $res->decoded_content; # Sua o day nua!

######################################################################
# call parsing functions:
my $passed = validatingEntry($Content); # Check if the ID requested return a valid blog entry or not.

if($passed) {
	my $date =  getPostedDate($Content);
	my $title = getTitle($Content);
	my $entry = getEntry($Content);
	my $pure =  purify($entry,1);
	my $tag =   getTag($Content);
	my @comments = getComment($Content);
	my $comments='.';
	
# print out the result
	$date  = encode("utf8","$date");
	$title = encode("utf8",decode_entities("$title"));
	$entry = encode("utf8",decode_entities("$pure\n"));
	$tag  = encode("utf8",decode_entities("$tag"));
	print "<blog id=\"$id\">\n";
	print "<date>$date</date>\n";
	print "<til>$title</til>\n";
	print "<entry>$entry</entry>\n";
	print "<tag>$tag</tag>\n";
	print "<comments>";
	# <comment id="$">
	# <comment author="$">
	foreach $comments(@comments) {
		$comments = purify($comments,1);
		print $comments = encode("utf8",decode_entities("$comments"));
	}
	print "</comments>\n";
	print "</blog id=\"$id\">";
	}
}


sub getPostedDate {
	my $beginChar = '<span class="date">';
	my $endChar = '</span>';
	my $beginIndex = index($_[0],$beginChar);
	my $endIndex = index($_[0],$endChar,$beginIndex);
	my $lenght = $endIndex-($beginIndex+19);
	my $d = substr $_[0], $beginIndex+19, $lenght;

	return $d;
}; 

sub getTitle {
	my $beginChar = '<title>';
	my $endChar = '</title>';
	my $beginIndex = index($_[0],$beginChar);
	my $endIndex = index($_[0],$endChar,$beginIndex);
	my $lenght = $endIndex-($beginIndex+7);
	my $title = substr $_[0], $beginIndex+7, $lenght;

	return $title;
};

sub getEntry {
	my $beginChar = '<div class="main-bd">';
	my $endChar = '<div class="mod-alist-tagsbar">';
	my $beginIndex = index($_[0],$beginChar);
	my $endIndex = index($_[0],$endChar,$beginIndex);
	my $lenght = $endIndex-($beginIndex+21);
	my $entry = substr $_[0], $beginIndex+21, $lenght;
	
	return $entry;
};

sub getComment {
my $i = 0;
my @com = findCommentIndex($_[0]);
my $n = scalar(@com);
my @comments;
while ($i < $n) {
	my $beginChar = '';
        my $endChar = '<a href="#" id="';
        my $beginIndex = $com[$i];
        my $endIndex = index($_[0],$endChar,$beginIndex);
        
        my $len = $endIndex-($beginIndex+17);
        my $pre_tag = substr $_[0], $beginIndex+17, $len;
                        $beginChar = '<div class="bd">';
                        $endChar = '<div class="ft">';
                        $beginIndex = index($pre_tag,$beginChar);
                        $endIndex = index($pre_tag,$endChar,$beginIndex);
                        $len = $endIndex-($beginIndex+17);
                        my $cmt = substr $pre_tag, $beginIndex+17, $len;
			push(@comments,$cmt);	
	$i++;

	}

return @comments;
};

sub findCommentIndex {
	my $string =$_[0];
	my $char = '<div class="comment">';
	my $offset = 0;
	my @Indexes;
	my $index = index($string, $char, $offset);

  while ($index != -1) {
#	print "Found char at $index\n";
	push(@Indexes,$index);

    $offset = $index + 1;
    $index = index($string, $char, $offset);

  }
return @Indexes;

}

sub getTag {
	my $beginChar = '<div class="tag_content">';
        my $endChar = '</div>';
	my $beginIndex = index($_[0],$beginChar);
	my $endIndex = index($_[0],$endChar,$beginIndex);
	my $tg = 'NoTag';
	if($beginIndex > -1) {
        my $len = $endIndex-($beginIndex+26);
	my $pre_tag = substr $_[0], $beginIndex+26, $len;
			$beginChar = '">';
			$endChar = '</a>';
			$beginIndex = index($pre_tag,$beginChar);
			$endIndex = index($pre_tag,$endChar,$beginIndex);
			$len = $endIndex-($beginIndex+2);
			$tg = substr $pre_tag, $beginIndex+2, $len; 
	}

	purify($tg,2);	
        return $tg;
};

sub validatingEntry {
my $cont = 1;
my $error = index($_[0],'<div id="error_msg">');

	if ($error != -1) { # There are errors. No blog entry ID exists, for example.
		$cont=0;
	}

return $cont;
}


sub purify {
	my $cont=$_[0];
 	switch($_[1]) {	
	case 1 { # purify the entry
		chop($cont);
		$cont =~ s/<div>//gi;
		$cont =~ s/<\/div>//gi;
		$cont =~ s/">/" \/>/gi;
		return $cont;
		}
	case 2 { # purify any content
		$cont =~ s/^$/A/gi;
		return $cont;
		}
	}
}

##############################I/O Section###########################
#sub DAO {
##Structure: parent node: <id=$n><date></date><title></title><content></content><tag></tag><comment></comment></id=$n>
#        my $file = "our_blog.xml";
#        my $id = $_[0];
#        my $date = $_[1];
#        my $title = $_[2];
#        my $content = $_[3];
#        my $tag = $_[4];
#        my $comment = $_[5];
#
#                open (OUT, ">>$file");
#                binmode(OUT,':utf8');
#                print OUT encode_utf8 "<id=$id>\n<date>$date</date>\n<title>$title</title>\n<content>$content</content>\n<tag>$tag</tag>\n<comment>$comment</comment>\n</id=$id>";
#                close OUT;
#}
##############################I/O Section###########################

exit 0;
