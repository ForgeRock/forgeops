/*
 * Copyright 2014-2021 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

/*
 * This script computes claim values returned in ID tokens and/or at the UserInfo Endpoint.
 * The claim values are computed for:
 * the claims derived from the requested scopes,
 * the claims provided by the authorization server,
 * and the claims requested by the client via the claims parameter.
 *
 * In the CONFIGURATION AND CUSTOMIZATION section, you can
 * define the scope-to-claims mapping, and
 * assign to each claim a resolver function that will compute the claim value.
 *
 * Defined variables (class references are provided below):
 * scopes - Set<String> (6).
 *          Always present, the requested scopes.
 * claims - Map<String, Object> (5).
 *          Always present, default server provided claims.
 * claimObjects - List<Claim> (7, 2).
 *                Always present, the default server provided claims.
 * requestedClaims - Map<String, Set<String>> (5).
 *                   Always present, not empty if the request contains the claims parameter and the server has enabled
 *                   claims_parameter_supported. A map of the requested claims to possible values, otherwise empty;
 *                   requested claims with no requested values will have a key but no value in the map. A key with
 *                   a single value in its Set (6) indicates that this is the only value that should be returned.
 * requestedTypedClaims - List<Claim> (7, 2).
 *                        Always present, the requested claims.
 *                        Requested claims with no requested values will have a claim with no values.
 *                        A claim with a single value indicates this is the only value that should be returned.
 * claimsLocales - List<String> (7).
 *                 The values from the 'claims_locales' parameter.
 *                 See https://openid.net/specs/openid-connect-core-1_0.html#ClaimsLanguagesAndScripts for the OIDC specification details.
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
 *          Corresponding files will be prefixed with: scripts.OIDC_CLAIMS.
 * httpClient - HTTP Client (8).
 *              Always present, the HTTP Client instance:
 *              https://backstage.forgerock.com/docs/am/7/scripting-guide/scripting-api-global-http-client.html#scripting-api-global-http-client.
 *              In order to use the client, you may need to add
 *              org.forgerock.http.Client,
 *              org.forgerock.http.protocol.*,
 *              and org.forgerock.util.promise.PromiseImpl
 *              to the allowed Java classes in the scripting engine configuration, as described in:
 *              https://backstage.forgerock.com/docs/am/7/scripting-guide/script-engine-security.html
 *
 * Return - a new UserInfoClaims(Map<String, Object> values, Map<String, List<String>> compositeScopes) (1) object.
 *          The result of the last statement in the script is returned to the server.
 *          Currently, the Immediately Invoked Function Expression (also known as Self-Executing Anonymous Function)
 *          is the last (and only) statement in this script, and its return value will become the script result.
 *          Do not use "return variable" statement outside of a function definition.
 *          See RESULTS section for additional details.
 *
 * Class reference:
 * (1) UserInfoClaims - https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/oauth2/core/UserInfoClaims.html.
 * (2) Claim - https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html).
 *         An instance of org.forgerock.openidconnect.Claim has methods to access
 *         the claim name, requested values, locale, and whether the claim is essential.
 * (3) AMIdentity - https://backstage.forgerock.com/docs/am/7/apidocs/com/sun/identity/idm/AMIdentity.html.
 * (4) SSOToken - https://backstage.forgerock.com/docs/am/7/apidocs/com/iplanet/sso/SSOToken.html.
 * (5) Map - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/HashMap.html,
 *           or https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/LinkedHashMap.html.
 * (6) Set - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/HashSet.html.
 * (7) List - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/ArrayList.html.
 * (8) Client - https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/http/Client.html.
*/

(function () {
    // SETUP

    /**
     * Claim processing utilities.
     * An object that contains reusable functions for processing claims.
     * @see CLAIM PROCESSING UTILITIES section for details.
     */
    var utils = getUtils();

    // CONFIGURATION AND CUSTOMIZATION

    /**
     * OAuth 2.0 scope values (scopes) can be used by the Client to request OIDC claims.
     *
     * Call this configuration method, and pass in as the first argument
     * an object that maps a scope value to an array of claim names
     * to specify which claims need to be processed and returned for the requested scopes.
     * @see {@link https://openid.net/specs/openid-connect-core-1_0.html#ScopeClaims}
     * for the scope values that could be used to request claims as defined in the OIDC specification.
     *
     * Below, find a default configuration that is expected to work in the current environment.
     *
     * CUSTOMIZATION
     * You can choose the claim names returned for a scope.
     */
    utils.setScopeClaimsMap({
        profile: [
            'name',
            'family_name',
            'given_name',
            'zoneinfo',
            'locale'
        ],
        email: ['email'],
        address: ['address'],
        phone: ['phone_number']
    });

    /**
     * In this script, each claim
     * derived from the requested scopes,
     * provided by the authorization server, and
     * requested by the client via the claims parameter
     * will be processed by a function associated with the claim name.
     *
     * Call this configuration method, and pass in as the first argument
     * an object that maps a claim name to a resolver function,
     * which will be automatically executed for each claim processed by the script.
     *
     * The claim resolver function will receive the requested claim information
     * in an instance of org.forgerock.openidconnect.Claim as the first argument.
     * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html}
     * for details on the Claim class.
     *
     * If the claim resolver function returns a value,
     * other than undefined or null,
     * the claim will be included in the script's results.
     *
     * The Claim instance provides methods to check
     * what the name of the claim is,
     * which values the claim request contains,
     * whether the claim is essential, and
     * which locale the claim is associated with.
     * The resolver function can consider this information when computing and returning the claim value.
     *
     * Below, find a default configuration that is expected to work in the current environment.
     * A reusable function, utils.getUserProfileClaimResolver(String attribute-name),
     * is called to return a claim resolver function based on a user profile attribute.
     * @see CLAIM RESOLVERS section for the implementation details and examples.
     * For the address claim, an example of a claim resolver that uses another claim resolver is provided.
     *
     * CUSTOMIZATION
     * You can reuse the predefined utils methods with your custom arguments.
     * You can also specify a custom resolver function for a claim name,
     * that will compute and return the claim value—as shown in the commented out example below.
     */
    utils.setClaimResolvers({
        /*
        // An example of a simple claim resolver function that is defined for a claim
        // directly in the configuration object:
        custom-claim-name: function (requestedClaim) {
            // In this case, initially, the claim value comes straight from a user profile attribute value:
            var claimValue = identity.getAttribute('custom-attribute-name').toArray()[0]

            // Optionally, provide additional logic for processing (filtering, formatting, etc.) the claim value.
            // You can use:
            // requestedClaim.getName()
            // requestedClaim.getValues()
            // requestedClaim.getLocale()
            // requestedClaim.isEssential()

            return claimValue
        },
        */
        /**
         * The use of utils.getUserProfileClaimResolver shows how
         * an argument passed to a function that returns a claim resolver
         * becomes available to the resolver function (via its lexical context).
         */
        name: utils.getUserProfileClaimResolver('cn'),
        family_name: utils.getUserProfileClaimResolver('sn'),
        given_name: utils.getUserProfileClaimResolver('givenname'),
        zoneinfo: utils.getUserProfileClaimResolver('preferredtimezone'),
        locale: utils.getUserProfileClaimResolver('preferredlocale'),
        email: utils.getUserProfileClaimResolver('mail'),
        address: utils.getAddressClaimResolver(
            /**
             * The passed in user profile claim resolver function
             * can be used by the address claim resolver function
             * to obtain the claim value to be formatted as per the OIDC specification:
             * @see https://openid.net/specs/openid-connect-core-1_0.html#AddressClaim.
             */
            utils.getUserProfileClaimResolver('postaladdress')
        ),
        phone_number: utils.getUserProfileClaimResolver('telephonenumber')
    });

    // CLAIM PROCESSING UTILITIES

    /**
     * @returns {object} An object that contains reusable claim processing utilities.
     * @see PUBLIC METHODS section and the return statement for the list of exported functions.
     */
    function getUtils () {
        // IMPORT JAVA

        /**
         * Provides Java scripting functionality.
         * @see {@link https://developer.mozilla.org/en-US/docs/Mozilla/Projects/Rhino/Scripting_Java#javaimporter_constructor}.
         */
        var frJava = JavaImporter(
            org.forgerock.oauth2.core.exceptions.InvalidRequestException,
            org.forgerock.oauth2.core.UserInfoClaims,
            org.forgerock.openidconnect.Claim,

            java.util.LinkedHashMap,
            java.util.ArrayList
        );

        // SET UP CONFIGURATION

        /**
         * Placeholder for a configuration option that contains
         * an object that maps the supported scope values (scopes)
         * and the corresponding claim names for each scope value.
         */
        var scopeClaimsMap;

        /**
         * Placeholder for a configuration option that contains
         * an object that maps the supported claim names
         * and the resolver functions returning the claim value.
         */
        var claimResolvers;

        /**
         * A (public) method that accepts an object that maps the supported scopes and the corresponding claim names,
         * and assigns it to a (private) variable that serves as a configuration option.
         * @param {object} params - An object that maps each supported scope value to an array of claim names,
         * in order to specify which claims need to be processed for the requested scopes.
         * @see {@link https://openid.net/specs/openid-connect-core-1_0.html#ScopeClaims} for details.
         * @param {string[]} [params.profile] - An array of claim names to be returned if the profile scope is requested.
         * @param {string[]} [params.email] - An array of claim names to be returned if the email scope is requested.
         * @param {string[]} [params.address] - An array of claim names to be returned if the address scope is requested.
         * @param {string[]} [params.phone] - An array of claim names to be returned if the phone scope is requested.
         * @returns {undefined}
         */
        function setScopeClaimsMap(params) {
            scopeClaimsMap = params;
        }

        /**
         * A (public) method that accepts an object that maps the supported claim names
         * and the resolver functions returning the claim value,
         * and assigns it to a (private) variable that serves as a configuration option.
         * @param {object} params - An object that maps
         * each supported claim name to a function that computes and returns the claim value.
         */
        function setClaimResolvers(params) {
            claimResolvers = params;
        }

        // CLAIM RESOLVERS

        /**
         * Claim resolvers are functions that return a claim value.
         * @param {*}
         * @returns {*}
         */

        /**
         * Defines a claim resolver based on a user profile attribute.
         * @param {string} attributeName - Name of the user profile attribute.
         * @returns {function} A function that will determine the claim value
         * based on the user profile attribute and the (requested) claim properties.
         */
        function getUserProfileClaimResolver (attributeName) {
            /**
             * Resolves a claim with a user profile attribute value.
             * Returns undefined if the identity attribute is not populated,
             * OR if the claim has requested values that do not contain the identity attribute value.
             * ATTENTION: the aforementioned comparison is case-sensitive.
             * @param {org.forgerock.openidconnect.Claim} claim
             * An object that provides methods to obtain information/requirements associated with a claim.
             * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html} for details.
             * @returns {string|HashSet|undefined}
             */
            function resolveClaim(claim) {
                var userProfileValue;

                if (identity) {
                    userProfileValue = getClaimValueFromSet(claim, identity.getAttribute(attributeName));

                    if (userProfileValue && !userProfileValue.isEmpty()) {
                        if (!claim.getValues() || claim.getValues().isEmpty() || claim.getValues().contains(userProfileValue)) {
                            return userProfileValue;
                        }
                    }
                }
            }

            return resolveClaim;
        }

        /**
         * Returns an address claim resolver based on a claim value obtained with another claim resolver.
         * @param {function} resolveClaim - A function that returns a claim value.
         * @returns {function} A function that will accept a claim as an argument,
         * run the claim resolver function for the claim and obtain the claim value,
         * and apply additional formatting to the value before returning it.
         */
        function getAddressClaimResolver (resolveClaim) {
            /**
             * Creates an address claim object from a value returned by a claim resolver,
             * and returns the address claim object as the claim value.
             * @see {@link https://openid.net/specs/openid-connect-core-1_0.html#AddressClaim}.
             * The claim value is obtained with a claim resolving function available from the closure.
             * @param {org.forgerock.openidconnect.Claim} claim
             * An object that provides methods to obtain information/requirements associated with a claim.
             * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html} for details.
             * @returns {java.util.LinkedHashMap|undefined} The address claim object created from a claim value.
             */
            function resolveAddressClaim(claim) {
                var claimValue = resolveClaim(claim);
                var addressObject;

                if (isClaimValueValid(claimValue)) {
                    addressObject = new frJava.LinkedHashMap();

                    addressObject.put('formatted', claimValue);

                    return addressObject;
                }
            }

            return resolveAddressClaim;
        }

        /**
         * Returns an essential claim resolver based on a claim value obtained with another claim resolver.
         * @param {function} resolveClaim - A function that returns a claim value.
         * @returns {function} A function that will accept a claim as an argument,
         * run the claim resolver function for the claim and obtain the claim value,
         * and apply additional logic for essential claims.
         */
        function getEssentialClaimResolver (resolveClaim) {
            /**
             * Returns a claim value or throws an error.
             * The claim value is obtained with a claim resolving function available from the closure.
             * Throws an exception if the claim is essential and no value is returned for the claim.
             *
             * Use of this resolver is optional.
             * @see {@link https://openid.net/specs/openid-connect-core-1_0.html#IndividualClaimsRequests} stating:
             * "Note that even if the Claims are not available because the End-User did not authorize their release or they are not present,
             * the Authorization Server MUST NOT generate an error when Claims are not returned, whether they are Essential or Voluntary,
             * unless otherwise specified in the description of the specific claim."
             *
             * @param {org.forgerock.openidconnect.Claim} claim
             * An object that provides methods to obtain information/requirements associated with a claim.
             * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html} for details.
             * @returns {*}
             * @throws {org.forgerock.oauth2.core.exceptions.InvalidRequestException}
             */
            function resolveEssentialClaim(claim) {
                var claimValue = resolveClaim(claim);

                if (claim.isEssential() && !isClaimValueValid(claimValue)) {
                    throw new frJava.InvalidRequestException('Could not provide value for essential claim: ' + claim.getName());
                }

                return claimValue;
            }

            return resolveEssentialClaim;
        }

        /**
         * Provides default resolution for a claim.
         * Use it if a claim-specific resolver is not defined in the configuration.
         * @param {org.forgerock.openidconnect.Claim} claim
         * An object that provides methods to obtain information/requirements associated with a claim.
         * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html} for details.
         * @returns {*} A single value associated with this claim.
         */
        function resolveAnyClaim (claim) {
            if (claim.getValues().size() === 1) {
                return claim.getValues().toArray()[0];
            }
        }

        // UTILITIES

        /**
         * Returns claim value from a set.
         * If the set contains a single value, returns the value.
         * If the set contains multiple values, returns the set.
         * Otherwise, returns undefined.
         *
         * @param {org.forgerock.openidconnect.Claim} claim
         * An object that provides methods to obtain information/requirements associated with a claim.
         * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html} for details.
         * @param {java.util.HashSet} set The set—for example, a user profile attribute value.
         * @returns {string|java.util.HashSet|undefined}
         */
        function getClaimValueFromSet (claim, set) {
            if (set && set.size()) {
                if (set.size() === 1) {
                    return set.toArray()[0];
                } else {
                    return set;
                }
            } else if (logger.warningEnabled()) {
                logger.warning('OIDC Claims script. Got an empty set for claim: ' + claim.getName());
            }
        }

        function isClaimValueValid (claimValue) {
            if (typeof claimValue === 'undefined' || claimValue === null) {
                return false;
            }

            return true;
        }

        // CLAIM PROCESSING

        /**
         * Constructs and returns an object populated with the computed claim values
         * and the requested scopes mapped to the claim names.
         * @returns {org.forgerock.oauth2.core.UserInfoClaims} The object to be returned to the authorization server.
         * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/oauth2/core/UserInfoClaims.html}.
         * @see RESULTS section for the use of this function.
         */
        function getUserInfoClaims () {
            return new frJava.UserInfoClaims(getComputedClaims(), getCompositeScopes());
        }

        /**
         * Creates a map of (requested) claim names populated with the computed claim values.
         * @returns {java.util.LinkedHashMap}
         * A map of the requested claim names and the corresponding claim values.
         */
        function getComputedClaims () {
            /**
             * Creates a complete list of claim objects from:
             * the claims derived from the scopes,
             * the claims provided by the authorization server,
             * and the claims requested by the client.
             * @returns {java.util.ArrayList}
             * Returns a complete list of org.forgerock.openidconnect.Claim objects available to the script.
             * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html} for the claim object details.
             */
            function getClaims() {
                /**
                 * Returns a list of claim objects for the requested scopes.
                 * Uses the scopeClaimsMap configuration option to derive the claim names;
                 * no other properties of a claim derived from a scope are populated.
                 * @returns {java.util.ArrayList}
                 * A list of org.forgerock.openidconnect.Claim objects derived from the requested scopes.
                 * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html} for the claim object details.
                 */
                function convertScopeToClaims() {
                    var claims = new frJava.ArrayList();

                    scopes.toArray().forEach(function (scope) {
                        if (String(scope) !== 'openid' && scopeClaimsMap[scope]) {
                            scopeClaimsMap[scope].forEach(function (claimName) {
                                claims.add(new frJava.Claim(claimName));
                            });
                        }
                    });

                    return claims;
                }

                var claims = new frJava.ArrayList();

                claims.addAll(convertScopeToClaims());
                claims.addAll(claimObjects);
                claims.addAll(requestedTypedClaims);

                return claims;
            }

            /**
             * Computes and returns a claim value.
             * To obtain the claim value, uses the resolver function specified for the claim in the claimResolvers configuration object.
             * @see claimResolvers
             * If no resolver function is found, uses the default claim resolver function.
             *
             * @param {org.forgerock.openidconnect.Claim} claim
             * An object that provides methods to obtain information/requirements associated with a claim.
             * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/openidconnect/Claim.html} for details.
             * @returns {*} Claim value.
             * @throws {org.forgerock.oauth2.core.exceptions.InvalidRequestException}
             * Rethrows this exception if a claim resolver throws it.
             * You can throw org.forgerock.oauth2.core.exceptions.InvalidRequestException from your custom claim resolver
             * if you want to terminate the claim processing.
             */
            function computeClaim(claim) {
                var resolveClaim;
                var message;

                try {
                    resolveClaim = claimResolvers[claim.getName()] || resolveAnyClaim;

                    return resolveClaim(claim);
                } catch (e) {
                    message = 'OIDC Claims script exception. Unable to resolve OIDC Claim. ' + e;

                    if (String(e).indexOf('org.forgerock.oauth2.core.exceptions.InvalidRequestException') !== -1) {
                        throw e;
                    }

                    if (logger.warningEnabled()) {
                        logger.warning(message);
                    }
                }
            }

            var computedClaims = new frJava.LinkedHashMap();

            getClaims().toArray().forEach(function (claim) {
                var claimValue = computeClaim(claim);

                if (isClaimValueValid(claimValue)) {
                    computedClaims.put(claim.getName(), claimValue);
                } else {
                    /**
                     * If a claim has been processed, but appears in the list again,
                     * and its value cannot be computed under the new conditions,
                     * the claim is removed from the final result.
                     *
                     * For example, a claim could be mapped to a scope and found in the user profile,
                     * but also requested by the client with required values that don't match the computed one.
                     * @see {link https://openid.net/specs/openid-connect-core-1_0.html#IndividualClaimsRequests}.
                     * for the relevant OIDC specification details.
                     */
                    computedClaims.remove(claim.getName());
                }
            });

            return computedClaims;
        }

        /**
         * Creates a map of requested scopes and the corresponding claim names.
         * @returns {java.util.LinkedHashMap}
         */
        function getCompositeScopes () {
            var compositeScopes = new frJava.LinkedHashMap();

            scopes.toArray().forEach(function (scope) {
                var scopeClaims = new frJava.ArrayList();

                if (scopeClaimsMap[scope]) {
                    scopeClaimsMap[scope].forEach(function (claimName) {
                        scopeClaims.add(claimName);
                    });
                }

                if (scopeClaims.size()) {
                    compositeScopes.put(scope, scopeClaims);
                }
            });

            return compositeScopes;
        }

        // PUBLIC METHODS

        return {
            setScopeClaimsMap: setScopeClaimsMap,
            setClaimResolvers: setClaimResolvers,
            getUserProfileClaimResolver: getUserProfileClaimResolver,
            getAddressClaimResolver: getAddressClaimResolver,
            getEssentialClaimResolver: getEssentialClaimResolver,
            getUserInfoClaims: getUserInfoClaims
        };
    }

    // RESULTS

    /**
     * This script returns an instance of the org.forgerock.oauth2.core.UserInfoClaims class
     * populated with the computed claim values and
     * the requested scopes mapped to the claim names.
     * @see {@link https://backstage.forgerock.com/docs/am/7/apidocs/org/forgerock/oauth2/core/UserInfoClaims.html}.
     *
     * Assigning it to a variable gives you an opportunity
     * to log the content of the returned value during development.
     */
    var userInfoClaims = utils.getUserInfoClaims();

    /*
    logger.error(scriptName + ' results:')
    logger.error('Values: ' + userInfoClaims.getValues())
    logger.error('Scopes: ' + userInfoClaims.getCompositeScopes())
    */

    return userInfoClaims;
}());
