# services/go

Holds golang based services for customer and registration environments.

## Dependency Management

Dependencies are managed using Go modules and are saved to `./vendor/`.

Add dependency:

_Note: The `go build` and `go test` commands resolve imports by using versions listed in `go.mod`. If an import cannot be resolved, then it is automatically added to `go.mod` using the latest version._

```bash
# add example.com/package latest
go get example.com/package

# add example.com/package v1.0.0
go get example.com/package@v1.0.0
```

Upgrade dependency:

```bash
# upgrade example.com/package
go get example.com/package

# upgrade example.com/package and its dependencies
go get -u example.com/package
```

Downgrade dependency:

```bash
# assuming example.com/package v1.5.0 was added
# downgrade example.com/package to v1.3.0
go get example.com/package@v1.3.0
```

Remove unused dependencies:

```bash
go mod tidy
```
