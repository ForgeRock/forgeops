/*
# Copyright 2018-2024 Ping Identity Corporation. All Rights Reserved
# 
# This code is to be used exclusively in connection with Ping Identity 
# Corporation software or services. Ping Identity Corporation only offers
# such software or services to legal entities who have entered into a 
# binding license agreement with Ping Identity Corporation.
 */


def addJsonEqualityMatchingRule(String providerName, String name, String oid, Collection<String> indexedFields) {
    def arguments = [ "create-schema-provider",
                      "--type", "json-query-equality-matching-rule",
                      "--set", "enabled:true",
                      "--set", "case-sensitive-strings:false",
                      "--set", "ignore-white-space:true",
                      "--provider-name", providerName,
                      "--set", "matching-rule-name:" + name,
                      "--set", "matching-rule-oid:" + oid ]
    for (String indexedField in indexedFields) {
        arguments.add("--set")
        arguments.add("indexed-field:" + indexedField)
    }
    ds.config arguments
}

addJsonEqualityMatchingRule "IDM managed/user Json Schema",
                            "caseIgnoreJsonQueryMatchManagedUser",
                            "1.3.6.1.4.1.36733.2.3.4.1",
                            [ "userName", "givenName", "sn", "mail", "accountStatus"]

addJsonEqualityMatchingRule "IDM managed/role Json Schema",
                            "caseIgnoreJsonQueryMatchManagedRole",
                            "1.3.6.1.4.1.36733.2.3.4.2",
                            [ "condition/**", "temporalConstraints/**" ]

addJsonEqualityMatchingRule "IDM Relationship Json Schema",
                            "caseIgnoreJsonQueryMatchRelationship",
                            "1.3.6.1.4.1.36733.2.3.4.3",
                            [ "firstResourceCollection", "firstResourceId", "firstPropertyName",
                              "secondResourceCollection", "secondResourceId", "secondPropertyName" ]

addJsonEqualityMatchingRule "IDM Cluster Object Json Schema",
                            "caseIgnoreJsonQueryMatchClusterObject",
                            "1.3.6.1.4.1.36733.2.3.4.4",
                            [ "timestamp", "state"]

ds.config "create-schema-provider",
        "--provider-name", "CTS OAuth2 Grant Set Matching Rule",
        "--type", "json-equality-matching-rule",
        "--set", "enabled:true",
        "--set", "case-sensitive-strings:true",
        "--set", "ignore-white-space:true",
        "--set", "matching-rule-name:ctsOAuth2GrantSetEqualityMatch",
        "--set", "matching-rule-oid:1.3.6.1.4.1.36733.2.2.4.1",
        "--set", "json-keys:g"

