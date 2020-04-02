package am

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"github.com/sethgrid/pester"
	log "github.com/sirupsen/logrus"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/models/app"
)

type ErrorResponse struct {
	Code    int64                  `json:"code"`
	Detail  map[string]interface{} `json:"detail"`
	Message string                 `json:"message"`
	Reason  string                 `json:"reason"`
}

type Servicer interface {
	GetOAuth2Client(id string) (*app.OAuth2Client, error)
}

type ServiceConfig struct {
	AM_Host     string
	AM_Password string
	AM_UserName string
	AM_URL      string
}

type AuthResponse struct {
	TokenID    string `json:"tokenId"`
	SuccessURL string `json:"successUrl"`
	Realm      string `json:"realm"`
}

type service struct {
	ServiceConfig
	cache    cacheTokenId  // cache for the sso token used for the REST API
	cacheTTL time.Duration // how long to cache the token for
	client   httpClient    // mockable http client interface - expect pester.New() to be used on construction
}

// A simple cache holder object for the AM sso token being used by the client to make REST calls.
type cacheTokenId struct {
	tokenId   string
	timestamp time.Time
}

type httpClient interface {
	Do(*http.Request) (*http.Response, error)
}

var InternalError = errors.New(http.StatusText(http.StatusInternalServerError))

func NewService(cnf ServiceConfig) *service {
	client := pester.New()
	client.Concurrency = 1
	client.MaxRetries = 5
	client.Backoff = pester.ExponentialBackoff
	client.KeepLog = true

	return &service{
		cache:         cacheTokenId{},
		cacheTTL:      30 * time.Minute,
		client:        client,
		ServiceConfig: cnf,
	}
}

func NewDefaultAdminService(password string) *service {
	return NewService(ServiceConfig{
		AM_Host:     "openam",
		AM_Password: password,
		AM_UserName: "amadmin",
		AM_URL:      "http://openam.fr-platform:80/am",
	})
}

func (s *service) GetOAuth2Client(id string) (*app.OAuth2Client, error) {
	req, err := http.NewRequest("GET", s.url("json/realms/root/realm-config/agents/OAuth2Client/%s", id), nil)
	if err != nil {
		return nil, err
	}

	res, err := s.do(req, false)
	if err != nil {
		return nil, err
	}

	defer res.Body.Close()

	var body app.OAuth2Client
	err = json.NewDecoder(res.Body).Decode(&body)
	if err != nil {
		return nil, err
	}

	return &body, nil
}

func (s *service) GetAmEncryptionKey() (string, error) {
	req, err := http.NewRequest("GET", s.url("json/global-config/servers/01/properties/security"), nil)
	if err != nil {
		return "", err
	}
	res, err := s.do(req, false)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	body := map[string]interface{}{}
	if err := json.NewDecoder(res.Body).Decode(&body); err != nil {
		return "", err
	}
	encryptionSettings := body["amconfig.header.encryption"].(map[string]interface{})
	encryptionKeyValue := encryptionSettings["am.encryption.pwd"].(map[string]interface{})
	return encryptionKeyValue["value"].(string), nil
}

func (s *service) UpdateOAuth2Client(client *app.OAuth2Client) error {
	rev := client.Rev
	client.Rev = nil

	clientBody, err := json.Marshal(client)
	if err != nil {
		return err
	}
	req, err := http.NewRequest("PUT", s.url("json/realms/root/realm-config/agents/OAuth2Client/%s", client.ID), bytes.NewBuffer(clientBody))
	if err != nil {
		return err
	}

	if rev != nil {
		req.Header.Set("if-match", *rev)
	}

	res, err := s.do(req, false)
	if err != nil {
		return err
	}

	if res.StatusCode != 200 {
		return fmt.Errorf("unexpected status from client update: %d", res.StatusCode)
	}

	return nil
}

func (s *service) GetOAuth2Clients() (*app.OAuth2Clients, error) {
	req, err := http.NewRequest("GET", s.url("json/realms/root/realm-config/agents/OAuth2Client?_queryFilter=true&_fields=_id"), nil)
	if err != nil {
		return nil, fmt.Errorf("could not create request to get oauth clients: %w", err)
	}

	res, err := s.do(req, false)
	if err != nil {
		return nil, fmt.Errorf("could not get oauth clients: %w", err)
	}

	defer res.Body.Close()

	var body app.OAuth2Clients
	err = json.NewDecoder(res.Body).Decode(&body)
	if err != nil {
		return nil, fmt.Errorf("could not decode JSON for oauth clients: %w", err)
	}

	return &body, nil
}

// do adds admin tokenId header to request and returns response
// will re-attempt once on an Unauthorized am response with a fresh token
func (s *service) do(req *http.Request, refreshTokenId bool) (*http.Response, error) {
	tokenId, err := s.getTokenId(refreshTokenId)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept-API-Version", "resource=1.0,protocol=2.0")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("iPlanetDirectoryPro", tokenId)
	req.Host = s.AM_Host
	res, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	// consider status >= 400 an error
	if res.StatusCode >= 400 {
		if 401 == res.StatusCode && !refreshTokenId {
			// try again w/ refreshedTokenId
			return s.do(req, true)
		}
		// unset tokenId cache, read body and return formatted error
		defer res.Body.Close()
		s.cache.tokenId = ""
		var body ErrorResponse
		bodyContent, err := ioutil.ReadAll(res.Body)
		if err != nil {
			log.Errorf("unable to read am error response: %s", err.Error())
			return res, InternalError
		}
		err = json.Unmarshal(bodyContent, &body)
		if err != nil {
			log.WithField("body", string(bodyContent)).Errorf("unable to decode am error response: %s", err.Error())
			return res, InternalError
		}
		if body.Detail != nil && len(body.Detail) > 0 {
			log.WithField("detail", body.Detail).Info("error detail from AM")
		}
		return res, fmt.Errorf("%s: %s", body.Message, body.Reason)
	}
	return res, err
}

func (s *service) url(value string, opts ...interface{}) string {
	if len(opts) > 0 {
		value = fmt.Sprintf(value, opts...)
	}
	return fmt.Sprintf("%s/%s", s.AM_URL, value)
}

//getTokenId returns an am tokenId and caches inmem
// unset cached tokenId on errors
func (s *service) getTokenId(refreshTokenId bool) (string, error) {
	// basic inmem cache
	if !refreshTokenId && "" != s.cache.tokenId && time.Until(s.cache.timestamp) < s.cacheTTL {
		return s.cache.tokenId, nil
	}
	req, err := http.NewRequest("POST", s.url("json/realms/root/authenticate"), nil)
	if err != nil {
		s.cache.tokenId = ""
		log.Errorf("Unable build am request: %s", err.Error())
		return "", InternalError
	}

	req.Header.Set("Accept-API-Version", "resource=1.0,protocol=2.0")
	req.Header.Set("X-OpenAM-Username", s.AM_UserName)
	req.Header.Set("X-OpenAM-Password", s.AM_Password)
	req.Host = s.AM_Host

	res, err := s.client.Do(req)
	if err != nil {
		s.cache.tokenId = ""
		log.Errorf("Unable to do am request: %s", err.Error())
		return "", InternalError
	}
	defer res.Body.Close()

	if res.StatusCode >= 400 {
		s.cache.tokenId = ""
		var body ErrorResponse
		err = json.NewDecoder(res.Body).Decode(&body)
		if err != nil {
			log.Errorf("unable to decode am error response: %s", err.Error())
			return "", InternalError
		}
		return "", fmt.Errorf("%s: %s", body.Message, body.Reason)
	}

	var body AuthResponse
	err = json.NewDecoder(res.Body).Decode(&body)
	if err != nil {
		s.cache.tokenId = ""
		log.Errorf("unable to decode am response: %s", err.Error())
		return "", InternalError
	}

	s.cache.timestamp = time.Now()
	s.cache.tokenId = body.TokenID

	return body.TokenID, nil
}
