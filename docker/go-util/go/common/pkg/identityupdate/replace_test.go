package identityupdate

import (
	"fmt"
	"io/ioutil"
	"os"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"gopkg.in/src-d/go-billy.v4"
)

func TestMain(m *testing.M) {
	logrus.SetLevel(logrus.DebugLevel)
	m.Run()
}

func Test_replaceYamlValue(t *testing.T) {
	type args struct {
		fileContent string
		oldValue    string
		newValue    string
	}
	tests := []struct {
		name    string
		args    args
		want    string
		wantErr bool
	}{
		// TODO: Some way of checking that it warns user
		{
			name: "Test no replacement has no effect",
			args: args{
				fileContent: "abc123",
				oldValue:    "h",
				newValue:    "b",
			},
			want:    "abc123",
			wantErr: false,
		},
		{
			name: "Test replace simple",
			args: args{
				fileContent: "abc123",
				oldValue:    "a",
				newValue:    "z",
			},
			want:    "zbc123",
			wantErr: false,
		},
		{
			name: "Test replace regex",
			args: args{
				fileContent: "abc123",
				oldValue:    "[abc]",
				newValue:    "z",
			},
			want:    "zzz123",
			wantErr: false,
		},
		{
			name: "Test replace Big realistic thing",
			args: args{
				fileContent: `
version: "1.0"
stages:
  - git-clone
  - analysis
  - am
  - amster
  - forgeops-secrets
  - idm
  - ctsstore
  - userstore
  - common
  - backup-datastore
  - org-api
  - org-gateway
  - org-ui
  - org-worker
  - org-engine-binary
  - org-engine
mode: parallel
steps:
  #
  # git-clone steps
  #
  CloneSaasGitRepo:
    title: "Clone saas mono-repo"
    stage: "git-clone"
    type: git-clone
    repo: "${{CF_REPO_OWNER}}/${{CF_REPO_NAME}}"
    revision: "${{CF_REVISION}}"
    git: github-fr-saas-codefresh
  CloneForgeopsGitRepo:
    title: "Clone forgeops repo"
    stage: "git-clone"
    type: git-clone
    repo: "https://stash.forgerock.org/scm/cloud/forgeops.git"
    # WARNING: revision should not be set manually.
    # To "upgrade" to a later release, use the script: /devtools/upgrade_identity_stack.sh
    revision: "5693f4bf905ef10291081c28ca3fd4e133be5cb3"
    git: github-fr-saas-codefresh
`,
				oldValue: "5693f4bf905ef10291081c28ca3fd4e133be5cb3",
				newValue: "glop",
			},
			want: `
version: "1.0"
stages:
  - git-clone
  - analysis
  - am
  - amster
  - forgeops-secrets
  - idm
  - ctsstore
  - userstore
  - common
  - backup-datastore
  - org-api
  - org-gateway
  - org-ui
  - org-worker
  - org-engine-binary
  - org-engine
mode: parallel
steps:
  #
  # git-clone steps
  #
  CloneSaasGitRepo:
    title: "Clone saas mono-repo"
    stage: "git-clone"
    type: git-clone
    repo: "${{CF_REPO_OWNER}}/${{CF_REPO_NAME}}"
    revision: "${{CF_REVISION}}"
    git: github-fr-saas-codefresh
  CloneForgeopsGitRepo:
    title: "Clone forgeops repo"
    stage: "git-clone"
    type: git-clone
    repo: "https://stash.forgerock.org/scm/cloud/forgeops.git"
    # WARNING: revision should not be set manually.
    # To "upgrade" to a later release, use the script: /devtools/upgrade_identity_stack.sh
    revision: "glop"
    git: github-fr-saas-codefresh
`,
			wantErr: false,
		},
		{
			name: "Test replace dockerfile",
			args: args{
				fileContent: `
FROM gcr.io/forgerock-io/am:7.0.0-c747a9248be37a3164e63f4d41466ff740e9f502
`,
				oldValue: "c747a9248be37a3164e63f4d41466ff740e9f502",
				newValue: "glop",
			},
			want: `
FROM gcr.io/forgerock-io/am:7.0.0-glop
`,
			wantErr: false,
		},
		{
			name: "Test replace dockerfile with regex",
			args: args{
				fileContent: `
FROM gcr.io/forgerock-io/am:7.0.0-c747a9248be37a3164e63f4d41466ff740e9f502
`,
				oldValue: "FROM .*",
				newValue: "uii4",
			},
			want: `
uii4
`,
			wantErr: false,
		},
		{
			name: "Errors on invalid input",
			args: args{
				fileContent: "abc123",
				oldValue:    "",
				newValue:    "z",
			},
			want:    "",
			wantErr: true,
		},
		{
			name: "Errors on invalid regex",
			args: args{
				fileContent: "abc123",
				oldValue:    "[abc",
				newValue:    "z",
			},
			want:    "",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(fmt.Sprintf("Replacing string directly: %s", tt.name), func(t *testing.T) {
			got, err := findReplaceInString(tt.args.fileContent, tt.args.oldValue, tt.args.newValue)
			if (err != nil) != tt.wantErr {
				t.Errorf("replaceValueInFile() error = %v, wantErr %v", err, tt.wantErr)
			}

			assert.Equal(t, tt.want, got)
		})

		t.Run(fmt.Sprintf("Replacing string in file: %s", tt.name), func(t *testing.T) {
			file := makeTempFileWithContents(t, "kglkglg", tt.args.fileContent)
			defer deleteFile(t, file)

			got, err := ReplaceValueInFile(file, tt.args.oldValue, tt.args.newValue)
			if (err != nil) != tt.wantErr {
				t.Errorf("replaceValueInFile() error = %v, wantErr %v", err, tt.wantErr)
			}

			assert.Equal(t, tt.want, got)

			if !tt.wantErr {
				err = rewindFile(file)
				if err != nil {
					t.Fatal("Error rewinding file in test")
				}
				content, err := ioutil.ReadAll(file)
				if err != nil {
					t.Fatal("Error reading tempfile for test")
				}

				assert.Equal(t, tt.want, string(content))
			}
		})
	}
}

func TestFindValuesInFile(t *testing.T) {
	type args struct {
		fileContent string
		value       string
	}
	tests := []struct {
		name    string
		args    args
		want    []string
		wantErr bool
	}{
		{
			name: "Test find multiple",
			args: args{
				fileContent: "abc123",
				value:       "[0-9]{3}",
			},
			want:    []string{"123"},
			wantErr: false,
		},
		{
			name: "Test find simple thing",
			args: args{
				fileContent: "abc123",
				value:       "[0-9]",
			},
			want:    []string{"1"},
			wantErr: false,
		},
		{
			name: "Test find with group",
			args: args{
				fileContent: "abc123",
				value:       "(?P<first>[0-9])[0-9]",
			},
			// First element is the whole match
			// Second element is the group
			want:    []string{"12", "1"},
			wantErr: false,
		},
		{
			name: "Test find with group",
			args: args{
				fileContent: "abc123",
				value:       "(?P<first>[0-9])(?P<second>[0-9])[0-9]",
			},
			// First element is the whole match
			// Second element is the first group
			// Third element is the second group
			want:    []string{"123", "1", "2"},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(fmt.Sprintf("Replacing string directly: %s", tt.name), func(t *testing.T) {
			got, err := findValuesInString(tt.args.fileContent, tt.args.value)
			if (err != nil) != tt.wantErr {
				t.Errorf("replaceValueInFile() error = %v, wantErr %v", err, tt.wantErr)
			}

			assert.Equal(t, tt.want, got)
		})

		t.Run(fmt.Sprintf("Replacing string in file: %s", tt.name), func(t *testing.T) {
			file := makeTempFileWithContents(t, "kglkglg", tt.args.fileContent)
			defer deleteFile(t, file)

			got, err := FindValuesInFile(file, tt.args.value)
			if (err != nil) != tt.wantErr {
				t.Errorf("replaceValueInFile() error = %v, wantErr %v", err, tt.wantErr)
			}

			assert.Equal(t, tt.want, got)
		})
	}
}

// Make a temporary file in the test memory filesystem.
// Make sure to call 'defer deletefile' after
func makeTempFileWithContents(t *testing.T, prefix string, content string) billy.File {
	file, err := testFs.TempFile("", prefix)
	if err != nil {
		t.Fatal("Error creating temp file for test")
	}

	_, err = file.Write([]byte(content))
	if err != nil {
		t.Fatal("Error writing to temp file in test")
	}

	return file
}

// Close and delete a file. Does not error out, only warns
func deleteFile(t *testing.T, file billy.File) {
	err := file.Close()
	if err != nil {
		log.Warn("Error closing temp file")
	}
	err = os.Remove(file.Name())
	if err != nil {
		log.Warn("Error deleting temp file after test")
	}
}
