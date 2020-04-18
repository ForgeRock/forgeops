package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

func main() {
	file := os.Args[1]
	jv := map[string]interface{}{}
	f, err := os.Open(file)
	defer f.Close()
	if err != nil {
		fmt.Printf("Could not open file %s: %+v\n", file, err)
		os.Exit(1)
	}
	if err = json.NewDecoder(f).Decode(&jv); err != nil {
		fmt.Printf("Could not read JSON from file %s: %+v\n", file, err)
		os.Exit(1)
	}
	deleteEncrypted(&jv)

	f.Close()
	f, err = os.Create(file)
	defer f.Close()
	if err != nil {
		fmt.Printf("Could not open file for writing %s: %+v\n", file, err)
		os.Exit(1)
	}
	writer := bufio.NewWriter(f)
	if err = json.NewEncoder(writer).Encode(&jv); err != nil {
		fmt.Printf("Could not write JSON to file %s: %+v\n", file, err)
		os.Exit(1)
	}
	if err = writer.Flush(); err != nil {
		fmt.Printf("Could not flush JSON to file %s: %+v\n", file, err)
		os.Exit(1)
	}
}

func deleteEncrypted(jv *map[string]interface{}) {
	for key, value := range *jv {
		if strings.HasSuffix(key, "-encrypted") {
			delete(*jv, key)
		}
		if v, ok := value.(map[string]interface{}); ok {
			deleteEncrypted(&v)
		}
	}
}
