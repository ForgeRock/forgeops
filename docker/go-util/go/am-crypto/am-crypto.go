package main

import (
	"bufio"
	"encoding/base64"
	"fmt"
	"log"
	"os"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/am"
)

func main() {
	if len(os.Args) < 2 || len(os.Args) > 3 {
		usage()
	}
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		switch os.Args[1] {
		case "encrypt":
			if len(os.Args) != 3 {
				usage()
			}
			var v am.Version
			switch os.Args[2] {
			case "aes":
				v = am.AesKeyWrapVersion
			case "des":
				v = am.Md5DesVersion
			default:
				usage()
			}
			amEncKey := os.Getenv("AM_ENCRYPTION_PWD")
			if amEncKey == "" {
				usage()
			}
			result, err := am.Encode(v, scanner.Bytes(), []byte(amEncKey))
			if err != nil {
				fmt.Fprintf(os.Stderr, "Encryption failed: %+v", err)
			} else {
				fmt.Println(base64.StdEncoding.EncodeToString(result))
			}
		case "hash":
			hash, err := am.SecureHash(scanner.Text())
			if err != nil {
				fmt.Fprintf(os.Stderr, "Hashing failed: %+v", err)
			} else {
				fmt.Println(hash)
			}
		default:
			usage()
		}
		scanner.Bytes()
	}

	if err := scanner.Err(); err != nil {
		log.Println(err)
	}
}

func usage() {
	println("Usage: am-crypto <encrypt|hash> [arguments...]")
	println("  encrypt    Encrypt the lines passed on STDIN. The environment variable")
	println("             AM_ENCRYPTION_PWD must be set. An additional argument of ")
	println("             version <aes|des> must be passed\n")
	println("  hash       Create an AM-compatible (SSHA-512) hash of each line on STDIN")
	os.Exit(0)
}
