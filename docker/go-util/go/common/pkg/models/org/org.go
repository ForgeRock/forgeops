package org

// nolint
// organization model, maps to Organization (kind) in datastore
//
// swagger:model organization
type DatastoreEntity struct {
	Name                          string
	Subdomain                     string
	GoogleProjectID               string
	SalesforceID                  string
	SupportSetKey                 string
	TrialStartDate                string
	TrialEndDate                  string
	Members                       []int64
	OrgEngineDockerImageTag       string
	OrgBootstrapperDockerImageTag string
	EnvironmentComplete           bool
	VerifyEndUserEmailAddress     bool
	TenantType                    string
	Region                        string
	Sysdig                        bool
	Pingdom                       bool
	WithSLA                       bool
}

func (de *DatastoreEntity) IsBillable() bool {
	return len(de.SalesforceID) > 0
}
