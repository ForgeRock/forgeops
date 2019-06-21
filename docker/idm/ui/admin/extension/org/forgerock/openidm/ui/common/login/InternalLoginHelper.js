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
    "org/forgerock/openidm/ui/common/UserModel",
    "org/forgerock/commons/ui/common/main/EventManager",
    "org/forgerock/commons/ui/common/main/AbstractConfigurationAware",
    "org/forgerock/commons/ui/common/main/ServiceInvoker",
    "org/forgerock/commons/ui/common/main/Configuration",
    "org/forgerock/openidm/ui/common/util/Constants"
], function ($, _,
             UserModel,
             eventManager,
             AbstractConfigurationAware,
             serviceInvoker,
             conf,
             Constants) {
    var obj = new AbstractConfigurationAware();

    obj.login = function(params, successCallback, errorCallback) {
        if (_.has(params, "userName") && _.has(params, "password")) {
            return (new UserModel()).login(params.userName, params.password).then(successCallback, function (xhr) {
                var reason = xhr.responseJSON.reason;
                if (reason === "Unauthorized") {
                    reason = "authenticationFailed";
                }
                if (errorCallback) {
                    errorCallback(reason);
                }
            });
        } else if (_.has(params, "oauthLogin")) {
            return (new UserModel()).oauthLogin(params.provider).then(successCallback, function (xhr) {
                var reason = xhr.responseJSON.reason;

                if (reason === "Unauthorized") {
                    eventManager.sendEvent(Constants.EVENT_DISPLAY_MESSAGE_REQUEST, {"key" : "socialAuthenticationFailed"});
                    errorCallback();
                } else {
                    errorCallback(xhr);
                }
            });
        }
    };

    obj.logout = function (successCallback) {
        // var promise;
        // if (conf.loggedUser) {
        //     promise = conf.loggedUser.logout().then((logoutUrl) => {
        //         delete conf.loggedUser;
        //         return logoutUrl;
        //     });
        // } else {
        //     promise = $.Deferred().resolve();
        // }
        //
        // promise.then((logoutUrl) => {
        //     if (logoutUrl || conf.globalData.logoutUrl) {
        //         window.location.href = logoutUrl || conf.globalData.logoutUrl;
        //         return false;
        //     }
        //
        //     successCallback();
        // });
        window.logout();
    };

    obj.getLoggedUser = function(successCallback, errorCallback) {
        return (new UserModel()).getProfile().then(successCallback, function(e) {
            if(e.responseJSON && e.responseJSON.detail && e.responseJSON.detail.failureReasons && e.responseJSON.detail.failureReasons.length){
                if(_.where(e.responseJSON.detail.failureReasons,{ isAlive: false }).length){
                    conf.globalData.authenticationUnavailable = true;
                }
            }
            errorCallback();
        });

    };
    return obj;
});
