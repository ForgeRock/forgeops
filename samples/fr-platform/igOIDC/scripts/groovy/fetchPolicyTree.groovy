String realm
if (pepRealm == '/') {
    realm = 'root'
} else {
    realm = pepRealm
}

Request amAuthRequest = new Request()
    .setUri(openamUrl + "/json/realms/${realm}/authenticate")
    .setMethod("POST")

amAuthRequest.getHeaders().add('Accept-API-Version', 'protocol=1.0,resource=2.1')
amAuthRequest.getHeaders().add('X-OpenAM-Username', pepUsername)
amAuthRequest.getHeaders().add('X-OpenAM-Password', pepPassword)
amAuthRequest.getHeaders().add('Content-type', 'application/json')

return http.send(amAuthRequest).thenAsync( new AsyncFunction() {
    Promise apply (response) {
        if (response.getStatus() == Status.OK) {
            def responseObj = response.entity.json
            if (!responseObj.tokenId) {
                return failureHandler.handle(context, request)
            }

            Request amPolicyRequest = new Request()
                .setUri(openamUrl + "/json/realms/${realm}/policies?_action=evaluateTree")
                .setMethod("POST")

            amPolicyRequest.getEntity().setJson([
                resource: resource,
                application: application,
                subject: [
                    ssoToken: session.openid.id_token
                ],
                environment: [
                    "securityContextPath": [
                        session.idmUserDetails.authorization.component + "/" + session.idmUserDetails.authorization.id
                    ],
                    "securityContextRoles": session.idmUserDetails.authorization.roles
                ]
            ])

            amPolicyRequest.getHeaders().add('iPlanetDirectoryPro', responseObj.tokenId)

            return http.send(amPolicyRequest).thenAsync( new AsyncFunction() {
                Promise apply (policyTreeResponse) {
                    return Response.newResponsePromise(policyTreeResponse)
                }
            })
        } else {
            return Response.newResponsePromise(response)
        }
    }
})
