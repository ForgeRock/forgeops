if (!httpRequest.getHeaders().getFirst("X-OpenIDM-RunAs")) {
    throw {
        "code": 401,
        "message": "Required RunAs header missing"
    };
}
