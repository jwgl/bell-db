#!/bin/sh
# https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+4
# Stopping and disabling postgresql service if running
# NOTE: The script should be executed as postgres user
 
echo "disable_postgresql - Start"
 
# Defining default values
version="9.6"
trigger_file="/etc/postgresql/$version/main/im_the_master"
standby_file="/etc/postgresql/$version/main/im_slave"
conf_file="/etc/postgresql/$version/main/postgresql.conf"
recovery_file="/var/lib/postgresql/$version/main/recovery.conf"
primary_info="/var/lib/postgresql/$version/main/primary_info"

while test $# -gt 0; do
 
    case "$1" in
 
        -h|--help)
 
            echo "Disables PostgreSQL"
            echo " "
            echo "disable_postgresql [options]"
            echo " "
            echo "options:"
            echo "-h, --help                show brief help"
            echo "-t, --trigger_file=FILE   specify trigger file path"
            echo "    Optional, default: $trigger_file"
            echo "-s, --standby_file=FILE   specify standby file path"
            echo "    Optional, default: $standby_file"
            echo " "
            echo "Error Codes:"
            echo "  1 - Wrong user. The script has to be executed as 'postgres' user."
            echo "  2 - Argument error. Caused either by bad format of provided flags and"
            echo "      arguments or if a mandatory argument is missing."
            exit 0
            ;;
 
        -t)
 
            shift
 
            if test $# -gt 0; then
 
                trigger_file=$1
             
            else
             
                echo "ERROR: -t flag requires trigger file to be specified."
                exit 2
             
            fi
             
            shift
            ;;
         
        --trigger-file=*)
         
            trigger_file=`echo $1 | sed -e 's/^[^=]*=//g'`
         
            shift
            ;;
         
        -s)
         
            shift
         
            if test $# -gt 0; then
         
                standby_file=$1
         
            else
         
                echo "ERROR: -s flag requires standby file to be specified."
                exit 2
         
            fi
         
            shift
            ;;
         
        --standby-file=*)
         
            standby_file=`echo $1 | sed -e 's/^[^=]*=//g'`
         
            shift
            ;;
         
        *)
         
            echo "ERROR: Unrecognized option $1"
            exit 2
            ;;
 
    esac
     
done
 
# Ensuring that 'postgres' runs the script
if [ "$(id -u)" -ne "$(id -u postgres)" ]; then
 
    echo "ERROR: The script must be executed as 'postgres' user."
    exit 1
 
fi
 
echo "INFO: Stopping postgresql service..."
service postgresql stop
 
# Moving postgresql.conf file in order to prevent service to be started
if [ -f $conf_file ]; then
 
    if [ -f $conf_file.disabled ]; then
        rm $conf_file.disabled
    fi
 
    echo "INFO: Renaming postgresql.conf file to prevent future service start."
    mv $conf_file $conf_file.disabled
 
fi
 
# Deleting recovery.conf file
echo "INFO: Checking if recovery.conf file exists..."
if [ -f $recovery_file ]; then
 
    echo "INFO: recovery.conf file found. Deleting..."
     
    rm $recovery_file
fi
 
# Deleting trigger file
echo "INFO: Checking if trigger file exists..."
if [ -f $trigger_file ]; then
 
    echo "INFO: Trigger file found. Deleting..."
    rm $trigger_file
 
fi
 
# Deleting standby file
echo "INFO: Checking if standby file exists..."
if [ -f $standby_file ]; then
 
    echo "INFO: Standby file found. Deleting..."
    rm $standby_file
 
fi
 
# Deleting primary info file
echo "INFO: Checking if primary info file exists..."
if [ -f $primary_info ]; then
 
    echo "INFO: primary_info file found. Deleting..."
    rm $primary_info
 
fi
 
echo "disable_postgresql - Done!"
exit 0

