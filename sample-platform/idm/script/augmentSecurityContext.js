var authzHeaderValue = httpRequest.getHeaders().getFirst(authzHeaderName);

if (authzHeaderValue) {
    security.authorization = JSON.parse(authzHeaderValue.toString());
} else {
    var modifiedMap = {};
    Object.keys(security.authorization).forEach(function (k) {
        modifiedMap[k] = security.authorization[k];
    });
    security.authorization = modifiedMap;
}

var scopeHeaderValue = httpRequest.getHeaders().getFirst(scopeHeaderName);
if (scopeHeaderValue) {
    security.authorization.scopes = scopeHeaderValue.split(' ')
}

security.authorization.logoutUrl = '/logout';

security;
