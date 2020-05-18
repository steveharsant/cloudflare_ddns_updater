#!/usr/bin/env bash
#
# Cloudflare DNS Manager
# version: 0.1.0
# Author: Steve Harsant

# Set liniting rules
# shellcheck disable=SC2059
# shellcheck disable=SC2091
# shellcheck disable=SC2164

api_endpoint='https://api.cloudflare.com/client/v4'
ttl="120"

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

current_dns_configuration=$(get_dns_a_record "$api_key" "$domain" "$email" "$zone_id")
current_recorded_ip=$(echo "$current_dns_configuration" | grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')
desired_ip=$(curl -sS icanhazip.com)
# grep doesn't seem to like the expression [0-9a-z]{32} Belows regex is a dirty, dirty workaround
domain_id=$(echo "$current_dns_configuration" | grep "\"id\":" | grep -o '[0-9a-z]*' | tail -1)

# Test if DNS record is current
if [[ "$current_recorded_ip" == "$desired_ip" ]]; then
  printf "Cloudflare DNS entry matches current IP for ${domain}. exit 0 \n"
  exit 0
fi

update_result=$(update_dns_a_record "$api_key" "$domain" "$email" "$zone_id" "$domain_id" "$desired_ip")

if echo "$update_result" | grep -q '\"success\": true,'; then
  printf "Success! The IP address was updated to ${desired_ip}. exit 0 \n"
  exit 0
else
  printf "Failure! IP address was not updated. exit 1 \n"
  exit 1
fi