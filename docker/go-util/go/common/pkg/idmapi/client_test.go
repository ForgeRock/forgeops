package idmapi

import (
	"fmt"
	"net/http"
	"testing"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/httputil"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/testutil"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

type clientTestSuite struct {
	suite.Suite
}

func TestSaasAPIClientSuite(t *testing.T) {
	suite.Run(t, &clientTestSuite{})
}

var (
	idmBaseURL  = "https://localhost:443/openidm"
	idmUserName = "openidm-admin"
	idmPassword = "openidm-admin"

	xEmail     = "email@example.com"
	xPassword  = "P@55word"
	xFirstName = "First"
	xLastName  = "Last"

	errGeneric        = fmt.Errorf("Generic Error")
	errFromStatusCode = fmt.Errorf(StatusCodeErrorTemplate, http.StatusInternalServerError)

	createResponseBody = &CreateResponseBody{ID: "1"}
)

func (s *clientTestSuite) TestUserNamePasswordRequiredValidation() {
	// given / when
	_, errNoUserName := NewClientWithHTTPClienter(idmBaseURL, "", idmPassword, &httputil.MockHTTPClienter{})
	_, errNoPassword := NewClientWithHTTPClienter(idmBaseURL, idmUserName, "", &httputil.MockHTTPClienter{})

	// then
	require.EqualError(s.T(), errNoUserName, ErrUserNameAndPasswordRequired.Error())
	require.EqualError(s.T(), errNoPassword, ErrUserNameAndPasswordRequired.Error())
}

func (s *clientTestSuite) TestBaseURLValidation() {
	// given
	tests := []struct {
		baseURL       string
		expectedError error
	}{
		{"http://localhost:80", nil},
		{"http://localhost:80/path", nil},
		{"https://localhost:443", nil},
		{"https://localhost:443/path", nil},
		// empty string
		{"", ErrIDMBaseURLInvalid},
		// missing port
		{"http://localhost", ErrIDMBaseURLInvalid},
		// ends with forward slash
		{"http://localhost/", ErrIDMBaseURLInvalid},
		// capital letters used for protocol
		{"HTTP://localhost:80", ErrIDMBaseURLInvalid},
	}

	for _, test := range tests {
		// when
		_, err := NewClientWithHTTPClienter(test.baseURL, idmUserName, idmPassword, &httputil.MockHTTPClienter{})

		// then
		if test.expectedError == nil {
			require.Nil(s.T(), err)
		} else {
			require.EqualError(s.T(), err, test.expectedError.Error())
		}
	}
}

func (s *clientTestSuite) TestDeleteManagedUser() {
	// given
	tests := []struct {
		managedUserID      string
		httpClientResponse *http.Response
		httpClientError    error
		expectedError      error
	}{
		// success
		{"1", testutil.MarshalHTTPResponse(s.T(), http.StatusOK, nil), nil, nil},
		// ID required
		{"", nil, nil, ErrIDRequired},
		// team member not found
		{"1", testutil.MarshalHTTPResponse(s.T(), http.StatusNotFound, nil), nil, ErrTeamMemberNotFound},
		// IDM authentication failed
		{"1", testutil.MarshalHTTPResponse(s.T(), http.StatusUnauthorized, nil), nil, ErrIDMAuthenticationFailed},
		// HTTP client error with "errors" field in response
		{"1", testutil.MarshalHTTPResponse(s.T(), http.StatusInternalServerError, nil), errGeneric, errGeneric},
		// HTTP client error without "errors" field in response
		{"1", testutil.MarshalHTTPResponse(s.T(), http.StatusInternalServerError, nil), nil, errFromStatusCode},
	}

	for _, test := range tests {
		httpClient := &httputil.MockHTTPClienter{}
		httpClient.
			On("Do", mock.Anything).
			Return(test.httpClientResponse, test.httpClientError)

		client, err := NewClientWithHTTPClienter(idmBaseURL, idmUserName, idmPassword, httpClient)
		s.NoError(err)

		// when
		err = client.DeleteTeamMember(test.managedUserID)

		// then
		if test.expectedError == nil {
			require.Nil(s.T(), err)
		} else {
			require.EqualError(s.T(), err, test.expectedError.Error())
		}
	}
}

func (s *clientTestSuite) TestCreateManagedUser() {
	// given
	tests := []struct {
		email              string
		password           string
		firstName          string
		lastName           string
		httpClientResponse *http.Response
		httpClientError    error
		expectedError      error
	}{
		// success with all args
		{xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusOK, createResponseBody), nil, nil},
		// success with required args
		{xEmail, xPassword, "", "", testutil.MarshalHTTPResponse(s.T(), http.StatusOK, createResponseBody), nil, nil},
		// missing _id from IDM response body
		{xEmail, xPassword, "", "", testutil.MarshalHTTPResponse(s.T(), http.StatusOK, &CreateResponseBody{ID: ""}), nil, ErrUnexpectedIDMResponse},
		// email required
		{"", xPassword, xFirstName, xLastName, nil, nil, ErrEmailRequired},
		// password required
		{xEmail, "", xFirstName, xLastName, nil, nil, ErrPasswordRequired},
		// team member not found
		{xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusNotFound, nil), nil, ErrTeamMemberNotFound},
		// team member already exists
		{xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusPreconditionFailed, nil), nil, ErrTeamMemberAlreadyExists},
		// IDM authentication failed
		{xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusUnauthorized, nil), nil, ErrIDMAuthenticationFailed},
		// HTTP client error with "errors" field in response
		{xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusInternalServerError, nil), errGeneric, errGeneric},
		// HTTP client error without "errors" field in response
		{xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusInternalServerError, nil), nil, errFromStatusCode},
	}

	for _, test := range tests {
		httpClient := &httputil.MockHTTPClienter{}
		httpClient.
			On("Do", mock.Anything).
			Return(test.httpClientResponse, test.httpClientError)

		client, err := NewClientWithHTTPClienter(idmBaseURL, idmUserName, idmPassword, httpClient)
		s.NoError(err)

		// when
		id, err := client.CreateTeamMember(test.email, test.password, test.firstName, test.lastName)

		// then
		if test.expectedError == nil {
			require.Nil(s.T(), err)
			require.NotEmpty(s.T(), id)
		} else {
			require.EqualError(s.T(), err, test.expectedError.Error())
			require.Empty(s.T(), id)
		}
	}
}

func (s *clientTestSuite) TestUpdateManagedUser() {
	// given
	tests := []struct {
		managedUserID      string
		email              string
		password           string
		firstName          string
		lastName           string
		httpClientResponse *http.Response
		httpClientError    error
		expectedError      error
	}{
		// success with all fields changed
		{"1", xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusOK, nil), nil, nil},
		// success with nothing to change
		{"1", "", "", "", "", testutil.MarshalHTTPResponse(s.T(), http.StatusOK, nil), nil, nil},
		// tests that change a single field
		{"1", xEmail, "", "", "", testutil.MarshalHTTPResponse(s.T(), http.StatusOK, nil), nil, nil},
		{"1", "", xPassword, "", "", testutil.MarshalHTTPResponse(s.T(), http.StatusOK, nil), nil, nil},
		{"1", "", "", xFirstName, "", testutil.MarshalHTTPResponse(s.T(), http.StatusOK, nil), nil, nil},
		{"1", "", "", "", xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusOK, nil), nil, nil},
		// ID required
		{"", xEmail, xPassword, xFirstName, xLastName, nil, nil, ErrIDRequired},
		// team member not found
		{"1", xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusNotFound, nil), nil, ErrTeamMemberNotFound},
		// IDM authentication failed
		{"1", xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusUnauthorized, nil), nil, ErrIDMAuthenticationFailed},
		// HTTP client error with "errors" field in response
		{"1", xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusInternalServerError, nil), errGeneric, errGeneric},
		// HTTP client error without "errors" field in response
		{"1", xEmail, xPassword, xFirstName, xLastName, testutil.MarshalHTTPResponse(s.T(), http.StatusInternalServerError, nil), nil, errFromStatusCode},
	}

	for _, test := range tests {
		httpClient := &httputil.MockHTTPClienter{}
		httpClient.
			On("Do", mock.Anything).
			Return(test.httpClientResponse, test.httpClientError)

		client, err := NewClientWithHTTPClienter(idmBaseURL, idmUserName, idmPassword, httpClient)
		s.NoError(err)

		// when
		err = client.UpdateTeamMember(test.managedUserID, test.email, test.password, test.firstName, test.lastName)

		// then
		if test.expectedError == nil {
			require.Nil(s.T(), err)
		} else {
			require.EqualError(s.T(), err, test.expectedError.Error())
		}
	}
}
