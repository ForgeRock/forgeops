
String sub = contexts.oauth2.accessToken.info.sub
request.getHeaders().add('X-OpenIDM-RunAs', sub)
request.getHeaders().add('X-Requested-With', 'IG')

String adminContext = (new groovy.json.JsonBuilder([
    "id" : "amAdmin",
    "component" : "endpoint/static/user",
    "roles" : ["openidm-admin", "openidm-authorized"],
    "moduleId" : "STATIC_USER"
])).toString()

// remove any client-supplied protected values
request.getHeaders().remove('X-Authorization-Map')
if (sub.toLowerCase() == 'amadmin') {
    request.getHeaders().add('X-Authorization-Map', adminContext)
}

return next.handle(context, request)
