package am

import (
	"encoding/base64"
	"reflect"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Replicate a test from AM to check we get the same value
func TestAesEncode(t *testing.T) {
	amTestCleartext := "A test message to be encrypted"
	amTestEncKey := "password"
	amTestSalt, _ := base64.StdEncoding.DecodeString("ANQ7kB2uSjlRzimzf32LRg==")
	amTestExpected, _ := base64.StdEncoding.DecodeString("AhAA1DuQHa5KOVHOKbN/fYtGe+KLLN5DbQbLo8w0EJHEum0EOd+hrF/moBOGvhvQSXO4CJrd1UnKyA==")
	got, err := aesEncode([]byte(amTestCleartext), []byte(amTestEncKey), amTestSalt)
	assert.NoError(t, err)
	assert.Equal(t, amTestExpected, got)
}

func TestMd5DesEncode(t *testing.T) {
	amTestCleartext := "A test message to be encrypted"
	amTestEncKey := "password"
	amTestExpected, _ := base64.StdEncoding.DecodeString("AQICv6c3Z1VfvgAtyLDM2OI72NmbGHybL2ERlEvoXM7eOjm0xW1l3ZzMpQ==")
	got, err := md5DesEncode([]byte(amTestCleartext), []byte(amTestEncKey))
	assert.NoError(t, err)
	assert.Equal(t, amTestExpected, got)
}

func TestPkcs5Pad(t *testing.T) {
	tests := []struct {
		name string
		src  []byte
		want []byte
	}{
		{
			"zero",
			[]byte{},
			[]byte{8, 8, 8, 8, 8, 8, 8, 8},
		},
		{
			"one",
			[]byte{1},
			[]byte{1, 7, 7, 7, 7, 7, 7, 7},
		},
		{
			"two",
			[]byte{1, 2},
			[]byte{1, 2, 6, 6, 6, 6, 6, 6},
		},
		{
			"three",
			[]byte{1, 2, 3},
			[]byte{1, 2, 3, 5, 5, 5, 5, 5},
		},
		{
			"four",
			[]byte{1, 2, 3, 4},
			[]byte{1, 2, 3, 4, 4, 4, 4, 4},
		},
		{
			"five",
			[]byte{1, 2, 3, 4, 5},
			[]byte{1, 2, 3, 4, 5, 3, 3, 3},
		},
		{
			"six",
			[]byte{1, 2, 3, 4, 5, 6},
			[]byte{1, 2, 3, 4, 5, 6, 2, 2},
		},
		{
			"seven",
			[]byte{1, 2, 3, 4, 5, 6, 7},
			[]byte{1, 2, 3, 4, 5, 6, 7, 1},
		},
		{
			"eight",
			[]byte{1, 2, 3, 4, 5, 6, 7, 8},
			[]byte{1, 2, 3, 4, 5, 6, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := pkcs5Pad(tt.src); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("pkcs5Pad() = %v, want %v", got, tt.want)
			}
		})
	}
}
