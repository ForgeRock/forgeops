package idmapi

/*
Example create-managed-user JSON payload:

{
    "userName":"bjensen@example.com",
    "sn":"Jensen",
    "givenName":"Barbara",
    "mail": "bjensen@example.com",
    "password":"Passw0rd",
    "authzRoles": [
         {
             "_ref": "internal/role/openidm-admin"
         },
         {
             "_ref": "internal/role/openidm-authorized"
         }
    ]
}
*/

// CreateRequestBody creates a Managed User with admin roles.
type CreateRequestBody struct {
	UserName   string     `json:"userName"`
	Email      string     `json:"mail"`
	Password   string     `json:"password"`
	FirstName  string     `json:"givenName,omitempty"`
	LastName   string     `json:"sn,omitempty"`
	AuthzRoles []RoleItem `json:"authzRoles"`
}

// CreateResponseBody represents a subset of fields from a create-Managed-User response.
type CreateResponseBody struct {
	ID string `json:"_id"`
}

const (
	// OpenIDMAdminRoleRef defines the "internal/role/openidm-admin" role-reference value.
	openIDMAdminRoleRef = "internal/role/openidm-admin"

	// OpenIDMAuthorizedRoleRef defines the "internal/role/openidm-authorized" role-reference value.
	openIDMAuthorizedRoleRef = "internal/role/openidm-authorized"
)

// RoleItem is a single role reference.
type RoleItem struct {
	Ref string `json:"_ref"`
}

/*
Example patch JSON payload:

[{
  "operation":"replace",
  "field":"/mail",
  "value":"bj@example.com"
},{
  "operation":"replace",
  "field":"/userName",
  "value":"bj@example.com"
}]
*/

const (
	// PatchReplaceOperation is the "replace" patch operation.
	patchReplaceOperation = "replace"

	// PatchEmailField field reference for email (must also update user-name)
	patchEmailField = "/mail"

	// PatchPasswordField field reference for password
	patchPasswordField = "/password"

	// PatchFirstNameField field reference for first-name
	patchFirstNameField = "/givenName"

	// PatchLastNameField field reference for last-name
	patchLastNameField = "/sn"
)

// PatchRequestBody is an array of PatchOperation items.
type PatchRequestBody []PatchOperation

// PatchOperation is a single patch operation.
type PatchOperation struct {
	Operation string `json:"operation"`
	Field     string `json:"field"`
	Value     string `json:"value"`
}
