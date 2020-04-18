var fr = new JavaImporter(
  org.forgerock.http.protocol,
  org.forgerock.util.promise,
  org.forgerock.openam.auth.nodes,
  org.forgerock.guice.core
);

var ORG_API_VAR_URL = "&{org.api.url}";
var IDM_VAR_URL = "&{idm.rest.url}";
var IDM_VAR_USERNAME = "&{idm.username|openidm-admin}";
var IDM_VAR_PASSWORD = "&{idm.password}";

function getUUIDFromIDMByUsername(username) {
  with (fr) {
    var encodedName = encodeURIComponent('"' + username + '"');
    var idm_url = IDM_VAR_URL.replace(/\/[\s]*$/,'');
    var url =
      idm_url +
      "/managed/user?_queryFilter=(userName+eq+" +
      encodedName +
      ")&_fields=_id";

    logger.error("IDM URL: " + url);

    var request = new Request();
    request.method = "GET";
    request.setUri(url);

    var headers = request.getHeaders()
    headers.add("Accept", "application/json");
    headers.add("Content-Type", "application/json");
    headers.add("X-Requested-With", "openam-send-templated-email");
    headers.add("X-OpenIDM-Username", IDM_VAR_USERNAME);
    headers.add("X-OpenIDM-Password", IDM_VAR_PASSWORD);

    promise = httpClient.send(request);
    var response = promise.get();

    logger.message("IDM response status: " + response.status);

    if (response.getStatus().getCode() == 200) {
      entity = response.getEntity().getString();
      var data = JSON.parse(entity);

      if (data.resultCount > 0) {
        return data.result[0]._id;
      }
    }
    return null;
  }
}

function getOTPRequestBody(uuid, otp) {
  var body = {
    templateType: "one-time-passcode",
    userId: uuid,
    params: {
      otp: otp.toString()
    }
  };
  return body;
}

function sendOTPRequest(username, otp) {
  with (fr) {
    var org_api_url = ORG_API_VAR_URL.replace(/\/[\s]*$/,'');
    var url = org_api_url + "/email";
    var uuid = getUUIDFromIDMByUsername(username);

    if (uuid == null) {
      logger.error(
        "unable to get fr-idm-uuid from IDM for username " + username
      );
      return false;
    }
    logger.message("uuid: " + uuid);

    var request = new Request();
    request.method = "POST";
    request.setUri(url);
    var headers = request.getHeaders()
    headers.add("Content-Type", "application/json");
    headers.add("X-Requested-With", "openam-send-templated-email");
    headers.add('Accept-API-Version', 'resource=2.0');
    var body = getOTPRequestBody(uuid, otp);
    request.setEntity(body);
    promise = httpClient.send(request);
    var response = promise.get();

    var message = "Templated Email Status: " + response.getStatus() + ", Cause: " + response.getCause();
    if(response.getStatus().getCode() >= 200 && response.getStatus().getCode() < 299) {
        logger.message(message);
        return true;
    }

    logger.error(message);
    return false;
  }
}

function postEmail() {
  with (fr) {
    var username = sharedState.get("username");
    var otp = sharedState.get("oneTimePassword");

    logger.message("username: " + username);
    logger.message("otp: " + otp);

    sendOTPRequest(username, otp);
  }
}

postEmail();
outcome = "outcome";
