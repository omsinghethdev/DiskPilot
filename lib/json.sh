#Description:wrap given data into a standard success JSON response
#Argument:
#   $1 = JSON data (object or array) to include in the response

#Return:JSON string with status "ok" and given data
json_success() {
    echo "{\"status\":\"ok\",\"data\":$1}"
}

#Description:wrap the given error into standard error JSON response
#Argument:
# $1 = error code (e.g. "invalid_args", "not_found")
# $2 = messege about the error 
#Return:JSON string with status "error" and 
json_error() {
    echo "{\"status\":\"error\",\"code\":\"$1\",\"message\":\"$2\"}"
}
#Description:Creates JSON object from variable key-value pairs
#Argument:
# $1,$2 = first key-value pair (key,value)
# $3,$4 = second key-value pair (if provided)
# ... (any number of key value pairs , must be even count )
#Return:JSON object string, or error JSON if odd number of arguments is given 
json_obj_create(){
    local result=""
    if [ $(($# % 2)) -ne 0 ];then
        json_error "invalid_args" "Key-Value pairs required, odd number of arguments given" 
        return 1
    fi
    while [ $# -gt 0 ];do
        if [ "${result}" != "" ];then
            result="${result},"
        fi
        
        result="${result}\"$1\":\"$2\""
        shift 2
    done
    echo "{${result}}"

}
#Description:Creates JSON array from given one or more object
#Arguemnt:
# $1,$2,.... = JSON objects (any number, each already formated as a JSON objects)
#Return: JSON array string combining all given objects
json_array_create(){
    local result=""
    while [ $# -gt 0 ]; do
        if [ "${result}" != "" ]; then
            result="${result},"
        fi
        result="${result}$1"
        shift
    done
    echo "[${result}]"
}
