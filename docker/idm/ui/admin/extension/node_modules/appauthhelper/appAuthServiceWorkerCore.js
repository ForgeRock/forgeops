(function () {
    "use strict";

    var IdentityProxyServiceWorker = require("./IdentityProxyServiceWorker");

    self.addEventListener("install", (event) => {
        event.waitUntil(self.skipWaiting());
    });

    self.addEventListener("activate", (event) => {
        event.waitUntil(self.clients.claim());
    });

    self.addEventListener("message", (event) => {
        if (event.data.message === "configuration") {
            self.identityProxy = new IdentityProxyServiceWorker(event.data.config, event.ports[0]);
            event.waitUntil(self.clients.claim().then(() =>
                event.ports[0].postMessage({
                    "message": "configured"
                })
            ));
        } else if (event.data.message === "tokensRenewed") {
            self.identityProxy.retryFailedRequests(event.data.resourceServer);
        }
    });

    self.addEventListener("fetch", (event) => {
        if (self.identityProxy) {
            var resourceServer = self.identityProxy.getResourceServerFromUrl(event.request.url);
            if (resourceServer) {
                event.respondWith(self.identityProxy.interceptRequest(event.request, resourceServer));
            }
        }
        return;
    });
}());
