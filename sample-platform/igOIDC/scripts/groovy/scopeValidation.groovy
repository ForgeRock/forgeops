import org.forgerock.http.util.Uris
import java.util.ArrayList

// Ensure that a policy decision has been made prior to running this filter
if (!contexts.policyDecision) {
    return failureResponse.handle(context, request)
}

// Scoping the request is only possible if there are attributes defined in the policy decision
if (contexts.policyDecision.attributes == null ||
    contexts.policyDecision.attributes[scopingAttribute] == null) {
    return next.handle(context, request)
}

// The scoping attribute, if present, has to have a single string value for it to be usable for scoping
if (contexts.policyDecision.attributes[scopingAttribute].size() != 1 &&
    !(contexts.policyDecision.attributes[scopingAttribute][0] instanceof String)) {
    return failureResponse.handle(context, request)
}

def encode = Uris.&urlEncodeQueryParameterNameOrValue
String scopingValue = contexts.policyDecision.attributes[scopingAttribute][0]
def uri = request.getUri()

// special case for queryId-based query requests:
if (request.method == "GET") {
    def queryStringEntries = request.form

    // we can't enforce scoping for arbitrary queries such as expressions:
    if (queryStringEntries.get('_queryExpression') != null) {
        return failureResponse.handle(context, request)
    }

    // we can scope with a queryFilter by wrapping up the provided filter with some additional AND'ed logic
    if  (queryStringEntries.get('_queryFilter') != null) {
        def templateEngine = new groovy.text.SimpleTemplateEngine()
        def params = [:]
        params[scopingAttribute] = scopingValue.replaceAll('"', '\\"')
        String renderedQueryFilter = templateEngine.createTemplate(scopeResourceQueryFilter)
            .make(params)
            .toString()

        def queryParameters = []

        queryStringEntries.each { key, value ->
            if (key == "_queryFilter") {
                queryParameters += ("_queryFilter=" + encode("((${renderedQueryFilter}) AND (${value[0]}))"));
            } else {
                queryParameters += "${encode(key)}=${encode(value[0])}"
            }
        }
        uri.setRawQuery(queryParameters.join("&"))
        return next.handle(context, request)
    }

    // we can facilitate scoping with _queryId entries by passing the attributes from the policy
    // decision along as additional arguments to the query
    if (queryStringEntries.get('_queryId') != null) {
        uri.setRawQuery(uri.getRawQuery() + "&${encode(scopingAttribute)}=${encode(scopingValue)}")
        return next.handle(context, request)
    }
}

// any request other than a query will be subject to verification by the scopeResourceQueryFilter
// assumed to be a request to a singleton resource (READ/PATCH/DELETE)

def pathElements = new ArrayList(uri.getPathElements())
def queryFilterTemplate = "(" + scopeResourceQueryFilter + ") AND _id eq \"\${resourceId}\""

def templateEngine = new groovy.text.SimpleTemplateEngine()
def params = ["resourceId":pathElements.pop().replaceAll('"', '\\"')]
params[scopingAttribute] = scopingValue.replaceAll('"', '\\"')
String renderedQueryFilter = templateEngine.createTemplate(queryFilterTemplate)
    .make(params)
    .toString()

def collectionURI = Uris.create(
    uri.scheme,
    null,
    uri.host,
    uri.port,
    "/" + pathElements.join('/'),
    "_queryFilter=${encode(renderedQueryFilter)}",
    null
)

Request idmRequest = new Request()
    .setUri(collectionURI)
    .setMethod("GET")

idmRequest.getHeaders().add('X-Special-Trusted-User', 'IG')
idmRequest.getHeaders().add('X-Authorization-Map', (new groovy.json.JsonBuilder([
        "id" : "ig",
        "component" : "endpoint/static/user",
        "roles" : ["openidm-admin"],
        "moduleId" : "TRUSTED_ATTRIBUTE"
    ])).toString())
idmRequest.getHeaders().add('X-Requested-With', 'IG')

return http.send(idmRequest).thenAsync( new AsyncFunction() {
    Promise apply (response) {
        if (response.status == Status.OK) {
            def responseObj = response.entity.json
            if (responseObj.result.size() != 1 ||
                responseObj.result[0]._id.replaceAll('"', '\\"') != params["resourceId"]) {
                return failureResponse.handle(context, request)
            }
            return next.handle(context, request)
        } else {
            return failureResponse.handle(context, request)
        }
    }
})
