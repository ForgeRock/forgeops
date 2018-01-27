import org.forgerock.json.jose.jws.SignedJwt
import org.forgerock.json.jose.common.JwtReconstruction
import org.forgerock.json.jose.exceptions.JwtReconstructionException

if (request.headers['idtoken']) {
    try {
        // we don't need to validate the id_token because it will be sent to AM and AM will validate it for us
        SignedJwt idToken = (new JwtReconstruction()).reconstructJwt(request.headers.getFirst('idtoken'), SignedJwt.class)
        def idTokenClaims = idToken.getClaimsSet().keys().inject([:]) { result, key ->
            result[key] = idToken.getClaimsSet().getClaim(key)
            return result
        }

        session.openid = [
            id_token: request.headers.getFirst('idtoken'),
            id_token_claims: idTokenClaims
        ]
    } catch (JwtReconstructionException e) {
        return failureResponse.handle(context, request)
    }
}

if (session.openid != null && session.openid.id_token_claims.sub != null) {
    String sub = session.openid.id_token_claims.sub
    String adminContext = (new groovy.json.JsonBuilder([
        "id" : "amAdmin",
        "component" : "endpoint/static/user",
        "roles" : ["openidm-admin", "openidm-authorized"],
        "moduleId" : "TRUSTED_ATTRIBUTE"
    ])).toString()

    request.getHeaders().add('X-Special-Trusted-User', sub);

    if (sub.toLowerCase() == 'amadmin') {
        request.getHeaders().add('X-Authorization-Map', adminContext);
    }

    return next.handle(context, request)
} else {
    return failureResponse.handle(context, request)
}
