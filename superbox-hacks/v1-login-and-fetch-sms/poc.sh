#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 user_id user_pw router_ip"
    printf "\n"
    echo "Example: $0 admin p455w0rd 192.168.1.1"
    exit 1
fi

epoch() {
    date +%s%3N
}

get_cmd() {
    curl -s -H "$HEADER_REF" "$URL_GET_CMD&cmd=$1" \
        | jq -r ".$1"
}

hex_to_utf8() {
    echo "$1" \
        | perl -CS -pe 's/[0-9A-F]{4}/chr(hex($&))/egi'

    # if [ $? -eq 0 ]; then
    #     echo "$DECODED"
    # else
    #     echo "$1"
    # fi
}

parse_date() {
    local year=${1:0:2}
    local month=${1:3:2}
    local day=${1:6:2}
    local hour=${1:9:2}
    local minute=${1:12:2}
    local second=${1:15:2}

    year=$((year + 2000))

    echo "$day.$month.$year $hour:$minute:$second"
}

main() {
    # Let's skip input validation and sanitization for now.
    USER_ID="$1"
    USER_PW_PLAIN="$2"
    ROUTER_IP="$3"

    URL_GET_CMD="http://$ROUTER_IP/goform/goform_get_cmd_process?isTest=false&_=$(epoch)"
    URL_SET_CMD="http://$ROUTER_IP/goform/goform_set_cmd_process"

    HEADER_REF="Referer: http://$ROUTER_IP/index.html"

    # get RD
    RD=$(get_cmd "RD")
    # get rd0 a.k.a. rd_params0 a.k.a. wa_inner_version
    rd0=$(get_cmd "wa_inner_version")
    # get rd1 a.k.a. rd_params1 a.k.a. cr_version
    rd1=$(get_cmd "cr_version")

    # compose AD with following formula: AD = md5(md5(rd0+rd1)+RD)
    MD5_rd=$(echo -n "$rd0$rd1" \
        | md5sum \
        | awk '{print $1}')

    AD=$(echo -n "$MD5_rd$RD" \
        | md5sum \
        | awk '{print $1}')

    PATH_COOKIE_FILE=$(mktemp --suffix .superbox-cookie)

    HEADER_CONTENT_TYPE="Content-Type: application/x-www-form-urlencoded; charset=UTF-8"
    USER_PW_BASE64=$(echo -n "$USER_PW_PLAIN" | base64)
    LOGIN_PARAMS="isTest=false&goformId=LOGIN_MULTI_USER&user=$USER_ID&password=$USER_PW_BASE64&AD=$AD"

    LOGIN_RESULT=$(curl -s -c "$PATH_COOKIE_FILE" -H "$HEADER_REF" -H "$HEADER_CONTENT_TYPE" -d "$LOGIN_PARAMS" "$URL_SET_CMD" | jq -r ".result")

    LOGIN_COOKIE=$(grep zwsd "$PATH_COOKIE_FILE" | awk '{print $7}')
    COOKIE_PARAM="Cookie: zwsd=$LOGIN_COOKIE"
    rm "$PATH_COOKIE_FILE"

    # Possible values for LOGIN_RESULT (found by trial and error, not confirmed)
    # null: invalid json key
    # failure: missing POST parameter
    # 1: wrong credentials
    # 0: success

    if [ "$LOGIN_RESULT" = 0 ]; then
        echo "Successfully logged in."
    elif [ "$LOGIN_RESULT" = 1 ]; then
        echo "Invalid login credentials."
        exit 1
    else
        echo "Unknown error occurred."
        echo "LOGIN_RESULT: $LOGIN_RESULT"
        exit 1
    fi

    # Warning! This is not a solid test.
    # I've seen that "wa_version" can be queried only after a successful login.
    # "wa_version" is yet another name for "rd0" and "rd0" can be fetched before login.
    # It's either a dumb design or i'm missing something but it somehow works.
    TEST_RETRIEVE=$(curl -s -H "$HEADER_REF" -H "$COOKIE_PARAM" "$URL_GET_CMD&cmd=wa_version" | jq -r ".wa_version")

    echo -n "Data retrieve test: "
    if [ "$TEST_RETRIEVE" = "$rd0" ]; then
        echo "Success"
    else
        echo "Fail"
    fi

    QUERY_SMS="sms_data_total&page=0&data_per_page=500&mem_store=1&tags=10&order_by=order+by+id+desc"

    MSG_RESPONSE="$(curl -s -H "$HEADER_REF" -H "$COOKIE_PARAM" "$URL_GET_CMD&cmd=$QUERY_SMS")"

    echo "Fetch messages..."
    echo "-----------------"

    # Some contacts include "space" in their name. If we do not ignore "space",
    # it would be split apart into multiple lines.
    IFS=$'\n'
    for msg in $(echo "$MSG_RESPONSE" | jq -c '.messages | .[]'); do
        # echo "$msg"
        MSG_ID="$(echo "$msg" | jq -r '.id')"
        MSG_NUMBER="$(echo "$msg" | jq -r '.number')"
        MSG_DATE_RAW="$(echo "$msg" | jq -r '.date')"
        MSG_TEXT_RAW="$(echo "$msg" | jq -r '.content')"

        MSG_DATE=$(parse_date "$MSG_DATE_RAW")
        MSG_TEXT=$(hex_to_utf8 "$MSG_TEXT_RAW")

        printf "[%3d] %s | %s\n" "$MSG_ID" "$MSG_NUMBER" "$MSG_DATE"
        echo "- - - - - - - - - - - - - - - - - - - - - - -"
        echo "$MSG_TEXT"
        # echo "$MSG_TEXT_RAW"
        # echo "$MSG_TEXT_RAW" | xxd -ps -r
        printf "\n"
    done
}

main "$@"

exit 0
