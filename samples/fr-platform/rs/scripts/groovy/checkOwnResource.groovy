String sub = contexts.oauth2.accessToken.info.sub

Request readRequest = new Request(request)
    .setMethod("GET")

readRequest.getHeaders().remove('if-match')

return http.send(readRequest).thenAsync( new AsyncFunction() {
    Promise apply (response) {
        if (response.status == Status.OK) {
            def responseObj = response.entity.json
            if (responseObj[subjectField] != sub) {
                return failureResponse.handle(context, request)
            } else {
                return next.handle(context, request)
            }
        } else {
            return failureResponse.handle(context, request)
        }
    }
})
