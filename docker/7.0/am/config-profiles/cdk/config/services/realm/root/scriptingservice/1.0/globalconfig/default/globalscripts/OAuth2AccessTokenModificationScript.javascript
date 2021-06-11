/*
 * Copyright 2019-2021 ForgeRock AS. All Rights Reserved.
 *
 * Use of this code requires a commercial software license with ForgeRock AS
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

/*
 * This script lets you modify information associated with an OAuth2 access token
 * with methods provided by the AccessToken (1) interface.
 * The changes made to OAuth2 access tokens will directly impact the size of the CTS tokens,
 * and, similarly, the size of the JWTs if client-based OAuth2 tokens are utilized.
 * When adding/updating fields make sure that the token size remains within client/user-agent limits.
 *
 * Defined variables:
 * accessToken - AccessToken (1).
 *               The access token to be updated.
 *               Mutable object, all changes to the access token will be reflected.
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
 *          Corresponding log files will be prefixed with: scripts.OAUTH2_ACCESS_TOKEN_MODIFICATION.
 * httpClient - HTTP Client (8).
 *              Always present, the HTTP Client instance:
 *              https://backstage.forgerock.com/docs/am/7/scripting-guide/scripting-api-global-http-client.html#scripting-api-global-http-client.
 *
 * Return - no value is expected, changes shall be made to the accessToken parameter directly.
 *
 * Class reference:
 * (1) AccessToken - https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/oauth2/core/AccessToken.html.
 * (3) AMIdentity - https://backstage.forgerock.com/docs/am/7/apidocs/com/sun/identity/idm/AMIdentity.html.
 * (4) SSOToken - https://backstage.forgerock.com/docs/am/7/apidocs/com/iplanet/sso/SSOToken.html.
 * (5) Map - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/HashMap.html,
 *           or https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/LinkedHashMap.html.
 * (6) Set - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/HashSet.html.
 * (8) Client - https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/http/Client.html.
 */

/* EXAMPLE
(function () {
    var frJava = JavaImporter(
        org.forgerock.http.protocol.Request,
        org.forgerock.http.protocol.Response
    );

    // Always includes this field in the token.
    accessToken.setField('key1', 'value1');

    // Receives and adds to the access token additional values by performing a REST call to an external service.
    // WARNING: Below, you will find a reference to a third-party site, which is provided only as an example.
    var uri = 'https://jsonplaceholder.typicode.com/posts';

    try {
        var request = new frJava.Request();

        // You can chain methods that return the request object.
        request.setUri(uri)
            .setMethod('POST')
            .setEntity(JSON.stringify({
                updatedFields: {
                    key2: 'value2',
                    key3: 'value3'
                }
            }));

        // You can call a method when chaining is not possible.
        request.getHeaders().add('Content-Type', 'application/json; charset=UTF-8');

        // Sends the request and receives the response.
        var response = httpClient.send(request).getOrThrow();

        // Checks if the response status is as expected.
        if (response.getStatus() === org.forgerock.http.protocol.Status.CREATED) {
            var result = JSON.parse(response.getEntity().getString());

            // Set multiple token fields at once.
            accessToken.setFields(result.updatedFields);
        } else {
            logger.error('Unable to obtain access token modifications. Status: ' + response.getStatus() + '. Content: ' + response.getEntity().getString());
        }
    } catch (e) {
        logger.error('The request processing was interrupted. ' + e);

        // The access token request fails with the HTTP 500 error in this case.
        throw ('Unable to obtain response from: ' + uri);
    }

    // Adds new fields containing identity attribute values to the access token.
    accessToken.setField('mail', identity.getAttribute('mail'));
    accessToken.setField('phone', identity.getAttribute('telephoneNumber').toArray()[0]);

    // Adds new fields containing the session property values.
    // NOTE: session may not be available for non-interactive authorization grants.
    if (session) {
        try {
            accessToken.setField('ipAddress', session.getProperty('Host'));
        } catch (e) {
            logger.error('Unable to retrieve session property value. ' + e);
        }
    }

    // Removes a native field from the token entry, that was set by AM.
    // WARNING: removing native fields from the token may result in loss of functionality.
    // accessToken.removeTokenName()

    // No return value is expected. Let it be undefined.
}());
*/
