(function () {
    "use strict";
    /**
     * This code is designed to run in the context of a window (or frame)
     * that has been loaded as the redirect_uri target of an OIDC implicit
     * flow. As such, it is expected that there will be hash fragment values
     * that appear as query string values. Note that it is expected that this
     * is using the "id_token" response_type; there should not be any "access_token"
     * values present in the hash fragment.
     *
     * For more details see :
     * https://openid.net/specs/openid-connect-core-1_0.html#ImplicitAuthResponse
     *
     * This code expects there to be two values in sessionStorage prior to handling the
     * authentication response:
     *
     * - "sessionCheckNonce" - This should be set during the authentication request, and it must
     *                         match the value found in the "nonce" claim of the id_token
     *
     * - "sessionCheckSubject" - This is the user that is currently logged-in to the RP. It
     *                           must match the "sub" claim of the id_token, otherwise it is
     *                           assumed that a different user has logged into the OP and the RP
     *                           session is therefore invalid.
     *
     * In the case when any errors are detected with the OP session, a "sessionCheckFailed"
     * message will be sent to the parent frame using the postMessage API.
     *
     */

     if (parent.window.origin !== window.origin) {
         // have to be running within a child frame hosted on the same origin
         return;
     }

    /**
     * Simple jwt parsing code purely used for extracting claims.
     */
    function getIdTokenClaims(id_token) {
        return JSON.parse(
            atob(id_token.split(".")[1].replace("-", "+").replace("_", "/"))
        );
    }

    var implict_params = window.location.hash
        .replace("#","")
        .split("&")
        .reduce(function (result, entry) {
            var pair = entry.split("=");
            if (pair[0] && pair[1]) {
                result[pair[0]] = pair[1];
            }
            return result;
        }, {});

    if (implict_params.id_token) {
        var new_claims = getIdTokenClaims(implict_params.id_token);
        if (sessionStorage.getItem("sessionCheckNonce") !== new_claims.nonce) {
            parent.postMessage( "sessionCheckFailed", document.location.origin);
            return;
        }

        if (new_claims.sub !== sessionStorage.getItem("sessionCheckSubject")) {
            parent.postMessage( "sessionCheckFailed", document.location.origin);
            return;
        }
    } else if (implict_params.error) {
        parent.postMessage( "sessionCheckFailed", document.location.origin);
        return;
    }

}());
