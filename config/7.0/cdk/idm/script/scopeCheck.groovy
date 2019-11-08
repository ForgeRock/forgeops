import java.util.regex.Pattern
import org.forgerock.http.oauth2.OAuth2Context

if (context.containsContext(OAuth2Context.class)) {

    def accessTokenInfo = context.asContext(OAuth2Context.class).getAccessToken().asJsonValue()
    def scopes = accessTokenInfo.scope.asString().tokenize(" ")
    def route = routes.find { currentRoute ->
        //println "Checking to see if ${currentRoute.pattern} matches ${request.resourcePath}"
        (
            Pattern.compile(currentRoute.pattern).matcher(request.resourcePath).find() != false &&

            currentRoute.methods.inject(false) { anyMethodResult, currentMethod ->
                //println "Checking to see if request method ${request.getRequestType().name().toLowerCase()} is listed"
                anyMethodResult || (
                    currentMethod == request.getRequestType().name().toLowerCase() &&
                    (
                        currentMethod != "action" ||
                        currentRoute.actions == null ||
                        currentRoute.actions.indexOf(request.action) != -1
                    )
                )
            }
        )
    }

    if (route != null) {
       if (!route.scopes.inject(true) { everyScopeResult, currentlyRequiredScope ->
           //println "Checking to see if token has scope matching ${currentlyRequiredScope}"
           everyScopeResult && scopes.inject(false) { anyScopeResult, currentlyAvailableScopePattern ->
               //println "Checking to see if ${currentlyAvailableScopePattern} matches ${currentlyRequiredScope}: ${Pattern.compile(currentlyAvailableScopePattern).matcher(currentlyRequiredScope).find() != false}"
               anyScopeResult || Pattern.compile(currentlyAvailableScopePattern).matcher(currentlyRequiredScope).find() != false
           }
       }) {
           throw new Exception("Request denied - scopes available insufficient for path & method")
       }
    }
}
