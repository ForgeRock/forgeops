# App Auth JS Helper

Wrapper for [AppAuthJS](https://www.npmjs.com/package/@openid/appauth) to assist with silent token acquisition and renewal

## Purpose

The primary goal of both AppAuth and this helper is to allow your single-page application to obtain OAuth2 access tokens and OpenID Connect id tokens. AppAuth for JavaScript provides an SDK for performing a PKCE-based Authorization Code flow within a JavaScript-based application. It is designed to be the generic underlying library for any type of JS app - not necessarily browser-based single-paged applications. The specific patterns for how you would use it within a single-page application are therefore not very clear. The goal of this helper library is to make that specific integration easier.

There are several aspects that this helper aims to support:

 - **Simpler application integration**
 - **Embedded log in using an iframe**
 - **Simple log out support**
 - **Silent token acquisition**
 - **Silent access token renewal**
 - **Direct access to id token claims**
 - **Pre-configured token storage**

## Why PKCE for a Single-Page App?

Single-page applications are called a "user-agent-based application" in the [OAuth2 Spec for Client Types](https://tools.ietf.org/html/rfc6749#section-2.1). As it says in the description for these sorts of clients, they are "public" clients - this means they are "incapable of maintaining the confidentiality of their credentials". These sorts of clients typically have no "client secret" associated with them, and so to obtain an access token they must be implemented with a grant type that does not require one.

Public clients have two types of grants available to implement - [Authorization Code](https://tools.ietf.org/html/rfc6749#section-4.1) and [Implicit](https://tools.ietf.org/html/rfc6749#section-4.2). Based on the descriptions in the specification, it may appear that a SPA should be built using the implicit grant; however, [industry trends](https://oauth.net/2/grant-types/implicit/) and [best current practices](https://tools.ietf.org/id/draft-ietf-oauth-security-topics-07.html#rfc.section.3.3.2) that have emerged since the initial spec was written suggest that this is not the best choice after all. Instead, use of the authorization code grant as a public client is considered more secure.

While the authorization code grant is an improvement over implicit, there is one additional concern remaining - the risk of exposing the code during redirection. Any malicious third party that is able to intercept a public client's code could use that code to obtain an access token. The [PKCE](https://tools.ietf.org/html/rfc7636) extension to OAuth2 was designed specifically to protect against this type of exposure. While it should be very difficult to intercept an authorization code served over HTTPS, using PKCE provides a valuable additional layer of protection.

## How it works

Your SPA needs access tokens so that it can make requests to resource server endpoints. It needs id tokens so that it can know who is logged in (and possibly also so that it can know other details about the user's session). This helper reduces the boilerplate code that you would need to write in order to invoke AppAuth for these purposes.

This helper makes the tokens available to your SPA by storing them within the browser's **sessionStorage**:

    sessionStorage.get("accessToken");
    sessionStorage.get("idToken");

In order to obtain those tokens, the browser operates as an OIDC Relying Party (RP). It initiates a PKCE-based authorization code flow to the OpenID Provider (OP), the completion of which results in fresh tokens. The difficulty is that this flow normally involves a very noticeable and jarring redirection of the browser. Sometimes, that is unavoidable - when the user isn't currently logged into the OP, then they have to do so. But if the user has a valid session within the OP (and if they have already granted consent for this RP) then that obvious redirection shouldn't be necessary.

To make the interaction between the RP and the OP more smooth, this library is designed to hide most of it within a hidden iframe. When the user has an active OP session, the hidden iframe will silently obtain the tokens - there is no obvious browser redirection involved.

Similarly, there is the possibility that the access token has expired. This can be detected when the resource server responds with a `www-authenticate` header along with an `error=invalid_token` detail. If this happens while the user still has a valid session within the OP, then a new access token can be silently obtained using the same iframe mechanism. This library monitors XHR requests and detects these responses; when found, it will automatically attempt to obtain a new access token before the XHR failure callbacks are triggered. This allows your SPA to retry the original request using a fresh access token.

## Using this library

First, install this library within your SPA:

    npm i appauthhelper

This will make the code available within node_modules/appauthhelper.

You will need to copy node_modules/appauthhelper/appAuthHelperRedirect.html into the base folder of your SPA; you also need to register it as the redirect_uri within your OP.

Next, you need to alter your SPA code to invoke the module. The "AppAuthHelper" module can be loaded in two ways:
 - using a global variable by directly including a script tag: `<script src="node_modules/appauthhelper/appAuthHelperBundle.js"></script>`
 - as a CommonJS module: `var AppAuthHelper = require('appauthhelper');`

Once the library is loaded, you have to provide the environmental details for this relying party. Here's an example:

*Initializing the environment:*

    AppAuthHelper.init({
        clientId: "myRP",
        scopes: "openid profile profile_update consent_read workflow_tasks notifications",
        authorizationEndpoint: "https://login.example.com/oauth2/authorize",
        tokenEndpoint: "https://login.example.com/oauth2/access_token",
        revocationEndpoint: "https://login.example.com/oauth2/token/revoke",
        endSessionEndpoint: "https://login.example.com/oauth2/connect/endSession",
        interactionRequiredHandler: function () {
            // Add whatever is appropriate for your app to do when the user needs to log in.
            // Default behavior (when this handler is unspecified) is to redirect the window
            // to the authorizationEndpoint.

            // A good example of something you might want to do is render the authorizationEndpoint login prompt
            // within an iframe (for a more tightly-integrated login experience). You can do that like so:

            AppAuthHelper.iframeRedirect(document.getElementById('loginIframe'));

            // this assumes that 'loginIframe' is an iframe that has already been mounted to the DOM
        },
        tokensAvailableHandler: function (claims) {
            // whatever your application should do once tokens are available
            // the "claims" argument is the content from the id token

            // the tokens are available within sessionStorage:
            var accessToken = sessionStorage.getItem("accessToken");
            var idToken = sessionStorage.getItem("idToken");

            // use the access token in your XHR requests to resource server endpoints
        },
        renewCooldownPeriod: 1,
        redirectUri: "appAuthHelperRedirect.html" // can be a relative or absolute url
    });

*Details you need to provide to the init function:*

 - clientId - The id of this RP client within the OP
 - scopes - Space-delimited list of scopes requested by this RP
 - authorizationEndpoint - Full URL to the OP authorization endpoint
 - tokenEndpoint - Full URL to the OP token endpoint
 - revocationEndpoint - Full URL to the OP revocation endpoint
 - endSessionEndpoint - Full URL to the OP end session endpoint
 - tokensAvailableHandler - function to be called every time tokens are available - both initially and upon renewal
 - interactionRequiredHandler - optional function to be called when the user needs to interact with the OP; for example, to log in.
 - renewCooldownPeriod [default: 1] - Minimum time (in seconds) between requests to the authorizationEndpoint for token renewal attempts
 - redirectUri [default: appAuthHelperRedirect.html] - The redirect uri registered in the OP

You will need to make sure the redirect_uri used for this is registered with the OP. By default, you can use the included [appAuthHelperRedirect.html](./appAuthHelperRedirect.html) as the uri to register. Whatever you choose to use, be sure there is similar JavaScript code as is included within [appAuthHelperRedirect.html](./appAuthHelperRedirect.html).

*Requesting tokens:*

    AppAuthHelper.getTokens();

When this function is called, the library will work to return tokens to your application (via the `tokensAvailableHandler` defined in the init function). If there are existing tokens in sessionStorage, this function will be called immediately. Otherwise, there will be a background authorization code flow initiated. If there is an active session in the OP (such that the tokens can be returned immediately without user interaction) then those will be fetched and saved in sessionStorage, followed by triggering that function.

If there is no way to fetch the tokens non-interactively, then the parent frame will be redirected to the OP authorization endpoint, allowing the user to log in (and possibly provide consent for this RP). Upon successful authentication, the OP will redirect you back to the configured "redirectUri" which will resume execution within your SPA (ultimately using the authorization code returned to fetch the tokens and save them in sessionStorage).

*Logging in within an iframe:*

If you want your users to be able to log in without having to leave your app, you can render an iframe within it and then provide the frame reference to `AppAuthHelper.iframeRedirect`. This will trigger an immediate call to the OP's authentication endpoint within the context of that frame. When the user returns from the OP, the `tokensAvailableHandler` will be triggered in the same way as it would if the user had been redirected within the context of the full window.

*Logging Out:*

    AppAuthHelper.logout().then(function () {
        // whatever your application should do after the tokens are removed
    });

Calling `logout()` will trigger calls to both the access token revocation endpoint, as well as the id token end session endpoint. When both of those have completed, the promise returned from the `logout()` call will be resolved. At that point you can call `.then()` and do whatever is appropriate for your application.

### Using Tokens

Once `tokensAvailableHandler` has been called, your application can start using the tokens. You can read them from sessionStorage, like so: `sessionStorage.getItem("accessToken")` and `sessionStorage.getItem("idToken")`. The accessToken value should be used when making requests to resource server endpoints. You provide the value as an "Authorization" request header. An example of doing this with jQuery:

```
$.ajax({
    url: "https://rs.example.com/openidm/endpoint/usernotifications/",
    headers: {
        "Authorization": "Bearer " + sessionStorage.getItem("accessToken")
    }
})
```

You can also read the details about the authenticated user (called "claims") from the argument passed to the `tokensAvailableHandler`. Claims are useful for your application, particularly if you need your application to behave differently for different types of users. The structure of the `claims` object is like so:

    {
        "at_hash": "7LsOpEFOK4zH46H96iDOHg",
        "sub": "amadmin",
        "auditTrackingId": "b2e094db-b135-4504-85a2-05897fcb7e6c-31192",
        "iss": "https://login.sample.forgeops.com/oauth2",
        "tokenName": "id_token",
        "aud": "appAuthClient",
        "c_hash": "X7O8AL3Zt4B2Cr6BwmeFmg",
        "acr": "0",
        "org.forgerock.openidconnect.ops": "xJ-cc7K4RQR6gx4kNrfLIIRNg5k",
        "s_hash": "I3riYOxd8FcFEm0aPZrxaw",
        "azp": "appAuthClient",
        "auth_time": 1540235130,
        "realm": "/",
        "exp": 1540238731,
        "tokenType": "JWTToken",
        "iat": 1540235131
    }

Depending on the settings in your OP, there may be more claim values included. See the [OpenID Connect spec on claims](https://openid.net/specs/openid-connect-core-1_0.html#Claims) for more details.


### Expired Token Renewal

This helper library includes code that will help you recover from failures related to access token expiration. If the lifetime of the access token is shorter than the lifetime of the user's session in the OP, then it is possible to silently obtain fresh access tokens. In order to make this as transparent as possible to the user, the XMLHttpRequest implementation has been overridden. With this code in place, the failure callback will not be triggered until there is a new token obtained. This will allow you to retry your failed XHR call immediately. For example, if you use jQuery your XHR handler code for requesting resource server endpoints could look like so:

```
function resourceServerRequest(options) {
    var _rejectHandler,
        promise = $.Deferred();

    options.headers = options.headers || {};
    options.retryAttempts = 0;

    _rejectHandler = function (jqXHR) {
        if (jqXHR.getResponseHeader("www-authenticate") && options.retryAttempts < 1) {
            options.headers["Authorization"] = "Bearer " + sessionStorage.getItem("accessToken");
            options.retryAttempts++;
            $.ajax(options).then(promise.resolve, _rejectHandler);
        } else {
            promise.reject(jqXHR);
        }
    };

    options.headers["Authorization"] = "Bearer " + sessionStorage.getItem("accessToken");
    $.ajax(options).then(promise.resolve, _rejectHandler);
    return promise;
}
```

With this function defined, you can make a call like so:

```
resourceServerRequest({
    url: "https://rs.example.com/openidm/endpoint/usernotifications/"
}).then(function (response) { console.log(response); });
```

Even if your accessToken had expired, the code will not see the error response. `resourceServerRequest` will recover from the failure and will resolve the promise using the successful response.

## License

Apache 2.0. Portions Copyright ForgeRock, Inc. 2018
