package am

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/stretchr/testify/suite"
)

type securehashTestSuite struct {
	suite.Suite
}

func TestSecureHashSuite(t *testing.T) {
	suite.Run(t, &securehashTestSuite{})
}

func (s *securehashTestSuite) TestWellKnownResult() {
	// given (a value generated with the original Java code)
	const expectedResult = "{SSHA-512}FAAAAAAAAAAAAAAAAAAAAAAAAAAAjSSqRIRQ0t41hi" +
		"d6CvguVVR/XChxJUw1jpU8+My3/X0XiwXWz/swJxDAwmBl05CoAceOGj3MW2SKeIm/aqzHdg=="

	// all salt bytes are zero in this test
	saltBytes := make([]byte, saltSize)

	// when
	actualResult, err := apply("forgerock", saltBytes)

	// then
	require.NoError(s.T(), err)
	require.Equal(s.T(), expectedResult, actualResult)
}

func (s *securehashTestSuite) TestEmptyString() {
	// given / when
	result, err := SecureHash("")

	// then
	require.EqualError(s.T(), err, errEmptyString.Error())
	require.Empty(s.T(), result)
}

func (s *securehashTestSuite) TestSecureHash() {
	// given
	const cleartext = "super secret"

	// when
	result1, err := SecureHash(cleartext)
	result2, _ := SecureHash(cleartext)

	// then
	require.NoError(s.T(), err)
	require.NotEmpty(s.T(), result1)
	require.NotEqual(s.T(), result1, result2)
	require.Equal(s.T(), len(result1), len(result2))
}
