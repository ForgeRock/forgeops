String sub = contexts.oauth2.accessToken.info.sub

String adminContext = (new groovy.json.JsonBuilder([
      "id" : "amAdmin",
      "component" : "endpoint/static/user",
      "roles" : ["openidm-admin", "openidm-authorized"],
      "moduleId" : "TRUSTED_ATTRIBUTE",
      "scopes" : contexts.oauth2.accessToken.info.scope.split()
  ])).toString()

request.getHeaders().add('X-Special-Trusted-User', sub);
request.getHeaders().add('X-Special-Trusted-User-Scope', contexts.oauth2.accessToken.info.scope);

if (sub.toLowerCase() == 'amadmin') {
  request.getHeaders().add('X-Authorization-Map', adminContext);
}


return next.handle(context, request)
