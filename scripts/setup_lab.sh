#!/bin/bash
##
# Adding user to htpasswd
##
htpasswd -c -b users.htpasswd admin password
for i in {1..100}
do
  htpasswd -b users.htpasswd user$i user$i
  oc new-project user$i-namespace
  oc adm policy add-role-to-user admin user$i -n user$i-namespace
done

##
# Creating htpasswd file in Openshift
##
oc delete secret lab-users -n openshift-config
oc create secret generic lab-users --from-file=htpasswd=users.htpasswd -n openshift-config

##
# Configuring OAuth to authenticate users via htpasswd
##
cat <<EOF > oauth.yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - htpasswd:
      fileData:
        name: lab-users
    mappingMethod: claim
    name: my_htpasswd_provider
    type: HTPasswd
EOF

cat oauth.yaml | oc apply -f -

echo "Please, enter quay registry servername (E.g example-registry-quay-quay.apps.lab.sandbox1202.opentlc.com)"
read quay_reg

echo quit | openssl s_client -showcerts -servername $quay_reg -connect $quay_reg:443 > cacert.pem
oc create configmap registry-cas -n openshift-config --from-file=$quay_reg=cacert.pem
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge