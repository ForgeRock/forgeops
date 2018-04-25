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
    "org/forgerock/commons/ui/common/util/Constants",
    "org/forgerock/commons/ui/common/main/AbstractDelegate",
    "org/forgerock/openidm/ui/common/delegates/ConfigDelegate",
    "org/forgerock/commons/ui/common/components/Messages",
    "org/forgerock/commons/ui/common/util/ObjectUtil"
], function($, _, Constants, AbstractDelegate, configDelegate, messagesManager, ObjectUtil) {

    var obj = new AbstractDelegate(Constants.host + Constants.context + "/");

    obj.getSchema = function(args){
        var objectType = args[0],
            objectName = args[1],
            objectName2 = args[2];

        if (objectType === "managed") {
            return configDelegate.readEntity("managed").then(function(managed){
                var managedObject = _.findWhere(managed.objects,{ name: objectName });

                if(managedObject){
                    if(managedObject.schema){
                        managedObject.schema.allSchemas = managed.objects;
                        return managedObject.schema;
                    } else {
                        return false;
                    }
                } else {
                    return "invalidObject";
                }
            });
        } else if (objectType === "system") {
            return obj.getProvisioner(objectType, objectName).then(function(prov){
                var schema;

                if(prov.objectTypes){
                    schema = prov.objectTypes[objectName2];
                    if(schema){
                        schema.title = objectName;
                        return schema;
                    } else {
                        return false;
                    }
                } else {
                    return "invalidObject";
                }
            });
        } else {
            return $.Deferred().resolve({});
        }
    };

    obj.serviceCall = function (callParams) {
        callParams.errorsHandlers = callParams.errorsHandlers || {};
        callParams.errorsHandlers.policy = {
            status: 403,
            event: Constants.EVENT_POLICY_FAILURE
        };

        return AbstractDelegate.prototype.serviceCall.call(this, callParams);
    };

    obj.createResource = function (serviceUrl) {
        return AbstractDelegate.prototype.createEntity.apply(_.extend({}, AbstractDelegate.prototype, this, {"serviceUrl": serviceUrl}), _.toArray(arguments).slice(1));
    };
    obj.readResource = function (serviceUrl) {
        return AbstractDelegate.prototype.readEntity.apply(_.extend({}, AbstractDelegate.prototype, this, {"serviceUrl": serviceUrl}), _.toArray(arguments).slice(1));
    };
    obj.updateResource = function (serviceUrl) {
        return AbstractDelegate.prototype.updateEntity.apply(_.extend({}, AbstractDelegate.prototype, this, {"serviceUrl": serviceUrl}), _.toArray(arguments).slice(1));
    };
    obj.deleteResource = function (serviceUrl, id, successCallback, errorCallback) {
        var callParams = {
            serviceUrl: serviceUrl, url: "/" + id,
            type: "DELETE",
            success: successCallback,
            error: errorCallback,
            errorsHandlers: {
                "Conflict": {
                    status: 409
                }
            },
            headers: {
                "If-Match": "*"
            }
        };

        return obj.serviceCall(callParams).fail(function(err){
            var response = err.responseJSON;
            if(response.code === 409) {
                messagesManager.messages.addMessage({"type": "error", "message": response.message});
            }
        });
    };
    obj.patchResourceDifferences = function (serviceUrl, queryParameters, oldObject, newObject, successCallback, errorCallback) {
        var patchDefinition = ObjectUtil.generatePatchSet(newObject, oldObject);

        if(patchDefinition.length === 0) {
            return $.Deferred().resolve(oldObject).then(successCallback(oldObject));
        } else {
            return AbstractDelegate.prototype.patchEntity.apply(_.extend({}, AbstractDelegate.prototype, this, {"serviceUrl": serviceUrl}), [queryParameters, patchDefinition, successCallback, errorCallback]);
        }
    };

    obj.getServiceUrl = function(args) {
        var url = Constants.context + "/" + args[0] + "/" + args[1];

        if(args[0] === "system") {
            url += "/" + args[2];
        }

        return url;
    };

    obj.searchResource = function(filter, serviceUrl) {
        return obj.serviceCall({
            url: serviceUrl +"?_queryFilter="+filter
        });
    };

    obj.getProvisioner = function(objectType, objectName) {
        return obj.serviceCall({
            serviceUrl: obj.serviceUrl + objectType + "/" + objectName,
            url: "?_action=test",
            type: "POST",
            errorsHandlers: {
                "NotFound": {
                    status: 404
                }
            }
        }).then(function(connector) {
            var config = connector.config.replace("config/","");

            return configDelegate.readEntity(config);
        });
    };

    obj.linkedView = function(id, resourcePath) {
        return obj.serviceCall({
            serviceUrl: Constants.host + Constants.context + "/endpoint/linkedView/" + resourcePath,
            url: id,
            type: "GET",
            errorsHandlers: {
                "NotAuthorized": {
                    status: 403
                }
            }
        });
    };

    obj.queryStringForSearchableFields = function (searchFields, query) {
        var queryFilter = "",
            queryFilterArr = [];
        /*
         * build up the queryFilterArr based on searchFields
         */
        _.each(searchFields, function (field) {
            queryFilterArr.push(field + " sw \"" + query + "\"");
        });

        queryFilter = queryFilterArr.join(" or ") + "&_pageSize=10&_fields=*";

        return queryFilter;
    };

    obj.getResource = function (url) {
        return obj.serviceCall({ url: url });
    };

    return obj;
});
