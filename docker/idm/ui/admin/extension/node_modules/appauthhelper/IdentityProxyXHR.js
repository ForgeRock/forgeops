(function () {
    "use strict";

    var IdentityProxyCore = require("./IdentityProxyCore"),
        IdentityProxyXHR = function (appAuthConfig, renewTokens) {
            var _this = this,
                RealXHROpen = XMLHttpRequest.prototype.open,
                RealXHRSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader,
                RealOverrideMimeType = XMLHttpRequest.prototype.overrideMimeType;
            this.RealXHRSend = XMLHttpRequest.prototype.send;
            this.renewTokens = renewTokens;

            /**
             * Override default methods for all XHR requests in order to add
             * access tokens and intercept invalid_token failures
             */
            XMLHttpRequest.prototype.open = function (method, url) {
                var calculatedUriLink = document.createElement("a");
                calculatedUriLink.href = url;

                this.url = calculatedUriLink.href;
                this.openArgs = arguments;
                return RealXHROpen.apply(this, arguments);
            };
            XMLHttpRequest.prototype.setRequestHeader = function (header, value) {
                this.headers = this.headers || [];
                this.headers.push([header, value]);
                return RealXHRSetRequestHeader.call(this, header, value);
            };
            XMLHttpRequest.prototype.setRequestHeadersExceptAuthorization = function (headers) {
                (headers || []).forEach((function (header) {
                    if (header[0].toLowerCase() !== "authorization") {
                        RealXHRSetRequestHeader.call(this, header[0], header[1]);
                    }
                }).bind(this));
            };
            XMLHttpRequest.prototype.overrideMimeType = function (mimeType) {
                this.overriddenMimeType = mimeType;
                return RealOverrideMimeType.call(this, mimeType);
            };
            XMLHttpRequest.prototype.send = function (body) {
                var resourceServer = _this.getResourceServerFromUrl(this.url);
                if (resourceServer) {
                    _this.interceptRequest({
                        xhr: this,
                        body: body
                    }, resourceServer).then((request) => {
                        Object.keys(request.original_events).forEach((event) => {
                            if (request.original_events[event]) {
                                request.original_events[event].call(this);
                            }
                        });
                    });
                } else {
                    _this.RealXHRSend.call(this, body);
                }
            };
            XMLHttpRequest.prototype.setNewResponseObject = function (newXHR) {
                this.newResponseObject = newXHR;
                ["response","responseText","responseType","responseURL",
                    "responseXML","status","statusText"].forEach((function (property) {
                    Object.defineProperty(this, property, {
                        "get": function () {
                            return this.newResponseObject[property];
                        }
                    });
                }).bind(this));
            };

            return IdentityProxyCore.call(this, appAuthConfig);
        };
    IdentityProxyXHR.prototype = Object.create(IdentityProxyCore.prototype);

    IdentityProxyXHR.prototype.tokensRenewed = function (currentResourceServer) {
        this.retryFailedRequests(currentResourceServer);
    };

    IdentityProxyXHR.prototype.addAuthorizationRequestHeader = function(resolve, request, token) {
        if (request.xhr.status !== 0) {
            request.originalxhr = request.xhr;
            request.xhr = new XMLHttpRequest();
            request.xhr.open.apply(request.xhr, request.originalxhr.openArgs);
            request.xhr.setRequestHeadersExceptAuthorization(request.originalxhr.headers);
            request.xhr.timeout = request.originalxhr.timeout;
            request.xhr.withCredentials = request.originalxhr.withCredentials;
            request.xhr.overrideMimeType(request.originalxhr.overriddenMimeType);
        }
        request.xhr.setRequestHeader("Authorization", "Bearer " + token);

        resolve(request);
    };

    IdentityProxyXHR.prototype.getAuthHeaderDetails = function (resp) {
        var response_headers = resp.xhr.getAllResponseHeaders()
            .split("\n")
            .map(function (header) {
                return header.split(": ");
            })
            .reduce(function (result, pair) {
                if (pair.length === 2) {
                    result[pair[0].toLowerCase()] = pair[1];
                }
                return result;
            }, {});

        if (response_headers["www-authenticate"] && response_headers["www-authenticate"].match(/^Bearer /)) {
            return response_headers["www-authenticate"]
                .replace(/^Bearer /, "")
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

    IdentityProxyXHR.prototype.makeRequest = function (rsRequest) {
        return new Promise((resolve) => {
            rsRequest.original_events = rsRequest.original_events || {
                onload: rsRequest.xhr.onload,
                onreadystatechange: rsRequest.xhr.onreadystatechange,
                onloadend: rsRequest.xhr.onloadend,
                onerror: rsRequest.xhr.onerror
            };
            rsRequest.xhr.onload = null;
            rsRequest.xhr.onreadystatechange = null;
            rsRequest.xhr.onloadend = null;
            rsRequest.xhr.onerror = null;

            rsRequest.xhr.onload = () => {
                if (rsRequest.originalxhr) {
                    rsRequest.originalxhr.setNewResponseObject(rsRequest.xhr);
                }
                resolve(rsRequest);
            };
            this.RealXHRSend.call(rsRequest.xhr, rsRequest.body);
        });
    };

    module.exports = IdentityProxyXHR;
}());
