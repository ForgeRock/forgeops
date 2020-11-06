"use strict";
/*
 * Copyright 2014-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */
define(["org/forgerock/openidm/ui/common/util/Constants"], function (constants) {
    var obj = {
        moduleDefinition: [{
            moduleClass: "org/forgerock/commons/ui/common/main/SessionManager",
            configuration: {
                loginHelperClass: "org/forgerock/openidm/ui/common/login/InternalLoginHelper"
            }
        }, {
            moduleClass: "org/forgerock/openidm/ui/admin/connector/ConnectorRegistry",
            configuration: {
                "org.identityconnectors.ldap.LdapConnector_1.1": "org/forgerock/openidm/ui/admin/connector/ldap/LDAPTypeView",
                "org.identityconnectors.ldap.LdapConnector_1.4": "org/forgerock/openidm/ui/admin/connector/ldap/LDAPTypeView",
                "org.identityconnectors.ldap.LdapConnector_1.5": "org/forgerock/openidm/ui/admin/connector/ldap/LDAPTypeView",
                "org.forgerock.openicf.connectors.googleapps.GoogleAppsConnector_1.4": "org/forgerock/openidm/ui/admin/connector/oauth/GoogleTypeView",
                "org.forgerock.openicf.connectors.googleapps.GoogleAppsConnector_1.5": "org/forgerock/openidm/ui/admin/connector/oauth/GoogleTypeView",
                "org.forgerock.openicf.connectors.salesforce.SalesforceConnector_1.5": "org/forgerock/openidm/ui/admin/connector/oauth/SalesforceTypeView",
                "org.forgerock.openicf.connectors.marketo.MarketoConnector_1.4": "org/forgerock/openidm/ui/admin/connector/marketo/MarketoView",
                "org.forgerock.openicf.connectors.workday.WorkdayConnector_1.4": "org/forgerock/openidm/ui/admin/connector/workday/WorkdayView"
            }
        }, {
            moduleClass: "org/forgerock/openidm/ui/common/resource/ResourceEditViewRegistry",
            configuration: {
                "resource-assignment": "org/forgerock/openidm/ui/admin/assignment/AssignmentView",
                "resource-user": "org/forgerock/openidm/ui/admin/user/EditUserView",
                "resource-role": "org/forgerock/openidm/ui/admin/role/EditRoleView"
            }
        }, {
            moduleClass: "org/forgerock/commons/ui/common/components/Messages",
            configuration: {
                messages: {},
                loader: [{ "messages": "config/messages/CommonMessages" }, { "messages": "config/messages/CommonIDMMessages" }, { "messages": "config/messages/AdminMessages" }]
            }
        }, {
            moduleClass: "org/forgerock/commons/ui/common/SiteConfigurator",
            configuration: {
                remoteConfig: true,
                delegate: "org/forgerock/openidm/ui/admin/delegates/SiteConfigurationDelegate"
            }
        }, {
            moduleClass: "org/forgerock/commons/ui/common/main/ProcessConfiguration",
            configuration: {
                processConfigurationFiles: ["config/process/CommonConfig", "config/process/CommonIDMConfig", "config/process/AdminIDMConfig"]
            }
        }, {
            moduleClass: "org/forgerock/commons/ui/common/main/Router",
            configuration: {
                routes: {},
                loader: [{ "routes": "config/routes/CommonRoutesConfig" }, { "routes": "config/routes/CommonIDMRoutesConfig" }, { "routes": "config/routes/AdminRoutesConfig" }]
            }
        }, {
            moduleClass: "org/forgerock/commons/ui/common/main/ServiceInvoker",
            configuration: {
                defaultHeaders: {}
            }
        }, {
            moduleClass: "org/forgerock/commons/ui/common/main/ErrorsHandler",
            configuration: {
                defaultHandlers: {},
                loader: [{ "defaultHandlers": "config/errorhandlers/CommonErrorHandlers" }]
            }
        }, {
            moduleClass: "org/forgerock/commons/ui/common/components/Navigation",
            configuration: {
                userBar: [{
                    "id": "user_link",
                    "href": "",
                    "event": constants.EVENT_SELF_SERVICE_CONTEXT,
                    "i18nKey": "common.form.userView"
                }, {
                    "id": "logout_link",
                    "href": "#logout/",
                    "i18nKey": "common.form.logout"
                }],
                links: {
                    "admin": {
                        "role": "ui-admin",
                        "urls": {
                            "dashboard": {
                                "name": "config.AppConfiguration.Navigation.links.dashboard",
                                "icon": "fa fa-dashboard",
                                "dropdown": true,
                                "urls": []
                            },
                            "configuration": {
                                "name": "Configure",
                                "icon": "fa fa-wrench",
                                "dropdown": true,
                                "urls": [{
                                    "url": "#connectors/",
                                    "name": "config.AppConfiguration.Navigation.links.connectors",
                                    "icon": "fa fa-cubes",
                                    "inactive": false
                                }, {
                                    "url": "#managed/",
                                    "name": "config.AppConfiguration.Navigation.links.managedObjects",
                                    "icon": "fa fa-th",
                                    "inactive": false
                                }, {
                                    "url": "#mapping/",
                                    "name": "config.AppConfiguration.Navigation.links.mapping",
                                    "icon": "fa fa-map-marker",
                                    "inactive": false
                                }, {
                                    "url": "#scheduler/",
                                    "name": "config.AppConfiguration.Navigation.links.scheduler",
                                    "icon": "fa fa-calendar",
                                    "inactive": false
                                }, {
                                    "url": "#emailsettings/",
                                    "name": "config.AppConfiguration.Navigation.links.emailSettings",
                                    "icon": "fa fa-envelope",
                                    "inactive": false
                                }, {
                                    "url": "#termsAndConditions/",
                                    "name": "config.AppConfiguration.Navigation.links.termsAndConditions",
                                    "icon": "fa fa-check-square-o",
                                    "inactive": false
                                }, {
                                    "url": "#kba/",
                                    "name": "config.AppConfiguration.Navigation.links.kba",
                                    "icon": "fa fa-list-ol",
                                    "inactive": false
                                }, {
                                    "url": "#settings/",
                                    "name": "config.AppConfiguration.Navigation.links.systemPref",
                                    "icon": "fa fa-cog",
                                    "inactive": false
                                }]
                            },
                            "managed": {
                                "name": "config.AppConfiguration.Navigation.links.manage",
                                "icon": "fa fa-cogs",
                                "dropdown": true,
                                "urls": []
                            }
                        }
                    }
                }
            }
        }, {
            moduleClass: "org/forgerock/commons/ui/common/util/UIUtils",
            configuration: {
                templateUrls: [//preloaded templates
                ]
            }
        }, {
            moduleClass: "org/forgerock/commons/ui/common/main/ValidatorsManager",
            configuration: {
                validators: {},
                loader: [{ "validators": "config/validators/CommonValidators" }, { "validators": "config/validators/AdminValidators" }]
            }
        }],
        loggerLevel: 'debug'
    };
    return obj;
});
