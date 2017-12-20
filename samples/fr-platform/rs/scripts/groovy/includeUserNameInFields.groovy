import org.forgerock.http.protocol.Form

Form query = new Form()

if (request.uri.query) {
    String fields = query.fromQueryString(request.uri.query).getFirst('_fields')

    if (fields != null) {
        // fields is a csv
        if (! fields.split(',').find { it ==~ /userName/ }) {
            query.putSingle('_fields', fields + ',userName')
            request.uri.setQuery(query.toQueryString())
        }
    }
}

return next.handle(context, request)
