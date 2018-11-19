import org.forgerock.http.protocol.Form


Form query = (new Form()).fromQueryString(request.uri.query?:"")
String fields = query.getFirst('_fields')

if (fields == null) {
    fields = "*"
}

// Put the requested field in the list if it isn't already present
if (! fields.split(',').find { it ==~ field }) {
    query.putSingle('_fields', fields + ",${field}")
    request.uri.setQuery(query.toQueryString())
}

return next.handle(context, request)
