if (!request.headers.get('Authorization') &&
    session.openid && session.openid.access_token) {
    request.headers.add('Authorization', 'Bearer ' + session.openid.access_token)
}

return next.handle(context, request)
