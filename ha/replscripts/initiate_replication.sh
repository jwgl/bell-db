#!/bin/sh
# https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+4
# Promoting standby to primary node.
# NOTE: The script should be executed as postgres user
 
echo "initiate_replication - Start"
 
# Defining default values
version="9.6"
trigger_file="/etc/postgresql/$version/main/im_the_master"
standby_file="/etc/postgresql/$version/main/im_slave"
pgpass_file="/var/lib/postgresql/.pgpass"
create_slot_script="/etc/postgresql/$version/main/replscripts/create_slot.sh"
main_dir="/var/lib/postgresql/$version/main"
recovery_conf="/var/lib/postgresql/$version/main/recovery.conf"
postgresql_conf="/etc/postgresql/$version/main/postgresql.conf"
postgresql_conf_standby="/etc/postgresql/$version/main/repltemplates/postgresql.conf.standby"
primary_host=""
primary_port="5433"
slot_name=$(echo "$HOSTNAME" | tr '[:upper:]' '[:lower:]')
slot_name=${slot_name/-/_}
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
            echo "-H, --primary-host=HOST   specify primary host (Mandatory)"
            echo "-P, --primary-port=PORT   specify primary port"
            echo "    Optional, default: 5432"
            echo "-n, --slot_name=NAME      specify slot name"
            echo "    Optional, defaults to lowercase hostname with dashes replaced"
            echo "                          by underscores."
            echo "-u, --user                specify replication role"
            echo "    Optional, default: replication"
            echo "-p, --password=PASSWORD   specify password for --user"
            echo "    Optional, default: empty"
            echo "-f, --force               Forces promotion regardless to"
            echo "                          trigger / standby files."
            echo "    Optional, default: N/A"
            echo "    Description:       Without this flag the script will require"
            echo "                       presence of standby file."
            echo "                       With the flag set the script will create"
            echo "                       standby file as needed."
            echo " "
            echo "Error Codes:"
            echo "  1 - Wrong user. The script has to be executed as 'postgres' user."
            echo "  2 - Argument error. Caused either by bad format of provided flags and"
            echo "      arguments or if a mandatory argument is missing."
            echo "  3 - Inapropriate trigger / standby files. See -f flag for details."
            echo "  4 - Error creating/deleting/copying configuration files"
            echo "      (postgresql.conf and recovery.conf)."
            echo "      Hint: ensure that templates exist and check permissions."
            echo "  5 - Error in communicating with the primary server (to create the"
            echo "      slot or get the initial data)."
            echo "  6 - Error deleting old data directory."
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
 
        -H)
 
            shift
 
            if test $# -gt 0; then
 
                primary_host=$1
 
            else
 
                echo "ERROR: -H flag requires primary host to be specified."
                exit 2
 
            fi
 
            shift
            ;;
 
        --primary-host=*)
 
            primary_host=`echo $1 | sed -e 's/^[^=]*=//g'`
 
            shift
            ;;
 
        -P)
 
            shift
 
            if test $# -gt 0; then
 
                primary_port=$1
 
            else
 
                echo "ERROR: -p flag requires port to be specified."
                exit 2
 
            fi
 
            shift
            ;;
 
        --primary-port=*)
 
            primary_port=`echo $1 | sed -e 's/^[^=]*=//g'`
 
            shift
            ;;
 
        -n)
 
            shift
 
            if test $# -gt 0; then
 
                slot_name=$1
 
            else
 
                echo "ERROR: -n flag requires slot name to be specified."
                exit 2
 
            fi
 
            shift
            ;;
 
        --slot-name=*)
 
            slot_name=`echo $1 | sed -e 's/^[^=]*=//g'`
 
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
 
if [ "$primary_host" = "" ]; then
 
    echo "ERROR: Primary host is mandatory. For help execute 'initiate_replication -h'"
    exit 2
 
fi
 
if [ "$replication_password" = "" ]; then
 
    echo "ERROR: --password is mandatory. For help execute 'initiate_replication -h'"
    exit 2
 
fi
 
if $debug; then
 
    echo "DEBUG: The script will be executed with the following arguments:"
    echo "DEBUG: --trigger-file=$trigger_file"
    echo "DEBUG: --standby_file=$standby_file"
    echo "DEBUG: --primary-host=$primary_host"
    echo "DEBUG: --primary-port=$primary_port"
    echo "DEBUG: --slot-name=$slot_name"
    echo "DEBUG: --user=$replication_user"
    echo "DEBUG: --password=$replication_password"
 
    if $force; then
        echo "DEBUG: --force"
    fi
 
fi
 
echo "INFO: Checking if trigger file exists..."
if [ -e $trigger_file ]; then
 
    if $force; then
 
        echo "INFO: Trigger file found. Deleting..."
        rm $trigger_file
 
    else
 
        echo "ERROR: Cannot initiate server as standby while it contains trigger file: ${trigger_file}"
        exit 3
 
    fi
     
fi
 
echo "INFO: Checking if standby file exists..."
if [ ! -e $standby_file ]; then
 
    if $force; then
 
        echo "INFO: Standby file not found. Creating new one..."
        echo "Initiated at: $(date)" >> $standby_file
 
    else
 
        echo "ERROR: Cannot initiate server as standby if it does not contain standby file: ${standby_file}"
        exit 3
 
    fi
     
fi
 
echo "INFO: Ensuring replication user and password in password file (.pgpass)..."
password_line="*:*:*:${replication_user}:${replication_password}"
 
if [ ! -f $pgpass_file ]; then
 
    echo $password_line >> $pgpass_file
 
elif ! grep -q "$password_line" $pgpass_file ; then
 
    sed -i -e '$a\' $pgpass_file
    echo $password_line >> $pgpass_file
    sed -i -e '$a\' $pgpass_file
 
fi
 
chown postgres:postgres $pgpass_file
chmod 0600 $pgpass_file
 
success=false
 
echo "INFO: Creating replication slot at the primary server..."
ssh -T postgres@$primary_host $create_slot_script -r $slot_name && success=true
 
if ! $success ; then
 
    echo "ERROR: Creating replication slot at the primary server failed."
    exit 5
 
fi
 
service postgresql stop
 
if [ -d $main_dir ]; then
 
    echo "INFO: Deleting old data..."
 
    success=false      
    rm -rf $main_dir && success=true
 
    if ! $success ; then
 
        echo "ERROR: Deleting data directory failed."
        exit 6
 
    fi
 
fi
 
echo "INFO: Getting the initial backup..."
 
success=false
pg_basebackup -D $main_dir -h $primary_host -p $primary_port -U $replication_user && success=true
 
if ! $success; then
 
    echo "ERROR: Initial backup failed."
    exit 5
 
fi
 
if [ -e $recovery_conf ]; then
 
    echo "INFO: Removing old recovery.conf file..."
 
    success=false
    rm $recovery_conf && success=true
 
    if ! $success; then
 
        echo "ERROR: Removing old recovery.conf failed."
        exit 4
 
    fi
 
fi
 
echo "INFO: Creating recovery.conf file..."
cat >$recovery_conf <<EOL
standby_mode       = 'on'
primary_conninfo   = 'user=${replication_user} password=${replication_password} host=${primary_host} port=${primary_port} sslmode=prefer sslcompression=1 krbsrvname=postgres'
primary_slot_name  = '${slot_name}'
trigger_file       = '${trigger_file}'
EOL
 
chown postgres:postgres $recovery_conf
chmod 0644 $recovery_conf
 
if [ -e $postgresql_conf ]; then
 
    echo "INFO: Removing old postgresql.conf file..."
 
    success=false
    rm $postgresql_conf && success=true
 
    if ! $success; then
 
        echo "ERROR: Removing old postgresql.conf failed."
        exit 4
 
    fi
 
fi
 
echo "INFO: Copying new postgresql.conf file..."
 
success=false
cp $postgresql_conf_standby $postgresql_conf && success=true
 
if ! $success; then
 
    echo "ERROR: Copying new postgresql.conf failed."
    exit 4
 
fi
 
chown postgres:postgres $postgresql_conf
chmod 0644 $postgresql_conf
 
echo "INFO: Starting postgresql service..."
service postgresql start
 
echo "initiate_replication - Done!"
exit 0

