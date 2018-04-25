if (session.openid && session.openid.id_token) {
    Request logoutRequest = new Request()
        .setUri(endSessionEndpoint + "?id_token_hint=" + session.openid.id_token)
        .setMethod("GET")

    return http.send(logoutRequest).thenAsync( new AsyncFunction() {
        Promise apply (response) {
            session.clear()
            return next.handle(context, request)
        }
    })

} else {
    session.clear()
    return next.handle(context, request)
}
