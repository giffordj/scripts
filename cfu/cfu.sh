#!/bin/bash
#
##############################################################
# Common Variables
#
cfu_api_link="https://api.cloudflare.com/client/v4/zones"
#
##############################################################
# Functions
#
# Startup
#
function cfu_startup {
  #
  # Get Current IP
  #
  cfu_file="/etc/cfu/cfu_previous_ip-$cfu_dns_entry.txt"
  echo -e "`date +"%b %d %T"` Started\t\t\t: `date +"%b %d %Y %T"`"
  if [ "$cfs_dns_record_type" == "A" ]; then
    cfu_cur_ip=$(curl -s -4 "http://icanhazip.com")
    echo -e "`date +"%b %d %T"` IP Version\t\t: 4"
    echo -e "`date +"%b %d %T"` Current\t\t\t: $cfu_cur_ip"
  fi
  if [ "$cfs_dns_record_type" == "AAAA" ]; then
    cfu_cur_ip=$(curl -s -6 "http://icanhazip.com")
    echo -e "`date +"%b %d %T"` IP Version\t\t: 6"
    echo -e "`date +"%b %d %T"` Current\t\t\t: $cfu_cur_ip"
  fi
    touch $cfu_file
    cfu_old_ip=$(cat $cfu_file)
    if [ "$cfu_old_ip" == "" ]; then
      cfu_old_ip="Not Available"
    fi
    echo -e "`date +"%b %d %T"` Old\t\t\t: $cfu_old_ip"
    if [ "$cfu_cur_ip" != "$cfu_old_ip" ]; then
    echo -e "$cfu_cur_ip" > $cfu_file
    echo -e "`date +"%b %d %T"` Update\t\t\t: In-Progress"
  else
    echo -e "`date +"%b %d %T"` Exiting\t\t\t: No Change Needed"
    echo -e "`date +"%b %d %T"` Ended\t\t\t: `date +"%b %d %Y %T"`"
    echo -e "`date +"%b %d %T"` ------------------------------------------------------------"
    exit 1
  fi
}
#
# Get Zone ID
#
function cfu_get_zone_id {
  cfu_zone_id=$(curl -s -X GET "$cfu_api_link?name=$cfu_domain_zone&status=active&account.id=$cfu_account_key" \
                       -H "X-Auth-Email: $cfu_email" \
                       -H "X-Auth-Key: $cfu_auth_key" \
                       -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')
  echo -e "`date +"%b %d %T"` Zone ID\t\t\t: $cfu_zone_id"
}
#
# Get Record ID
#
function cfu_get_record_id {
  cfu_record_id=$(curl -s -X GET "$cfu_api_link/$cfu_zone_id/dns_records?type=A&name=$cfu_domain_zone" \
                          -H "X-Auth-Email: $cfu_email" \
                          -H "X-Auth-Key: $cfu_auth_key" \
                          -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')
  echo -e "`date +"%b %d %T"` Record ID\t\t: $cfu_record_id"
}
#
# Update DNS Entry
#
function cfu_update_dns_entry {
  cfu_update_status=$(curl -s -X PUT "$cfu_api_link/$cfu_zone_id/dns_records/$cfu_record_id" \
                              -H "X-Auth-Email: $cfu_email" \
                              -H "X-Auth-Key: $cfu_auth_key" \
                              -H "Content-Type: application/json" \
                              --data "{\"type\":\"$cfs_dns_record_type\",\"name\":\"$cfu_dns_entry\",\"content\":\"$cfu_cur_ip\",\"ttl\":1,\"proxied\":false}" | jq '{"success"}[]')
  if [ "$cfu_update_status" == "true" ];then
    echo -e "`date +"%b %d %T"` Update\t\t\t: Completed"
    echo -e "`date +"%b %d %T"` Exiting\t\t\t: Change Completed"
    echo -e "`date +"%b %d %T"` Ended\t\t\t: `date +"%b %d %Y %T"`"
    echo -e "`date +"%b %d %T"` ------------------------------------------------------------"
  else
    echo -e "`date +"%b %d %T"` Update\t\t\t: FAILED"
    echo -e "`date +"%b %d %T"` Exiting\t\t\t: Change NOT Completed"
    echo -e "`date +"%b %d %T"` Ended\t\t\t: `date +"%b %d %Y %T"`"
    echo -e "`date +"%b %d %T"` ------------------------------------------------------------"
    exit 0
  fi
}
##############################################################
#
# Get the configuration files - then process them
#
cfu_config_files=$(ls -A1 config/)
for cfu_conf_file in $cfu_config_files; do
  echo -e "`date +"%b %d %T"` ------------------------------------------------------------"
  echo -e "`date +"%b %d %T"` Processing Config File\t: $cfu_conf_file"
  source config/$cfu_conf_file
  cfu_startup
  cfu_get_zone_id
  cfu_get_record_id
  echo -e "`date +"%b %d %T"` Processing\t\t: Completed"
  echo -e "`date +"%b %d %T"` ------------------------------------------------------------"
done
