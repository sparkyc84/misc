#!/bin/bash
# A script for managing automatic updates to WordPress with wp-cli. 
# The script assumes you have wp_cli aliased to wp and in your PATH.
# It creates a backup before running updates
# remove the --network flags if running single-site install of WordPress (i.e. not multisite)
# Written by Chris Sparks
wp_path=/var/www/html/
backup_path=~/wp-backups
date=$(date +%Y-%m-%d)
timestamp=$(date +%Y-%m-%d--%H-%M-%S)
# delete old backups
removal_dirs=$(find $backup_path -mtime +30 -type d | grep -P "^$backup_path/[0-9]{4}-[0-9]{2}-[0-9]{2}$")
rm -rf $removal_dirs
# create new backup
mkdir -p ~/$backup_path/$date/
filename=~/$backup_path/$date/projects-wp-db-$timestamp.sql
wp db export $filename  --path=$wp_path --add-drop-table
gzip $filename
# run minor updates to WordPress, and upgrade the database
wp core update --minor --path=$wp_path
wp core update-db --path=$wp_path
wp core update-db --network --path=$wp_path
# optional lines for automatic updates of themes/plugins - not recommended - can break WP
#wp plugin update --all --path=$wp_path
#wp theme update --all --path=$wp_path
