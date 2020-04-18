package httputil

import "testing"

func TestParseEntityID(t *testing.T) {
	type args struct {
		src       string
		defaultID int64
	}
	tests := []struct {
		name    string
		args    args
		want    int64
		wantErr bool
	}{
		{"should parse", args{src: "10", defaultID: 0}, 10, false},
		{"shouldn't parse", args{src: "", defaultID: 0}, 0, false},
		{"should parse with error", args{src: "-1", defaultID: 0}, -1, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ParseEntityID(tt.args.src, tt.args.defaultID)
			if (err != nil) != tt.wantErr {
				t.Errorf("ParseEntityID() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if got != tt.want {
				t.Errorf("ParseEntityID() = %v, want %v", got, tt.want)
			}
		})
	}
}
