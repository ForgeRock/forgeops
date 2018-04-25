/*
 * Copyright 2011-2017 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

define([
    "jquery",
    "underscore",
    "org/forgerock/commons/ui/common/main/AbstractDelegate",
    "org/forgerock/commons/ui/common/util/Constants",
    "org/forgerock/commons/ui/common/components/Navigation",
    "./PolicyTree",
    "org/forgerock/openidm/ui/admin/delegates/SiteConfigurationDelegate"
], function($, _,
            AbstractDelegate,
            Constants,
            Navigation,
            PolicyTree,
            adminSiteConfigurationDelegate) {

    var SiteConfigurationDelegate = function (url) {
            AbstractDelegate.call(this, url);
            return this;
        };

    SiteConfigurationDelegate.prototype = Object.create(adminSiteConfigurationDelegate);

    SiteConfigurationDelegate.prototype.getConfiguration = function (successCallback) {
        adminSiteConfigurationDelegate.getConfiguration.call(this, function (config) {
            PolicyTree.initialize().then(function () {
                successCallback(config);
            });
        });
    };

    SiteConfigurationDelegate.prototype.checkForDifferences = function() {
        return adminSiteConfigurationDelegate.checkForDifferences().then(function () {
            var adminNav = Navigation.configuration.links.admin;
            if (!adminNav.urls.managed.policiesApplied) {
                adminNav.urls.managed.urls = adminNav.urls.managed.urls.map(function (managedUrl) {
                    managedUrl.requiredResources = [{
                        "method": "GET",
                        "path": "managed/"+managedUrl.name+"?_queryFilter=*"
                    }];
                    return managedUrl;
                });

                var filterNav = function (navPoint) {
                    if (navPoint.requiredResources) {
                        if (!navPoint.requiredResources.reduce(function (result, requirement) {
                            return result && PolicyTree.evaluate(requirement.path, requirement.method);
                        }, true)) {
                            navPoint.cssClass = 'hidden';
                        }
                    }
                    if (navPoint.dropdown) {
                        navPoint.urls.forEach(function (subNav) {
                            filterNav(subNav);
                        });
                    } else if (navPoint.urls) {
                        Object.keys(navPoint.urls).forEach(function (subNavKey) {
                            filterNav(navPoint.urls[subNavKey]);
                        });
                    }
                };

                filterNav(adminNav);

                adminNav.urls.managed.policiesApplied = true;

                Navigation.reload();
            }
        });
    };



    return new SiteConfigurationDelegate(Constants.host + Constants.context + "/config/ui/configuration");
});
