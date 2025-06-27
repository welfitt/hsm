#!/bin/bash

yum update -y
yum install -y cloudhsm-cli openssl aws-cli jq

cd /root
mkdir cloudhsm-certs
cd cloudhsm-certs

# Generate CA
openssl genrsa -out customerCA.key 2048
openssl req -x509 -new -nodes -key customerCA.key \
  -sha256 -days 3650 -out customerCA.crt \
  -subj "/C=US/ST=WA/L=Seattle/O=MyOrg/OU=IT/CN=customer-root-ca"

# CSR and cert
openssl req -new -key customerCA.key -out customerCA.csr \
  -subj "/C=US/ST=WA/L=Seattle/O=MyOrg/OU=IT/CN=customer-hsm"

openssl x509 -req -in customerCA.csr -CA customerCA.crt -CAkey customerCA.key \
  -CAcreateserial -out customerHsmCert.crt -days 365 -sha256

cp customerCA.crt customerCAChain.pem
cp customerHsmCert.crt signedCert.pem

# Wait for HSM IP to become available
for i in {1..20}; do
  echo "Waiting for HSM to become available..."
  HSM_IP=$(aws cloudhsmv2 describe-clusters --region ${region} \
    --filter clusterIds=${cluster_id} \
    | jq -r '.Clusters[0].Hsms[0].EniIp')

  if [[ "$HSM_IP" != "null" ]]; then
    echo "HSM IP is $HSM_IP"
    break
  fi
  sleep 30
done

if [[ "$HSM_IP" == "null" ]]; then
  echo "HSM IP not found after waiting. Exiting."
  exit 1
fi

# Initialize the cluster
cloudhsm-cli initialize-cluster \
  --cluster-id ${cluster_id} \
  --signed-cert file://signedCert.pem \
  --trust-anchor file://customerCAChain.pem

