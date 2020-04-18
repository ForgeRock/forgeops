package random

import (
	"crypto/rand"
	"math/big"
)

type RandomIntegerFunc func(n int) int

const alphanumericBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

// AlphanumericStringOfLength generates a random alphanumeric string of a given
// length
func AlphanumericStringOfLength(n int, rFn RandomIntegerFunc) string {
	b := make([]byte, n)
	for i := range b {
		b[i] = alphanumericBytes[rFn(len(alphanumericBytes))]
	}

	return string(b)
}

// CryptoRandomIntegerFunc generates a random number using crypto/rand
func CryptoRandomIntegerFunc(n int) int {
	i, err := rand.Int(rand.Reader, big.NewInt(int64(n)))
	if err != nil {
		return 0
	}

	return int(i.Int64())
}
