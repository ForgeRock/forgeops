/*
 * Copyright 2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

/*
 * This script lets you add may_act field
 * to an OAuth2 access token
 * or OIDC ID Token
 * object with the setMayAct method.
 *
 * Defined variables:
 * token - AccessToken (1) or org.forgerock.openidconnect.OpenIdConnectToken.
 *               The token to be updated.
 *               Mutable object, all changes to the token will be reflected.
 * scopes - Set<String> (6).
 *          Always present, the requested scopes.
 * requestProperties - Unmodifiable Map (5).
 *                     Always present, contains a map of request properties:
 *                     requestUri - The request URI.
 *                     realm - The realm that the request relates to.
 *                     requestParams - A map of the request params and/or posted data.
 *                                     Each value is a list of one or more properties.
 *                                     Please note that these should be handled in accordance with OWASP best practices:
 *                                     https://owasp.org/www-community/vulnerabilities/Unsafe_use_of_Reflection.
 * clientProperties - Unmodifiable Map (5).
 *                    Present if the client specified in the request was identified, contains a map of client properties:
 *                    clientId - The client's URI for the request locale.
 *                    allowedGrantTypes - List of the allowed grant types (org.forgerock.oauth2.core.GrantType) for the client.
 *                    allowedResponseTypes - List of the allowed response types for the client.
 *                    allowedScopes - List of the allowed scopes for the client.
 *                    customProperties - A map of the custom properties of the client.
 *                                       Lists or maps will be included as sub-maps; for example:
 *                                       customMap[Key1]=Value1 will be returned as customMap -> Key1 -> Value1.
 *                                       To add custom properties to a client, update the Custom Properties field
 *                                       in AM Console > Realm Name > Applications > OAuth 2.0 > Clients > Client ID > Advanced.
 * identity - AMIdentity (3).
 *            Always present, the identity of the resource owner.
 * session - SSOToken (4).
 *           Present if the request contains the session cookie, the user's session object.
 * scriptName - String (primitive).
 *              Always present, the display name of the script.
 * logger - Always present, the "OAuth2Provider" debug logger instance:
 *          https://backstage.forgerock.com/docs/am/7/scripting-guide/scripting-api-global-logger.html#scripting-api-global-logger.
 *          Corresponding log files will be prefixed with: scripts.OAUTH2_MAY_ACT.
 *
 * Return - no value is expected, changes shall be made to the token parameter directly.
 *
 * Class reference:
 * (1) AccessToken - https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/oauth2/core/AccessToken.html.
 * (3) AMIdentity - https://backstage.forgerock.com/docs/am/7/apidocs/com/sun/identity/idm/AMIdentity.html.
 * (4) SSOToken - https://backstage.forgerock.com/docs/am/7/apidocs/com/iplanet/sso/SSOToken.html.
 * (5) Map - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/HashMap.html,
 *           or https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/LinkedHashMap.html.
 * (6) Set - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/HashSet.html.
 */

/* EXAMPLE
(function () {
    var frJava = JavaImporter(
        org.forgerock.json.JsonValue
    );

    var mayAct = frJava.JsonValue.json(frJava.JsonValue.object());
    mayAct.put('client_id', 'myClient');
    mayAct.put('sub', '(usr!myActor)');

    token.setMayAct(mayAct);

    // No return value is expected. Let it be undefined.
}());
*/
