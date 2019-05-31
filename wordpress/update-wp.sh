#!/bin/bash

PATH=/usr/local/bin:$PATH
export PATH
wp_path=/var/www/html
backup_path=~/wp-backups
themes=0
plugins=0
silent=0
path_env=
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
bold=`tput bold`
reset=`tput sgr0`

while :; do
  case $1 in
    -h|-\?|--help)
      echo -e "${bold}USAGE:${reset} update-wp [<options>]

${bold}SYNOPSIS${reset}
Attempts to update the WordPress install at the specified path (defaulting to /var/www/html).  Can also optionally update themes and plugins.  The script will try to install wp-cli if it cannot be found.

${bold}OPTIONS${reset}
    --path_env=<paths>
	Specify additional paths to look for executables in.  Equvalent to eport PATH=<path>:$PATH.
    --wp_path=<path>
        Specify the path to the WordPress install.  Defaults to /var/www/html if not provided.
    --backup_path=<path>
        Specify the path to your backup directory.  Defaults to ~/wp-backups if not provided.
    --themes
	Attempt to download and install theme updates.
    --plugins
	Attempt to download and install plugin updates.
    --silent
        Do not raise any promtps, just accept defaults.
"
      exit
      ;;
    --path_env)       # takes an option argument; ensure it has been specified.
      if [ "$2" ]; then
        path_env=$2
        export PATH=$path_env:$PATH
        shift
      else
        die "${red}Error${reset}: '--path_env' requires a non-empty option argument."
      fi
      ;;
    --path_env=?*)
      path_env=${1#*=} # delete everything up to "=" and assign the remainder.
      export PATH=$path_env:$PATH
      ;;
    --path_env=)         # handle the case of an empty --file=
      die "${red}Error${reset}: '--path_env' requires a non-empty option argument."
      ;;
    --wp_path)       # takes an option argument; ensure it has been specified.
      if [ "$2" ]; then
        file=$2
        shift
      else
        die "${red}Error${reset}: '--path_env' requires a non-empty option argument."
      fi
      ;;
    --wp_path=?*)
      file=${1#*=} # delete everything up to "=" and assign the remainder.
      ;;
    --wp_path=)         # handle the case of an empty --file=
        die "${red}Error${reset}: '--wp_path' requires a non-empty option argument."
      ;;
    --backup_path)       # takes an option argument; ensure it has been specified.
      if [ "$2" ]; then
        file=$2
        shift
      else
        die "${red}Error${reset}: '--backup_path' requires a non-empty option argument."
      fi
      ;;
    --backup_path=?*)
      file=${1#*=} # delete everything up to "=" and assign the remainder.
      ;;
    --backup_path=)         # handle the case of an empty --file=
        die "${red}Error${reset}: '--backup_path' requires a non-empty option argument."
      ;;
    --themes)       # takes an option argument; ensure it has been specified.
      themes=1
      ;;
    --plugins)       # takes an option argument; ensure it has been specified.
      plugins=1
      ;;
    --silent)       # takes an option argument; ensure it has been specified.
      silent=1
      ;;
    -?*)
      printf "${yellow}Warn${reset}: unknown option (ignored): %s\n" '$1' >&2
      ;;
    *)               # default case: no more options, so break out of the loop.
      break
  esac

  shift
done
if ! [ -x "$(command -v update-wp)" ] && [ "${silent}" -eq "0" ]; then
  read -e -r -p "${yellow}Warning:${reset} This script (update-wp) does not appear to be installed in /usr/local/bin. Would you like me to try to add it there (will prompt for sudo password)?
[y/N]:" response
  case "$response" in
    [yY][eE][sS]|[yY])
      update_wp="$0"
      chmod +x ${update_wp}
      if ! sudo mv ${update_wp} /usr/local/bin/update-wp; then
        echo -e "${yellow}Warning:${reset} Could not self-install to /usr/local/bin/update-wp"
      fi
      ;;
    *)
      # do nothing
      ;;
  esac
fi
if ! [ -x "$(command -v wp)" ]; then
    echo -e "${blue}Info:${reset} Can't find wp-cli, trying to install."
  cd ~/
  if ! curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; then
    echo -e "${red}Error:${reset} failed to download wp-cli  Do you have write permissions to the current directory?"
    exit 1
  fi
  if ! chmod +x wp-cli.phar; then
    echo -e "${red}Error:${reset} failed to make wp-cli executable."
    exit 1
  fi
  echo -e "${yellow}Warning:${reset} About to try to copy wp-cli to /user/local/bin/wp -- this will prompt for your sudo password."
  if ! sudo mv wp-cli.phar /usr/local/bin/wp; then
    echo -e "${red}Error:${reset} failed to install wp-cli."
    exit 1
  fi
fi
response=
crons=`crontab -l | grep \`which update-wp\` -c`
if [ "${crons}" -eq "0" ]  && [ "${silent}" -eq "0" ]; then
  read -e -r -p "${blue}Info:${reset} It doesn't look like you have any crontabs. Would you like me to install one?
[y/N]:" response
  case "$response" in
    [yY][eE][sS]|[yY])
      which update-wp
      if [ "$?" -eq "0" ]; then
        cron_cmd=`which update-wp`
      else
        cron_cmd="$0"
      fi
      cron_cmd="${cron_cmd} --silent --wp_path=${wp_path} --backup_path=${backup_path} --path_env=${path_env}"
      response=
      read -e  -r -p"${blue}Info:${reset} Do you want to include themes?
[y/N]:" response
      case "$response" in
        [yY][eE][sS]|[yY])
          cron_cmd="${cron_cmd} --themes"
          ;;
        *)
          ;;
      esac
      response=
      read -e  -r -p"${blue}Info:${reset} Do you want to include plugins?
[y/N]:" response
      case "$response" in
        [yY][eE][sS]|[yY])
          cron_cmd="${cron_cmd} --plugins"
          ;;
        *)
          ;;
      esac
      if ! ( crontab -l || true ; echo "@daily $cron_cmd" ) | crontab -; then
        echo -e "${yellow}Warning:${reset} Could not install a crontab"
      fi
      ;;
    *)
      # do nothing
      ;;
  esac
fi
if !  wp core is-installed --path=$wp_path ; then
  echo -e "${red}Error:${reset} Could not find a WordPress install at ${wp_path}."
  exit 1
fi
date=$(date +%Y-%m-%d)
timestamp=$(date +%Y-%m-%d--%H-%M-%S)
if !  mkdir -p $backup_path/$date/; then
  echo -e "${red}Error:${reset} Could not create backup directory at ${backup_path}."
  exit 1
else
  echo -e "${green}Success:${reset} Created backup directory at ${backup_path}."
fi
removal_dirs=$(find $backup_path -mtime +30 -type d | grep -P "^$backup_path/[0-9]{4}-[0-9]{2}-[0-9]{2}$")
if [${removal_dirs// } -eq ""]; then 
  echo -e "${blue}Info:${reset} Could not find any old backup files to delete."
else
  if ! rm -rf $removal_dirs; then
    echo -e "${yellow}Warning:${reset} Could not delete old backup files ${removal_dirs}.  Make sure you don't run out of disk space."
  else
    echo -e "${green}Success:${reset} Deleted old backup files ${removal_dirs}."
  fi
fi
filename=$backup_path/$date/${HOSTNAME}${wp_path////_}-wp-db-$timestamp.sql
wp db export $filename  --path=$wp_path --add-drop-table
if ! gzip $filename; then
  echo -e "${yellow}Warning:${reset} Could not compress the backup file. Make sure you don't disk space."
wp core update --minor --path=$wp_path
fi
if  wp core is-installed --path=$wp_path --network; then
    echo -e "${blue}Info:${reset} WordPress seemes to be a network install - updating the database across the network"
  wp core update-db --path=$wp_path --network
else
  echo -e "${blue}Info:${reset} WordPress seemes to be a single-site install - updating the database for one site"
  wp core update-db --path=$wp_path
fi
if [ "$plugins" -eq "1" ]; then
  echo -e "${blue}Info:${reset} Attempting to update plugins \n"
  wp plugin update --all --path=$wp_path
fi
if [ "$themes" -eq "1" ]; then
  echo -e "${blue}Info:${reset} Attempting to update themes \n"
  wp theme update --all --path=$wp_path
fi  
