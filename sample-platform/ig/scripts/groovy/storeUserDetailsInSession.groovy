if (!session.idmUserDetails || session.idmUserDetails.authenticationId != contexts.ssoToken.info.uid) {

    Request idmRequest = new Request()
        .setUri(idmUserDetailEndpoint)
        .setMethod(idmUserDetailMethod)

    idmRequest.getHeaders().add(request.getHeaders().get('X-Special-Trusted-User'))
    if (request.getHeaders().get('X-Authorization-Map')) {
        idmRequest.getHeaders().add(request.getHeaders().get('X-Authorization-Map'))
    }
    return http.send(idmRequest).thenAsync( new AsyncFunction() {
        Promise apply (response) {
            if (response.getStatus() == Status.OK) {
                session.idmUserDetails = response.getEntity().getJson()
                return next.handle(context, request)
            } else {
                return Response.newResponsePromise(response)
            }
        }
    })

} else {
    return next.handle(context, request)
}
