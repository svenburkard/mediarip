#!/usr/bin/perl
#
# @DESC  : main script for ripping and converting videos from media libraries
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

use func '.';

our $SCRIPT = 'mediarip';
our $CONFIG = &func::getScriptConfig();
our $MEDIA  = &func::getMediaConfig();
our $SHOWS  = &func::getIndexOfNewEpisodes();


&getNewEpisodes();
&func::cleanExit();


#--------------------------------------------------
sub printDebugInfo() {
# @AUTHOR:  Sven Burkard
# @DESC  :  prints some debug infos
#--------------------------------------------------
  my $sourceName;
  my $showName;
  my $url;

  foreach $sourceName(sort keys %{$main::SHOWS}){
    foreach $showName(sort keys %{$main::SHOWS->{$sourceName}}){
      foreach $url(sort keys %{$main::SHOWS->{$sourceName}->{$showName}->{'episode'}}){
        print "source: $sourceName\n";
        print "show: $showName\n";
        print "episode: $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}\n";
        print "date: $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}\n";
        print "1000: $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'quality'}->{'1000'}\n";
        print "2000: $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'quality'}->{'2000'}\n";
        print "imageUrl: $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'imageUrl'}\n";
        print "text: $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'text'}\n";
      }
    }
  }
}

#--------------------------------------------------
sub getNewEpisodes() {
# @AUTHOR:  Sven Burkard
# @DESC  :  downloads new episodes 
#--------------------------------------------------
  my $sourceName;
  my $showName;
  my $url;
  my $sourceCode;
  my $cmd;
  my $done;
  my $debug;
  my $fileName;
  my $try;
  my $tryMax      = 3;

  foreach $sourceName(sort keys %{$main::SHOWS}){
    foreach $showName(sort keys %{$main::SHOWS->{$sourceName}}){
      NEXT_SHOW: foreach $url(sort keys %{$main::SHOWS->{$sourceName}->{$showName}->{'episode'}}){
        $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'} =~  s/ /_/g;
        if($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'date_-_show_-_episode.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}_-_$showName\_-_$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}";
        }elsif($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'date-show-episode.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}-$showName-$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}";
        }elsif($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'show-episode.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName-$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}";
        }elsif($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'show_-_episode_-_date.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName\_-_$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}_-_$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}";
        }elsif($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'show-episode-date.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName-$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}-$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}";
        }elsif($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'show/episode.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName/$showName-$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}";
          &func::pathCheck("$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName");
        }elsif($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'show/date_-_episode.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName/$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}_-_$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}";
          &func::pathCheck("$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName");
        }elsif($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'show/date-episode.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName/$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}-$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}";
          &func::pathCheck("$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName");
        }elsif($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'show/episode-date.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName/$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}-$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}";
          &func::pathCheck("$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName");
        }elsif($main::CONFIG->{'DATA_FILE_NAME_FORMAT'} eq 'show/episode_-_date.EXT'){
          $fileName = "$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName/$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}_-_$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}";
          &func::pathCheck("$main::SHOWS->{$sourceName}->{$showName}->{'path'}$showName");
        }else{
          &func::printError("not supported DATA_FILE_NAME_FORMAT in use; check your config"); 
          &func::cleanExit();
        }

        $fileName =~  s/ /\\ /g;

        if($sourceName eq 'zdf'){
          $sourceCode = &func::getSourceCode($main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'quality'}->{'2000'});
          $sourceCode =~  m/<Ref href="([^"]+)"\/>/g;
          if(defined($1)){
            $fileName = "$fileName.wmv";
            $cmd  = "$main::CONFIG->{'MPLAYER_BIN'} -dumpstream -dumpfile $fileName $1 2>&1";

            $try  = 0;
            $done = 0;
            while($try<$tryMax){
              $try++;
              &func::printDebug($cmd);
              $debug  = `$cmd`;
              if(defined($debug) && $debug =~ m/Everything done\./g){
                $try  = $tryMax;
                $done = 1;
              }elsif(defined($debug) && $debug !~ m/Error while reading network stream/g){
                &func::printDebug("$sourceName ($showName/$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}) ignoring small connection faults from $sourceName (for example: too small stream_chunk size)");
                $try  = $tryMax;
                $done = 1;
              }else{
                &func::printError("$sourceName ($showName/$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}) download failed. try $try of $tryMax");
                sleep(2);
              }
            }

            if($done == 1 && -e $fileName){
              &func::printDebug("$fileName successfully downloaded");
            }else{
              &func::printError("$sourceName ($showName/$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}) download failed. will jump to the next episode, if more are available.");
              next NEXT_SHOW;
            }

            &transcode($fileName);
            &expandDoneLog($sourceName,$showName,$url);

          }else{
            &func::printError("videoUrl is not defined; asx container changed?");
          }
        }
      }
    }
  }
}

#--------------------------------------------------
sub expandDoneLog() {
# @AUTHOR:  Sven Burkard
# @DESC  :  initialized subs for adding a new file to the doneLog; depending on $CONFIG->{'DATA_STORE_METHOD'}
#--------------------------------------------------
  my $sourceName  = shift();
  my $showName    = shift();
  my $url         = shift();  

  if($main::CONFIG->{'DATA_STORE_METHOD'} eq 'file'){
    &expandDoneLogFile($sourceName,$showName,$url);
  }elsif($main::CONFIG->{'DATA_STORE_METHOD'} eq 'db'){
    require DBI;
    &expandDoneLogDB($sourceName,$showName,$url);
  }
}

#--------------------------------------------------
sub expandDoneLogFile() {
# @AUTHOR:  Sven Burkard
# @DESC  :  adds a new file to the doneLog; $CONFIG->{'DATA_STORE_METHOD'} = 'file'
#--------------------------------------------------
  my $sourceName  = shift();
  my $showName    = shift();
  my $url         = shift();  

  if(!-e $main::CONFIG->{'DATA_STORE_NAME_DONE'}){
    &func::printDebug("$main::CONFIG->{'DATA_STORE_NAME_DONE'} doesn't exist and will be created...");
    if(open(DONE, "> $main::CONFIG->{'DATA_STORE_NAME_DONE'}")){
      print DONE "#sourceName;showName;episodeName;date;runTimeInMin\n";
      close(DONE);
      &func::printDebug("$main::CONFIG->{'DATA_STORE_NAME_DONE'} $main::CONFIG->{'DATA_STORE_METHOD'} created");
    }else{
      &func::printError("$main::CONFIG->{'DATA_STORE_NAME_DONE'} $main::CONFIG->{'DATA_STORE_METHOD'} can not be created");
      &func::cleanExit();
    }
  }
  if(open(DONE, ">> $main::CONFIG->{'DATA_STORE_NAME_DONE'}")){
    print DONE "$sourceName;$showName;$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'};$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'};$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'runTimeInMin'}\n";
    close(DONE);
  }else{
    &func::printError("$main::CONFIG->{'DATA_STORE_NAME_DONE'} $main::CONFIG->{'DATA_STORE_METHOD'} can not be expanded");
    &func::cleanExit();
  }
}

#--------------------------------------------------
sub expandDoneLogDB() {
# @AUTHOR:  Sven Burkard
# @DESC  :  adds a new file to the doneLog; $CONFIG->{'DATA_STORE_METHOD'} = 'db'
#--------------------------------------------------
  my $sourceName  = shift();
  my $showName    = shift();
  my $url         = shift();  
  my $o_db;
  my $query;
  my $sql;
  my @result;

  if($o_db = &func::getDB()){
    &func::printDebug("db connection established");
    $query   =  "SELECT sourceName,showName,episodeName,date,runTimeInMin ";
    $query  .=  "FROM $main::CONFIG->{'DATA_STORE_NAME_DONE'} ";
    $query  .=  "LIMIT 1;";
    $sql     =  $o_db->prepare($query);
    if(!$sql->execute){
      &func::printError("table $main::CONFIG->{'DATA_STORE_NAME_DONE'} doesn't exists");
      $query   =  "CREATE TABLE $main::CONFIG->{'DATA_STORE_NAME_DONE'} ";
      $query  .=  "(id int auto_increment primary key, sourceName varchar(10), showName varchar(40), episodeName varchar(100)), date varchar(9), runTimeInMin int;";
      $sql     =  $o_db->prepare($query);
      if($sql->execute){
        &func::printDebug("table $main::CONFIG->{'DATA_STORE_NAME_DONE'} created");
      }else{
        &func::printError("table $main::CONFIG->{'DATA_STORE_NAME_DONE'} can't be created");
      }
    }
    $query   =  "INSERT INTO $main::CONFIG->{'DATA_STORE_NAME_DONE'} ";
    $query  .=  "SET sourceName='$sourceName',showName='$showName',episodeName='$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}',date='$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}',runTimeInMin='$main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'runTimeInMin'}';";
    $sql     =  $o_db->prepare($query);
    if(!$sql->execute){
      &func::printError("$main::CONFIG->{'DATA_STORE_NAME_DONE'} $main::CONFIG->{'DATA_STORE_METHOD'} can not be expanded ($query)");
    }
  }else{
    &func::printError("can't establish a db connection ($main::CONFIG->{'DB_IP'}), check your settings");
    &func::cleanExit();
  }
}

#--------------------------------------------------
sub transcode() {
# @AUTHOR:  Sven Burkard
# @DESC  :  transcode the video file; e.g.: wmv > mkv
#--------------------------------------------------
  my $fileName      = shift();
  my $fileNameNew   = $fileName;
  my $options;
  my $done;
  my $cmd;
  my $debug;

  if($main::CONFIG->{'CONVERT'} eq 'yes'){
    if($main::CONFIG->{'CONVERT_CONTAINER'} eq 'avi'){
      $fileNameNew =~  s/\.[^\.]+$/\.avi/g
    }elsif($main::CONFIG->{'CONVERT_CONTAINER'} eq 'mkv'){
      $fileNameNew =~  s/\.[^\.]+$/\.mkv/g
    }
    if($main::CONFIG->{'CONVERT_VIDEO_CODEC'} eq 'xvid'){
      if($main::CONFIG->{'CONVERT_QUALITY'} eq 'high'){
        $options  = "-xvidencopts fixed_quant=4";
      }elsif($main::CONFIG->{'CONVERT_QUALITY'} eq 'highest'){
        $options  = "-xvidencopts fixed_quant=1";
      }
    }elsif($main::CONFIG->{'CONVERT_VIDEO_CODEC'} eq 'x264'){
      if($main::CONFIG->{'CONVERT_QUALITY'} eq 'high'){
        $options  = "-x264encopts qp=26";
      }elsif($main::CONFIG->{'CONVERT_QUALITY'} eq 'highest'){
        $options  = "-x264encopts qp=20";
      }
    }
    if($fileName eq $fileNameNew){
      &func::printError("filName has not changed; check the regex");
      next NEXT_SHOW;
    }

    if(!defined($options)){
      &func::printError("transcoding options not set correctly, check all settings, which starging with CONVERT_ at your CONFIG");
      next NEXT_SHOW;
    }

    $done = 0;
    $cmd  = "$main::CONFIG->{'CONVERT_BIN'} $fileName -ovc $main::CONFIG->{'CONVERT_VIDEO_CODEC'} -oac $main::CONFIG->{'CONVERT_AUDIO_CODEC'} $options -o $fileNameNew 1>/dev/null 2>&1";
    &func::printDebug($cmd);
    $debug  = system($cmd);

    while($done != 1){
      if(defined($debug) && $debug == 0){
        $done = 1;
      }else{
        &func::printError("$fileName transcode failed: $cmd");
        sleep(30);
        $debug  = system($cmd);
      }
    }

    &func::printDebug("$fileNameNew successfully transcoded");
    if(unlink($fileName)){
      &func::printDebug("$fileName successfully deleted");
    }else{
      &func::printError("can't delete $fileName");
    }
  }
}
