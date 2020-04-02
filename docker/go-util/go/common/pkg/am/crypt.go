package am

import (
	"bytes"
	"crypto"
	"crypto/aes"
	"crypto/cipher"
	"crypto/des"
	"crypto/md5"
	"crypto/rand"
	"fmt"

	keywrap "github.com/NickBall/go-aes-key-wrap"
	"golang.org/x/crypto/pbkdf2"
)

const (
	aesBlockSize      = 8
	Md5DesVersion     = 1
	AesKeyWrapVersion = 2
	keyGenAlgIndex    = 2
	encAlgIndex       = 2
	md5Iterations     = 5
)

var fixedSalt = []byte{0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01}

type Version int

//
// The Encode function replicates the behaviour of the AM Crypt#encode(byte[], AMEncryption)
// method.
//
// The result of this function is the AES-Wrap encrypted cleartext, base64-encoded, using
// the provided symmetric encryption key.
//
// For full details of the implementation, see the AM class
// org.forgerock.openam.shared.security.crypto.AESWrapEncryption
//
func Encode(v Version, cleartext []byte, amEncKey []byte) ([]byte, error) {
	switch v {
	case Md5DesVersion:
		return md5DesEncode(cleartext, amEncKey)
	case AesKeyWrapVersion:
		salt := make([]byte, 16)
		_, err := rand.Read(salt)
		if err != nil {
			return nil, fmt.Errorf("could not generate randomness for Crypt.encode: %w", err)
		}
		return aesEncode(cleartext, amEncKey, salt)
	}
	return nil, fmt.Errorf("unknown version: %v", v)
}

func md5DesEncode(cleartext []byte, password []byte) ([]byte, error) {
	padNum := byte(8 - len(cleartext)%8)
	for i := byte(0); i < padNum; i++ {
		cleartext = append(cleartext, padNum)
	}
	key, iv := md5DeriveKey(password, md5Iterations)
	block, err := des.NewCipher(key)
	if err != nil {
		return nil, err
	}
	encrypter := cipher.NewCBCEncrypter(block, iv)
	result := make([]byte, len(cleartext))
	encrypter.CryptBlocks(result, cleartext)
	formatted := []byte{byte(Md5DesVersion), byte(keyGenAlgIndex), byte(encAlgIndex)}
	formatted = append(formatted, iv...)
	formatted = append(formatted, result...)
	return formatted, nil
}

func md5DeriveKey(password []byte, count int) ([]byte, []byte) {
	md5Input := password[:]
	md5Input = append(md5Input, fixedSalt...)
	key := md5.Sum(md5Input)
	for i := 0; i < count-1; i++ {
		key = md5.Sum(key[:])
	}
	return key[:8], key[8:]
}

func aesEncode(cleartext []byte, amEncKey []byte, salt []byte) ([]byte, error) {
	pbekey := pbkdf2.Key(amEncKey, salt, 10000, 16, crypto.SHA1.New)
	cipher, err := aes.NewCipher(pbekey)
	if err != nil {
		return nil, fmt.Errorf("invalid cipher key for encode: %w", err)
	}
	wrapped, err := keywrap.Wrap(cipher, pkcs5Pad(cleartext))
	if err != nil {
		return nil, fmt.Errorf("could not keywrap: %w", err)
	}
	formatted := []byte{byte(AesKeyWrapVersion), byte(len(salt))}
	formatted = append(formatted, salt...)
	formatted = append(formatted, wrapped...)
	return formatted, err
}

func pkcs5Pad(src []byte) []byte {
	srcLen := len(src)
	padLen := aesBlockSize - (srcLen % aesBlockSize)
	padText := bytes.Repeat([]byte{byte(padLen)}, padLen)
	return append(src, padText...)
}
