package identityupdate

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"gopkg.in/src-d/go-billy.v4"
	"gopkg.in/src-d/go-billy.v4/memfs"
	"gopkg.in/src-d/go-git.v4"
)

func TestUpgradeSpec_getLocalFile(t *testing.T) {
	tests := []struct {
		name         string
		testfileName string
		wantErr      bool
	}{
		{
			name:         "test file exists",
			testfileName: "dfg",
			wantErr:      false,
		},
		{
			name:         "test file in folder exists",
			testfileName: "dfg/gfd/asdf/f44",
			wantErr:      false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			newFs := memfs.New()

			s := hashUpdate{
				saasFs: newFs,
			}

			err := newFs.MkdirAll(filepath.Dir(tt.testfileName), os.ModeDir)
			if err != nil {
				t.Fatalf("Error creating fake directory: %s", err)
			}

			file, err := newFs.Create(tt.testfileName)
			if err != nil {
				t.Fatalf("Error creating test file: %s", err)
			}
			defer deleteFile(t, file)

			got, err := s.getLocalFile(tt.testfileName)

			assert.NoError(t, err)
			assert.NotNil(t, got)
		})
	}
}

func TestUpgradeSpec_updateDockerfile(t *testing.T) {
	d := dockerfileReplacementSpec{
		productName:           "testproduct",
		forgeopsProductFolder: "testproductfolder",
		localDockerPath:       "dockerfiles/testproduct.Dockerfile",
	}
	s := hashUpdate{
		saasFs: testFs,
		forgeopsTree: &git.Worktree{
			Filesystem: testFs,
		},
	}

	// Prepare 'remote' files
	actualFolder := filepath.Join("docker/7.0", d.forgeopsProductFolder)
	err := testFs.MkdirAll(actualFolder, os.ModeDir)
	if err != nil {
		t.Fatal("Error creating dir for test")
	}
	forgeopsFile, err := testFs.Create(filepath.Join(actualFolder, "Dockerfile"))
	if err != nil {
		t.Fatal("Error creating file for test")
	}
	defer deleteFile(t, forgeopsFile)

	_, err = forgeopsFile.Write([]byte("FROM testrepo:testtag"))
	if err != nil {
		t.Fatal("Error writing to test file")
	}

	// Prepare 'local' files
	localFile, err := testFs.Create(d.localDockerPath)
	if err != nil {
		t.Fatal("Error creating file for test")
	}
	defer deleteFile(t, localFile)

	fileContent := fmt.Sprintf(`
FROM oldrepo:oldtag
LABEL com.forgerock.%s.tag=oldtag
`, d.productName)
	_, err = localFile.Write([]byte(fileContent))
	if err != nil {
		t.Fatal("Error writing to test file")
	}

	// Should not match
	matches, err := FindValuesInFile(localFile, "FROM testrepo:testtag")
	if err == nil || len(matches) > 0 {
		t.Fatal("Did not expect matches for regex")
	}

	// Rewind before running update
	forceRewind(t, localFile)
	forceRewind(t, forgeopsFile)

	err = s.updateDockerfile(d)

	assert.NoError(t, err)

	matches, err = FindValuesInFile(localFile, "FROM testrepo:testtag")
	assert.NoError(t, err)
	assert.Len(t, matches, 1, "Expected 1 match in file")
	matches, err = FindValuesInFile(localFile, fmt.Sprintf("LABEL com.forgerock.%s.tag=testtag", d.productName))
	assert.NoError(t, err)
	assert.Len(t, matches, 1, "Expected 1 match in file")
}

// Rewind a file and fail immediately if it doesn't work
func forceRewind(t *testing.T, file billy.File) {
	err := rewindFile(file)
	if err != nil {
		t.Fatal("Error rewinding test file")
	}
}
