(function () {
    "use strict";

    var AppAuth = require("@openid/appauth");

    var appAuthConfig = JSON.parse(sessionStorage.getItem("appAuthConfig")),
        appAuthClient,
        tokenHandler;

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
                        sessionStorage.setItem("accessToken", token_endpoint_response.accessToken);
                        sessionStorage.setItem("idToken", token_endpoint_response.idToken);
                        parent.postMessage( "appAuth-tokensAvailable", document.location.origin);
                    });
            } else if (appAuthClient.error) {
                parent.postMessage("appAuth-interactionRequired", document.location.origin);
            }

        });
}());
