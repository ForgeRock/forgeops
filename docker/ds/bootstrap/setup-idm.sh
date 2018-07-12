
./bin/dsconfig \
 set-backend-prop \
 --backend-name idmRoot \
 --add base-dn:o=idm \
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
   --set indexed-field:"timestamp" \
   --set indexed-field:"state" \
   --offline \
   --no-prompt


./bin/dsconfig \
    create-backend-index \
    --backend-name userRoot \
    --index-name fr-idm-link-firstid \
    --set index-type:equality \
    --offline \
    --no-prompt

./bin/dsconfig \
    create-backend-index \
    --backend-name userRoot \
    --index-name fr-idm-link-secondid \
    --set index-type:equality \
    --offline \
    --no-prompt

./bin/dsconfig \
    create-backend-index \
    --backend-name userRoot \
    --index-name fr-idm-link-qualifier \
    --set index-type:equality \
    --offline \
    --no-prompt

./bin/dsconfig \
    create-backend-index \
    --backend-name userRoot \
    --index-name fr-idm-link-type \
    --set index-type:equality \
    --offline \
    --no-prompt


./bin/dsconfig \
    create-backend-index \
    --backend-name userRoot \
    --index-name fr-idm-managed-role-json \
    --set index-type:equality \
    --offline \
    --no-prompt

./bin/dsconfig \
    create-backend-index \
    --backend-name userRoot \
    --index-name fr-idm-cluster-json \
    --set index-type:equality \
    --offline \
    --no-prompt

./bin/dsconfig \
    create-backend-index \
    --backend-name userRoot \
    --index-name fr-idm-relationship-json \
    --set index-type:equality \
    --offline \
    --no-prompt


# vlvs for admin UI usage

./bin/dsconfig \
    create-backend-vlv-index \
    --backend-name userRoot \
    --index-name people-by-uid \
    --set base-dn:ou=People,dc=example,dc=com \
    --set filter:"(uid=*)" \
    --set scope:single-level \
    --set sort-order:"+uid" \
    --offline \
    --no-prompt

./bin/dsconfig \
    create-backend-vlv-index \
    --backend-name userRoot \
    --index-name people-by-uid-matchall \
    --set base-dn:ou=People,dc=example,dc=com \
    --set filter:"(&)" \
    --set scope:single-level \
    --set sort-order:"+uid" \
    --offline \
    --no-prompt



