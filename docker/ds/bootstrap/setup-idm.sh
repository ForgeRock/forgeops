#!/usr/bin/env bash

echo "Applying configuration changes to DS backend for IDM"

set -x 

./bin/dsconfig \
 set-backend-prop \
 --backend-name idmRoot \
 --add base-dn:o=idm \
 --offline \
 --no-prompt

 ./bin/dsconfig \
    create-schema-provider \
    --provider-name "IDM managed/user Json Schema" \
    --type json-query-equality-matching-rule \
    --set enabled:true \
    --set case-sensitive-strings:false \
    --set ignore-white-space:true \
    --set matching-rule-name:caseIgnoreJsonQueryMatchManagedUser \
    --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.1  \
    --set indexed-field:userName \
    --set indexed-field:givenName \
    --set indexed-field:sn \
    --set indexed-field:mail \
    --set indexed-field:accountStatus \
    --offline \
    --no-prompt


./bin/dsconfig \
   create-schema-provider \
   --provider-name "IDM managed/role Json Schema" \
   --type json-query-equality-matching-rule \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchManagedRole \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.2  \
   --set indexed-field:"condition/**" \
   --set indexed-field:"temporalConstraints/**" \
   --offline \
   --no-prompt

./bin/dsconfig \
   create-schema-provider \
   --provider-name "IDM Relationship Json Schema" \
   --type json-query-equality-matching-rule \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchRelationship \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.3  \
   --set indexed-field:firstResourceCollection \
   --set indexed-field:firstResourceId \
   --set indexed-field:firstPropertyName \
   --set indexed-field:secondResourceCollection \
   --set indexed-field:secondResourceId \
   --set indexed-field:secondPropertyName \
   --offline \
   --no-prompt

./bin/dsconfig \
   create-schema-provider \
   --provider-name "IDM Cluster Object Json Schema" \
   --type json-query-equality-matching-rule \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchClusterObject \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.4  \
   --set indexed-field:timestamp \
   --set indexed-field:state \
   --offline \
   --no-prompt

# Add the index name to an array and since these are all "equality"
# it is easy to execute the command in a loop 
INDEX=(fr-idm-json fr-idm-managed-user-json fr-idm-managed-role-json 
       fr-idm-link-firstid fr-idm-link-secondid fr-idm-link-qualifier 
       fr-idm-link-type fr-idm-cluster-json fr-idm-relationship-json)

for idx in ${INDEX[@]}; do
  ./bin/dsconfig \
    create-backend-index \
    --backend-name idmRoot \
    --index-name ${idx} \
    --set index-type:equality \
    --offline \
    --no-prompt
done

# userRoot also needs few of the above indexes if and when it is used
# in explicit mapping for idm
INDEX=(fr-idm-json fr-idm-managed-user-json fr-idm-managed-role-json)

for idx in ${INDEX[@]}; do
  ./bin/dsconfig \
    create-backend-index \
    --backend-name userRoot \
    --index-name ${idx} \
    --set index-type:equality \
    --offline \
    --no-prompt
done

# vlvs for admin UI usage

./bin/dsconfig \
    create-backend-vlv-index \
    --backend-name userRoot \
    --index-name people-by-uid \
    --set base-dn:ou=People,o=userstore \
    --set filter:"(uid=*)" \
    --set scope:single-level \
    --set sort-order:"+uid" \
    --offline \
    --no-prompt

./bin/dsconfig \
    create-backend-vlv-index \
    --backend-name userRoot \
    --index-name people-by-uid-matchall \
    --set base-dn:ou=People,o=userstore \
    --set filter:"(&)" \
    --set scope:single-level \
    --set sort-order:"+uid" \
    --offline \
    --no-prompt



