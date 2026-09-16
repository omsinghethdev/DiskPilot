SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
source ${SCRIPT_DIR}/../lib/log.sh
source ${SCRIPT_DIR}/../lib/json.sh


#Description:List physical disk devices, excluding loop and rom devices
#Argument:NONE
#Returns: JSON success with array of disks (name, size, type), or JSON error if none found
disk_list() {
     mapfile -t disk_names < <(lsblk -d -n -o NAME,SIZE,TYPE| grep -w disk) 

        if [ ${#disk_names[@]} -eq 0 ]; then
            log "WARN" "disk" "No physical disk found" 
            json_error "no-disk" "no physical disk present"
            return 1
        fi

        local json_objects=()
    
        for line in "${disk_names[@]}"; do
            local line
            read name size type <<< "$line"
            local obj=$(json_obj_create "name" "$name" "size" "$size" "type" "$type")
            json_objects+=("$obj")

        done
        local arry=$(json_array_create "${json_objects[@]}")

        json_success "${arry}"
        
    

}

#Description:List a disk's partitions size, filesystem type and mount status 
#Argument:
#   $1 = disk name (e.g sda)
#Returns: Populates disk_details array with disk/partition info 
disk_info(){
    local disk_name="$1"
    if [ -z "${disk_name}" ]; then
        log "WARN" "disk" "No disk name provided to disk_info"
        json_error "no-disk" "no disk provides to disk_info"
        return 1
    fi

    if [ ! -b "/dev/$disk_name" ]; then
        log "WARN" "disk" "Given disk named ${disk_name} does'nt exist"
        json_error "invalid-disk" "Disk named ${disk_name} doesn'nt exist"
        return 1
    fi

    
    mapfile -t disk_details < <(lsblk -n -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT /dev/$disk_name)

    local json_objects=()
    for disk in "${disk_details[@]}";do
        local disk
        read name size type fstype mountpoint <<< "$disk"
        local obj=$(json_obj_create "name" "$name" "size" "$size" "type" "$type" "fstype" "$fstype" "mountpoint" "$mountpoint")
        json_objects+=("$obj")
    done
    local arry=$(json_array_create "${json_objects[@]}" )
    json_success   "${arry}"
    return 0
}

#Description:Checks the block device exists or not 
#Argumnets:
#   $1 = disk name e.g(sda, sdb)
#Returns: 0 if disk  exists , 1 otherwise 

disk_exists(){
    local disk_name="$1"
    if [ -b "/dev/$disk_name" ]; then
        log "INFO" "disk" "Disk $disk_name exist"
        local data=$(json_obj_create "disk" "${disk_name}" "exist" "true")
        json_success "${data}"
        return 0
    else
        log "WARN" "disk" "Disk $disk_name does not exist" 
        json_error "invalid-disk" "Disk $disk_name does not exist"
        return 1
    fi
}



# Description: Gives the type of disk -SSD or -HDD
# Arguments:
#  $1 = disk name
# Returns: Prints "SSD" or "HDD" based on the disk's rotational  flag
# Note: USB devices can be unreliable here - some report HDD (1)
#       even without moving parts, depending on driver behavior

disk_type() {
    local disk_name="$1"
    if [ -z "${disk_name}" ]; then
        log "WARN" "disk" "No disk name provided to disk_type"
        json_error "missing-disk-name" "No disk-name provided"
        return 1
    fi

    if [ ! -b "/dev/$disk_name" ]; then
        log "WARN" "disk" "Given disk named ${disk_name} does'nt exist"
        json_error "invalid-disk" "Disk named ${disk_name} doesn'nt exist"
        return 1
    fi

    if [ ! -f "/sys/block/${disk_name}/queue/rotational" ]; then
        log "WARN" "disk" "Rotational information not available for disk ${disk_name}"
        json_error "rotational-info" "Rotational info unavailable for disk ${disk_name}"
        return 1
    fi

    local rotational=$(cat /sys/block/$disk_name/queue/rotational)

    if [ "${rotational}" -eq 0 ]; then
        local data=$(json_obj_create "disk-type" "SSD")
        json_success "${data}"
        log "INFO" "disk" "Disk ${disk_name} type is ssd"
        return 0

    else
        local data=$(json_obj_create "disk-type" "HDD")
        json_success "${data}"
        log "INFO" "disk" "Disk ${disk_name} type is hdd"
        return 0 
    fi
}

