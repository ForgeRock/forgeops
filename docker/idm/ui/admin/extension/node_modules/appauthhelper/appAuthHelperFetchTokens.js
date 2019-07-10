(function () {
    "use strict";

    var AppAuth = require("@openid/appauth");

    var appAuthConfig = JSON.parse(sessionStorage.getItem("appAuthConfig")),
        currentResourceServer = sessionStorage.getItem("currentResourceServer"),
        appAuthClient,
        tokenHandler;

    function fetchTokensFromIndexedDB () {
        return new Promise((function (resolve, reject) {
            var dbReq = indexedDB.open("appAuth"),
                upgradeDb = (function () {
                    return dbReq.result.createObjectStore(appAuthConfig.clientId);
                }).bind(this),
                onsuccess;
            onsuccess = (function () {
                if (!dbReq.result.objectStoreNames.contains(appAuthConfig.clientId)) {
                    var version = dbReq.result.version;
                    version++;
                    dbReq.result.close();
                    dbReq = indexedDB.open("appAuth", version);
                    dbReq.onupgradeneeded = upgradeDb;
                    dbReq.onsuccess = onsuccess;
                    return;
                }
                var objectStoreRequest = dbReq.result.transaction([appAuthConfig.clientId], "readonly")
                    .objectStore(appAuthConfig.clientId).get("tokens");
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
    }

    if (typeof Promise === "undefined" || typeof fetch === "undefined") {
        // Fall back to default, jQuery-based implementation for legacy browsers (IE).
        // Be sure jQuery is available globally if you need to support these.
        tokenHandler = new AppAuth.BaseTokenRequestHandler();
    } else {
        tokenHandler = new AppAuth.BaseTokenRequestHandler({
            // fetch-based alternative to built-in jquery implementation
            xhr: function (settings) {
                return new Promise(function (resolve, reject) {
                    fetch(settings.url, {
                        method: settings.method,
                        body: settings.data,
                        mode: "cors",
                        cache: "no-cache",
                        headers: settings.headers
                    }).then(function (response) {
                        if (response.ok) {
                            response.json().then(resolve);
                        } else {
                            reject(response.statusText);
                        }
                    }, reject);
                });
            }
        });
    }

    appAuthClient = {
        clientId: appAuthConfig.clientId,
        scopes: appAuthConfig.scopes,
        redirectUri: appAuthConfig.redirectUri,
        configuration: new AppAuth.AuthorizationServiceConfiguration(appAuthConfig.endpoints),
        notifier: new AppAuth.AuthorizationNotifier(),
        authorizationHandler: new AppAuth.RedirectRequestHandler(),
        tokenHandler: tokenHandler
    };

    appAuthClient.authorizationHandler.setAuthorizationNotifier(appAuthClient.notifier);

    /**
     * This is invoked when the browser has returned from the OP with either a code or an error.
     */
    appAuthClient.notifier.setAuthorizationListener(function (request, response, error) {
        if (response) {
            appAuthClient.request = request;
            appAuthClient.response = response;
            appAuthClient.code = response.code;
        }
        if (error) {
            appAuthClient.error = error;
        }
    });

    appAuthClient.authorizationHandler.completeAuthorizationRequestIfPossible()
        .then(function () {
            var request;
            // The case when the user has successfully returned from the authorization request
            if (appAuthClient.code) {
                var extras = {};
                // PKCE support
                if (appAuthClient.request && appAuthClient.request.internal) {
                    extras["code_verifier"] = appAuthClient.request.internal["code_verifier"];
                }
                request = new AppAuth.TokenRequest({
                    client_id: appAuthClient.clientId,
                    redirect_uri: appAuthClient.redirectUri,
                    grant_type: AppAuth.GRANT_TYPE_AUTHORIZATION_CODE,
                    code: appAuthClient.code,
                    refresh_token: undefined,
                    extras: extras
                });
                appAuthClient.tokenHandler
                    .performTokenRequest(appAuthClient.configuration, request)
                    .then(function (token_endpoint_response) {
                        fetchTokensFromIndexedDB().then((tokens) => {
                            if (!tokens) {
                                tokens = {};
                            }
                            if (token_endpoint_response.idToken) {
                                tokens["idToken"] = token_endpoint_response.idToken;
                            }
                            if (currentResourceServer !== null) {
                                tokens[currentResourceServer] = token_endpoint_response.accessToken;
                            } else {
                                tokens.accessToken = token_endpoint_response.accessToken;
                            }

                            var dbReq = indexedDB.open("appAuth");
                            dbReq.onsuccess = function () {
                                var objectStoreRequest = dbReq.result.transaction([appAuthClient.clientId], "readwrite")
                                    .objectStore(appAuthClient.clientId).put(tokens, "tokens");
                                objectStoreRequest.onsuccess = function () {
                                    dbReq.result.close();
                                    parent.postMessage( "appAuth-tokensAvailable", document.location.origin);
                                };
                            };
                        });
                    });
            } else if (appAuthClient.error) {
                parent.postMessage("appAuth-interactionRequired", document.location.origin);
            }

        });
}());
