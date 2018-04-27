define([
    "jquery",
    "org/forgerock/commons/ui/common/main/AbstractDelegate",
    "org/forgerock/commons/ui/common/util/Constants"
], function ($, AbstractDelegate, Constants) {

    var PolicyTree = new AbstractDelegate("/policyTree/");

    var matches = function (resourcePattern, url) {
        var regexp = new RegExp('^' + resourcePattern.replace('?', '\\?').replace(/\*/g, '[^\\?]*') + '[^\\?]*$');
        return !!url.match(regexp);
    }

    var urlForPath = function (path) {
        var url = (Constants.host || window.location.origin);
        if (!window.location.port.length) {
            if (window.location.protocol === "https:") {
                url += ":443";
            } else {
                url += ":80";
            }
        }
        url += Constants.context + "/" + path;
        return url;
    }

    PolicyTree.initialize = function () {
        return PolicyTree.serviceCall({}).then(function (resp) {
            PolicyTree.policies = resp;
        });
    };

    PolicyTree.evaluate = function (path, method) {
        var url = urlForPath(path);
        return this.policies.reduce(function (result, currentPolicy) {
            return result || (matches(currentPolicy.resource, url) && currentPolicy.actions[method]);
        }, false);
    };

    PolicyTree.getAllowedFieldsToPatch = function (path) {
        var url = urlForPath(path),
            patchPolicy = this.policies.filter(function (currentPolicy) {
                return matches(currentPolicy.resource, url) && currentPolicy.actions["PATCH"];
            })[0];
        if (!patchPolicy) {
            return [];
        } else {
            // may be undefined if user is allowed
            return patchPolicy.attributes.allowedFields;
        }
    };

    return PolicyTree;
})
