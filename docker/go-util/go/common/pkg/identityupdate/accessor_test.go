package identityupdate

import (
	"fmt"

	_ "github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/logging"

	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewAccessor(t *testing.T) {
	tests := []struct {
		name     string
		accessor string
		want     *YamlAccessor
		wantErr  bool
	}{
		{
			name:     "Test valid accessor",
			accessor: "a.b.c",
			want: &YamlAccessor{
				original: []string{"a", "b", "c"},
				state:    []string{"a", "b", "c"},
			},
			wantErr: false,
		},
		{
			name:     "Test invalid empty accessor",
			accessor: "a.b.",
			want:     nil,
			wantErr:  true,
		},
		{
			name:     "Test invalid empty whole string",
			accessor: "",
			want:     nil,
			wantErr:  true,
		},
		// TODO: Implement logic
		//{
		//	name:     "Test invalid indexing accessor",
		//	accessor: "a[0]",
		//	want:     nil,
		//	wantErr:  true,
		//},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := NewAccessor(tt.accessor)

			if (err != nil) != tt.wantErr {
				t.Errorf("NewAccessor() error = %v, wantErr %v", err, tt.wantErr)
			}

			if tt.want == nil {
				assert.Equal(t, tt.want, got)
			} else if got != nil {
				assert.Equal(t, *tt.want, *got)
			} else {
				t.Fatalf("NewAccessor() want = %v, got %v", tt.want, got)
			}
		})
	}
}

func TestYamlAccessor_find(t *testing.T) {
	type args struct {
		fileContent string
		accessor    []string
	}
	tests := []struct {
		name    string
		args    args
		want    string
		wantErr bool
	}{
		{
			name: "Test find successfully",
			args: args{
				fileContent: `
a:
  b:
    c: blit
`,
				accessor: []string{"a", "b", "c"},
			},
			want:    "blit",
			wantErr: false,
		},
		{
			name: "Test failure if it is found, but its a number",
			args: args{
				fileContent: `
a:
  b:
    c: 3
`,
				accessor: []string{"a", "b", "c"},
			},
			want:    "",
			wantErr: true,
		},
		{
			name: "Test failure if it is found, but its a map",
			args: args{
				fileContent: `
a:
  b:
    c: 3
`,
				accessor: []string{"a", "b", "c"},
			},
			want:    "",
			wantErr: true,
		},
		{
			name: "Test trying to find nonexistent thing fails",
			args: args{
				fileContent: `
a:
  b:
    c: blit
`,
				accessor: []string{"a", "z"},
			},
			want:    "",
			wantErr: true,
		},
		{
			name: "Test trying to find something inside a string fails",
			args: args{
				fileContent: `
a:
  b:
    c: blit
`,
				accessor: []string{"a", "b", "c", "d"},
			},
			want:    "",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(fmt.Sprintf("Test finding in map: %s", tt.name), func(t *testing.T) {
			unmarshaled, err := unmarshalYaml([]byte(tt.args.fileContent))
			if err != nil {
				t.Fatalf("Error unmarshaling yaml for test: %v", err)
			}

			y := YamlAccessor{
				state:    tt.args.accessor,
				original: tt.args.accessor,
			}

			got, err := y.findInMap(unmarshaled)
			if (err != nil) != tt.wantErr {
				t.Errorf("findInMap() error = %v, wantErr %v", err, tt.wantErr)
			}

			if got != "" {
				assert.Equal(t, tt.want, got)
			}
		})

		t.Run(fmt.Sprintf("Test finding in file: %s", tt.name), func(t *testing.T) {
			file := makeTempFileWithContents(t, "kglkglg", tt.args.fileContent)
			defer deleteFile(t, file)

			y := YamlAccessor{
				state:    tt.args.accessor,
				original: tt.args.accessor,
			}

			got, err := y.findInFile(file)
			if (err != nil) != tt.wantErr {
				t.Errorf("findInMap() error = %v, wantErr %v", err, tt.wantErr)
			}

			if got != "" {
				assert.Equal(t, tt.want, got)
			}
		})
	}
}
