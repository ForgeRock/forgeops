if (request.headers.get('X-Requested-With') ||
    request.headers.get('Authorization') ||
    request.headers.get('X-OpenIDM-Username')) {
    return next.handle(context, request)
} else {
    return failureResponse.handle(context, request)
}
