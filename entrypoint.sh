#!/bin/sh
NAMESPACE=mw
cd /root
until [ -s playground.staging.api-creds.p12 ]; do
  sleep 1
  curl -f -XPOST http://localhost:8070/secret/unseal -d @api-creds.json | base64 -d > /root/playground.staging.api-creds.p12
done

export VES_P12_PASSWORD=$(curl -XPOST http://localhost:8070/secret/unseal -d @pwd.json | base64 -d)
#echo $VES_P12_PASSWORD
cat > /root/.vesconfig <<EOF
server-urls: https://playground.staging.volterra.us/api
p12-bundle: /root/playground.staging.api-creds.p12
EOF
mkdir /root/.aws/
curl -f -XPOST http://localhost:8070/secret/unseal -d @aws.json | base64 -d > /root/.aws/credentials

while true; do
  for lb in $(vesctl configuration list http_loadbalancer -n $NAMESPACE --outfmt json | jq -r '.items[].name'); do
    domainIp=$(vesctl configuration get  http_loadbalancer $lb -n $NAMESPACE --outfmt json | jq -r '.spec.domains[] + " " + .spec.advertise_custom.advertise_where[0].site.site.name+ " " + .spec.advertise_custom.advertise_where[0].site.ip + " " + .spec.advertise_custom.advertise_where[0].site.network')
    domain=$(echo $domainIp | cut -d' ' -f1)
    site=$(echo $domainIp | cut -d' ' -f2)
    ip=$(echo $domainIp | cut -d' ' -f3)
    if [[ "$site" = "$VES_IO_SITENAME" ]]; then
      if [[ $ip != "SITE_NETWORK_OUTSIDE" ]]; then
        if curl -m 2 -fs -o /dev/null -H host:$domain $ip; then
          echo "$site $lb: domain=$domain ip=$ip good"
          cat > batch-changes.json <<EOF
{
  "Changes": [
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$domain.mwlabs.net.",
      "Type": "A",
      "TTL": 1,
      "ResourceRecords": [
        {
          "Value": "$ip"
        }
      ]
    }
  }
  ]
}
EOF
          aws route53 change-resource-record-sets --hosted-zone-id Z01985532A3LVOA8Z4RPJ --change-batch file://batch-changes.json
        else
          echo "$site $lb: domain=$domain ip=$ip bad"
          cat > batch-changes.json <<EOF
{
  "Changes": [
  {
    "Action": "DELETE",
    "ResourceRecordSet": {
      "Name": "$domain.mwlabs.net.",
      "Type": "A",
      "TTL": 1,
      "ResourceRecords": [
        {
          "Value": "$ip"
        }
      ]
    }
  }
  ]
}
EOF
          aws route53 change-resource-record-sets --hosted-zone-id Z01985532A3LVOA8Z4RPJ --change-batch file://batch-changes.json
        fi
      fi
    fi
  done
  echo ""
  sleep 30
done

#tail -f /dev/null
