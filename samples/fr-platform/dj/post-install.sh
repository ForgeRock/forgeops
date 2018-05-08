/opt/opendj/bin/start-ds

/opt/opendj/bin/dsconfig \
 set-backend-prop \
 --hostname localhost \
 --port 4444 \
 --bindDN "cn=Directory Manager" \
 --bindPassword password \
 --backend-name userRoot \
 --add base-dn:dc=openidm,dc=forgerock,dc=com \
 --trustAll \
 --no-prompt

/opt/opendj/bin/dsconfig \
   create-schema-provider \
   --hostname localhost \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword password \
   --provider-name "IDM managed/role Json Schema" \
   --type json-query-equality-matching-rule \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchManagedRole \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.2  \
   --set indexed-field:"condition/**" \
   --set indexed-field:"temporalConstraints/**" \
   --trustAll \
   --no-prompt

/opt/opendj/bin/dsconfig \
   create-schema-provider \
   --hostname localhost \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword password \
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
   --trustAll \
   --no-prompt

/opt/opendj/bin/dsconfig \
   create-schema-provider \
   --hostname localhost \
   --port 4444 \
   --bindDN "cn=Directory Manager" \
   --bindPassword password \
   --provider-name "IDM Cluster Object Json Schema" \
   --type json-query-equality-matching-rule \
   --set enabled:true \
   --set case-sensitive-strings:false \
   --set ignore-white-space:true \
   --set matching-rule-name:caseIgnoreJsonQueryMatchClusterObject \
   --set matching-rule-oid:1.3.6.1.4.1.36733.2.3.4.4  \
   --set indexed-field:"timestamp" \
   --set indexed-field:"state" \
   --trustAll \
   --no-prompt

/opt/opendj/bin/stop-ds

cp -r /tmp/schema/* /opt/opendj/db/schema

/opt/opendj/bin/start-ds

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-link-firstid \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-link-secondid \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-link-qualifier \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-link-type \
    --set index-type:equality \
    --trustAll \
    --no-prompt


/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-managed-role-json \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-cluster-json \
    --set index-type:equality \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-index \
    --hostname localhost \
    --port 4444 \
    --bindDN "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name fr-idm-relationship-json \
    --set index-type:equality \
    --trustAll \
    --no-prompt


# vlvs for admin UI usage

/opt/opendj/bin/dsconfig \
    create-backend-vlv-index \
    --hostname localhost \
    --port 4444 \
    --bindDn "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name people-by-uid \
    --set base-dn:ou=People,dc=example,dc=com \
    --set filter:"(uid=*)" \
    --set scope:single-level \
    --set sort-order:"+uid" \
    --trustAll \
    --no-prompt

/opt/opendj/bin/dsconfig \
    create-backend-vlv-index \
    --hostname localhost \
    --port 4444 \
    --bindDn "cn=Directory Manager" \
    --bindPassword password \
    --backend-name userRoot \
    --index-name people-by-uid-matchall \
    --set base-dn:ou=People,dc=example,dc=com \
    --set filter:"(&)" \
    --set scope:single-level \
    --set sort-order:"+uid" \
    --trustAll \
    --no-prompt



ldif="bootstrap/extra/ldif"

if [ -d "$ldif" ]; then
    echo "Loading LDIF files in $ldif"
    for file in "${ldif}"/*.ldif;  do
        echo "Loading $file"
        # search + replace all placeholder variables. Naming conventions are from AM.
        sed -e "s/@BASE_DN@/$BASE_DN/"  \
            -e "s/@userStoreRootSuffix@/$BASE_DN/"  \
            -e "s/@DB_NAME@/$DB_NAME/"  \
            -e "s/@SM_CONFIG_ROOT_SUFFIX@/$BASE_DN/"  <${file}  >/tmp/file.ldif
        /opt/opendj/bin/ldapmodify -D "cn=Directory Manager"  --continueOnError -h localhost -p 1389 -j ${DIR_MANAGER_PW_FILE} -f /tmp/file.ldif
      echo "  "
    done
fi

/opt/opendj/bin/stop-ds
