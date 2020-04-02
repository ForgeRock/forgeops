package identityupdate

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_unmarshalYaml(t *testing.T) {
	tests := []struct {
		name    string
		content string
		want    map[interface{}]interface{}
		wantErr bool
	}{
		{
			name: "unmarshal simple mapping",
			content: `
a: b
`,
			want: map[interface{}]interface{}{
				"a": "b",
			},
			wantErr: false,
		},
		{
			name: "unmarshal with document thing",
			content: `
---
a: b
`,
			want: map[interface{}]interface{}{
				"a": "b",
			},
			wantErr: false,
		},
		{
			name: "error on invalid yaml",
			content: `
fffff/
`,
			want:    nil,
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := unmarshalYaml([]byte(tt.content))

			if (err != nil) != tt.wantErr {
				t.Errorf("unmarshalYaml() error = %v, wantErr %v", err, tt.wantErr)
			}

			assert.Equal(t, tt.want, got)
		})
	}
}
