if (request.headers['x-requested-with'] ||
    request.headers['authorization'] ||
    request.headers['idtoken'] ||
    request.headers['x-openidm-username']) {
    return next.handle(context, request)
} else {
    return failureResponse.handle(context, request)
}
