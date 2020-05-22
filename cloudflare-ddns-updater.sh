#!/usr/bin/env bash
#
# Cloudflare DNS Manager
# version: 0.2.1
# Author: Steve Harsant

# Set liniting rules
# shellcheck disable=SC2059
# shellcheck disable=SC2091
# shellcheck disable=SC2164

api_endpoint='https://api.cloudflare.com/client/v4'
ttl="120"

# Enable debug messages
enable_debug=0

get_dns_a_record() {
  curl -sS -X GET "${api_endpoint}/zones/${4}/dns_records?type=A&name=${2}" \
           -H "X-Auth-Email: ${3}" \
           -H "X-Auth-Key: ${1}" \
           -H "Content-Type: application/json"
}

update_dns_a_record() {
  curl -sS -X PUT "${api_endpoint}/zones/${4}/dns_records/${5}" \
         -H "X-Auth-Email: ${3}" \
         -H "X-Auth-Key: ${1}" \
         -H "Content-Type: application/json" \
         --data "{\"type\":\"A\",\"name\":\"${2}\",\"content\":\"${6}\",\"ttl\":${ttl},\"proxied\":false}"
}

debug() {
  if [[ $enable_debug == 1 ]]; then
    printf "$1\n"
  fi
}

parse_configuration() {
  echo "$1" | cut -d= -f 2
}

test_requirement() {
  if [[ ! $2 ]]; then
    printf "$1 not found. Satisfy the requirement and try again. exit 1 \n"
    exit 1
  fi
}

script_location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

test_requirement curl "$(command -v curl)"
test_requirement settings.conf "$(ls "${script_location}"/settings.conf)"

# Get configuration from settings file
configuration=$(cat "${script_location}/settings.conf")
for line in $configuration
do
  case "$line" in
    api_key*) api_key=$(parse_configuration "$line");;
    domain*) domain=$(parse_configuration "$line");;
    email*) email=$(parse_configuration "$line");;
    zone_id*) zone_id=$(parse_configuration "$line");;
  esac
done

# Print debug messages of configruation variables
debug " api_key: $api_key"; debug " domain: $domain"; debug " email: $email"; debug " zone_id: $zone_id"

current_dns_configuration=$(get_dns_a_record "$api_key" "$domain" "$email" "$zone_id")
current_recorded_ip=$(echo "$current_dns_configuration" | grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')
desired_ip=$(curl -sS icanhazip.com)

# Parse domain id from returned json
for entry in $current_dns_configuration
do
  if [[ $entry == *\"id\"* ]]; then
    domain_id=$(echo "$entry" | cut -d\" -f 6)
  fi
done

# Print debug messages of current and desired DNS information
debug " current_dns_configuration: $current_dns_configuration"; debug " current_recorded_ip: $current_recorded_ip"
debug " api_desired_ipkey: $desired_ip"; debug " domain_id: $domain_id";

# Test if DNS record is current
if [[ "$current_recorded_ip" == "$desired_ip" ]]; then
  printf "Cloudflare DNS entry matches current IP for ${domain}. exit 0 \n"
  exit 0
fi

update_result=$(update_dns_a_record "$api_key" "$domain" "$email" "$zone_id" "$domain_id" "$desired_ip")
debug "$update_result"

if echo "$update_result" | grep -q '\"success\": true,'; then
  printf "Success! The IP address was updated to ${desired_ip}. exit 0 \n"
  exit 0
else
  printf "Failure! IP address was not updated. exit 1 \n"
  exit 1
fi
