#!/bin/sh
# https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+4
# Promoting standby to primary node
# NOTE: The script should be executed as postgres user
 
echo "promote - Start"
 
# Defining default values
version="9.6"
trigger_file="/etc/postgresql/$version/main/im_the_master"
standby_file="/etc/postgresql/$version/main/im_slave"
disable_script="/etc/postgresql/$version/main/replscripts/disable_postgresql.sh"
recovery_conf="/var/lib/postgresql/$version/main/recovery.conf"
postgresql_conf="/etc/postgresql/$version/main/postgresql.conf"
postgresql_conf_primary="/etc/postgresql/$version/main/repltemplates/postgresql.conf.primary"
primary_info="/var/lib/postgresql/$version/main/primary_info"

demote_host=""
replication_user="replication"
replication_password=""
force=false
 
debug=true
 
while test $# -gt 0; do
 
    case "$1" in
     
        -h|--help)
     
            echo "Promotes a standby server to primary role"
            echo " "
            echo "promote [options]"
            echo " "
            echo "options:"
            echo "-h, --help                show brief help"
            echo "-t, --trigger_file=FILE   specify trigger file path"
            echo "    Optional, default: $trigger_file"
            echo "-s, --standby_file=FILE   specify standby file path"
            echo "    Optional, default: $standby_file"
            echo "-d, --demote=HOST         specify old primary to demote"
            echo "    Optional, if not specified no demotion will be performed."
            echo "-u, --user                specify replication role"
            echo "    Optional, default: replication"
            echo "-p, --password=PASSWORD   specify password for --user (mandatory)"
            echo "-f, --force               Forces promotion regardless of existence"
            echo "                          of trigger / standby files."
            echo "    Optional, default: N/A"
            echo "    Description:       Without this flag the script will require"
            echo "                       presence of trigger file."
            echo "                       With the flag set the script will create"
            echo "                       trigger file as needed."
            echo " "
            echo "Error Codes:"
            echo "  1 - Wrong user. The script has to be executed as 'postgres' user."
            echo "  2 - Argument error. Caused either by bad format of provided flags and"
            echo "      arguments or if a mandatory argument is missing."
            echo "  3 - Inapropriate trigger / standby files. See -f flag for details."
            echo "  4 - Error creating/deleting/copying configuration files"
            echo "      (postgresql.conf and recovery.conf)."
            echo "      Hint: ensure that templates exist and check permissions."
            echo "  5 - Error creating / altering replication_user."
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
 
        -d)
 
            shift
 
            if test $# -gt 0; then
 
                demote_host=$1
 
            else
 
                echo "ERROR: -d flag requires host that will be demoted to be specified."
                exit 2
 
            fi
 
            shift
            ;;
        --demote-host=*)
 
            demote_host=`echo $1 | sed -e 's/^[^=]*=//g'`
 
            shift
            ;;
 
        -u)
 
            shift
 
            if test $# -gt 0; then
 
                replication_user=$1
 
            else
 
                echo "ERROR: -u flag requires replication user to be specified."
                exit 2
 
            fi
 
            shift
            ;;
        --user=*)
 
            replication_user=`echo $1 | sed -e 's/^[^=]*=//g'`
 
            shift
            ;;
        -p)
 
            shift
 
            if test $# -gt 0; then
 
                replication_password=$1
 
            else
 
                echo "ERROR: -p flag requires replication password to be specified."
                exit 2
 
            fi
 
            shift
            ;;
 
        --password=*)
 
            replication_password=`echo $1 | sed -e 's/^[^=]*=//g'`
 
            shift
            ;;
 
        -f|--force)
 
            force=true
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
 
if [ "$replication_password" = "" ]; then
 
    echo "ERROR: --password is mandatory. For help execute 'promote -h'"
    exit 2
 
fi
 
if $debug; then
 
    echo "DEBUG: The script will be executed with the following arguments:"
    echo "DEBUG: --trigger-file=$trigger_file"
    echo "DEBUG: --standby_file=$standby_file"
    echo "DEBUG: --demote-host=$demote_host"
    echo "DEBUG: --user=$replication_user"
    echo "DEBUG: --password=$replication_password"
 
    if $force; then
        echo "DEBUG: --force"
    fi
 
fi
 
echo "INFO: Checking if standby file exists..."
if [ -e $standby_file ]; then
 
    if $force; then
 
        echo "INFO: Standby file found. Deleting..."
        rm $standby_file
 
    else
 
        echo "ERROR: Cannot promote server that contains standby file: ${standby_file}"
        exit 3
 
    fi
     
fi
 
echo "INFO: Checking if trigger file exists..."
if [ ! -e $trigger_file ]; then
 
    if $force; then
 
        echo "INFO: Trigger file not found. Creating a new one..."
        echo "Promoted at: $(date)" >> $trigger_file
 
    else
 
        echo "ERROR: Cannot promote server that does not contain trigger file: ${trigger_file}"
        exit 3
 
    fi
     
fi
 
success=false
 
# Disabling postgresql on demote host (if specified):
if [ "$demote_host" != "" ]; then
 
    echo "INFO: Trying to disable postgresql at ${demote_host}..."
    ssh -T postgres@$demote_host $disable_script -t $trigger_file -s $standby_file && success=true
 
    if ! $success ; then
        echo "WARNING: Failed to execute 'disable_postgresql.sh' at demoted host."
    fi
     
fi
 
if [ -e $recovery_conf ]; then
     
    echo "INFO: Deleting recovery.conf file..."
 
    success=false
    rm $recovery_conf && success=true
     
    if ! $success ; then
 
        echo "ERROR: Failed to delete '$recovery_conf'."
        exit 4
 
    fi
     
fi
 
echo "INFO: Checking if postgresql.conf file exists..."
if [ -e $postgresql_conf ]; then
 
    echo "INFO: postgresql.conf file found. Checking if it is for primary server..."
    if diff $postgresql_conf $postgresql_conf_primary >/dev/null ; then
     
        echo "INFO: postgresql.conf file corresponds to primary server file. Nothing to do."
         
    else
     
        echo "INFO: postgresql.conf file does not correspond to primary server file. Deleting..."
 
        success=false
        rm $postgresql_conf && success=true
             
        if ! $success ; then
 
            echo "ERROR: Failed to delete '$postgresql_conf' file."
            exit 4
 
        fi
         
        echo "INFO: Copying new postgresql.conf file..."
 
        success=false
        cp $postgresql_conf_primary $postgresql_conf && success=true
         
        if ! $success ; then
 
            echo "ERROR: Failed to copy new postgresql.conf file."
            exit 4
 
        fi
         
        if service postgresql status ; then
             
            echo "INFO: Restarting postgresql service..."
            service postgresql restart
 
        fi
         
    fi
     
else
 
    echo "INFO: postgresql.conf file not found. Copying new one..."
 
    success=false
    cp $postgresql_conf_primary $postgresql_conf && success=true
     
    if ! $success ; then
 
        echo "ERROR: Failed to copy new postgresql.conf file."
        exit 4
 
    fi
 
    if service postgresql status ; then
         
        echo "INFO: Restarting postgresql service..."
        service postgresql restart
 
    fi
     
fi
 
if service postgresql status ; then
 
    echo "INFO: postgresql already running."
     
else
 
    echo "INFO: Starting postgresql service..."
    service postgresql start
 
fi
 
echo "INFO: Ensuring replication role and password..."
 
success=false
rolecount=$(psql -Atc "SELECT count (*) FROM pg_roles WHERE rolname='${replication_user}';") && success=true
 
if ! $success ; then
 
    echo "ERROR: Failed to check existence of '${replication_user}' role."
    exit 5
 
fi
 
if [ "$rolecount" = "0" ]; then
 
    echo "INFO: Replication role not found. Creating..."
 
    success=false
    psql -c "CREATE ROLE ${replication_user} WITH REPLICATION PASSWORD '${replication_password}' LOGIN;" && success=true
 
    if ! $success ; then
 
        echo "ERROR: Failed to create '${replication_user}' role."
        exit 5
 
    fi
 
else
 
    echo "INFO: Replication role found. Ensuring password..."
 
    success=false
    psql -c "ALTER ROLE ${replication_user} WITH REPLICATION PASSWORD '${replication_password}' LOGIN;" && success=true
 
    if ! $success ; then
 
        echo "ERROR: Failed to set password for '${replication_user}' role."
        exit 5
 
    fi
 
fi
 
echo "INFO: Creating primary info file..."
if [ -e $primary_info ]; then
    rm $primary_info
fi
 
echo "REPL_USER=${replication_user}\nREPL_PASSWORD=${replication_password}\nTRIGGER_FILE=${trigger_file}\nSTANDBY_FILE=${standby_file}\n" >> $primary_info
 
chown postgres:postgres $primary_info
chmod 0600 $primary_info
 
echo "promote - Done!"
exit 0

