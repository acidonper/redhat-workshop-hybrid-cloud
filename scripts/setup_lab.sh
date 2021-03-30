#!/bin/bash
##
# Adding user to htpasswd
##
htpasswd -c -b users.htpasswd admin password
for i in {1..100}
do
  htpasswd -b users.htpasswd user$i user$i
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
