(function () {
    "use strict";

    var IdentityProxyCore = require("./IdentityProxyCore"),
        IdentityProxyServiceWorker = function (appAuthConfig, messageChannel) {
            this.messageChannel = messageChannel;
            return IdentityProxyCore.call(this, appAuthConfig);
        };

    IdentityProxyServiceWorker.prototype = Object.create(IdentityProxyCore.prototype);

    IdentityProxyServiceWorker.prototype.renewTokens = function (resourceServer) {
        this.messageChannel.postMessage({
            "message": "renewTokens",
            "resourceServer": resourceServer
        });
    };

    IdentityProxyServiceWorker.prototype.addAuthorizationRequestHeader = function (resolve, request, token) {
        var rsHeaders =  new Headers(request.headers);
        rsHeaders.set("Authorization", `Bearer ${token}`);

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
    };

    IdentityProxyServiceWorker.prototype.getAuthHeaderDetails = function (resp) {
        var authHeader = resp.headers.get("www-authenticate");

        if (!resp.ok && authHeader && authHeader.match(/^Bearer /)) {
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

    IdentityProxyServiceWorker.prototype.makeRequest = function (rsRequest) {
        return fetch(rsRequest);
    };

    module.exports = IdentityProxyServiceWorker;

}());
