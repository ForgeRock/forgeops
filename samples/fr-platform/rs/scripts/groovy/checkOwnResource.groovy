String sub = contexts.oauth2.accessToken.info.sub
def env = System.getenv()

Request readRequest = new Request(request)
    .setMethod("GET")

readRequest.getHeaders().remove('if-match')

readRequest.getHeaders().add('X-OpenIDM-Username', env["IG_CLIENT_USERNAME"])
readRequest.getHeaders().add('X-OpenIDM-Password', env["IG_CLIENT_PASSWORD"])

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
