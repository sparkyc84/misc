#!/bin/bash
# A script for managing automatic updates to WordPress with wp-cli
# written by Chris Sparks
wp_path=/var/www/html/
date=$(date +%Y-%m-%d)
timestamp=$(date +%Y-%m-%d--%H-%M-%S)
backup_path=~/wp-backups
mkdir -p ~/$backup_path/$date/
filename=~/$backup_path/$date/projects-wp-db-$timestamp.sql
wp db export $filename  --path=$wp_path --add-drop-table
gzip $filename
wp core update --minor --path=$wp_path
wp core update-db --path=$wp_path
wp core update-db --network --path=$wp_path
removal_dirs=$(find $backup_path -mtime +30 -type d | grep -P "^$backup_path/[0-9]{4}-[0-9]{2}-[0-9]{2}$")
rm -rf $removal_dirs
#wp plugin update --all --path=$wp_path
#wp theme update --all --path=$wp_path
