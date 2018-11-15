/*
 * Copyright 2011-2017 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

/**
 * @author mbilski
 *
 * Endpoint for managing user notifications
 *
 */
(function () {

    if (request.method === "read") {

        var response = openidm.read(context.security.authorization.component + "/" + context.security.authorization.id, null, ["_notifications/*"]);

        return {
            "notifications" : response['_notifications']
        };

    } else if (request.method === "delete") {
        var notificationQuery = openidm.query(context.security.authorization.component + "/" + context.security.authorization.id + "/_notifications",
            {"_queryFilter": "_refResourceCollection eq 'internal/notification' AND _refResourceId eq '"+request.resourcePath+"'"});

        if (notificationQuery.result.length === 1) {
            return openidm['delete'](notificationQuery.result[0]._ref, null);
        } else {
            throw {
                "code": 403,
                "message": "Access denied"
            };
        }
    } else {
        throw {
            "code" : 403,
            "message" : "Access denied"
        };
    }
}());
