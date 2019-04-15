(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.SessionCheck = f()}})(function(){var define,module,exports;return (function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
(function () {
    "use strict";
    /**
     * Module used to setup the browser environment needed to verify that the
     * session at the OpenID Provider is still valid and associated with the
     * same user authenticated within this app (the OIDC Relying Party).
     * @module SessionCheck
     * @param {Object} config - configation needed for working with the OP
     * @param {string} config.subject - The user currently logged into the RP
     * @param {string} config.clientId - The id of this RP client within the OP
     * @param {string} config.opUrl - Full URL to the OP Authorization Endpoint
     * @param {function} config.invalidSessionHandler - function to be called once any problem with the session is detected
     * @param {string} config.redirectUri [sessionCheck.html] - The redirect uri registered in the OP for session-checking purposes
     * @param {number} config.cooldownPeriod [5] - Minimum time (in seconds) between requests to the opUrl
     */
    module.exports = function (config) {
        var calculatedUriLink;

        if (!config.redirectUri) {
            // trick used to make the DOM resolve a complete URI based on the relative URI
            calculatedUriLink = document.createElement("a");
            calculatedUriLink.href = "sessionCheck.html";

            this.redirectUri = calculatedUriLink.href;
        } else {
            this.redirectUri = config.redirectUri;
        }

        this.subject = config.subject;
        this.clientId = config.clientId;
        this.opUrl = config.opUrl;

        this.cooldownPeriod = config.cooldownPeriod || 5;

        /*
         * Attach a hidden iframe onto the main document body that is used to perform
         * background OP-session checking
         */
        var iframe = document.createElement("iframe");
        iframe.setAttribute("src", this.redirectUri);
        iframe.setAttribute("id", "sessionCheckFrame" + this.clientId);
        iframe.setAttribute("style", "display:none");
        document.getElementsByTagName("body")[0].appendChild(iframe);

        window.addEventListener("message", function (e) {
            if (e.origin !== document.location.origin) {
                return;
            }
            if (e.data === "sessionCheckFailed") {
                config.invalidSessionHandler();
            }
        });

        sessionStorage.setItem("sessionCheckSubject", this.subject);
        return this;
    };

    /**
     * Private function only to be called through the triggerSessionCheck function.
     * Responsible for updating the hidden iframe url to trigger the implicit-flow-based
     * id_token grant. Also constructs the nonce value, which is later verified in
     * the sessionCheckFrame code.
     */
    var idTokenRequest = function(config) {
        var nonce = Math.floor(Math.random() * 100000);
        sessionStorage.setItem("sessionCheckNonce", nonce);
        document
            .getElementById("sessionCheckFrame" + config.clientId)
            .setAttribute("src", config.opUrl + "?client_id=" + config.clientId +
                "&response_type=id_token&scope=openid&prompt=none&redirect_uri=" +
                config.redirectUri + "&nonce=" + nonce);
    };

    /** @function triggerSessionCheck
     * Call this function as frequently as you like (based on either events or
     * set intervals) - the check to the OP will only occur once per cooldown period.
     */
    module.exports.prototype.triggerSessionCheck = function () {
        // Helper function used to prevent simultaneous requests being issued
        function idTokenRequestCooldown() {
            var timestamp = (new Date()).getTime();
            if (!this.checkSessionTimestamp || (this.checkSessionTimestamp + (this.cooldownPeriod * 1000)) < timestamp) {
                this.checkSessionTimestamp = timestamp;

                idTokenRequest(this);
            }
        }

        idTokenRequestCooldown.call(this);
    };

}());

},{}]},{},[1])(1)
});
