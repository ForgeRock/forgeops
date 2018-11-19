import org.forgerock.http.util.Uris
import java.util.ArrayList

String sub = contexts.oauth2.accessToken.info.sub

// In this case, we validate the request by reading the value of the target and make sure that
// the target object matches the subject from the accessToken
if (request.form.getFirst('_action') == "deleteNotificationsForTarget") {

    String target = request.form.getFirst('target')

    if (target == null || target.indexOf(targetComponent) != 0) {
        return failureResponse.handle(context, request)
    }

    def uri = request.getUri()
    Request readRequest = new Request()
        .setMethod("GET")
        .setUri(Uris.create(
            uri.scheme,
            null,
            uri.host,
            uri.port,
            "/openidm/" + target,
            null,
            null
        ))

    return http.send(readRequest).thenAsync( new AsyncFunction() {
        Promise apply (response) {
            if (response.status != Status.OK) {
                return failureResponse.handle(context, request)
            }

            def responseObj = response.entity.json
            if (responseObj[subjectField] != sub) {
                return failureResponse.handle(context, request)
            } else {
                return next.handle(context, request)
            }
        }
    })

// In this case, we validate the request by reading the "target" relationship
// from the to-be-deleted notification
} else if (request.method == "DELETE") {

    // Before we delete, we get the target of the to-be-deleted notification
    Request readRequest = new Request(request)
        .setMethod("GET")
    readRequest.getUri().setQuery("_fields=target/${subjectField},target/_refResourceCollection")
    readRequest.getHeaders().remove('if-match')

    return http.send(readRequest).thenAsync( new AsyncFunction() {
        Promise apply (response) {
            if (response.status != Status.OK) {
                return failureResponse.handle(context, request)
            }

            def responseObj = response.entity.json
            if (responseObj["target"]["_refResourceCollection"] != targetComponent ||
                responseObj["target"][subjectField] != sub) {
                return failureResponse.handle(context, request)
            }

            return next.handle(context, request)
        }
    })

} else {
    return failureResponse.handle(context, request)
}
