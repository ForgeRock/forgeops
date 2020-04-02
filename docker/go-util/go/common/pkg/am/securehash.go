package am

import (
	"crypto/rand"
	"crypto/sha512"
	"encoding/base64"
	"fmt"
)

const saltSize = 20

var errEmptyString = fmt.Errorf("input string must not be empty")

// SecureHash applies the hashing algorithm required by AM 6 to set
// a custom amAdmin password in an Amster JSON file. We should NOT use this
// anywhere else, because it is a proprietary format chosen by AM, which
// may not be needed in future releases.
//
// For reference, see the following Java function in the AM codebase:
//
// org.forgerock.openam.shared.security.crypto.Hashes.secureHash(string)
func SecureHash(cleartext string) (string, error) {
	if len(cleartext) == 0 {
		return "", errEmptyString
	}

	// random salt
	saltBytes := make([]byte, saltSize)
	_, err := rand.Read(saltBytes)
	if err != nil {
		return "", err
	}

	return apply(cleartext, saltBytes)
}

func apply(cleartext string, saltBytes []byte) (string, error) {
	cleartextBytes := []byte(cleartext)

	// sha512(salt|text)
	saltAndTextBytes := append(saltBytes, cleartextBytes...)
	digestBytes := sha512.Sum512(saltAndTextBytes)

	// base64( saltSize | salt | sha512(salt|text) )
	finalBytes := append(append([]byte{saltSize}, saltBytes...), digestBytes[:]...)
	b64 := base64.StdEncoding.EncodeToString([]byte(finalBytes[:]))

	// add prefix string
	return "{SSHA-512}" + b64, nil
}
