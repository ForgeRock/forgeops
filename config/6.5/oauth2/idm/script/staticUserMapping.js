(function () {
    var foundMapping = staticUserMapping.filter(function (mapping) {
        return mapping.idpUser === security.authenticationId;
    })[0];

    if (foundMapping) {
        // copy and update necessary fields within security authorization map
        var securityContextClone = {};
        Object.keys(security.authorization).forEach(function (k) {
            securityContextClone[k] = security.authorization[k];
        });

        var localUser = openidm.read(foundMapping.localUser, null, [foundMapping.userRoles]);
        if (!localUser) {
            throw {
                "code" : 401
            };
        }

        securityContextClone.id = localUser._id;
        securityContextClone.roles = localUser[foundMapping.userRoles].map(function (role) {
            if (typeof role === "string") {
                return role;
            } else {
                return role._ref;
            }
        });

        security.authorization = securityContextClone;
    } else {
        throw {
            "code" : 401
        };
    }

    return security;
}());
