(function () {
    "use strict";

    module.exports = function IdentityProxyCore(appAuthConfig) {
        this.appAuthConfig = appAuthConfig;
        this.failedRequestQueue = this.failedRequestQueue || {};
        return this;
    };

    module.exports.prototype = {
        waitForRenewedToken: function (resourceServer) {
            return new Promise((resolve, reject) => {
                if (!this.failedRequestQueue[resourceServer]) {
                    this.failedRequestQueue[resourceServer] = [];
                }
                this.failedRequestQueue[resourceServer].push([resolve, reject]);
            });
        },
        retryFailedRequests: function (resourceServer) {
            if (this.failedRequestQueue && this.failedRequestQueue[resourceServer]) {
                var p = this.failedRequestQueue[resourceServer].shift();
                while (p) {
                    p[0]();
                    p = this.failedRequestQueue[resourceServer].shift();
                }
            }
        },
        getResourceServerFromUrl: function (url) {
            if (typeof this.appAuthConfig.resourceServers === "object" &&
                Object.keys(this.appAuthConfig.resourceServers).length) {

                return Object.keys(this.appAuthConfig.resourceServers)
                    .filter((rs) => url.indexOf(rs) === 0)[0];
            } else {
                return undefined;
            }
        },
        fetchTokensFromIndexedDB: function () {
            return new Promise((function (resolve, reject) {
                var dbReq = indexedDB.open("appAuth"),
                    upgradeDb = (function () {
                        return dbReq.result.createObjectStore(this.appAuthConfig.clientId);
                    }).bind(this),
                    onsuccess;
                onsuccess = (function () {
                    if (!dbReq.result.objectStoreNames.contains(this.appAuthConfig.clientId)) {
                        var version = dbReq.result.version;
                        version++;
                        dbReq.result.close();
                        dbReq = indexedDB.open("appAuth", version);
                        dbReq.onupgradeneeded = upgradeDb;
                        dbReq.onsuccess = onsuccess;
                        return;
                    }
                    var objectStoreRequest = dbReq.result.transaction([this.appAuthConfig.clientId], "readonly")
                        .objectStore(this.appAuthConfig.clientId).get("tokens");
                    objectStoreRequest.onsuccess = (function () {
                        var tokens = objectStoreRequest.result;
                        dbReq.result.close();
                        resolve(tokens);
                    }).bind(this);
                    objectStoreRequest.onerror = reject;
                }).bind(this);

                dbReq.onupgradeneeded = upgradeDb;
                dbReq.onsuccess = onsuccess;
                dbReq.onerror = reject;
            }).bind(this));
        },
        addAccessTokenToRequest: function (request, resourceServer) {
            return new Promise((resolve, reject) => {
                this.fetchTokensFromIndexedDB().then((tokens) => {
                    if (!tokens[resourceServer]) {
                        this.waitForRenewedToken(resourceServer).then(() => {
                            this.addAccessTokenToRequest(request, resourceServer).then(resolve, reject);
                        }, reject);
                        this.renewTokens(resourceServer);
                    } else {
                        this.addAuthorizationRequestHeader(resolve, request, tokens[resourceServer]);
                    }
                }, reject);
            });
        },
        interceptRequest: function (request, resourceServer) {
            return new Promise((resolve, reject) => {
                this.addAccessTokenToRequest(request, resourceServer)
                    .then((rsRequest) => this.makeRequest(rsRequest))
                    .then((resp) => {
                        // Watch for retry-able errors as described by https://tools.ietf.org/html/rfc6750#section-3
                        if (this.getAuthHeaderDetails(resp)["error"] === "invalid_token") {
                            let promise = this.waitForRenewedToken(resourceServer)
                                .then(() => this.addAccessTokenToRequest(request, resourceServer))
                                .then((freshRSRequest) => this.makeRequest(freshRSRequest));

                            this.renewTokens(resourceServer);
                            return promise;
                        } else {
                            return resp;
                        }
                    })
                    .then(resolve, reject);
            });
        },
        renewTokens: function () {/* implementation needed */},
        addAuthorizationRequestHeader: function () {/* implementation needed */},
        getAuthHeaderDetails: function () {/* implementation needed*/},
        makeRequest: function () {/* implementation needed*/}
    };
}());
