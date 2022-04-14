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

while true; do
  for lb in $(vesctl configuration list http_loadbalancer -n $NAMESPACE --outfmt json | jq -r '.items[].name'); do
    domainIp=$(vesctl configuration get  http_loadbalancer $lb -n $NAMESPACE --outfmt json | jq -r '.spec.domains[] + " " + .spec.advertise_custom.advertise_where[0].site.ip + " " + .spec.advertise_custom.advertise_where[0].site.network')
    domain=$(echo $domainIp | cut -d' ' -f1)
    ip=$(echo $domainIp | cut -d' ' -f2)
    if [[ $ip != "SITE_NETWORK_OUTSIDE" ]]; then
      if curl -fs -o /dev/null -H host:$domain $ip; then
        echo "$lb: domain=$domain ip=$ip good"
      else
        echo "$lb: domain=$domain ip=$ip bad"
      fi
    fi
  done
  echo ""
  sleep 10
done

#tail -f /dev/null