/*
  - Data made available by nodes that have already executed are available in the sharedState variable.
  - The script should set outcome to either "true" or "false".
 */

var fr = new JavaImporter(
  org.forgerock.http.protocol,
  org.forgerock.util.promise,
  org.forgerock.openam.auth.nodes,
  org.forgerock.guice.core,
  org.forgerock.json
);

var ORG_API_VAR_URL = "&{org.api.url}";

function postSMS() {
  with (fr) {
    var identityProvider = InjectorHolder.getInstance(IdentityProvider);
    var identity = identityProvider.getIdentity(sharedState.get('username'), sharedState.get('realm'));
    var phoneNumberAttr = identity.getAttribute('fr-idm-phone-numbers');
    if (phoneNumberAttr == null || phoneNumberAttr.size() == 0) {
      logger.error('No phone number available');
      return;
    }

    var phoneNumberJson = phoneNumberAttr.iterator().next();
    var phoneNumber = JSON.parse(phoneNumberJson).value;
    var oneTimePassword = sharedState.get('oneTimePassword');
    var org_api_url = ORG_API_VAR_URL.replace(/\/[\s]*$/,'');
    var url = org_api_url + '/sms';

    var entityObject = {
      message: 'One time password: ' + oneTimePassword,
      phoneNumber: '+' + phoneNumber
    }

    var request = new Request();
    request.method = 'POST';
    request.setUri(url);

    var headers = request.getHeaders();
    headers.add('Accept', 'application/json');
    headers.add('Content-Type', 'application/json');
    headers.add('Accept-API-Version', 'resource=2.0');

    request.setEntity(entityObject);

    var promise = httpClient.send(request);
    var response = promise.get();

    logger.message('Twilio Call. Status: ' + response.getStatus());
  }
}

postSMS();

outcome = 'outcome';
