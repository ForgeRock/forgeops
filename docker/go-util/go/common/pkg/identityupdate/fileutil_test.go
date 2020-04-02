package identityupdate

import (
	"math/rand"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"gopkg.in/src-d/go-billy.v4/memfs"
)

// A test memory filesystem
var testFs = memfs.New()

func TestGetFile_good(t *testing.T) {
	file := makeTempFileWithContents(t, "kglkglg", "")
	defer deleteFile(t, file)

	got, err := GetFileIn(testFs, file.Name())

	if assert.NoError(t, err) {
		if assert.NotNil(t, got) {
			assert.Equal(t, file.Name(), got.Name())
		}
	}
}

func TestGetFile_bad(t *testing.T) {
	got, err := GetFileIn(testFs, filepath.Join("/tmp", randomString(t)))

	assert.Error(t, err)
	assert.Nil(t, got)
}

func randomString(t *testing.T) string {
	var letters = []rune("abcdef0123456789")

	var output []rune

	for i := 0; i < 40; i++ {
		output = append(output, letters[rand.Int31n(int32(len(letters)))])
	}

	return string(output)
}
