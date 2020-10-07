/*
 * Copyright 2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */
import static java.util.Arrays.asList
import static java.util.Collections.singletonMap
import static org.forgerock.openam.amp.dsl.ConfigTransforms.*
import static org.forgerock.openam.amp.dsl.ServiceTransforms.*
import static org.forgerock.openam.amp.dsl.fbc.FileBasedConfigTransforms.*
import static org.forgerock.openam.amp.dsl.valueproviders.ValueProviders.objectProvider

/**
 * Placeholders to apply to AM 7.0.0 file config.
 *
 * <p>
 *     This is to be used in conjunction with the AM Docker image to placeholder the dev-ops static file deployment.
 *     This file therefore assumes values set by the AM Docker image deployment configuration based on the intended
 *     usage of the Docker image in a dev-ops deployment.
 * </p>
 */
def getRules() {
    return [
            forRealm("/",
                    replace("aliases")
                            .with(objectProvider(singletonMap("\$list", "&{am.server.hostnames|&{am.server.fqdn},am,am-config}")))),

            forGlobalService("amDataStoreService",
                    forDefaultInstanceSettings(
                            forNamedInstanceSettings("application-store", replace("bindDN")
                                    .with("&{am.stores.application.username}"),
                                    replace("bindPassword")
                                            .with("&{am.stores.application.password}"),
                                    replace("useSsl")
                                            .with(objectProvider(singletonMap("\$bool", "&{am.stores.application.ssl.enabled|false}"))),
                                    replace("serverUrls")
                                            .with(objectProvider(singletonMap("\$list", "&{am.stores.application.servers}")))),
                            forNamedInstanceSettings("policy-store",
                                    replace("bindDN")
                                            .with("&{am.stores.policy.username}"),
                                    replace("bindPassword")
                                            .with("&{am.stores.policy.password}"),
                                    replace("useSsl")
                                            .with(objectProvider(singletonMap("\$bool", "&{am.stores.policy.ssl.enabled|false}"))),
                                    replace("serverUrls")
                                            .with(objectProvider(singletonMap("\$list", "&{am.stores.policy.servers}")))))),

            forRealmService("amRealmBaseURL",
                    forRealmDefaults(where(isAnything(),
                            replace("fixedValue")
                                    .with("&{am.server.protocol|https}://&{am.server.fqdn}"))),
                    forSettings(
                            replace("fixedValue")
                                    .with("&{am.server.protocol|https}://&{am.server.fqdn}"))),

            forRealmService("AuthenticatorOATH",
                    forRealmDefaults(where(isAnything(),
                            replace("authenticatorOATHDeviceSettingsEncryptionKeystorePassword")
                                    .with("&{am.keystore.default.password}"),
                            replace("authenticatorOATHDeviceSettingsEncryptionKeystorePrivateKeyPassword")
                                    .with("&{am.keystore.default.entry.password}")))),

            forRealmService("AuthenticatorPush",
                    forRealmDefaults(where(isAnything(),
                            replace("authenticatorPushDeviceSettingsEncryptionKeystorePassword")
                                    .with("&{am.keystore.default.password}"),
                            replace("authenticatorPushDeviceSettingsEncryptionKeystorePrivateKeyPassword")
                                    .with("&{am.keystore.default.entry.password}")))),

            forRealmService("AuthenticatorWebAuthn",
                    forRealmDefaults(where(isAnything(),
                            replace("authenticatorWebAuthnDeviceSettingsEncryptionKeystorePassword")
                                    .with("&{am.keystore.default.password}"),
                            replace("authenticatorWebAuthnDeviceSettingsEncryptionKeystorePrivateKeyPassword")
                                    .with("&{am.keystore.default.entry.password}")))),

            forRealmService("DeviceId",
                    forRealmDefaults(where(isAnything(),
                            replace("deviceIdSettingsEncryptionKeystorePassword")
                                    .with("&{am.keystore.default.password}"),
                            replace("deviceIdSettingsEncryptionKeystorePrivateKeyPassword")
                                    .with("&{am.keystore.default.entry.password}")))),

            forRealmService("iPlanetAMAuthAmsterService",
                    forRealmDefaults(replace("authorizedKeys")
                            .with("&{secrets.path}/amster/authorized_keys")),
                    forSettings(replace("authorizedKeys")
                            .with("&{secrets.path}/amster/authorized_keys"))),

            forRealmService("iPlanetAMAuthService",
                    forRealmDefaults(within("security",
                            where(isAnything(),
                                    replace("sharedSecret")
                                            .with("&{am.authentication.shared.secret}"))))),

            forRealmService("iPlanetAMAuthLDAPService",
                    forRealmDefaults(
                            replace("primaryLdapServer")
                                    .with(objectProvider(
                                            singletonMap("\$list", "&{am.authentication.modules.ldap.servers}"))),
                            replace("userBindDN")
                                    .with("&{am.authentication.modules.ldap.username}")),
                    forSettings(
                            replace("userBindPassword")
                                    .with("&{am.authentication.modules.ldap.password}")),
                    forSettings(
                            replace("openam-auth-ldap-connection-mode")
                                    .with("&{am.authentication.modules.ldap.connection.mode}"))),

            forGlobalService("iPlanetAMPlatformService",
                    forDefaultInstanceSettings(
                            forNamedInstanceSettings("http://am:80/am",
                                    withinSet("serverconfig")
                                            .replaceValueOfKey("am.encryption.pwd")
                                            .with("&{am.encryption.key}"),
                                    replace("serverconfigxml")
                                            .with(objectProvider(singletonMap("\$inline", "serverconfig.xml")))),
                            forNamedInstanceSettings("server-default",
                                    withinSet("serverconfig")
                                            .replaceValueOfKey("am.encryption.pwd")
                                            .with("&{am.encryption.key}")
                                            .replaceValueOfKey("org.forgerock.services.cts.store.password")
                                            .with("&{am.stores.cts.password}")
                                            .replaceValueOfKey("org.forgerock.services.cts.store.directory.name")
                                            .with("&{am.stores.cts.servers|ds-cts-0.ds-cts:1389}")
                                            .replaceValueOfKey("org.forgerock.services.cts.store.loginid")
                                            .with("&{am.stores.cts.username|uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens}")
                                            .replaceValueOfKey("org.forgerock.services.cts.store.ssl.enabled")
                                            .with("&{am.stores.cts.ssl.enabled|false}")

                                            .replaceValueOfKey("org.forgerock.services.resourcesets.store.password")
                                            .with("&{am.stores.uma.password|&{am.stores.application.password}}")
                                            .replaceValueOfKey("org.forgerock.services.resourcesets.store.directory.name")
                                            .with("&{am.stores.uma.servers|&{am.stores.user.servers}}")
                                            .replaceValueOfKey("org.forgerock.services.resourcesets.store.loginid")
                                            .with("&{am.stores.uma.username|uid=am-config,ou=admins,ou=am-config}")
                                            .replaceValueOfKey("org.forgerock.services.resourcesets.store.ssl.enabled")
                                            .with("&{am.stores.uma.ssl.enabled|false}")

                                            .replaceValueOfKey("org.forgerock.services.umaaudit.store.password")
                                            .with("&{am.stores.uma.password|&{am.stores.application.password}}")
                                            .replaceValueOfKey("org.forgerock.services.umaaudit.store.directory.name")
                                            .with("&{am.stores.uma.servers|&{am.stores.user.servers}}")
                                            .replaceValueOfKey("org.forgerock.services.umaaudit.store.loginid")
                                            .with("&{am.stores.uma.username|uid=am-config,ou=admins,ou=am-config}")
                                            .replaceValueOfKey("org.forgerock.services.umaaudit.store.ssl.enabled")
                                            .with("&{am.stores.uma.ssl.enabled|false}")

                                            .replaceValueOfKey("org.forgerock.services.uma.pendingrequests.store.password")
                                            .with("&{am.stores.uma.password|&{am.stores.application.password}}")
                                            .replaceValueOfKey("org.forgerock.services.uma.pendingrequests.store.directory.name")
                                            .with("&{am.stores.uma.servers|&{am.stores.user.servers}}")
                                            .replaceValueOfKey("org.forgerock.services.uma.pendingrequests.store.loginid")
                                            .with("&{am.stores.uma.username|uid=am-config,ou=admins,ou=am-config}")
                                            .replaceValueOfKey("org.forgerock.services.uma.pendingrequests.store.ssl.enabled")
                                            .with("&{am.stores.uma.ssl.enabled|false}")

                                            .replaceValueOfKey("org.forgerock.services.uma.labels.store.password")
                                            .with("&{am.stores.uma.password|&{am.stores.application.password}}")
                                            .replaceValueOfKey("org.forgerock.services.uma.labels.store.directory.name")
                                            .with("&{am.stores.uma.servers|&{am.stores.user.servers}}")
                                            .replaceValueOfKey("org.forgerock.services.uma.labels.store.loginid")
                                            .with("&{am.stores.uma.username|uid=am-config,ou=admins,ou=am-config}")
                                            .replaceValueOfKey("org.forgerock.services.uma.labels.store.ssl.enabled")
                                            .with("&{am.stores.uma.ssl.enabled|false}")
                            ),
                            forNamedInstanceSettings("accesspoint",
                                    replace("primary-url").with("&{am.server.protocol|https}://&{am.server.fqdn}")))),

            forRealmService("iPlanetAMPolicyConfigService",
                    forSettings(where(isAnything(),
                            replace("bindDn")
                                    .with("&{am.stores.policy.username}"),
                            replace("bindPassword")
                                    .with("&{am.stores.policy.password}"),
                            replace("sslEnabled")
                                    .with(objectProvider(singletonMap("\$bool", "&{am.stores.policy.ssl.enabled}"))))),
                    forRealmDefaults(where(isAnything(),
                            replace("bindDn")
                                    .with("&{am.stores.policy.username}"),
                            replace("bindPassword")
                                    .with("&{am.stores.policy.password}"),
                            replace("sslEnabled")
                                    .with(objectProvider(singletonMap("\$bool", "&{am.stores.policy.ssl.enabled}"))),
                            replace("ldapServer")
                                    .with(objectProvider(singletonMap("\$list", "&{am.stores.policy.servers}")))))),

            forGlobalService("iPlanetAMSessionService",
                    forSettings(within("stateless",
                            where(isDefault(),
                                    replace("statelessSigningHmacSecret")
                                            .with("&{am.session.stateless.signing.key}")))),
                    forSettings(within("stateless",
                            where(isDefault(),
                                    replace("statelessEncryptionAesKey")
                                            .with("&{am.session.stateless.encryption.key}"))))),
                                            
            forRealmService("OAuth2Provider",
                    forRealmDefaults(within("advancedOAuth2Config",
                            where(isAnything(),
                                    replace("hashSalt")
                                            .with("&{am.oidc.client.subject.identifier.hash.salt}"))))),

            forRealmService("validationService",
                    forRealmDefaults(where(isAnything(),
                            replace("validGotoDestinations")
                                    .with(["&{am.server.protocol|https}://&{fqdn}/*?*"]))),
                    forSettings(
                                replace("validGotoDestinations")
                                        .with(["&{am.server.protocol|https}://&{fqdn}/*?*"])
                                        )),

            forGlobalService("iPlanetAMMonitoringService",
                    forDefaultInstanceSettings(where(isAnything(),
                            replace("password")
                                    .with("&{am.monitoring.prometheus.password.encrypted}")
                                    ))),

            forRealmService("RestSecurity",
                    forRealmDefaults(
                            replace("confirmationIdHmacKey")
                                    .with("&{am.selfservice.legacy.confirmation.email.link.signing.key}"))),

            forRealmService("sunFAMSAML2Configuration",
                    forRealmDefaults(where(isAnything(),
                            replace("metadataSigningKeyPass")
                                    .with("&{am.keystore.default.password}")))),

            forGlobalService("sunIdentityRepositoryService",
                    forDefaultInstanceSettings(
                            forNamedInstanceSettings("amAdmin",
                                    replace("userPassword")
                                            .with("&{am.passwords.amadmin.hashed.encrypted}")),
                            forNamedInstanceSettings("anonymous",
                                    replace("userPassword")
                                            .with("&{am.passwords.anonymous.hashed.encrypted}")),
                            forNamedInstanceSettings("dsameuser",
                                    replace("userPassword")
                                            .with("&{am.passwords.dsameuser.hashed.encrypted}")))),

            forRealmService("sunIdentityRepositoryService",
                    forDefaultInstanceSettings(
                            forNamedInstanceSettings("OpenDJ",
                                    within("ldapsettings",
                                            where(isAnything(),
                                                    replace("sun-idrepo-ldapv3-config-authpw")
                                                            .with("&{am.stores.user.password}"))),
                                    within("ldapsettings",
                                            where(isAnything(),
                                                    replace("sun-idrepo-ldapv3-config-authid")
                                                            .with("&{am.stores.user.username}"))),
                                    within("ldapsettings",
                                            where(isAnything(),
                                                    replace("sun-idrepo-ldapv3-config-connection-mode")
                                                            .with("&{am.stores.user.connection.mode}"))),
                                    within("ldapsettings",
                                            where(isAnything(),
                                                    replace("sun-idrepo-ldapv3-config-ldap-server")
                                                            .with(objectProvider(singletonMap("\$list", "&{am.stores.user.servers}")))))))),
    ]
}