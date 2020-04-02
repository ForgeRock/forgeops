/*
 * Copyright 2015-2017 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */
/**
 * This is a Policy Condition example script. It demonstrates how to access a user's information,
 * use that information in external HTTP calls and make a policy decision based on the outcome.
 */

var userAddress, userIP, resourceHost;

if (validateAndInitializeParameters()) {

    var countryFromUserAddress = getCountryFromUserAddress();
    logger.message("Country retrieved from user's address: " + countryFromUserAddress);
    var countryFromUserIP = getCountryFromUserIP();
    logger.message("Country retrieved from user's IP: " + countryFromUserIP);
    var countryFromResourceURI = getCountryFromResourceURI();
    logger.message("Country retrieved from resource URI: " + countryFromResourceURI);

    if (countryFromUserAddress === countryFromUserIP && countryFromUserAddress === countryFromResourceURI) {
        logger.message("Authorization Succeeded");
        responseAttributes.put("countryOfOrigin", [countryFromUserAddress]);
        authorized = true;
    } else {
        logger.message("Authorization Failed");
        authorized = false;
    }

} else {
    logger.message("Required parameters not found. Authorization Failed.");
    authorized = false;
}

/**
 * Use the user's address to lookup their country of residence.
 *
 * @returns {*} The user's country of residence.
 */
function getCountryFromUserAddress() {

    var request = new org.forgerock.http.protocol.Request();
    request.setUri("http://maps.googleapis.com/maps/api/geocode/json?address=" + encodeURIComponent(userAddress));
  	request.setMethod("GET");

    var response = httpClient.send(request).get();
    logResponse(response);

    var geocode = JSON.parse(response.getEntity());
    var i;
    for (i = 0; i < geocode.results.length; i++) {
        var result = geocode.results[i];
        var j;
        for (j = 0; j < result.address_components.length; i++) {
            if (result.address_components[i].types[0] == "country") {
                return result.address_components[i].long_name;
            }
        }
    }
}

/**
 * Use the user's IP to lookup the country from which the request originated.
 *
 * @returns {*} The country from which the request originated.
 */
function getCountryFromUserIP() {
    var request = new org.forgerock.http.protocol.Request();
    request.setUri("http://ip-api.com/json/" + userIP);
  	request.setMethod("GET");

    var response = httpClient.send(request).get();
    logResponse(response);

    var result = JSON.parse(response.getEntity());
    if (result) {
        return result.country;
    }
}

/**
 * Use the requested resource's host name to lookup the country where the resource is hosted.
 *
 * @returns {*} The country in which the resource is hosted.
 */
function getCountryFromResourceURI() {
    var request = new org.forgerock.http.protocol.Request();
    request.setUri("http://ip-api.com/json/" + encodeURIComponent(resourceHost));
  	request.setMethod("GET");

    var response = httpClient.send(request).get();
    logResponse(response);

    var result = JSON.parse(response.getEntity());
    if (result) {
        return result.country;
    }
}

/**
 * Retrieve and validate the variables required to make the external HTTP calls.
 *
 * @returns {boolean} Will be true if validation was successful.
 */
function validateAndInitializeParameters() {
    var userAddressSet = identity.getAttribute("postalAddress");
    if (userAddressSet == null || userAddressSet.isEmpty()) {
        logger.warning("No address specified for user: " + username);
        return false;
    }
    userAddress = userAddressSet.iterator().next();
    logger.message("User address: " + userAddress);

    if (!environment) {
        logger.warning("No environment parameters specified in the evaluation request.");
        return false;
    }

    var ipSet = environment.get("IP");
    if (ipSet == null || ipSet.isEmpty()) {
        logger.warning("No IP specified in the evaluation request environment parameters.");
        return false;
    }
    userIP = ipSet.iterator().next();
    logger.message("User IP: " + userIP);

    if (!resourceURI) {
        logger.warning("No resource URI specified.");
        return false;
    }
    resourceHost = resourceURI.match(/^(.*:\/\/)(www\.)?([A-Za-z0-9\-\.]+)(:[0-9]+)?(.*)$/)[3];
    logger.message("Resource host: " + resourceHost);

    return true;
}

function logResponse(response) {
    logger.message("User REST Call. Status: " + response.getStatus() + ", Body: " + response.getEntity());
}