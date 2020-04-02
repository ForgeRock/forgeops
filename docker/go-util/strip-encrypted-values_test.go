package main

import (
	"reflect"
	"testing"
)

func Test_deleteEncrypted(t *testing.T) {
	hasEncrypted := map[string]interface{}{"key": "value", "key-encrypted": "enc-value"}
	encryptedStripped := map[string]interface{}{"key": "value"}
	noEncrypted := map[string]interface{}{"key": "value", "notencrypted": "enc-value", "o": encryptedStripped}
	tests := []struct {
		name     string
		jv       map[string]interface{}
		expected map[string]interface{}
	}{
		{"simple", hasEncrypted, encryptedStripped},
		{"nested", map[string]interface{}{"o": hasEncrypted}, map[string]interface{}{"o": encryptedStripped}},
		{"unmodified", noEncrypted, noEncrypted},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			deleteEncrypted(&tt.jv)
			if !reflect.DeepEqual(tt.jv, tt.expected) {
				t.Errorf("Not equal: %v - expected %v", tt.jv, tt.expected)
			}
		})
	}
}
