# OIDC Session Check

JavaScript library to assist with binding sessions between an OIDC OP and RP

## Purpose

When you use [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html) to handle authentication in your application, there are two parties involved - the "OpenID Provider" (OP) and the Relying Party (RP).

The OP is a web server, and it handles authenticating the user. Oftentimes, when the user logs into the OP with a browser there is a session created there. The OP will set a cookie in the user's browser, which allows the user to be remembered the next time they visit the OP.

The RP is an application which uses the identity details returned from the OP. Typically, it uses these details to construct it's own session. The session at the RP does not normally have any relationship to the session at the OP; if a user logs-out of one, it doesn't normally cause the session to end on the other.

When RP applications are owned by the same organization as the OP, there is often a desire to make the various sessions more closely associated. Doing so presents the user with a seamless experience as they navigate between each app. This library is designed to make that session association easier to establish.

## How it works

The cookie which identifies the session at the OP is assumed to be unavailable to the RP (due to differences in their respective domains). However, there is a mechanism available as part of OIDC which allows that cookie to be used. OIDC works by redirection between the RP and OP - the browser makes a request to the OP's "authorization endpoint"; when finished, the OP redirects the browser back to the RP's "redirect_uri" along with some relevant data. This is the fundamental mechanism by which the RP can learn about the state of the session in the OP.

This redirection needs to be non-intrusive; it shouldn't be noticeable to the user while they are interacting with the RP. The most practical way to accomplish this is to make use of hidden iframes within the RP application. The RP can set the iframe src value to be the OP authorization endpoint (along with the other required parameters); when this loads, the OP session cookie will be passed along as per normal browser behavior.

The simplest strategy for this interaction is to use the "Implicit Flow" along with the "id_token" response type. Doing so will allow the direct response to the redirect_uri (passing data within the hash fragment of the URL); successful responses will only include the id_token. See the specification for [Implicit Flow Authentication Requests](https://openid.net/specs/openid-connect-core-1_0.html#rfc.section.3.2.2.1) for more details.

Since this use-case involves simple message passing (with no direct user interaction) there is one more parameter that is passed along in the authentication request - `prompt=none`. By including this parameter, the response will either succeed immediately or fail immediately - there won't be any "prompt" for the user to log in or anything else.

The data that is passed back to the RP's redirect_uri is either an "id_token" (which contains the logged-in user's details) or an "error" parameter. The state of the user's session on the OP will determine which of these values are returned. These must be read by the redirect_uri page, and based on the values it must use the [postMessage](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage) API to communicate the results to the RP parent frame.

## Using this library

This library automates the iframe creation and message passing between your RP and the OP. It allows you to easily monitor the state of the OP session - you simply need to provide a few details about your operating environment and decide when you want those checks to be made.

The "SessionCheck" module can be loaded in several ways:
 - using a global variable by directly including a script tag: `<script src="sessionCheckGlobal.js"></script>`
 - using CommonJS modules: `var SessionCheck = require('sessionCheck');`

*Setting up the environment:*

    var sessionCheck = new SessionCheck({
        clientId: "myRP",
        opUrl: "https://login.example.com/oauth2/authorize",
        subject: loggedInUsername,
        invalidSessionHandler: function () {
            logoutFromRP();
        },
        // optional
        cooldownPeriod: 5,
        // optional
        redirectUri: "sessionCheck.html"
    });

*Examples for when to check the session:*

    // check every minute
    setInterval(function () {
        sessionCheck.triggerSessionCheck();
    }, 60000);

    // check with various events:
    document.addEventListener("click", function () {
        sessionCheck.triggerSessionCheck();
    });
    document.addEventListener("keypress", function () {
        sessionCheck.triggerSessionCheck();
    });

*Details you need to provide:*

 - subject - The user currently logged into the RP
 - clientId - The id of this RP client within the OP
 - opUrl - Full URL to the OP Authorization Endpoint
 - invalidSessionHandler - function to be called once any problem with the session is detected
 - redirectUri [default: sessionCheck.html] - The redirect uri registered in the OP for session-checking purposes
 - cooldownPeriod [default: 5] - Minimum time (in seconds) between requests to the opUrl

This library requires that your user is already authenticated prior to creating an instance of it. You *must* provide the current username of that user - this will be checked against the "subject" claim within the id_token that is returned by the OP. If they don't match, it is assumed that the OP and RP sessions are out of sync, and that will trigger the `invalidSessionHandler`.

The `invalidSessionHandler` will be called whenever there is a problem detected from the OP response. The intent for this handler is for you to trigger a local log-out event, so that the current RP session is terminated (likely to result in an interactive redirection to the OP so as to obtain a new RP session).

You will need to make sure the redirect_uri used for this is registered with the OP. By default, you can use the included [sessionCheck.html](./sessionCheck.html) as the uri to register. Whatever you choose to use, be sure the [sessionCheckFrame.js](./sessionCheckFrame.js) code is included within it.

It is up to you to decide how frequently and in which circumstances you want to check the OP for session status changes. The "cooldownPeriod" setting determines the maximum frequency you want to check the OP. Regardless of how many times you call `triggerSessionCheck()` within that period, it will only be checked once. As a result, you can call this using any combination of events without worrying about flooding the OP with requests.

## License

MIT. Copyright ForgeRock, Inc. 2018
