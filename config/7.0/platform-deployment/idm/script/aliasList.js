(function () {
    exports.update = function (object) {
        var managedUser = openidm.read("managed/user/" + object._id, null, ["idps"]);
        if (managedUser && managedUser.idps) {
            object.aliasList = managedUser.idps.map(function(relationship) {
                var provider = relationship["_ref"].split("/");
                return provider[1] + '-' + provider[2];
            });
        } else {
            object.aliasList = [];
        }
    };
}());
