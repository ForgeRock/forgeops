(function () {

    self.addEventListener("install", (event) => {
        event.waitUntil(self.skipWaiting());
    });

    self.addEventListener("activate", (event) => {
        event.waitUntil(self.clients.claim());
    });

    self.addEventListener("message", (event) => {
        if (event.data.message === "configuration") {
            self.appAuthConfig = event.data.config;
            self.failedRequestQueue = self.failedRequestQueue || {};
            self.messageChannel = event.ports[0];

            event.waitUntil(self.clients.claim().then(() =>
                self.messageChannel.postMessage({
                    "message": "configured"
                })
            ));
        } else if (event.data.message === "tokensRenewed") {
            self.retryFailedRequests(event.data.resourceServer);
        }
    });

    self.waitForRenewedToken = function (resourceServer) {
        return new Promise((resolve, reject) => {
            if (!self.failedRequestQueue[resourceServer]) {
                self.failedRequestQueue[resourceServer] = [];
            }
            self.failedRequestQueue[resourceServer].push([resolve, reject]);
        });
    };

    self.retryFailedRequests = function (resourceServer) {
        if (self.failedRequestQueue && self.failedRequestQueue[resourceServer]) {
            var p = self.failedRequestQueue[resourceServer].shift();
            while (p) {
                p[0]();
                p = self.failedRequestQueue[resourceServer].shift();
            }
        }
    };

    self.getAuthHeaderDetails = function (headers) {
        var authHeader = headers.get("www-authenticate");

        if (authHeader && authHeader.match(/^Bearer /)) {
            return authHeader.replace(/^Bearer /, "")
                .match(/[^,=]+=".*?"/g)
                .reduce(function (result, detail) {
                    var pair = detail.split("=");
                    result[pair[0]] = pair[1].replace(/"(.*)"/, "$1");
                    return result;
                }, {});
        } else {
            return {};
        }
    };


    self.fetchTokensFromIndexedDB = function () {
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
    };


    self.addAccessTokenToRequest = function (request, resourceServer) {
        return new Promise((resolve, reject) => {
            self.fetchTokensFromIndexedDB().then((tokens) => {
                var rsHeaders =  new Headers(request.headers);

                if (!tokens[resourceServer]) {
                    self.waitForRenewedToken(resourceServer).then(() => {
                        self.addAccessTokenToRequest(request, resourceServer).then(resolve, reject);
                    }, reject);
                    self.messageChannel.postMessage({
                        "message":"renewTokens",
                        "resourceServer": resourceServer
                    });
                } else {
                    rsHeaders.set("Authorization", `Bearer ${tokens[resourceServer]}`);

                    request.clone().text().then((bodyText) => resolve(new Request(request.url, {
                        method: request.method,
                        headers: rsHeaders,
                        body: ["GET","HEAD"].indexOf(request.method.toUpperCase()) === -1 && bodyText.length ? bodyText : undefined,
                        mode: request.mode,
                        credentials: request.credentials,
                        cache: request.cache,
                        redirect: request.redirect,
                        referrer: request.referrer,
                        integrity: request.integrity
                    })));
                }
            }, reject);
        });
    };

    self.addEventListener("fetch", (event) => {
        if (self.appAuthConfig &&
            typeof self.appAuthConfig.resourceServers === "object" &&
            Object.keys(self.appAuthConfig.resourceServers).length) {

            var resourceServer = Object.keys(self.appAuthConfig.resourceServers)
                .filter((rs) => event.request.url.indexOf(rs) === 0)[0];

            if (resourceServer) {
                event.respondWith(new Promise((resolve, reject) => {
                    self.addAccessTokenToRequest(event.request, resourceServer)
                        .then((rsRequest) => fetch(rsRequest))
                        .then((resp) => {
                            // Watch for retry-able errors as described by https://tools.ietf.org/html/rfc6750#section-3
                            if (!resp.ok && self.getAuthHeaderDetails(resp.headers)["error"] === "invalid_token") {
                                let promise = self.waitForRenewedToken(resourceServer)
                                    .then(() => self.addAccessTokenToRequest(event.request, resourceServer))
                                    .then((freshRSRequest) => fetch(freshRSRequest));

                                self.messageChannel.postMessage({
                                    "message":"renewTokens",
                                    "resourceServer": resourceServer
                                });
                                return promise;
                            } else {
                                return resp;
                            }
                        })
                        .then(resolve, reject);
                }));
            }
        }
        return;
    });
}());
