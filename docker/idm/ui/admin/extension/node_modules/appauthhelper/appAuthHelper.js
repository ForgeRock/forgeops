(function () {
    "use strict";

    var AppAuth = require("@openid/appauth");

    /**
     * Module used to easily setup AppAuthJS in a way that allows it to transparently obtain and renew access tokens
     * @module AppAuthHelper
     */
    module.exports = {
        /** @function init
         * @param {Object} config - configation needed for working with the OP
         * @param {string} config.clientId - The id of this RP client within the OP
         * @param {boolean} config.oidc [true] - indicate whether or not you want OIDC included
         * @param {string} config.authorizationEndpoint - Full URL to the OP authorization endpoint
         * @param {string} config.tokenEndpoint - Full URL to the OP token endpoint
         * @param {string} config.revocationEndpoint - Full URL to the OP revocation endpoint
         * @param {string} config.endSessionEndpoint - Full URL to the OP end session endpoint
         * @param {object} config.resourceServers - Map of resource server urls to the scopes which they require. Map values are space-delimited list of scopes requested by this RP for use with this RS
         * @param {function} config.interactionRequiredHandler - optional function to be called anytime interaction is required. When not provided, default behavior is to redirect the current window to the authorizationEndpoint
         * @param {function} config.tokensAvailableHandler - function to be called every time tokens are available - both initially and upon renewal
         * @param {number} config.renewCooldownPeriod [1] - Minimum time (in seconds) between requests to the authorizationEndpoint for token renewal attempts
         * @param {string} config.redirectUri [appAuthHelperRedirect.html] - The redirect uri registered in the OP
         * @param {string} config.serviceWorkerUri [appAuthServiceWorker.js] - The path to the service worker script
         */
        init: function (config) {
            var calculatedUriLink,
                iframe = document.createElement("iframe");

            this.renewCooldownPeriod = config.renewCooldownPeriod || 1;
            this.appAuthConfig = {};
            this.tokensAvailableHandler = config.tokensAvailableHandler;
            this.interactionRequiredHandler = config.interactionRequiredHandler;
            this.appAuthConfig.oidc = typeof config.oidc !== "undefined" ? !!config.oidc : true;
            this.pendingResourceServerRenewals = [];

            if (!config.redirectUri) {
                calculatedUriLink = document.createElement("a");
                calculatedUriLink.href = "appAuthHelperRedirect.html";

                this.appAuthConfig.redirectUri = calculatedUriLink.href;
            } else {
                this.appAuthConfig.redirectUri = config.redirectUri;
            }

            if (!config.serviceWorkerUri) {
                calculatedUriLink = document.createElement("a");
                calculatedUriLink.href = "appAuthServiceWorker.js";

                this.appAuthConfig.serviceWorkerUri = calculatedUriLink.href;
            } else {
                this.appAuthConfig.serviceWorkerUri = config.serviceWorkerUri;
            }


            this.appAuthConfig.resourceServers = config.resourceServers || {};
            this.appAuthConfig.clientId = config.clientId;
            this.appAuthConfig.scopes = (this.appAuthConfig.oidc ? ["openid"] : [])
                .concat(
                    Object.keys(this.appAuthConfig.resourceServers).reduce((function (scopes, rs) {
                        return scopes.concat(this.appAuthConfig.resourceServers[rs]);
                    }).bind(this), [])
                ).join(" ");

            this.appAuthConfig.endpoints = {
                "authorization_endpoint": config.authorizationEndpoint,
                "token_endpoint": config.tokenEndpoint,
                "revocation_endpoint": config.revocationEndpoint,
                "end_session_endpoint": config.endSessionEndpoint
            };

            window.addEventListener("message", (function (e) {
                if (e.origin !== document.location.origin) {
                    return;
                }
                switch (e.data) {
                case "appAuth-tokensAvailable":
                    var originalWindowHash = sessionStorage.getItem("originalWindowHash-" + this.appAuthConfig.clientId);
                    if (originalWindowHash !== null) {
                        window.location.hash = originalWindowHash;
                        sessionStorage.removeItem("originalWindowHash-" + this.appAuthConfig.clientId);
                    }

                    // this should only be set as part of token renewal
                    if (sessionStorage.getItem("currentResourceServer")) {
                        var currentResourceServer = sessionStorage.getItem("currentResourceServer");
                        sessionStorage.removeItem("currentResourceServer");
                        this.renewTokenTimestamp = false;

                        if (this.pendingResourceServerRenewals.length) {
                            this.pendingResourceServerRenewals.shift()();
                        }

                        this.identityProxy.tokensRenewed(currentResourceServer);
                    } else {
                        this.registerIdentityProxy()
                            .then((function() { return this.fetchTokensFromIndexedDB(); }).bind(this))
                            .then((function (tokens) {
                                return this.tokensAvailableHandler(this.appAuthConfig.oidc ? getIdTokenClaims(tokens.idToken) : {});
                            }).bind(this));
                    }

                    break;
                case "appAuth-interactionRequired":
                    if (this.interactionRequiredHandler) {
                        this.interactionRequiredHandler();
                    } else {
                        // Default behavior for when interaction is required is to redirect to the OP for login.

                        // When interaction is required, the current hash state may be lost during redirection.
                        // Save it in sessionStorage so that it can be returned to upon successfully authenticating
                        sessionStorage.setItem("originalWindowHash-" + this.appAuthConfig.clientId, window.location.hash);

                        // Use the default redirect request handler, because it will use the current window
                        // as the redirect target (rather than the hidden iframe).
                        this.client.authorizationHandler = (new AppAuth.RedirectRequestHandler());
                        authnRequest(this.client, this.appAuthConfig);
                    }

                    break;
                }
            }).bind(this), false);


            /*
             * Attach a hidden iframe onto the main document body that is used to handle
             * interaction with the token endpoint. This will allow us to perform
             * background access token renewal, in addition to handling the main PKCE-based
             * authorization code flow performed in the foreground.
             *
             * sessionStorage is used to pass the configuration down to the iframe
             */
            sessionStorage.setItem("appAuthConfig", JSON.stringify(this.appAuthConfig));

            iframe.setAttribute("src", "about:blank");
            iframe.setAttribute("id", "AppAuthHelper");
            iframe.setAttribute("style", "display:none");
            document.getElementsByTagName("body")[0].appendChild(iframe);

            var tokenHandler;
            if (typeof Promise === "undefined" || typeof fetch === "undefined") {
                // Fall back to default, jQuery-based implementation for legacy browsers (IE).
                // Be sure jQuery is available globally if you need to support these.
                tokenHandler = new AppAuth.BaseTokenRequestHandler();
            } else {
                tokenHandler = new AppAuth.BaseTokenRequestHandler(new AppAuth.FetchRequestor());
            }

            this.client = {
                configuration: new AppAuth.AuthorizationServiceConfiguration(this.appAuthConfig.endpoints),
                notifier: new AppAuth.AuthorizationNotifier(),
                authorizationHandler: new AppAuth.RedirectRequestHandler(
                    // handle redirection within the hidden iframe
                    void 0, void 0, iframe.contentWindow.location
                ),
                tokenHandler: tokenHandler
            };

            // There normally shouldn't be an active authorization request going on when AppAuthHelper.init is
            // called. Just in case we somehow got here with a remnant left over, clean it out.
            this.checkForActiveAuthzRequest().then((function (activeRequestHandle) {
                if (activeRequestHandle) {
                    return Promise.all([
                        this.client.authorizationHandler.storageBackend.removeItem("appauth_current_authorization_request"),
                        this.client.authorizationHandler.storageBackend.removeItem(activeRequestHandle + "_appauth_authorization_request"),
                        this.client.authorizationHandler.storageBackend.removeItem(activeRequestHandle + "_appauth_authorization_service_configuration")
                    ]);
                }
            }).bind(this));
        },
        checkForActiveAuthzRequest: function () {
            return this.client.authorizationHandler
                .storageBackend.getItem("appauth_current_authorization_request");
        },
        /**
         * Pass in a reference to an iframe element that you would like to use to handle the AS redirection,
         * rather than relying on a full-page redirection.
         */
        iframeRedirect: function (iframe) {
            // Use a provided iframe element to handle the authentication request.
            this.client.authorizationHandler = (new AppAuth.RedirectRequestHandler(
                // handle redirection within the hidden iframe
                void 0, void 0, iframe.contentWindow.location
            ));
            authnRequest(this.client, this.appAuthConfig);
        },
        /**
         * Begins process which will either get the tokens that are in session storage or will attempt to
         * get them from the OP. In either case, the tokensAvailableHandler will be called. No guarentee that the
         * tokens are still valid, however - you must be prepared to handle the case when they are not.
         */
        getTokens: function () {
            this.fetchTokensFromIndexedDB().then((function (tokens) {
                if (!tokens) {
                    // we don't have tokens yet, but we might be in the process of obtaining them
                    this.checkForActiveAuthzRequest().then((function (hasActiveRequest) {
                        if (!hasActiveRequest) {
                            // only start a new authorization request if there isn't already an active one
                            // attempt silent authorization

                            this.client.authorizationHandler = new AppAuth.RedirectRequestHandler(
                                // handle redirection within the hidden iframe
                                void 0, void 0, document.getElementById("AppAuthHelper").contentWindow.location
                            );
                            authnRequest(this.client, this.appAuthConfig, { "prompt": "none" });
                        }
                    }).bind(this));
                } else {
                    this.registerIdentityProxy()
                        .then((function () {
                            this.tokensAvailableHandler(this.appAuthConfig.oidc ? getIdTokenClaims(tokens.idToken) : {});
                        }).bind(this));
                }
            }).bind(this));
        },
        /**
         * logout() will revoke the access token, use the id_token to end the session on the OP, clear them from the
         * local session, and finally notify the SPA that they are gone.
         */
        logout: function () {
            return this.fetchTokensFromIndexedDB().then((function (tokens) {
                if (!tokens) {
                    return;
                }
                var revokeRequests = [];
                if (tokens.accessToken) {
                    revokeRequests.push(new AppAuth.RevokeTokenRequest({
                        client_id: this.appAuthConfig.clientId,
                        token: tokens.accessToken
                    }));
                }

                return Promise.all(
                    revokeRequests.concat(
                        Object.keys(this.appAuthConfig.resourceServers)
                            .filter(function (rs) { return !!tokens[rs]; })
                            .map((function (rs) {
                                return new AppAuth.RevokeTokenRequest({
                                    client_id: this.appAuthConfig.clientId,
                                    token: tokens[rs]
                                });
                            }).bind(this))
                    ).map((function (revokeRequest) {
                        return this.client.tokenHandler.performRevokeTokenRequest(
                            this.client.configuration,
                            revokeRequest
                        );
                    }).bind(this))
                ).then((function () {
                    if (this.appAuthConfig.oidc && tokens.idToken && this.client.configuration.endSessionEndpoint) {
                        return fetch(this.client.configuration.endSessionEndpoint + "?id_token_hint=" + tokens.idToken);
                    } else {
                        return;
                    }
                }).bind(this)).then((function () {
                    return new Promise((function (resolve, reject) {
                        var dbReq = indexedDB.open("appAuth");
                        dbReq.onsuccess = (function () {
                            var objectStoreRequest = dbReq.result.transaction([this.appAuthConfig.clientId], "readwrite")
                                .objectStore(this.appAuthConfig.clientId).clear();
                            dbReq.result.close();
                            objectStoreRequest.onsuccess = resolve;
                        }).bind(this);
                        dbReq.onerror = reject;
                    }).bind(this));
                }).bind(this));
            }).bind(this));
        },
        whenRenewTokenFrameAvailable: function (resourceServer) {
            return new Promise((function (resolve) {
                var currentResourceServer = sessionStorage.getItem("currentResourceServer");
                if (currentResourceServer === null) {
                    sessionStorage.setItem("currentResourceServer", resourceServer);
                    currentResourceServer = resourceServer;
                }
                if (resourceServer === currentResourceServer) {
                    resolve();
                } else {
                    this.pendingResourceServerRenewals.push(resolve);
                }
            }).bind(this));
        },
        renewTokens: function (resourceServer) {
            this.whenRenewTokenFrameAvailable(resourceServer).then((function () {
                var timestamp = (new Date()).getTime();
                sessionStorage.setItem("currentResourceServer", resourceServer);
                if (!this.renewTokenTimestamp || (this.renewTokenTimestamp + (this.renewCooldownPeriod*1000)) < timestamp) {
                    this.renewTokenTimestamp = timestamp;
                    // update reference to iframe, to ensure it is still valid
                    this.client.authorizationHandler = new AppAuth.RedirectRequestHandler(
                        // handle redirection within the hidden iframe
                        void 0, void 0, document.getElementById("AppAuthHelper").contentWindow.location
                    );
                    var rsConfig = Object.create(this.appAuthConfig);
                    rsConfig.scopes = this.appAuthConfig.resourceServers[resourceServer];
                    authnRequest(this.client, rsConfig, { "prompt": "none" });
                }
            }).bind(this));
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
        receiveMessageFromServiceWorker: function (event) {
            return new Promise((function (resolve) {
                if (event.data.message === "renewTokens") {
                    this.renewTokens(event.data.resourceServer);
                }
                resolve();
            }).bind(this));
        },
        registerIdentityProxy: function () {
            return new Promise((function (resolve) {
                if ("serviceWorker" in navigator) {
                    navigator.serviceWorker.register(this.appAuthConfig.serviceWorkerUri)
                        .then((function (reg) {

                            this.identityProxy = {
                                tokensRenewed: function (currentResourceServer) {
                                    navigator.serviceWorker.controller.postMessage({
                                        "message": "tokensRenewed",
                                        "resourceServer": currentResourceServer
                                    });
                                }
                            };

                            var sendConfigMessage = (function () {
                                this.serviceWorkerMessageChannel = new MessageChannel();
                                this.serviceWorkerMessageChannel.port1.onmessage = (function (event) {
                                    return this.receiveMessageFromServiceWorker(event).then(resolve);
                                }).bind(this);
                                reg.active.postMessage({
                                    "message": "configuration",
                                    "config": this.appAuthConfig
                                }, [this.serviceWorkerMessageChannel.port2]);
                            }).bind(this);

                            navigator.serviceWorker.ready.then(sendConfigMessage);
                        }).bind(this))
                        .catch((function () {
                            this.registerXHRProxy();
                            resolve();
                        }).bind(this));
                } else {
                    this.registerXHRProxy();
                    resolve();
                }
            }).bind(this));
        },
        registerXHRProxy: function () {
            this.identityProxy = new (require("./IdentityProxyXHR"))(this.appAuthConfig, this.renewTokens.bind(this));
        }
    };

    /**
     * Helper function that reduces the amount of duplicated code, as there are several different
     * places in the code that require initiating an authorization request.
     */
    function authnRequest(client, config, extras) {
        var request = new AppAuth.AuthorizationRequest({
            client_id: config.clientId,
            redirect_uri: config.redirectUri,
            scope: config.scopes,
            response_type: AppAuth.AuthorizationRequest.RESPONSE_TYPE_CODE,
            extras: extras || {}
        });

        client.authorizationHandler.performAuthorizationRequest(
            client.configuration,
            request
        );
    }

    /**
     * Simple jwt parsing code purely used for extracting claims.
     */
    function getIdTokenClaims(id_token) {
        return JSON.parse(
            atob(id_token.split(".")[1].replace("-", "+").replace("_", "/"))
        );
    }

}());
