#!/usr/bin/perl
# 
# @DESC  : user script for modifying the MEDIA list 
#
#
# Copyright (C) Sven Burkard
#
# This program is free software;you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 3 of the License, 
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied 
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# 
# See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License 
# along with this program; if not, see <http://www.gnu.org/licenses/>.
################################################################################


use strict;
use warnings;

use Getopt::Long;

use func '.';


our $SCRIPT = 'control';
our $CONFIG = &func::getScriptConfig();
our $MEDIA;
our $SHOWS;
my $param; 
my $sourceName;
my $showName;
my $o_db;
my $query;
my $sql;
my @result;

GetOptions(
            "list=s"    => \$param->{'list'},
            "add"       => \$param->{'add'},
            "del"       => \$param->{'del'},
            "source=s"  => \$param->{'sourceName'},
            "show=s"    => \$param->{'showName'},
            "path=s"    => \$param->{'path'},
            "help"      => \$param->{'help'},
          );

if(defined($param->{'help'})){
  print "mediarip control script\n";
  print "\n";
  print "e.g.: ./control.pl --list='on'\n";
  print "      ./control.pl --list='off'\n";
  print "      ./control.pl --add --source='zdf' --show='SOKO_5113'\n";
  print "      ./control.pl --del --source='zdf' --show='SOKO_5113'\n";
  print "\n";
  print "  actions:\n";
  print "    --list   [options] can be 'on' (online available) or 'off' (offline marked, to check for updates)\n"; 
  print "    --add\n"; 
  print "    --del\n"; 
  print "    --help             this page\n";
  print "\n"; 
  print "  options:\n";
  print "    --source [options] can only be zdf at the moment\n";
  print "    --show   [options] can be any show from the source  \n";
  print "    --path   [options] if not set, DATA_PATH from your CONFIG will be used\n";
  print "\n";
  &func::cleanExit();
}

if(!defined($param->{'list'}) && !defined($param->{'add'}) && !defined($param->{'del'})){
  print "mediarip control script\n";
  print "\n";
  print "e.g.: ./control.pl --add --source='zdf' --show='SOKO_5113' --path='/media/videos/'\n";
  print "\n";
  print "use --help to get full help\n";
  &func::cleanExit();
}

if(defined($param->{'list'}) && ($param->{'list'} ne 'on' && $param->{'list'} ne 'off')){
  &func::printError("list parameter must be 'on' or 'off'");
  &func::cleanExit();
}

if(defined($param->{'list'})){
  if($param->{'list'} eq 'on'){
    $SHOWS = &func::getIndexOfAllShows();
    print "available shows:\n";
    foreach $sourceName(sort keys %{$main::SHOWS}){
      foreach $showName(sort keys %{$main::SHOWS->{$sourceName}}){
        print "$sourceName: $showName\n";
      }
    }
    &func::cleanExit();
  }elsif($param->{'list'} eq 'off'){
    $MEDIA  = &func::getMediaConfig();
    if(keys(%{$main::MEDIA}) > 0){
      print "sourceName;showName;path\n----------\n";
      foreach $sourceName(sort keys %{$main::MEDIA}){
        foreach $showName(sort keys %{$main::MEDIA->{$sourceName}}){
          print "$sourceName;$showName;$main::MEDIA->{$sourceName}->{$showName}\n";
        }
      }
    }else{
      &func::printError("your $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} config contains no valid entrys, check your $main::CONFIG->{'DATA_STORE_METHOD'}");
      &func::cleanExit();
    }
    &func::cleanExit();
  }
}


if(!defined($param->{'sourceName'})){
  &func::printError("no source defined; e.g.: zdf");
  &func::cleanExit();
}

if($param->{'sourceName'} !~ m/^zdf$/i){
  &func::printError("source can only be zdf at the moment");
  &func::cleanExit();
}

if(!defined($param->{'showName'})){
  &func::printError("no show defined; e.g.: SOKO_5113");
  &func::cleanExit();
}

if(!defined($param->{'path'})){
  $param->{'path'}  = '';
}

$MEDIA  = &func::getMediaConfig();

if(defined($param->{'add'})){
  &func::addShow($param);
}elsif(defined($param->{'del'})){
  &func::delShow($param);
}
