
String sub = contexts.ssoToken.info.uid

String adminContext = (new groovy.json.JsonBuilder([
      "id" : "openidm-admin",
      "component" : "repo/internal/user",
      "roles" : ["openidm-admin", "openidm-authorized"],
      "moduleId" : "TRUSTED_ATTRIBUTE"
  ])).toString()

request.getHeaders().add('X-Special-Trusted-User', sub);

if (sub.toLowerCase() == 'amadmin') {
  request.getHeaders().add('X-Authorization-Map', adminContext);
}


return next.handle(context, request)
