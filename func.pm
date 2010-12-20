package func;
#
# @DESC  : stores functions, that are used by the main- and the controlscript
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

use LWP::UserAgent;


#--------------------------------------------------
sub cleanExit() {
# @AUTHOR:  Sven Burkard
# @DESC  :  exit function
#--------------------------------------------------
  &deleteLock();
  exit();
}

#--------------------------------------------------
sub getScriptConfig() {
# @AUTHOR:  Sven Burkard
# @DESC  :  initialized subs for getting and checking the user config vars 
#--------------------------------------------------
  my $configFile = 'CONFIG';
  my $configData = '';

  if(open(CONFIG, "< $configFile")){
    while(<CONFIG>){
      if($_ !~ m/^#/){
        $configData .= $_;
      }
    }
    close(CONFIG);

    $main::CONFIG = &setConfigVars($configData);
    &configChecks();

  }else{
    &printError("can't open $configFile");
    &cleanExit();
  }


  return($main::CONFIG);
}

#--------------------------------------------------
sub printDebug() {
# @AUTHOR:  Sven Burkard
# @DESC  :  prints debug messages
#--------------------------------------------------
  my $text  = shift();

  if(exists($main::CONFIG->{'DEBUG'}) && defined($main::CONFIG->{'DEBUG'})){
    if($main::CONFIG->{'DEBUG'} eq 'yes'){
      print "[DEBUG]: $text\n";
    }
  }else{
    &printError("DEBUG is not defined!!");
    &cleanExit();
  }
}

#--------------------------------------------------
sub printError() {
# @AUTHOR:  Sven Burkard
# @DESC  :  prints error messages
#--------------------------------------------------
  my $msg  = shift();

  print STDERR "[ERROR]: $msg\n";
}

#--------------------------------------------------
sub setConfigVars() {
# @AUTHOR:  Sven Burkard
# @DESC  :  pushes the user config vars in a global config hash
#--------------------------------------------------
  my $configData  = shift();
  
  $main::CONFIG->{'DEBUG'}                  = &getConfigVar($configData,'DEBUG',['yes','no']);
  $main::CONFIG->{'LOCK'}                   = &getConfigVar($configData,'LOCK',['*']);
  $main::CONFIG->{'DATA_STORE_METHOD'}      = &getConfigVar($configData,'DATA_STORE_METHOD',['file','db']);
  $main::CONFIG->{'DATA_STORE_NAME_MEDIA'}  = &getConfigVar($configData,'DATA_STORE_NAME_MEDIA',['*'],'DATA_STORE_METHOD','*');
  $main::CONFIG->{'DATA_STORE_NAME_DONE'}   = &getConfigVar($configData,'DATA_STORE_NAME_DONE',['*'],'DATA_STORE_METHOD','*');
  $main::CONFIG->{'DB_TYPE'}                = &getConfigVar($configData,'DB_TYPE',['mysql'],'DATA_STORE_METHOD','db');
  $main::CONFIG->{'DB_IP'}                  = &getConfigVar($configData,'DB_IP',['*'],'DATA_STORE_METHOD','db');
  $main::CONFIG->{'DB_USERNAME'}            = &getConfigVar($configData,'DB_USERNAME',['*'],'DATA_STORE_METHOD','db');
  $main::CONFIG->{'DB_PASSWORD'}            = &getConfigVar($configData,'DB_PASSWORD',['*'],'DATA_STORE_METHOD','db');
  $main::CONFIG->{'DATA_PATH'}              = &getConfigVar($configData,'DATA_PATH',['*']);    
  $main::CONFIG->{'DATA_FILE_NAME_FORMAT'}  = &getConfigVar($configData,'DATA_FILE_NAME_FORMAT',['date_-_show_-_episode.EXT','date-show-episode.EXT','show-episode.EXT','show_-_episode_-_date.EXT','show-episode-date.EXT','show/episode.EXT','show/date_-_episode.EXT','show/date-episode.EXT','show/episode-date.EXT','show/episode_-_date.EXT']);    
  $main::CONFIG->{'MPLAYER_BIN'}            = &getConfigVar($configData,'MPLAYER_BIN',['*']);
  $main::CONFIG->{'CONVERT'}                = &getConfigVar($configData,'CONVERT',['yes','no']);
  $main::CONFIG->{'CONVERT_BIN'}            = &getConfigVar($configData,'CONVERT_BIN',['*'],'CONVERT','yes');
  $main::CONFIG->{'CONVERT_CONTAINER'}      = &getConfigVar($configData,'CONVERT_CONTAINER',['avi','mkv'],'CONVERT','yes');
  $main::CONFIG->{'CONVERT_AUDIO_CODEC'}    = &getConfigVar($configData,'CONVERT_AUDIO_CODEC',['copy','mp3lame'],'CONVERT','yes');
  $main::CONFIG->{'CONVERT_VIDEO_CODEC'}    = &getConfigVar($configData,'CONVERT_VIDEO_CODEC',['xvid','x264'],'CONVERT','yes');
  $main::CONFIG->{'CONVERT_QUALITY'}        = &getConfigVar($configData,'CONVERT_QUALITY',['highest','high'],'CONVERT','yes');


  return($main::CONFIG);
}

#--------------------------------------------------
sub getConfigVar() {
# @AUTHOR:  Sven Burkard
# @DESC  :  returns the $CONFIG->{$var} if everything is ok, or aborts
#--------------------------------------------------
  my $configData      = shift();
  my $var             = shift();
  my $options         = shift();
  my $dependencyKey   = shift();
  my $dependencyValue = shift();
  my $i;
  my $varValue;
  my $tempError;

  $configData =~  m/$var=([^\n]+)\n/g;
  if(defined($1) && $1 ne ''){
    $varValue = $1;
    if(grep(/^$varValue$/,@{$options}) || ${$options}[0] eq '*'){
      if(!defined($dependencyKey && $dependencyValue) || $dependencyKey eq '' || $dependencyValue eq ''){
        $main::CONFIG->{$var}  = $varValue;
        &printDebug("$var=$varValue");
      }elsif(defined($dependencyKey && $dependencyValue) && exists($main::CONFIG->{$dependencyKey}) && defined($main::CONFIG->{$dependencyKey}) && ($main::CONFIG->{$dependencyKey} eq $dependencyValue || $dependencyValue eq '*')){
        $main::CONFIG->{$var}  = $varValue;
        &printDebug("$var=$varValue");
      }
    }else{
      $tempError = "$var has a wrong value ($varValue). choose one of this: ";
      for($i=0;$i <= $#{$options};$i++){
        $tempError .= ${$options}[$i];
        if($i != $#{$options}){
          $tempError .=",";
        }
      }
      &printError($tempError);
      &cleanExit();
    }
  }else{
    if(!defined($dependencyKey && $dependencyValue)){
      &printError("$var is not defined!");
      &cleanExit();
    }elsif(defined($dependencyKey && $dependencyValue) && exists($main::CONFIG->{$dependencyKey}) && defined($main::CONFIG->{$dependencyKey}) && ($main::CONFIG->{$dependencyKey} eq $dependencyValue || $dependencyValue eq '*')){
      &printError("$var is not defined!");
      &cleanExit();
    }
  }


  return($main::CONFIG->{$var});
}

#--------------------------------------------------
sub configChecks() {
# @AUTHOR:  Sven Burkard
# @DESC  :  makes some path & binary tests 
#--------------------------------------------------
  my @cmd;
  my $debug;

  &createLock();

  if($main::CONFIG->{'DATA_PATH'} !~ m/\/$/){
    $main::CONFIG->{'DATA_PATH'} = "$main::CONFIG->{'DATA_PATH'}/";
  }

  &pathCheck($main::CONFIG->{'DATA_PATH'});


  if($main::CONFIG->{'CONVERT'} eq 'yes'){
    if(-e $main::CONFIG->{'CONVERT_BIN'}){
      if(!-x $main::CONFIG->{'CONVERT_BIN'}){
        &printError("$main::CONFIG->{'CONVERT_BIN'} is not executable by you, check the binary permissions");
        &cleanExit();
      }else{
        @cmd  = ("$main::CONFIG->{'CONVERT_BIN'} -ovc x264 -x264encopts qp=26 -oac mp3lame","$main::CONFIG->{'CONVERT_BIN'} -ovc xvid -xvidencopts fixed_quant=4 -oac mp3lame");
        foreach(@cmd){
          $debug  = `$_ 2>&1`;
          if($debug =~ m/not an MEncoder option|was compiled without/g){
            &printError("your installed mencoder binary has not all required options. please take a look into the README.");
            &cleanExit();
          }
        }
      }
    }else{
      &printError("$main::CONFIG->{'CONVERT_BIN'} does not exist!");
      &cleanExit();
    }
  }
}

#--------------------------------------------------
sub createLock() {
# @AUTHOR:  Sven Burkard
# @DESC  :  creates a LOCK file
#--------------------------------------------------
  if($main::SCRIPT eq 'mediarip'){
    if(!-e $main::CONFIG->{'LOCK'}){
      if(open(LOCK, "> $main::CONFIG->{'LOCK'}")){
        close(LOCK);
      }else{
        &printError("$main::CONFIG->{'LOCK'} can not be created");
        &cleanExit();
      }
    }else{
      &printError("$main::CONFIG->{'LOCK'} already exists. mediarip.pl only allows one instance at the same time.");
      exit();
    }
  }
}

#--------------------------------------------------
sub deleteLock() {
# @AUTHOR:  Sven Burkard
# @DESC  :  deletes the LOCK file
#--------------------------------------------------
  if($main::SCRIPT eq 'mediarip'){
    if(!unlink($main::CONFIG->{'LOCK'})){
      &func::printError("can not delete $main::CONFIG->{'LOCK'}");
    }
  }
}

#--------------------------------------------------
sub pathCheck() {
# @AUTHOR:  Sven Burkard
# @DESC  :  splits a pathname for mkdir
#--------------------------------------------------
  my $pathName  = shift();
  my @pathParts;
  my $path  = '';

  if(-e $pathName){
    if(!-w $pathName){
      &printError("$pathName is not writable for you");
      &cleanExit();
    }
  }else{
    @pathParts  = split('/',$pathName);
    if($pathName =~ m/^\//){
      $path = '/'.$path;
    }
    foreach(@pathParts){
      if($_ ne ''){
        $path .=  $_.'/';
        if(!-e $path){
          if(!mkdir($path)){
            &printError("$path ($pathName) can not be created for you, check the folder permissions");
            &cleanExit();
          }
        }
      }
    }
  }
}

#--------------------------------------------------
sub getMediaConfig() {
# @AUTHOR:  Sven Burkard
# @DESC  :  initialized subs for getting media config; depending on $CONFIG->{'DATA_STORE_METHOD'}
#--------------------------------------------------
  my $sourceName;
  my $showName;

  if($main::CONFIG->{'DATA_STORE_METHOD'} eq 'file'){
    $main::MEDIA  = &getMediaConfigFile();
  }elsif($main::CONFIG->{'DATA_STORE_METHOD'} eq 'db'){
    require DBI;
    $main::MEDIA  = &getMediaConfigDB();
  }

  if(keys(%{$main::MEDIA}) > 0){
    foreach $sourceName(sort keys %{$main::MEDIA}){
      foreach $showName(sort keys %{$main::MEDIA->{$sourceName}}){
        &printDebug("MEDIA: $sourceName;$showName;$main::MEDIA->{$sourceName}->{$showName}");
      }
    }
  }else{
    if($main::SCRIPT eq 'mediarip'){
      &printError("your MEDIA config contains no valid entrys, check your $main::CONFIG->{'DATA_STORE_METHOD'}");
      &cleanExit();
    }
  }

  return($main::MEDIA);
}

#--------------------------------------------------
sub getMediaConfigFile() {
# @AUTHOR:  Sven Burkard
# @DESC  :  getting media config; $CONFIG->{'DATA_STORE_METHOD'} = 'file'
#--------------------------------------------------
  if(open(MEDIA, "< $main::CONFIG->{'DATA_STORE_NAME_MEDIA'}")){
    while(<MEDIA>){
      if($_ !~ m/^#/ && $_ =~ m/^([^;]+);([^;]+);([^\n]*)\n/){
#         if(defined($1 && $2 && $3) && $1 ne '' && $2 ne ''){
        if(defined($1 && $2) && $1 ne '' && $2 ne ''){
          if(defined($3)){
            $main::MEDIA->{$1}->{$2}  = $3;
          }else{
            $main::MEDIA->{$1}->{$2}  = '';
          }
        }
      }
    }
    close(MEDIA);
  }else{
    if($main::SCRIPT eq 'mediarip'){
      &printError("$main::CONFIG->{'DATA_STORE_NAME_MEDIA'} doesn't exist, so you have to add some shows first. take a look into the README or ./control.pl --help");
      &cleanExit();
    }elsif($main::SCRIPT eq 'control'){ 
      &printDebug("$main::CONFIG->{'DATA_STORE_NAME_MEDIA'} doesn't exist and will be created...");
      if(open(MEDIA, "> $main::CONFIG->{'DATA_STORE_NAME_MEDIA'}")){
        print MEDIA "#sourceName;showName;path\n";
        close(MEDIA);
        &printDebug("$main::CONFIG->{'DATA_STORE_NAME_MEDIA'} $main::CONFIG->{'DATA_STORE_METHOD'} created");
      }else{
        &printError("$main::CONFIG->{'DATA_STORE_NAME_MEDIA'} $main::CONFIG->{'DATA_STORE_METHOD'} can not be created");
        &cleanExit();
      }
    }
  }

  return($main::MEDIA);
}

#--------------------------------------------------
sub getMediaConfigDB() {
# @AUTHOR:  Sven Burkard
# @DESC  :  getting media config; $CONFIG->{'DATA_STORE_METHOD'} = 'db'
#--------------------------------------------------
  my $o_db;
  my $query;
  my $sql;
  my @result;

  if($o_db = &getDB()){
    &printDebug("db connection established");
    $query   =  "SELECT sourceName,showName,path "; 
    $query  .=  "FROM $main::CONFIG->{'DATA_STORE_NAME_MEDIA'};";
    $sql     =  $o_db->prepare($query);
    if($sql->execute){
      &printDebug("reading table $main::CONFIG->{'DATA_STORE_NAME_MEDIA'}");
      while(@result = $sql->fetchrow_array()){ 
        $main::MEDIA->{$result[0]}->{$result[1]} = $result[2];
      }
    }else{
      &printError("table $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} please add some shows first; have a look at ./control --help");
      if($main::SCRIPT eq 'mediarip'){
        &cleanExit();
      }elsif($main::SCRIPT eq 'control'){ 
        &printError("table $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} doesn't exists;");
        $query   =  "CREATE TABLE $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} ";
        $query  .=  "(id int auto_increment primary key, sourceName varchar(10), showName varchar(40), path varchar(40));"; 
        $sql     =  $o_db->prepare($query);
        if($sql->execute){
          &printDebug("table $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} created");
        }else{
          &printError("table $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} can't be created");
        }
      }
    }
  }else{
    &printError("can't establish a db connection ($main::CONFIG->{'DB_IP'}), check your settings");
    &cleanExit();
  }


  return($main::MEDIA);
}

#--------------------------------------------------
sub addShow() {
# @AUTHOR:  Sven Burkard
# @DESC  :  adds a new show
#--------------------------------------------------
  my $param = shift();
  my $o_db;
  my $query;
  my $sql;
    
  if(keys(%{$main::MEDIA->{$param->{'sourceName'}}}) <= 0 || !grep{/^$param->{'showName'}$/i} keys %{$main::MEDIA->{$param->{'sourceName'}}}){
    $main::SHOWS = &func::getIndexOfAllShows();
    if(defined($main::SHOWS->{$param->{'sourceName'}}->{$param->{'showName'}})){
      if($main::CONFIG->{'DATA_STORE_METHOD'} eq 'db'){
        $o_db    = &func::getDB();
        $query   = "SELECT sourceName,showName,path ";
        $query  .= "FROM $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} ";
        $query  .= "WHERE sourceName='$param->{'sourceName'}' ";
        $query  .= "AND showName='$param->{'showName'}';";
        $sql    = $o_db->prepare($query);
        $sql->execute;

        if($sql->rows() <= 0){
          $query   = "INSERT INTO $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} ";
          $query  .= "SET sourceName='$param->{'sourceName'}',showName='$param->{'showName'}',path='$param->{'path'}';";
          $sql    = $o_db->prepare($query);

          if($sql->execute){
            &func::printDebug("$param->{'sourceName'};$param->{'showName'};$param->{'path'} successfully added");
          }else{
            &func::printError("can't insert $param->{'sourceName'}:$param->{'showName'}:$param->{'path'} into table $main::CONFIG->{'DATA_STORE_NAME_MEDIA'}");
            &cleanExit();
          }
        }else{
          &func::printError("$param->{'sourceName'}:$param->{'showName'} already exists");
          &cleanExit();
        }
      }elsif($main::CONFIG->{'DATA_STORE_METHOD'} eq 'file'){
        if(open(MEDIA, ">> $main::CONFIG->{'DATA_STORE_NAME_MEDIA'}")){
          print MEDIA "$param->{'sourceName'};$param->{'showName'};$param->{'path'}\n";
          close(MEDIA);
          &func::printDebug("$param->{'sourceName'};$param->{'showName'} successfully added");
        }else{
          &func::printError("$main::CONFIG->{'DATA_STORE_NAME_MEDIA'} $main::CONFIG->{'DATA_STORE_METHOD'} can't be updated");
          &cleanExit();
        }
      }
    }else{
      &func::printError("$param->{'showName'} is not available on $param->{'sourceName'}; take a look at ./control --list='on'");
      &cleanExit();
    }
  }else{
    &func::printError("$param->{'sourceName'}:$param->{'showName'} already exists");
    &cleanExit();
  }
}

#--------------------------------------------------
sub delShow() {
# @AUTHOR:  Sven Burkard
# @DESC  :  deletes a old show
#--------------------------------------------------
  my $param = shift();  
  my $o_db;
  my $query;
  my $sql;
  my $sourceName;
  my $showName;

  if(keys(%{$main::MEDIA->{$param->{'sourceName'}}}) >= 0 || grep{/^$param->{'showName'}$/i} keys %{$main::MEDIA->{$param->{'sourceName'}}}){
    if($main::CONFIG->{'DATA_STORE_METHOD'} eq 'db'){
      $o_db    = &func::getDB();
      $query   = "DELETE FROM $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} ";
      $query  .= "WHERE sourceName='$param->{'sourceName'}' ";
      $query  .= "AND showName='$param->{'showName'}';";
      $sql    = $o_db->prepare($query);
      $sql->execute;

      if($sql->rows() > 0){
        &func::printDebug("$param->{'sourceName'};$param->{'showName'} successfully deleted");
      }else{
        &func::printError("$param->{'sourceName'}:$param->{'showName'} doesn't exists");
        &cleanExit();
      }
    }elsif($main::CONFIG->{'DATA_STORE_METHOD'} eq 'file'){
      if(open(MEDIA, "> $main::CONFIG->{'DATA_STORE_NAME_MEDIA'}")){
        print MEDIA "#sourceName;showName;path\n";
        foreach $sourceName(sort keys %{$main::MEDIA}){
          foreach $showName(sort keys %{$main::MEDIA->{$sourceName}}){
            if($sourceName !~ m/^$param->{'sourceName'}$/i || $showName !~ m/^$param->{'showName'}$/i){
              print MEDIA "$sourceName;$showName;$main::MEDIA->{$sourceName}->{$showName}\n";
            }
          }
        }
        close(MEDIA);
        &func::printDebug("$param->{'sourceName'};$param->{'showName'} successfully deleted");
      }else{
        &func::printError("$main::CONFIG->{'DATA_STORE_NAME_MEDIA'} $main::CONFIG->{'DATA_STORE_METHOD'} can not be opened for deletion of $param->{'sourceName'};$param->{'showName'}");
        &cleanExit();
      }
    }
  }else{
    &func::printError("$param->{'sourceName'}:$param->{'showName'} doesn't exists");
    &cleanExit();
  }
}

#--------------------------------------------------
sub getDB() {
# @AUTHOR:  Sven Burkard
# @DESC  :  builds a db object
#--------------------------------------------------
  my $o_db  = DBI->connect("DBI:$main::CONFIG->{'DB_TYPE'}:mediarip:$main::CONFIG->{'DB_IP'}", $main::CONFIG->{'DB_USERNAME'}, $main::CONFIG->{'DB_PASSWORD'});


  return($o_db);
}

#--------------------------------------------------
sub getIndexOfNewEpisodes() {
# @AUTHOR:  Sven Burkard
# @DESC  :  creates a index of new episodes
#--------------------------------------------------
  my $sourceName;
  my $showName;
  my $url;
  my $episodeName;
  our $allShows;
  my $DONE;
  &getIndexOfAllShows();
  &getIndexOfAllEpisodesFromZDF();
  $DONE = &getIndexOfAllDownloadedEpisodes();

  foreach $sourceName(sort keys %{$func::allShows}){
    foreach $showName(sort keys %{$func::allShows->{$sourceName}}){
      foreach $url(sort keys %{$func::allShows->{$sourceName}->{$showName}->{'episode'}}){
        if(!defined($func::DONE->{$sourceName}->{$showName}->{$func::allShows->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}}) && !exists($func::DONE->{$sourceName}->{$showName}->{$func::allShows->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}})){
          if(exists($main::MEDIA->{'zdf'}->{$showName}) && defined($main::MEDIA->{'zdf'}->{$showName}) && $main::MEDIA->{'zdf'}->{$showName} ne ''){
            $main::SHOWS->{$sourceName}->{$showName}->{'path'} = $main::MEDIA->{$sourceName}->{$showName}; 
          }else{ 
            $main::SHOWS->{$sourceName}->{$showName}->{'path'} = $main::CONFIG->{'DATA_PATH'}; 
          }
          $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'}               = $func::allShows->{$sourceName}->{$showName}->{'episode'}->{$url}->{'name'};
          $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'}               = $func::allShows->{$sourceName}->{$showName}->{'episode'}->{$url}->{'date'};
          $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'quality'}->{'1000'}  = $func::allShows->{$sourceName}->{$showName}->{'episode'}->{$url}->{'quality'}->{'1000'};
          $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'quality'}->{'2000'}  = $func::allShows->{$sourceName}->{$showName}->{'episode'}->{$url}->{'quality'}->{'2000'};
          $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'imageUrl'}           = $func::allShows->{$sourceName}->{$showName}->{'episode'}->{$url}->{'imageUrl'};
          $main::SHOWS->{$sourceName}->{$showName}->{'episode'}->{$url}->{'text'}               = $func::allShows->{$sourceName}->{$showName}->{'episode'}->{$url}->{'text'};
        }
      }
    }
  }
 
 
  return($main::SHOWS);
}

#--------------------------------------------------
sub getIndexOfAllShows() {
# @AUTHOR:  Sven Burkard
# @DESC  :  creates a index of all shows
#--------------------------------------------------
  &getAllShowsFromZDF();

  &checkForNoLongerAvailableShows();  


  return($func::allShows);
}

#--------------------------------------------------
sub getAllShowsFromZDF() {
# @AUTHOR:  Sven Burkard
# @DESC  :  creates a index of all shows from zdf
#--------------------------------------------------
  my $sourceCode;
  my $url;
  my @lines;
  my $doIt;
  my $part;
  my $showName;

  $sourceCode->{'abc'}  = &getSourceCode('http://www.zdf.de/ZDFmediathek/hauptnavigation/sendung-a-bis-z/saz0?flash=off');
  $sourceCode->{'def'}  = &getSourceCode('http://www.zdf.de/ZDFmediathek/hauptnavigation/sendung-a-bis-z/saz1?flash=off');
  $sourceCode->{'ghi'}  = &getSourceCode('http://www.zdf.de/ZDFmediathek/hauptnavigation/sendung-a-bis-z/saz2?flash=off');
  $sourceCode->{'jkl'}  = &getSourceCode('http://www.zdf.de/ZDFmediathek/hauptnavigation/sendung-a-bis-z/saz3?flash=off');
  $sourceCode->{'mno'}  = &getSourceCode('http://www.zdf.de/ZDFmediathek/hauptnavigation/sendung-a-bis-z/saz4?flash=off');
  $sourceCode->{'pqrs'} = &getSourceCode('http://www.zdf.de/ZDFmediathek/hauptnavigation/sendung-a-bis-z/saz5?flash=off');
  $sourceCode->{'tuv'}  = &getSourceCode('http://www.zdf.de/ZDFmediathek/hauptnavigation/sendung-a-bis-z/saz6?flash=off');
  $sourceCode->{'wxyz'} = &getSourceCode('http://www.zdf.de/ZDFmediathek/hauptnavigation/sendung-a-bis-z/saz7?flash=off');
  $sourceCode->{'0-9'}  = &getSourceCode('http://www.zdf.de/ZDFmediathek/hauptnavigation/sendung-a-bis-z/saz8?flash=off');

  foreach $part(keys %{$sourceCode}){
    @lines = split("\n", $sourceCode->{$part});
    $doIt  = 0;

    foreach my $id(0 .. $#lines){
      if($lines[$id] =~ m/<div class="text">/g){
        $doIt = 1;
      }else{
        if($doIt == 1){
          if($lines[$id] =~ m/<\/div>/g){
            $doIt = 0;
          }else{
            if($lines[$id] =~ m/<a href="([^"]+)">([^<]+)<br \/>/g){
              if(defined($1)){
                if(defined($2)){
                  $showName = &clean($2);
                  $func::allShows->{'zdf'}->{$showName}->{'url'}   = "http://www.zdf.de$1";
                  $doIt   = 0;
                }else{
                  &printError("can't get a show name from zdf; layout changed?");
                  &cleanExit();
                }
              }else{
                &printError("can't get a show url from zdf; layout changed?");
                &cleanExit();
              }
            }
          }
        }
      }
    }
  }

  if(keys(%{$func::allShows->{'zdf'}}) <= 0){
    &printError("no show from zdf available; layout changed?");
    &cleanExit();
  }
}

#--------------------------------------------------
sub checkForNoLongerAvailableShows() {
# @AUTHOR:  Sven Burkard
# @DESC  :  checks for nor longer available shows
#--------------------------------------------------
  my $sourceName;
  my $showName;

  foreach $sourceName(keys %{$main::MEDIA}){
    foreach $showName(keys %{$main::MEDIA->{$sourceName}}){
      if(!exists($func::allShows->{$sourceName}->{$showName}->{'url'}) || !defined($func::allShows->{$sourceName}->{$showName}->{'url'})){
        &printError("$showName is no longer available on $sourceName. you can delete $showName from your $main::CONFIG->{'DATA_STORE_NAME_MEDIA'} list. check ./control --help");
        delete($main::MEDIA->{$sourceName}->{$showName});
      }
    }
  }
}

#--------------------------------------------------
sub getIndexOfAllEpisodesFromZDF() {
# @AUTHOR:  Sven Burkard
# @DESC  :  creates a index of all episodes from zdf
#--------------------------------------------------
  my $showName;
  my $episodeName;
  my $id;
  my @lines;
  my $doIt;
  my $id2;
  my @lines2;
  my $doIt2;
  my $doIt3;
  my $url;
  
  foreach $showName(sort keys %{$main::MEDIA->{'zdf'}}){
    @lines = split("\n", &getSourceCode($func::allShows->{'zdf'}->{$showName}->{'url'}));
    $doIt  = 0;

    foreach $id(0 .. $#lines){
      if($lines[$id] =~ m/<div class="text">/g){
        $doIt = 1;
      }else{     
        if($doIt == 1){
          if($lines[$id] =~ m/<\/div>/g){
            $doIt = 0;
          }else{     
            if($lines[$id] =~  m/<a href="(\/ZDFmediathek\/beitrag\/video\/[^"]+)">VIDEO, \d+ min/ig){
              if(defined($1)){
                $url  = "http://www.zdf.de$1";
                @lines2 = split("\n", &getSourceCode($url));
                $doIt2  = 0;
                $doIt3  = 0;
                  
                foreach $id2(0 .. $#lines2){
                  if($lines2[$id2] =~ m/<!-- StartHeadlineDesBeitrags -->/g){
                    $doIt2 = 1;
                  }else{     
                    if($doIt2 == 1){
                      if($lines2[$id2] =~ m/<!-- EndeBild&Kurzbeschreibung -->/g){
                        $doIt2 = 0;
                      }else{     
                        if($lines2[$id2] =~  m/<h1 class="beitragHeadline">([^<]+)<\/h1>/g){
                          if(defined($1)){
                            $func::allShows->{'zdf'}->{$showName}->{'episode'}->{$url}->{'name'} = &clean($1);
                          }else{
                            print STDERR "can't get the episode name of $showName ($url) from zdf; layout changed?\n";
                          }
                        }elsif($lines2[$id2] =~  m/<p class="datum">.+(\d{2})\.(\d{2})\.(\d{4})<\/p>/g){
                          if(defined($1 && $2 && $3)){
                            $func::allShows->{'zdf'}->{$showName}->{'episode'}->{$url}->{'date'} = "$3.$2.$1";
                          }else{
                            print STDERR "can't get episode date of $showName ($url) from zdf; layout changed?\n";
                          }
                        }elsif($lines2[$id2] =~  m/<img src="([^"]+)"/g){
                          if(defined($1)){
                            $func::allShows->{'zdf'}->{$showName}->{'episode'}->{$url}->{'imageUrl'} = "http://www.zdf.de$1";
                          }else{
                            print STDERR "can't get episode image of $showName ($url) from zdf; layout changed?\n";
                          }
                        }elsif($lines2[$id2] =~  m/<p class="kurztext">([^<]+)/g){
                          if(defined($1)){
                            $func::allShows->{'zdf'}->{$showName}->{'episode'}->{$url}->{'text'} = $1;
                          }else{
                            print STDERR "can't get episode text of $showName ($url) from zdf; layout changed?\n";
                          }
                        }
                      }
                    }
                  }

                  if($lines2[$id2] =~ m/<p class="player">Windows Media Player<\/p>/g){
                    $doIt3 = 1;
                  }else{     
                    if($doIt3 == 1){
                      if($lines2[$id2] =~ m/<\/ul>/g){
                        $doIt3 = 0;
                      }else{     
                        if($lines2[$id2] =~  m/<li>DSL 1000 <a href="([^"]+)"/g){
                          if(defined($1)){
                            $func::allShows->{'zdf'}->{$showName}->{'episode'}->{$url}->{'quality'}->{'1000'} = $1;
                          }else{
                            print STDERR "can't get new (DSL 1000) episode url ($showName: DSL 2000) from zdf; layout changed?\n";
                          }
                        }elsif($lines2[$id2] =~  m/<li>DSL 2000 <a href="([^"]+)"/g){
                          if(defined($1)){
                            $func::allShows->{'zdf'}->{$showName}->{'episode'}->{$url}->{'quality'}->{'2000'} = $1;
                          }else{
                            print STDERR "can't get new (DSL 2000) episode url ($showName: DSL 2000) from zdf; layout changed?\n";
                          }
                        }
                      }
                    }
                  }
                }
                if(!exists($func::allShows->{'zdf'}->{$showName}->{'episode'}->{$url}->{'quality'}->{'1000'}) || !exists($func::allShows->{'zdf'}->{$showName}->{'episode'}->{$url}->{'quality'}->{'2000'})){
                  
#                   delete($main::SHOWS->{'zdf'}->{$showName});
                }
              }
            }
          }
        }
      }
    }
  }
}

#--------------------------------------------------
sub getIndexOfAllDownloadedEpisodes() {
# @AUTHOR:  Sven Burkard
# @DESC  :  initialized subs for getting the already downloaded data; depending on $CONFIG->{'DATA_STORE_METHOD'}
#--------------------------------------------------
  my $sourceName;
  my $showName;
  my $episodeName;

  if($main::CONFIG->{'DATA_STORE_METHOD'} eq 'file'){
    $func::DONE = &getIndexOfAllDownloadedEpisodesFile();
  }elsif($main::CONFIG->{'DATA_STORE_METHOD'} eq 'db'){
    require DBI;
    $func::DONE = &getIndexOfAllDownloadedEpisodesDB();
  }

  if(keys(%{$func::DONE}) > 0){
    foreach $sourceName(sort keys %{$func::DONE}){
      foreach $showName(sort keys %{$func::DONE->{$sourceName}}){
        foreach $episodeName(sort keys %{$func::DONE->{$sourceName}->{$showName}}){
          &printDebug("DONE: $sourceName;$showName;$episodeName;$func::DONE->{$sourceName}->{$showName}->{$episodeName}");
        }
      }
    }
  }

  return($func::DONE);
}

#--------------------------------------------------
sub getIndexOfAllDownloadedEpisodesFile() {
# @AUTHOR:  Sven Burkard
# @DESC  :  gets the already downloaded data; $CONFIG->{'DATA_STORE_METHOD'} = 'file'
#--------------------------------------------------
  if(open(DONE, "< $main::CONFIG->{'DATA_STORE_NAME_DONE'}")){
    while(<DONE>){
      if($_ !~ m/^#/ && $_ =~ m/^([^;]+);([^;]+);([^;]+);([^\n]*)\n/){
#         if(defined($1 && $2 && $3) && $1 ne '' && $2 ne ''){
        if(defined($1 && $2 && $3 && $4) && $1 ne '' && $2 ne '' && $3 ne '' && $4 ne ''){
          $func::DONE->{$1}->{$2}->{$3} = $4;
        }else{
          &printError("$main::CONFIG->{'DATA_STORE_NAME_DONE'} contains invalid entrys");
          &cleanExit();
        }
      }
    }
    close(DONE);
  }else{
    &printError("can't open $main::CONFIG->{'DATA_STORE_NAME_DONE'} $main::CONFIG->{'DATA_STORE_METHOD'}");
    if(open(DONE, "> $main::CONFIG->{'DATA_STORE_NAME_DONE'}")){
      print DONE "#sourceName;showName;episodeName;date\n";
      close(DONE);
      &printDebug("$main::CONFIG->{'DATA_STORE_NAME_DONE'} $main::CONFIG->{'DATA_STORE_METHOD'} created");
    }else{
      &printError("$main::CONFIG->{'DATA_STORE_NAME_DONE'} $main::CONFIG->{'DATA_STORE_METHOD'} can not be created");
      &cleanExit();
    }
  }


  return($func::DONE);
}

#--------------------------------------------------
sub getIndexOfAllDownloadedEpisodesDB() {
# @AUTHOR:  Sven Burkard
# @DESC  :  gets the already downloaded data; $CONFIG->{'DATA_STORE_METHOD'} = 'db'
#--------------------------------------------------
  my $o_db;
  my $query;
  my $sql;
  my @result;

  if($o_db = &getDB()){
    &printDebug("db connection established");
    $query   =  "SELECT sourceName,showName,episodeName,date "; 
    $query  .=  "FROM $main::CONFIG->{'DATA_STORE_NAME_DONE'};";
    $sql     =  $o_db->prepare($query);
    if($sql->execute){
      &printDebug("reading table $main::CONFIG->{'DATA_STORE_NAME_DONE'}");
      while(@result = $sql->fetchrow_array()){ 
        $func::DONE->{$result[0]}->{$result[1]}->{$result[2]} = $result[3];
      }
    }else{
      &printError("table $main::CONFIG->{'DATA_STORE_NAME_DONE'} doesn't exists");
      $query   =  "CREATE TABLE $main::CONFIG->{'DATA_STORE_NAME_DONE'} ";
      $query  .=  "(id int auto_increment primary key, sourceName varchar(10), showName varchar(40), episodeName varchar(100), date varchar(10));"; 
      $sql     =  $o_db->prepare($query);
      if($sql->execute){
        &printDebug("table $main::CONFIG->{'DATA_STORE_NAME_DONE'} created");
      }else{
        &printError("table $main::CONFIG->{'DATA_STORE_NAME_DONE'} can't be created");
      }
    }
  }else{
    &printError("can't establish a db connection ($main::CONFIG->{'DB_IP'}), check your settings");
    &cleanExit();
  }


  return($func::DONE);
}

#--------------------------------------------------
sub getSourceCode() {
# @AUTHOR:  Sven Burkard
# @DESC  :  gets the source code of a site
#--------------------------------------------------
  my $url         = shift();
  my $ua          = new LWP::UserAgent();
  my $sourceCode;
  my $req;
  my $res;
  my $try         = 0;
  my $tryMax      = 3;

  if(defined($url) && $url ne ''){
    while($try<$tryMax){
      $try++;
      $ua->agent("Mozilla/4.0 (compatible; debian sid)");
      $req = new HTTP::Request ('GET',$url);
      $res = $ua->request($req);

      if($res->is_success){
        if($res->content ne ''){
          $sourceCode = &cleanSourceCode($res->content());
          $try  = $tryMax;
        }else{
          &printError("can't get sourceCode from $url. try $try of $tryMax");
          sleep(2);
        }
      }else{
        &printError("can't get sourceCode from $url. try $try of $tryMax");
        sleep(2);
      }
    }
    if(!defined($sourceCode) || $sourceCode eq ''){
      &printError("can't get sourceCode from $url. tried $tryMax times. perhaps the url or your internet connection is offline. please try again later.");
      &cleanExit();
    }
  }else{
    &printError("\$url is not defined.");
    &cleanExit();
  }


  return($sourceCode);
}

#--------------------------------------------------
sub cleanSourceCode() {
# @AUTHOR:  Sven Burkard
# @DESC  :  cleans the source code
#--------------------------------------------------
  my $sourceCode  = shift();

  $sourceCode =~  s/&quot;//g;
  $sourceCode =~  s/&amp;/&/g;
  $sourceCode =~  s/&auml;/ae/g;
  $sourceCode =~  s/&Auml;/Ae/g;
  $sourceCode =~  s/&ouml;/oe/g;
  $sourceCode =~  s/&Ouml;/Oe/g;
  $sourceCode =~  s/&uuml;/ue/g;
  $sourceCode =~  s/&Uuml;/Ue/g;

  return($sourceCode);
}

#--------------------------------------------------
sub clean() {
# @AUTHOR:  Sven Burkard
# @DESC  :  cleans a var
#--------------------------------------------------
  my $var  = shift();

  $var  =~  tr/a-zA-Z0-9_\-+.\//_/c;
  $var  =~  s/_$//;
  $var  =~  s/_+/_/;

  return($var);
}

1;



