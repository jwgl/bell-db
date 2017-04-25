#!/bin/sh
# https://www.itenlight.com/blog/2016/05/21/PostgreSQL+HA+with+pgpool-II+-+Part+4
# (Re)creates replication slot.
# NOTE: The script should be executed as postgres user
 
echo "create_slot - Start"
 
# Defining default values
version="9.6"
trigger_file="/etc/postgresql/$version/main/im_the_master"
slot_name=""
recreate=false
 
debug=true
 
while test $# -gt 0; do
 
    case "$1" in
 
        -h|--help)
 
            echo "Creates replication slot"
            echo " "
            echo "create_slot [options]"
            echo " "
            echo "options:"
            echo "-h, --help                show brief help"
            echo "-t, --trigger_file=FILE   specify trigger file path"
            echo "    Optional, default: $trigger_file"
            echo "-n, --name=NAME           slot name (mandatory)"
            echo "                          Slot name can be also specified without using"
            echo "                          flags (i.e. 'create_slot myslot')"
            echo "-r, --recreate            Forces re-creation if the slot already exists"
            echo "    Optional, default: N/A"
            echo "    Description:       Without this flag the script won't do anything if"
            echo "                       the slot with defined name already exists."
            echo "                       With the flag set, if the slot with defined name"
            echo "                       already exists it will be deleted and re-created."
            echo " "
            echo "Error Codes:"
            echo "  1 - Wrong user. The script has to be executed as 'postgres' user."
            echo "  2 - Argument error. Caused either by bad format of provided flags and"
            echo "      arguments or if a mandatory argument is missing."
            echo "  3 - Inapropriate trigger / standby files. This script REQUIRES trigger"
            echo "      file to be present."
            echo "  4 - Error executing a slot-related operation (query/create/drop)."
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
         
        -n)
         
            if [ "$slot_name" != "" ]; then
         
                echo "ERROR: Invalid command. For help execute 'create_slot -h'"
                exit 2
         
            fi
             
            shift
         
            if test $# -gt 0; then
         
                slot_name=$1
             
            else
             
                echo "ERROR: -n flag requires slot name to be specified."
                exit 2
             
            fi
             
            shift
            ;;
 
        --name=*)
             
            if [ "$slot_name" != "" ]; then
             
                echo "ERROR: Invalid command. For help execute 'create_slot -h'"
                exit 2
             
            fi
             
            slot_name=`echo $1 | sed -e 's/^[^=]*=//g'`
             
            shift
            ;;
 
        -r|--recreate)
 
            recreate=true
 
            shift
            ;;
 
        *)
 
            if [ "$slot_name" != "" ]; then
                 
                echo "ERROR: Invalid command. For help execute 'create_slot -h'"
                exit 2
             
            fi
             
            slot_name=$1
             
            shift
            ;;
 
    esac
 
done
 
# Ensuring that 'postgres' runs the script
if [ "$(id -u)" -ne "$(id -u postgres)" ]; then
 
    echo "ERROR: The script must be executed as 'postgres' user."
    exit 1
 
fi
 
if [ "$slot_name" = "" ]; then
 
    echo "ERROR: Slot name is mandatory. For help execute 'create_slot -h'"
    exit 2
 
fi
 
if $debug; then
 
    echo "DEBUG: The script will be executed with the following arguments:"
    echo "DEBUG: --trigger-file=${trigger_file}"
    echo "DEBUG: --name=${slot_name}"
     
    if $recreate; then
        echo "DEBUG: --recreate"
    fi
     
fi
 
echo "Checking if trigger file exists..."
if [ ! -e $trigger_file ]; then
 
    echo "ERROR: Cannot create replication slot if the server does not contain trigger file: ${trigger_file}"
    exit 3
     
fi
 
success=false
 
echo "INFO: Checking if slot '${slot_name}' exists..."
slotcount=$(psql -Atc "SELECT count (*) FROM pg_replication_slots WHERE slot_name='${slot_name}';") && success=true
 
if ! $success ; then
 
    echo "ERROR: Cannot check for '${slot_name}' slot existence."
    exit 4
 
fi
 
if [ "$slotcount" = "0" ]; then
 
    echo "INFO: Slot not found. Creating..."
 
    success=false
    psql -c "SELECT pg_create_physical_replication_slot('${slot_name}');" && success=true
         
    if ! $success ; then
 
        echo "ERROR: Cannot create '${slot_name}' slot."
        exit 4
 
    fi
 
elif $recreate ; then
 
    echo "INFO: Slot found. Removing..."
 
    success=false
    psql -c "SELECT pg_drop_replication_slot('${slot_name}');" && success=true
     
    if ! $success ; then
 
        echo "ERROR: Cannot drop existing '${slot_name}' slot."
        exit 4
 
    fi
 
    echo "INFO: Re-creating the slot..."
 
    success=false
    psql -c "SELECT pg_create_physical_replication_slot('${slot_name}');" && success=true
     
    if ! $success ; then
 
        echo "ERROR: Cannot create '${slot_name}' slot."
        exit 4
 
    fi
 
fi
 
echo "create_slot - Done!"
exit 0

