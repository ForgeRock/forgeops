package app

type OAuth2Clients struct {
	Clients []struct {
		ID string `json:"_id"`
	} `json:"result"`
}

type OAuth2Client struct {
	ID                         string  `json:"_id"`
	Rev                        *string `json:"_rev,omitempty"`
	AdvancedOAuth2ClientConfig struct {
		Descriptions struct {
			Inherited bool     `json:"inherited"`
			Value     []string `json:"value"`
		} `json:"descriptions"`
		RequestUris struct {
			Inherited bool          `json:"inherited"`
			Value     []interface{} `json:"value"`
		} `json:"requestUris"`
		SubjectType struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"subjectType"`
		Name struct {
			Inherited bool     `json:"inherited"`
			Value     []string `json:"value"`
		} `json:"name"`
		Contacts struct {
			Inherited bool          `json:"inherited"`
			Value     []interface{} `json:"value"`
		} `json:"contacts"`
		ResponseTypes struct {
			Inherited bool     `json:"inherited"`
			Value     []string `json:"value"`
		} `json:"responseTypes"`
		UpdateAccessToken struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"updateAccessToken"`
		MixUpMitigation struct {
			Inherited bool `json:"inherited"`
			Value     bool `json:"value"`
		} `json:"mixUpMitigation"`
		SectorIdentifierURI struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"sectorIdentifierUri"`
		TokenEndpointAuthMethod struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"tokenEndpointAuthMethod"`
		IsConsentImplied struct {
			Inherited bool `json:"inherited"`
			Value     bool `json:"value"`
		} `json:"isConsentImplied"`
		GrantTypes struct {
			Inherited bool     `json:"inherited"`
			Value     []string `json:"value"`
		} `json:"grantTypes"`
		JavascriptOrigins struct {
			Inherited bool     `json:"inherited"`
			Value     []string `json:"value"`
		} `json:"javascriptOrigins"`
	} `json:"advancedOAuth2ClientConfig"`
	SignEncOAuth2ClientConfig struct {
		TokenEndpointAuthSigningAlgorithm struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"tokenEndpointAuthSigningAlgorithm"`
		IDTokenEncryptionEnabled struct {
			Inherited bool `json:"inherited"`
			Value     bool `json:"value"`
		} `json:"idTokenEncryptionEnabled"`
		RequestParameterSignedAlg struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"requestParameterSignedAlg"`
		ClientJwtPublicKey struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"clientJwtPublicKey"`
		IDTokenPublicEncryptionKey struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"idTokenPublicEncryptionKey"`
		UserinfoResponseFormat struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"userinfoResponseFormat"`
		PublicKeyLocation struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"publicKeyLocation"`
		JwkStoreCacheMissCacheTime struct {
			Inherited bool `json:"inherited"`
			Value     int  `json:"value"`
		} `json:"jwkStoreCacheMissCacheTime"`
		RequestParameterEncryptedEncryptionAlgorithm struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"requestParameterEncryptedEncryptionAlgorithm"`
		UserinfoSignedResponseAlg struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"userinfoSignedResponseAlg"`
		IDTokenEncryptionAlgorithm struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"idTokenEncryptionAlgorithm"`
		RequestParameterEncryptedAlg struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"requestParameterEncryptedAlg"`
		JwkSet struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"jwkSet"`
		IDTokenEncryptionMethod struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"idTokenEncryptionMethod"`
		JwksCacheTimeout struct {
			Inherited bool `json:"inherited"`
			Value     int  `json:"value"`
		} `json:"jwksCacheTimeout"`
		UserinfoEncryptedResponseAlg struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"userinfoEncryptedResponseAlg"`
		IDTokenSignedResponseAlg struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"idTokenSignedResponseAlg"`
		JwksURI struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"jwksUri"`
		UserinfoEncryptedResponseEncryptionAlgorithm struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"userinfoEncryptedResponseEncryptionAlgorithm"`
	} `json:"signEncOAuth2ClientConfig"`
	CoreOpenIDClientConfig struct {
		Claims struct {
			Inherited bool          `json:"inherited"`
			Value     []interface{} `json:"value"`
		} `json:"claims"`
		ClientSessionURI struct {
			Inherited bool        `json:"inherited"`
			Value     interface{} `json:"value"`
		} `json:"clientSessionUri"`
		DefaultAcrValues struct {
			Inherited bool          `json:"inherited"`
			Value     []interface{} `json:"value"`
		} `json:"defaultAcrValues"`
		JwtTokenLifetime struct {
			Inherited bool `json:"inherited"`
			Value     int  `json:"value"`
		} `json:"jwtTokenLifetime"`
		DefaultMaxAgeEnabled struct {
			Inherited bool `json:"inherited"`
			Value     bool `json:"value"`
		} `json:"defaultMaxAgeEnabled"`
		DefaultMaxAge struct {
			Inherited bool `json:"inherited"`
			Value     int  `json:"value"`
		} `json:"defaultMaxAge"`
		PostLogoutRedirectURI struct {
			Inherited bool          `json:"inherited"`
			Value     []interface{} `json:"value"`
		} `json:"postLogoutRedirectUri"`
	} `json:"coreOpenIDClientConfig"`
	CoreOAuth2ClientConfig struct {
		Agentgroup            interface{} `json:"agentgroup"`
		Userpassword          interface{} `json:"userpassword"`
		UserpasswordEncrypted *string     `json:"userpassword-encrypted,omitempty"`
		DefaultScopes         struct {
			Inherited bool     `json:"inherited"`
			Value     []string `json:"value"`
		} `json:"defaultScopes"`
		RefreshTokenLifetime struct {
			Inherited bool `json:"inherited"`
			Value     int  `json:"value"`
		} `json:"refreshTokenLifetime"`
		Scopes struct {
			Inherited bool     `json:"inherited"`
			Value     []string `json:"value"`
		} `json:"scopes"`
		Status struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"status"`
		AccessTokenLifetime struct {
			Inherited bool `json:"inherited"`
			Value     int  `json:"value"`
		} `json:"accessTokenLifetime"`
		RedirectionUris struct {
			Inherited bool     `json:"inherited"`
			Value     []string `json:"value"`
		} `json:"redirectionUris"`
		ClientName struct {
			Inherited bool     `json:"inherited"`
			Value     []string `json:"value"`
		} `json:"clientName"`
		ClientType struct {
			Inherited bool   `json:"inherited"`
			Value     string `json:"value"`
		} `json:"clientType"`
		AuthorizationCodeLifetime struct {
			Inherited bool `json:"inherited"`
			Value     int  `json:"value"`
		} `json:"authorizationCodeLifetime"`
	} `json:"coreOAuth2ClientConfig"`
	CoreUmaClientConfig struct {
		ClaimsRedirectionUris struct {
			Inherited bool          `json:"inherited"`
			Value     []interface{} `json:"value"`
		} `json:"claimsRedirectionUris"`
	} `json:"coreUmaClientConfig"`
	Type struct {
		ID         string `json:"_id"`
		Name       string `json:"name"`
		Collection bool   `json:"collection"`
	} `json:"_type"`
}

func (o OAuth2Client) GetDescription() string {
	if len(o.AdvancedOAuth2ClientConfig.Descriptions.Value) > 0 {
		return o.AdvancedOAuth2ClientConfig.Descriptions.Value[0]
	}
	return ""
}

func (o OAuth2Client) GetName() string {
	if len(o.AdvancedOAuth2ClientConfig.Name.Value) > 0 {
		return o.AdvancedOAuth2ClientConfig.Name.Value[0]
	}
	return ""
}
