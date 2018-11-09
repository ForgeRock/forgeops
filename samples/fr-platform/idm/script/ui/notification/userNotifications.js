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
    var userId = context.security.authorization.id, res, ret, params, notification;

    if (request.method === "read") {
        res = {};
        params = {
            "_queryId": "get-notifications-for-user",
            "userId": userId
        };
        ret = openidm.query("repo/ui/notification", params);

        if(ret && ret.result) {
            res = ret.result;
        }

        return {
            "notifications" : res
        };

    } else if (request.method === "delete") {
        notification = openidm.read("repo/ui/notification/"+request.resourcePath);

        if(notification !== null) {
            if (notification.receiverId === userId) {
                return openidm['delete']('repo/ui/notification/' + notification._id, notification._rev);
            } else {
                throw {
                    "code": 403,
                    "message": "Access denied"
                };
            }
        }
    } else {
        throw {
            "code" : 403,
            "message" : "Access denied"
        };
    }
}());
