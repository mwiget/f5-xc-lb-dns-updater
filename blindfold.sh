#!/bin/bash
vesctl request secrets get-policy-document --namespace mw --name mw-dns2 > secret-policy
vesctl request secrets encrypt --policy-document secret-policy --public-key playground-api-pubkey ~/playground.staging.api-creds.p12 > api-creds.enc
echo $VES_P12_PASSWORD > /tmp/pwd
vesctl request secrets encrypt --policy-document secret-policy --public-key playground-api-pubkey /tmp/pwd > pwd.enc
rm /tmp/pwd

cat > api-creds.json <<EOF
{
  "type": "blindfold",
  "location": "string:///$(grep -v Encrypted api-creds.enc)"
}
EOF
cat > pwd.json <<EOF
{
  "type": "blindfold",
  "location": "string:///$(grep -v Encrypted pwd.enc)"
}
EOF
ls -l api-creds.json pwd.json
