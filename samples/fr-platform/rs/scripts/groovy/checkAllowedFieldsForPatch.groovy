import org.forgerock.json.JsonPointer
try {
    def content = request.entity.json

    // ensure that each patch operation specified refers to a field which
    // is allowed to be modified, per the "allowedFields" argument
    if (!content.inject(true) { result, patchOp ->
        result && allowedFields.inject(false) { found, allowedField ->
            found || (new JsonPointer(patchOp.field)).equals(new JsonPointer(allowedField))
        }
    }) {
        return failureResponse.handle(context, request)
    } else {
        return next.handle(context, request)
    }
} catch (Exception e) {
    return next.handle(context, request)
}
