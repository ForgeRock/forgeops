# App Auth JS Helper

Wrapper for [AppAuthJS](https://www.npmjs.com/package/@openid/appauth) to assist with the full OAuth2 / OIDC token life-cycle.

## Purpose

The primary goal of both AppAuth and this helper is to allow your single-page application to obtain OAuth2 access tokens and OpenID Connect id tokens. AppAuth for JavaScript provides an SDK for performing a PKCE-based Authorization Code flow within a JavaScript-based application. It is designed to be the generic underlying library for any type of JS app - not necessarily browser-based single-paged applications. The specific patterns for how you would use it within a single-page application are therefore not very clear. The goal of this helper library is to make that specific integration much easier.

There are several aspects that this helper aims to add on top of AppAuth:

 - **Simpler application integration**
 - **Silent token acquisition**
 - **Pairing access tokens with resource servers**
 - **Transparent access token usage**
 - **Automatic access token renewal**
 - **Simple log out support**
 - **Direct access to id token claims**
 - **Token storage**
 - **Support for alternative log-in flows**

## Why PKCE for a Single-Page App?

Single-page applications are called a "user-agent-based application" in the [OAuth2 Spec for Client Types](https://tools.ietf.org/html/rfc6749#section-2.1). As it says in the description for these sorts of clients, they are "public" clients - this means they are "incapable of maintaining the confidentiality of their credentials". These sorts of clients typically have no "client secret" associated with them, and so to obtain an access token they must be implemented with a grant type that does not require one.

Public clients have two types of grants available to implement - [Authorization Code](https://tools.ietf.org/html/rfc6749#section-4.1) and [Implicit](https://tools.ietf.org/html/rfc6749#section-4.2). Based on the descriptions in the specification, it may appear that a SPA should be built using the implicit grant; however, [industry trends](https://oauth.net/2/grant-types/implicit/) and [best current practices](https://tools.ietf.org/id/draft-ietf-oauth-security-topics-07.html#rfc.section.3.3.2) that have emerged since the initial spec was written suggest that this is not the best choice after all. Instead, use of the authorization code grant as a public client is considered more secure.

While the authorization code grant is an improvement over implicit, there is one additional concern remaining - the risk of exposing the code during redirection. Any malicious third party that is able to intercept a public client's code could use that code to obtain an access token. The [PKCE](https://tools.ietf.org/html/rfc7636) extension to OAuth2 was designed specifically to protect against this type of exposure. While it should be very difficult to intercept an authorization code served over HTTPS, using PKCE provides a valuable additional layer of protection.

## How it works

Your SPA needs access tokens so that it can make requests to resource server endpoints. It needs id tokens so that it can know who is logged in (and possibly also so that it can know other details about the user's session). This helper reduces the boilerplate code that you would need to write in order to invoke AppAuth for these purposes.

In order to obtain those tokens, the browser operates as an OIDC Relying Party (RP). It initiates a PKCE-based authorization code flow to the OpenID Provider (OP), the completion of which results in fresh tokens. The difficulty is that this flow normally involves a very noticeable and jarring redirection of the browser. Sometimes, that is unavoidable - when the user isn't currently logged into the OP, then they have to do so. But if the user has a valid session within the OP (and if they have already granted consent for the scopes this RP is asking for) then that obvious redirection shouldn't be necessary.

To make the interaction between the RP and the OP more smooth, this library is designed to hide most of it from your application code. To do this, it uses a hidden iframe and a [service worker](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API). When the user has an active OP session, the hidden iframe will silently obtain the tokens - there is no obvious browser redirection involved. When your application code makes a request to a resource server, the service worker will intercept that request and add the appropriate access token to the request. This allows your SPA to worry much less about token management and instead focus on the business logic associated with the resource server APIs.

Each resource server your application wants to work with should use a unique access token. This is considered the best practice, as it limits the exposure of scopes to only those resource servers which ought to be using them. AppAuthHelper automates this best practice - for each resource server you declare, a unique access token (with the appropriate scopes) will be requested. The service worker will find the appropriate token for your request and automatically include it.

In the case when your request fails because the access token has expired, the service worker will automatically attempt to obtain a fresh access token and then retry the request with that fresh token. This can be detected when the resource server responds with a `www-authenticate` header along with an `error=invalid_token` detail. If this happens while the user still has a valid session within the OP, a new access token can be silently obtained using the iframe. This is essentially the process described in https://tools.ietf.org/html/rfc6750#section-3.1:

> invalid_token
>     The access token provided is expired, revoked, malformed, or
>     invalid for other reasons.  The resource SHOULD respond with
>     the HTTP 401 (Unauthorized) status code.  The client MAY
>     request a new access token and retry the protected resource
>     request.

Thanks to the service worker, you won't have to worry about implementing this retry logic yourself. Just make the calls to your APIs and let the service worker handle the tokens. For more details on how a service worker accomplishes this, review this article: [Service Workers as an Identity Proxy](./service_workers.md).

## Using this library

A trivial example for using this library is included as part of the project, under [index.html](./index.html).

You will need to make sure at least two files are included in the base of your application - [appAuthHelperRedirect.html](./appAuthHelperRedirect.html) and [appAuthServiceWorker.js](./appAuthServiceWorker.js). If you want to call these files different names, you will need to provide their new names to the `AppAuthHelper.init` function. Also, you will need to make sure the path within appAuthHelperRedirect.html (or its equivalent) to [appAuthHelperFetchTokensBundle.js](./appAuthHelperFetchTokensBundle.js) is accurate.

You will also need to register appAuthHelperRedirect.html (or its equivalent) as the redirect_uri within your OP.

Next, you need to alter your application code to invoke the module. The "AppAuthHelper" module can be loaded in two ways:
 - using a global variable by directly including a script tag: `<script src="appAuthHelperBundle.js"></script>`
 - as a CommonJS module: `var AppAuthHelper = require('appauthhelper');`

Once the library is loaded, you have to provide the environmental details along with the function you'd like to trigger when the tokens are available. Here's an example:

*Initializing the environment:*

    AppAuthHelper.init({
        clientId: "myRP",
        authorizationEndpoint: "https://login.example.com/oauth2/authorize",
        tokenEndpoint: "https://login.example.com/oauth2/access_token",
        revocationEndpoint: "https://login.example.com/oauth2/token/revoke",
        endSessionEndpoint: "https://login.example.com/oauth2/connect/endSession",
        resourceServers: {
            "https://login.example.com/oauth2/userinfo": "profile",
            "https://rs.example.com/": "rs_custom_scope"
        },
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
            // This is a great place to startup the parts of your SPA that are for logged-in users.
            // The "claims" parameter is the content of the id_token, which tells you useful details
            // about the logged-in user.

            // At this point your application code can start making network calls to the resource servers
            // you have configured, above.
            fetch("https://login.example.com/oauth2/userinfo").then((resp) => resp.json()).then((profile) => {
                //...
            })
        },
        renewCooldownPeriod: 1,
        oidc: true,
        redirectUri: "appAuthHelperRedirect.html", // can be a relative or absolute url
        serviceWorkerUri: "appAuthServiceWorker.js" // can be a relative or absolute url
    });

*Details you need to provide to the init function:*

 - clientId - The id of this RP client within the OP
 - scopes - Space-delimited list of scopes requested by this RP
 - authorizationEndpoint - Full URL to the OP authorization endpoint
 - tokenEndpoint - Full URL to the OP token endpoint
 - revocationEndpoint - Full URL to the OP revocation endpoint
 - endSessionEndpoint - Full URL to the OP end session endpoint
 - resourceServers - Optional map of resource server urls to the scopes which they require. Map values are space-delimited list of scopes requested by this RP for use with this RS. If not specified, no tokens will be automatically included in any network request.
 - tokensAvailableHandler - function to be called when tokens are first available
 - interactionRequiredHandler - optional function to be called when the user needs to interact with the OP; for example, to log in.
 - renewCooldownPeriod [default: 1] - Minimum time (in seconds) between requests to the authorizationEndpoint for token renewal attempts
 - oidc [default: true] - indicate whether or not you want to get back an id_token
 - redirectUri [default: appAuthHelperRedirect.html] - The redirect uri registered in the OP
 - serviceWorkerUri [default: appAuthServiceWorker.js] - Path to the service worker script. Make sure it is located low enough in your URL path so that its scope encapsulates all application code making network requests. See [Why is my service worker failing to register?](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers#Why_is_my_service_worker_failing_to_register) if you have questions.

You will need to make sure the redirect_uri used for this is registered with the OP. By default, you can use the included [appAuthHelperRedirect.html](./appAuthHelperRedirect.html) as the uri to register. Whatever you choose to use, be sure there is similar JavaScript code as is included within [appAuthHelperRedirect.html](./appAuthHelperRedirect.html).

*Requesting tokens:*

    AppAuthHelper.getTokens();

When this function is called, the library will work to return tokens to your application (via the `tokensAvailableHandler` defined in the init function). If there are existing tokens in browser storage ([IndexedDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API)), this function will be called immediately. Otherwise, there will be a background authorization code flow initiated. If there is an active session in the OP (such that the tokens can be returned immediately without user interaction) then those will be fetched and saved in browser storage, followed by triggering that function.

If there is no way to fetch the tokens non-interactively, the default behavior is for the parent frame to be redirected to the OP authorization endpoint, allowing the user to log in (and possibly provide consent for this RP). Upon successful authentication, the OP will redirect you back to the configured "redirectUri" which will resume execution within your SPA (ultimately using the authorization code returned to fetch the tokens and save them in browser storage).

*Logging in within an iframe:*

If you want your users to be able to log in without having to leave your app, you can specify that behavior in the `interactionRequiredHandler`. For example, you can declare an iframe somewhere within your page and then using `interactionRequiredHandler` you can provide that frame reference to `AppAuthHelper.iframeRedirect`. This will trigger an immediate call to the OP's authentication endpoint within the context of that frame. When the user returns from the OP, the `tokensAvailableHandler` will be triggered in the same way as it would if the user had been redirected within the context of the full window.

*Logging Out:*

    AppAuthHelper.logout().then(function () {
        // whatever your application should do after the tokens are removed
    });

Calling `AppAuthHelper.logout()` will trigger calls to both the access token revocation endpoint, as well as the id token end session endpoint. When both of those have completed, the tokens are removed from browser storage. A promise is returned from `logout()`; use  `.then()` to do whatever is appropriate for your application after the session is terminated.

### Using Tokens

Once `tokensAvailableHandler` has been called, your application can start using the tokens. If you are curious about them, you can find them within your browser's IndexedDB under "appAuth/clientId". You shouldn't need to develop any code that directly accesses them there, however; you should be able to rely on the service worker managing them for your requests. Instead just make simple calls to your resource server APIs, and trust that the Authorization header with the access token included as a bearer will be added. For example:

```
fetch("https://login.example.com/oauth2/userinfo").then((resp) => resp.json())
```

You can also read the details about the authenticated user (called "claims") from the argument passed to the `tokensAvailableHandler`. Claims are useful for your application, particularly if you need your application to behave differently for different types of users. The structure of the `claims` object is like so:

    {
        "at_hash": "7LsOpEFOK4zH46H96iDOHg",
        "sub": "amadmin",
        "auditTrackingId": "b2e094db-b135-4504-85a2-05897fcb7e6c-31192",
        "iss": "https://login.example.com/oauth2",
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

## Contributing

AppAuthHelper was developed by ForgeRock, Inc. Please file issues and open pull requests, as you see fit.

## License

Apache 2.0. Portions Copyright ForgeRock, Inc. 2018-2019
