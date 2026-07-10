#!/usr/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Copyright (C) 2026 Georgi Chompalov & Stefan Nikolov  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
set -Eeuo pipefail

TOMCAT_HOME=/usr/local/tomcat

echo "Scanning TOMCATXML environment variables..."
echo

xpath_quote()
{
    local value="$1"

    if [[ "$value" == *"'"* ]]; then
        echo "ERROR: XPath value contains single quote: $value" >&2
        exit 1
    fi

    printf "'%s'" "$value"
}


build_xpath()
{
    local xml="$TOMCAT_HOME/$1"
    shift

    local xpath=""
    local node
    local ns
    local prefix="ns"

    ns=$(detect_namespace "$xml")

    for node in "$@"; do

        if [[ "$node" =~ ^([^\[]+)\[([^:]+):(.*)\]$ ]]; then

            local name="${BASH_REMATCH[1]}"
            local selector="${BASH_REMATCH[2]}"
            local value="${BASH_REMATCH[3]}"

            if [[ -n "$ns" ]]; then
                xpath+="/${prefix}:${name}[@${selector}=$(xpath_quote "$value")]"
            else
                xpath+="/${name}[@${selector}=$(xpath_quote "$value")]"
            fi

        else

            if [[ -n "$ns" ]]; then
                xpath+="/${prefix}:${node}"
            else
                xpath+="/${node}"
            fi

        fi

    done

    printf '%s' "$xpath"
}

detect_namespace()
{
    local xml="$1"
    local ns

    ns=$(xmlstarlet sel -t -v 'namespace-uri(/*)' "$xml")

    if [[ -n "$ns" ]]; then
        echo "$ns"
    fi
}

apply_change()
{
    local file="$1"
    local xpath="$2"
    local attribute="$3"
    local value="$4"
    local ns
    local ns_opt=()
    local xml="$TOMCAT_HOME/$file"
    
    if [[ ! -f "$xml" ]]; then
        echo "ERROR: XML file not found: $xml" >&2
        return 1
    fi

    ns=$(detect_namespace "$xml")
    if [[ -n "$ns" ]]; then
        ns_opt=(-N "ns=$ns")
    fi

    echo "Updating:"
    echo "  file : $xml"
    echo "  xpath: $xpath"
    echo "  attr : $attribute"
    echo "  value: $value"
    if [[ -n "$ns" ]]; then
        echo "  xmlns: $ns"
    fi

    local count
    count=$(xmlstarlet sel \
         "${ns_opt[@]}" \
        -t \
        -v "count($xpath)" \
        "$xml")

    if [[ "$count" == "0" ]]; then

        echo "  node missing, creating"

        #
        # Split:
        #
        local parent node
        parent="${xpath%/*}"
        node="${xpath##*/}"

        if [[ "$node" =~ ^([^\[]+)\[@([^=]+)=\'(.*)\'\]$ ]]; then

            local name key val create_name
            name="${BASH_REMATCH[1]}"
            key="${BASH_REMATCH[2]}"
            val="${BASH_REMATCH[3]}"

            #
            # create element
            #
            if [[ -n "$ns" ]]; then
                create_name="${name#*:}"
            else
                create_name="$name"
            fi
            
            xmlstarlet ed \
                -L \
                "${ns_opt[@]}" \
                -s "$parent" \
                -t elem \
                -n "$create_name" \
                -v "" \
                "$xml"

            #
            # add selector attribute
            #
            xmlstarlet ed \
                -L \
                "${ns_opt[@]}" \
                -i "$parent/$name[last()]" \
                -t attr \
                -n "$key" \
                -v "$val" \
                "$xml"

            xpath="$parent/$name[last()]"
        else
            if [[ -n "$ns" ]]; then
                create_name="${node#*:}"
            else
                create_name="$node"
            fi

            xmlstarlet ed \
                    -L \
                    "${ns_opt[@]}" \
                    -s "$parent" \
                    -t elem \
                    -n "$create_name" \
                    -v "" \
                    "$xml"

            xpath="$parent/$node[last()]"
        fi
    fi

    #
    # Add/update requested attribute
    #
    count=$(xmlstarlet sel \
        "${ns_opt[@]}" \
        -t \
        -v "count($xpath/@$attribute)" \
        "$xml")

    if [[ "$count" == "1" ]]; then
        xmlstarlet ed \
            -L \
            "${ns_opt[@]}" \
            -u "$xpath/@$attribute" \
            -v "$value" \
            "$xml"
    else
        xmlstarlet ed \
            -L \
            "${ns_opt[@]}" \
            -i "$xpath" \
            -t attr \
            -n "$attribute" \
            -v "$value" \
            "$xml"
    fi
    echo
}

while IFS='=' read -r var value; do

    [[ "$var" == TOMCATXML__* ]] || continue

    echo "VAR   : $var"
    echo "VALUE : $value"
    echo

    spec="${var#TOMCATXML__}"


    #
    # Split on "__"
    #
    IFS=$'\034' read -ra parts <<< "${spec//__/$'\034'}"


    if (( ${#parts[@]} < 3 )); then
        echo "Skipping invalid variable: $var"
        continue
    fi

    #
    # First part is XML file
    #
    file="${parts[0]//:/\/}"

    unset 'parts[0]'

    #
    # Last part is attribute name
    #
    attribute="${parts[-1]}"

    unset 'parts[-1]'

    #
    # Everything between is XPath
    #
    xpath=$(build_xpath "$file" "${parts[@]}")

    apply_change \
        "$file" \
        "$xpath" \
        "$attribute" \
        "$value"

done < <(env)

echo "Finished processing TOMCATXML environment variables..."
echo