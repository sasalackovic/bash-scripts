#!/bin/bash

#########################################################################################
# Bash script to create a backup of a directory with a dump of a whole MySQL database   #
# Author: Sasa Lackovic, 11.02.2008.                                                     #
#########################################################################################

# Directories and files to backup
folder2backup[1]="/var/www/balky"
#folder2backup[2]="/var/www/student-play"

# Directory in which a TAR backup archive will be saved
backup_folder="/root/backup_temp"

# Mail that will receive an error report
admin_mail="sasa.lackovic@bak.hr"
from_mail="backup@balky.bak.hr"

# Current day in a week
#day=`date '+%A'`
day=`date +%Y%m%d`

# Backup file name
prefix="backup-balky-$day"

# Willit dump a MySQL and a PostgreSQL databases? (0 - no; 1 - yes)
mysql_dump=1
postgresql_dump=0
# Directory where it will dumb databases
mysql_dump_dir=$backup_folder
postgresql_dump_dir=$backup_folder

# MySQL database names that will be dumped
#mysql_databases="balky student-play"
mysql_databases="balky"

# MySQL user i password (to MySQL a database)
mysql_user='balky'
mysql_pass='XXXXXXXX'

# PostgreSQL dump
postgres_user=postgres

##############################################################
## Do not touch nothing beneath this line unless neccessary ##
##############################################################

# Function that logs the backup status
logit()
{
        echo `date "+%F %T"`" --- $1"
}

if [ -z "$backup_folder" ]; then
        logit "Variable 'backup_folder' must contain directory name!"
        `echo -en "From: $from_mail\nTo: $admin_mail\nSubject: Backup error\n\nInvalid value of the variable backup_folder\n" | sendmail -t`
        exit 1
fi

if [ ! -d "$backup_folder" ]; then
        logit "ERROR: directory $backup_folder doesn't exist!"
        `echo -en "From: $from_mail\nTo: $admin_mail\nSubject: Backup error\n\nERROR: directory $backup_folder does not exist\n" | sendmail -t`
        exit 1;
fi

logit "Backup started."

# MySQL dump
if [ $mysql_dump = 1 ]; then
        if [ ! -d "$mysql_dump_dir" ]; then
                logit "ERROR: directory $mysql_dump_dir doesn't exist. Can't dump MySQL databases!"
                `echo -en "From: $from_mail\nTo: $admin_mail\nSubject: Backup error\n\ndirectory '$mysql_dump_dir' doesn't exist\n" | sendmail -t`
                exit 1
        else
                dumped_mysql_file="$mysql_dump_dir/mysql_dump.sql"

                # If a variable $mysql_databases contains database names, don't dump all databases
                if [ -n "$mysql_databases" ]; then
                        logit "Dumping MySQL databases '$mysql_databases'..."
                        mysqldump -u $mysql_user --password=$mysql_pass --databases $mysql_databases > "$dumped_mysql_file"
                else
                        logit "Dumping *ALL* MySQL databases..."
                        mysqldump --all-databases -u $mysql_user --password=$mysql_pass > "$dumped_mysql_file"
                        fi
        fi
fi

# PostgreSQL dump
if [ $postgresql_dump = 1 ]; then
        if [ ! -d "$postgresql_dump_dir" ]; then
                logit "ERROR: directory $postgresql_dump_dir doesn't exist! Can't dump PostrgeSQL databases!"
                `echo -en "From: $from_mail\nTo: $admin_mail\nSubject: Backup error\n\nDirectory '$mysql_dump_dir' doesn't exist!\n" | sendmail -t`
                exit 1
        else
                logit "Dumping PostgreSQL databases..."
                dumped_postgresql_file="$postgresql_dump_dir/all_postgresql_databases.dmp"
                pg_dumpall -U postgres > "$dumped_postgresql_file"
        fi
fi

element_count=${#folder2backup[@]}
logit "Compression of $element_count directories/files started..."

if [ -e "$dumped_mysql_file" ]; then
        files2tar="$dumped_mysql_file"
fi
if [ -e "$dumped_postgresql_file" ]; then
        files2tar="$files2tar $dumped_postgresql_file"
fi

x=1
succ_dirs=0
failed_dirs=
while [ $x -le $element_count ]
do
        dir_error=0
        if [ ! -d "${folder2backup[$x]}" ] && [ ! -f "${folder2backup[$x]}" ]; then
                logit "WARNING: Directory/file '${folder2backup[$x]}' doesn't exist. Moving on with compression..."
                failed_dirs="$failed_dirs, ${folder2backup[$x]}"
        else
                logit "Compressing folder ${folder2backup[$x]}"
                files2tar="$files2tar ${folder2backup[$x]}"
                succ_dirs=$((succ_dirs+1))
        fi

        x=$((x+1))
done

if [ $succ_dirs -lt $element_count ]; then
        logit "WARNING: Some directories were not backuped!"
fi

tar cfz "$backup_folder/$prefix.tar.gz" $files2tar

rm -f $dumped_mysql_file
rm -f $dumped_postgresql_file

logit "Backup finished. TAR file is located in $backup_folder/$prefix.tar.gz


"
