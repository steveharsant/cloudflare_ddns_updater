#!/usr/bin/env bash

# Cloudflare DNS Manager
# Author: Steve Harsant

# Set liniting rules
# shellcheck disable=SC2059
# shellcheck disable=SC2091
# shellcheck disable=SC2164

version='0.4.1'

# Set variables from env vars, otherwise fallback to defaults
api_endpoint=${CLOUDFLARE_API_ENDPOINT:-https://api.cloudflare.com/client/v4}
api_key=$CLOUDFLARE_API_KEY
domain=$CLOUDFLARE_DOMAIN
email=$CLOUDFLARE_EMAIL
enable_debug=${ENABLE_DEBUG:-0}
ttl=${CLOUDFLARE_DEFAULT_TTL:-120}
zone_id=$CLOUDFLARE_ZONE_ID

# Script functions
debug() {
  if [[ $enable_debug == 1 ]]; then
    printf "$1\n"
  fi
}

parse_configuration() {
  echo "$1" | cut -d= -f 2
}

print_help() {
  printf '\nCloudflare DNS Manager\n'
  printf 'Author: Steve Harsant\n\n'
  printf "Version: $version\n\n"
  printf 'Usage:\n\n'
  printf '  -f Specificies a command to run upon failure (optional)\n'
  printf '  -h Prints help message\n'
  printf '  -s Specificies a command to run upon success (optional)\n'
  printf '  -v Prints version\n\n'
  exit 0
}

print_version() {
  printf "$version\n"
  exit 0
}

test_requirement() {
  if [[ ! $2 ]]; then
    printf "$1 not found. Satisfy the requirement and try again. exit 1 \n"
    eval "$failure_command"
    exit 1
  fi
}

# Cloudflare API call functions

get_dns_a_record() {
  debug "Retrieving DNS A record from Cloudflare for domain: $2"
  curl -sS -X GET "$api_endpoint/zones/$4/dns_records?type=A&name=$2" \
    -H "X-Auth-Email: $3" \
    -H "X-Auth-Key: $1" \
    -H "Content-Type: application/json"
}

update_dns_a_record() {
  debug "Updating DNS A record to: $6 in Cloudflare for domain: $2"
  curl -sS -X PUT "$api_endpoint/zones/$4/dns_records/$5" \
    -H "X-Auth-Email: $3" \
    -H "X-Auth-Key: $1" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$2\",\"content\":\"$6\",\"ttl\":$ttl,\"proxied\":false}"
}

# set script arguments as variables
while getopts "hf:s:v" OPT; do
  case "$OPT" in
    h) print_help;;
    f) failure_command=$OPTARG;;
    s) success_command=$OPTARG;;
    v) print_version;;
    *) echo 'Unknown option passed. exit 1' && eval "$failure_command" && exit 1;;
  esac
done

#
# Start
#

# Ensure requirements are satisfied
test_requirement curl "$(command -v curl)"

# If not all environment variables are set, ensure the settings.conf file exists
# If it exists, update with required values
if [ -z "$api_key" ] || [ -z "$domain" ] || [ -z "$email" ] || [ -z "$zone_id" ]; then
  script_location="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  test_requirement settings.conf "$(ls "$script_location"/settings.conf)"
fi

# Get configuration from settings file if it exists. This overwrites environment variables.
# Useful if multiple instances of the script is needed.
if [[ -f "$script_location/settings.conf" ]]; then
  configuration=$(cat "$script_location/settings.conf")
  for line in $configuration; do
    case "$line" in
    api_key*) api_key=$(parse_configuration "$line") ;;
    domain*) domain=$(parse_configuration "$line") ;;
    email*) email=$(parse_configuration "$line") ;;
    zone_id*) zone_id=$(parse_configuration "$line") ;;
    esac
  done
fi

# Print debug messages of configruation variables
debug "api_endpoint: $api_endpoint"
debug "api_key: $api_key"
debug "domain: $domain"
debug "email: $email"
debug "enable_debug: $enable_debug"
debug "ttl: $ttl"
debug "zone_id: $zone_id"

# Get current DNS configuration details
current_dns_configuration=$(get_dns_a_record "$api_key" "$domain" "$email" "$zone_id")
current_recorded_ip=$(echo "$current_dns_configuration" | grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')
desired_ip=$(curl -sS https://api.ipify.org)

# Parse domain id from returned json
for entry in $current_dns_configuration; do
  if [[ $entry == *\"id\"* ]]; then
    domain_id=$(echo "$entry" | cut -d\" -f 6)
  fi
done

# Print debug messages of current and desired DNS information
debug " current_dns_configuration: $current_dns_configuration"
debug " current_recorded_ip: $current_recorded_ip"
debug " api_desired_ipkey: $desired_ip"
debug " domain_id: $domain_id"

# Test if DNS record is current
if [[ "$current_recorded_ip" == "$desired_ip" ]]; then
  printf "Cloudflare DNS entry matches current IP for $domain. exit 0 \n"
  exit 0
fi

update_result=$(update_dns_a_record "$api_key" "$domain" "$email" "$zone_id" "$domain_id" "$desired_ip")
debug "$update_result"

if echo "$update_result" | grep -q '\"success\": true,'; then
  printf "Success! The IP address was updated to $desired_ip. exit 0 \n"
  eval "$success_command"
  exit 0
else
  printf "Failure! IP address was not updated. exit 1 \n"
  eval "$failure_command"
  exit 1
fi
