/*
 * Copyright 2015-2017 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

var START_TIME = 9;  // 9am
var END_TIME   = 17; // 5pm
var longitude, latitude;
var localTime;

logger.message("Starting scripted authentication");
logger.message("User: " + username);

var userPostalAddress = getUserPostalAddress();
logger.message("User address: " + userPostalAddress);

getLongitudeLatitudeFromUserPostalAddress();
getLocalTime();

logger.message("Current time at the users location: " + localTime.getHours());
if (localTime.getHours() < START_TIME || localTime.getHours() > END_TIME) {
    logger.error("Login forbidden outside work hours!");
    authState = FAILED;
} else {
    logger.message("Authentication allowed!");
    authState = SUCCESS;
}

function getLongitudeLatitudeFromUserPostalAddress() {

    var request = new org.forgerock.http.protocol.Request();
    request.setUri("http://maps.googleapis.com/maps/api/geocode/json?address=" + encodeURIComponent(userPostalAddress));
  	request.setMethod("GET");
  	//the above URI has to be extended with an API_KEY if used in a frequent manner
  	//see documentation: https://developers.google.com/maps/documentation/geocoding/intro

    var response = httpClient.send(request).get();
    logResponse(response);

    var geocode = JSON.parse(response.getEntity());
    var i;
    for (i = 0; i < geocode.results.length; i++) {
        var result = geocode.results[i];
        latitude = result.geometry.location.lat;
        longitude = result.geometry.location.lng;
      
   	    logger.message("latitude:" + latitude + " longitude:" + longitude);
    }
}

function getLocalTime() {

    var now = new Date().getTime() / 1000;
    var location = "location=" + latitude + "," + longitude;
    var timestamp = "timestamp=" + now;
  	  
    var request = new org.forgerock.http.protocol.Request();
    request.setUri("https://maps.googleapis.com/maps/api/timezone/json?" + location + "&" + timestamp);
  	request.setMethod("GET");
  	//the above URI has to be extended with an API_KEY if used in a frequent manner
  	//see documentation: https://developers.google.com/maps/documentation/timezone/intro

    var response = httpClient.send(request).get();
    logResponse(response);

    var timezone = JSON.parse(response.getEntity());
    var localTimestamp = parseInt(now) + parseInt(timezone.dstOffset) + parseInt(timezone.rawOffset);
    localTime = new Date(localTimestamp*1000);
}

function getUserPostalAddress() {
    var userAddressSet = idRepository.getAttribute(username, "postalAddress");
    if (userAddressSet == null || userAddressSet.isEmpty()) {
        logger.warning("No address specified for user: " + username);
        return false;
    }
    return userAddressSet.iterator().next()
}

function logResponse(response) {
    logger.message("User REST Call. Status: " + response.getStatus() + ", Body: " + response.getEntity());
}