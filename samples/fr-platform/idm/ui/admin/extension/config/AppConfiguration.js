/*
 * Copyright 2014-2017 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

define([
    "org/forgerock/openidm/ui/common/util/Constants"
], function(constants) {
    var obj = {
        moduleDefinition: [
            {
                moduleClass: "org/forgerock/commons/ui/common/main/SessionManager",
                configuration: {
                    loginHelperClass: "org/forgerock/openidm/ui/common/login/InternalLoginHelper"
                }
            },
            {
                moduleClass: "org/forgerock/openidm/ui/admin/connector/ConnectorRegistry",
                configuration: {
                    "org.identityconnectors.ldap.LdapConnector_1.1" : "org/forgerock/openidm/ui/admin/connector/ldap/LDAPTypeView",
                    "org.identityconnectors.ldap.LdapConnector_1.4" : "org/forgerock/openidm/ui/admin/connector/ldap/LDAPTypeView",
                    "org.forgerock.openicf.connectors.googleapps.GoogleAppsConnector_1.4" : "org/forgerock/openidm/ui/admin/connector/oauth/GoogleTypeView",
                    "org.forgerock.openidm.salesforce.Salesforce_5.5" : "org/forgerock/openidm/ui/admin/connector/oauth/SalesforceTypeView",
                    "org.forgerock.openicf.connectors.marketo.MarketoConnector_1.4" : "org/forgerock/openidm/ui/admin/connector/marketo/MarketoView"
                }
            },
            {
                moduleClass: "org/forgerock/openidm/ui/common/resource/ResourceEditViewRegistry",
                configuration: {
                    "resource-assignment" : "org/forgerock/openidm/ui/admin/assignment/AssignmentView",
                    "resource-user" : "org/forgerock/openidm/ui/admin/custom/EditUserView",
                    "resource-role" : "org/forgerock/openidm/ui/admin/role/EditRoleView"
                }
            },
            {
                moduleClass: "org/forgerock/commons/ui/common/components/Messages",
                configuration: {
                    messages: {
                    },
                    loader: [
                        {"messages":"config/messages/CommonMessages"},
                        {"messages":"config/messages/CommonIDMMessages"},
                        {"messages":"config/messages/AdminMessages"}
                    ]
                }
            },
            {
                moduleClass: "org/forgerock/commons/ui/common/SiteConfigurator",
                configuration: {
                    remoteConfig: true,
                    delegate: "org/forgerock/openidm/ui/admin/custom/SiteConfigurationDelegate"
                }
            },
            {
                moduleClass: "org/forgerock/commons/ui/common/main/ProcessConfiguration",
                configuration: {
                    processConfigurationFiles: [
                        "config/process/CommonConfig",
                        "config/process/CommonIDMConfig",
                        "config/process/AdminIDMConfig"
                    ]
                }
            },
            {
                moduleClass: "org/forgerock/commons/ui/common/main/Router",
                configuration: {
                    routes: {
                    },
                    loader: [
                        {"routes":"config/routes/CommonRoutesConfig"},
                        {"routes":"config/routes/CommonIDMRoutesConfig"},
                        {"routes":"config/routes/AdminRoutesConfig"}
                    ]
                }
            },
            {
                moduleClass: "org/forgerock/commons/ui/common/main/ServiceInvoker",
                configuration: {
                    defaultHeaders: {
                    }
                }
            },
            {
                moduleClass: "org/forgerock/commons/ui/common/main/ErrorsHandler",
                configuration: {
                    defaultHandlers: {
                    },
                    loader: [
                        {"defaultHandlers":"config/errorhandlers/CommonErrorHandlers"}
                    ]
                }
            },
            {
                moduleClass: "org/forgerock/commons/ui/common/components/Navigation",
                configuration: {
                    userBar: [
                        {
                            "id": "user_link",
                            "href": "",
                            "event" : constants.EVENT_SELF_SERVICE_CONTEXT,
                            "i18nKey": "common.form.userView"
                        },
                        {
                            "id": "logout_link",
                            "href": "#logout/",
                            "i18nKey": "common.form.logout"
                        }
                    ],
                    links: {
                        "admin" : {
                            "role": "ui-admin",
                            "urls": {
                                "dashboard": {
                                    "name": "config.AppConfiguration.Navigation.links.dashboard",
                                    "icon": "fa fa-dashboard",
                                    "dropdown": true,
                                    "urls": [],
                                    "requiredResources": [
                                        {
                                            "method": "GET",
                                            "path": "config/ui/dashboard"
                                        }
                                    ]
                                },
                                "configuration": {
                                    "name": "Configure",
                                    "icon": "fa fa-wrench",
                                    "dropdown": true,
                                    "urls" : [
                                        {
                                            "url": "#connectors/",
                                            "name": "config.AppConfiguration.Navigation.links.connectors",
                                            "icon": "fa fa-cubes",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "POST",
                                                    "path": "system?_action=test"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#managed/",
                                            "name": "config.AppConfiguration.Navigation.links.managedObjects",
                                            "icon": "fa fa-th",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "config/managed"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "config?_queryFilter="
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#mapping/",
                                            "name": "config.AppConfiguration.Navigation.links.mapping",
                                            "icon": "fa fa-map-marker",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "endpoint/mappingDetails"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#scheduler/",
                                            "name": "config.AppConfiguration.Navigation.links.scheduler",
                                            "icon": "fa fa-calendar",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "scheduler/job?*"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#authentication/",
                                            "name": "config.AppConfiguration.Navigation.links.authentication",
                                            "icon": "fa fa-user",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "config/authentication"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "identityProviders"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#social/",
                                            "name": "config.AppConfiguration.Navigation.links.socialProviders",
                                            "icon": "fa fa-users",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "identityProviders"
                                                },
                                                {
                                                    "method": "POST",
                                                    "path": "identityProviders?_action=availableProviders"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#emailsettings/",
                                            "name": "config.AppConfiguration.Navigation.links.emailSettings",
                                            "icon": "fa fa-envelope",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "config/external.email"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "config?_queryFilter=*"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#progressiveProfileForms/",
                                            "name": "config.AppConfiguration.Navigation.links.progressiveProfile",
                                            "icon": "fa fa-list",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "config/selfservice/profile"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#settings/",
                                            "name": "config.AppConfiguration.Navigation.links.systemPref",
                                            "icon": "fa fa-cog",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "config/audit"
                                                },
                                                {
                                                    "method": "POST",
                                                    "path": "audit?_action=availableHandlers"
                                                },
                                                {
                                                    "method": "POST",
                                                    "path": "maintenance?_action=status"
                                                }
                                            ]
                                        },
                                        {
                                            divider: true
                                        },
                                        {
                                            "header": true,
                                            "headerTitle": "config.AppConfiguration.Navigation.links.userSelfService"
                                        },
                                        {
                                            "url": "#selfservice/userregistration/",
                                            "name": "config.AppConfiguration.Navigation.links.userRegistration",
                                            "icon": "fa fa-user",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "config/selfservice/registration"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "config/external.email"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "config/consent"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "config/selfservice.terms"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "config/selfservice.kba"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "identityProviders"
                                                },
                                                {
                                                    "method": "POST",
                                                    "path": "script?_action=eval"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#selfservice/passwordreset/",
                                            "name": "config.AppConfiguration.Navigation.links.passwordReset",
                                            "icon": "fa fa-key",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "config/selfservice/reset"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "config/external.email"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "config/selfservice.kba"
                                                }
                                            ]
                                        },
                                        {
                                            "url": "#selfservice/forgotUsername/",
                                            "name": "config.AppConfiguration.Navigation.links.forgotUsername",
                                            "icon": "fa fa-question",
                                            "inactive": false,
                                            "requiredResources": [
                                                {
                                                    "method": "GET",
                                                    "path": "config/selfservice/username"
                                                },
                                                {
                                                    "method": "GET",
                                                    "path": "config/external.email"
                                                }
                                            ]
                                        }
                                    ]
                                },
                                "managed": {
                                    "name": "config.AppConfiguration.Navigation.links.manage",
                                    "icon": "fa fa-cogs",
                                    "dropdown": true,
                                    "urls" : []
                                },
                                "helpLinks": {
                                    "url": "#api",
                                    "icon": "fa fa-question-circle",
                                    "dropdown" : true,
                                    "navbarRight" : true,
                                    "urls": [{
                                        "url" : "#apiExplorer",
                                        "icon" : "fa fa-code",
                                        "name" : "config.AppConfiguration.Navigation.links.apiExplorer"
                                    }]
                                }
                            }
                        }
                    }
                }
            },
            {
                moduleClass: "org/forgerock/commons/ui/common/util/UIUtils",
                configuration: {
                    templateUrls: [ //preloaded templates
                    ]
                }
            },

            {
                moduleClass: "org/forgerock/commons/ui/common/main/ValidatorsManager",
                configuration: {
                    validators: { },
                    loader: [
                        {"validators":"config/validators/CommonValidators"},
                        {"validators":"config/validators/AdminValidators"}
                    ]
                }
            }
        ],
        loggerLevel: 'debug'
    };

    return obj;
});
