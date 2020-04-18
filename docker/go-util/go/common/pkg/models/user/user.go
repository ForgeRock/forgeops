package user

import (
	"fmt"
)

type User struct {
	ID                   string                   `json:"_id"`
	Meta                 Meta                     `json:"_meta"`
	AccountStatus        string                   `json:"accountStatus"`
	Addresses            []Address                `json:"addresses"`
	CustomAttributes     map[string]interface{}   `json:"customAttributes"`
	DisplayName          string                   `json:"displayName"`
	EffectiveAssignments []map[string]interface{} `json:"effectiveAssignments"`
	EffectiveRoles       []map[string]interface{} `json:"effectiveRoles"`
	Emails               []Email                  `json:"emails"`
	IMS                  []ValueType
	Locale               string                 `json:"locale"`
	Mail                 string                 `json:"mail"`
	Name                 Name                   `json:"name"`
	Nickname             string                 `json:"nickName"`
	Password             string                 `json:"password"`
	PhoneNumbers         []ValueType            `json:"phoneNumbers"`
	Photos               []ValueType            `json:"photos"`
	Preferences          map[string]interface{} `json:"preferences"`
	ProfileURL           string                 `json:"profileUrl"`
	SN                   string                 `json:"sn"`
	Timezone             string                 `json:"timezone"`
	Title                string                 `json:"title"`
	UserName             string                 `json:"userName"`
	UserType             string                 `json:"userType"`
	X509Certificates     []X509Certificate      `json:"x509Certificates"`
}

type Address struct {
	Country       string `json:"country"`
	Formatted     string `json:"formatted"`
	Locality      string `json:"locality"`
	PostalCode    string `json:"postalCode"`
	Primary       bool   `json:"primary"`
	Region        string `json:"region"`
	StreetAddress string `json:"streetAddress"`
	Type          string `json:"type"`
}

type Email struct {
	ValueType
	Primary bool `json:"primary"`
}

type Meta struct {
	CreateDate  string `json:"createDate"`
	LastChanged struct {
		Date string `json:"date"`
	}
	LoginCount int64 `json:"loginCount"`
}

type Name struct {
	FamilyName      string `json:"familyName"`
	Formatted       string `json:"formatted"`
	GivenName       string `json:"givenName"`
	HonorificPrefix string `json:"honorificPrefix"`
	HonorificSuffix string `json:"honorificSuffix"`
	MiddleName      string `json:"middleName"`
}

type ValueType struct {
	Type  string `json:"type"`
	Value string `json:"value"`
}

type X509Certificate struct {
	Value string `json:"value"`
}

func (u User) GetEmail() string {
	if len(u.Emails) > 0 {
		for _, email := range u.Emails {
			if email.Primary {
				return email.Value
			}
		}
		return u.Emails[0].Value
	}
	return u.Mail
}

func (u User) GetName() string {
	if "" != u.DisplayName {
		return u.DisplayName
	}
	if "" != u.Name.Formatted {
		return u.Name.Formatted
	}
	if "" != u.Name.FamilyName && "" != u.Name.GivenName {
		return fmt.Sprintf("%s %s", u.Name.GivenName, u.Name.FamilyName)
	}
	return u.UserName
}
