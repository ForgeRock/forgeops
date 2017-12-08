
Boolean matches = false

checkRequests.forEach { checkRequest ->
    if (request.uri.path ==~ checkRequest.path) {
        if (checkRequest.methods.inject(false) { result, method -> result || request.method == method}) {
            matches = true
        }
    }
}

if (matches) {
    return delegate.handle(context, request)
} else {
    return failureResponse.handle(context, request)
}
