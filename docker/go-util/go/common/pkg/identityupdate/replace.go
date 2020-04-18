package identityupdate

import (
	"errors"
	"regexp"

	"gopkg.in/src-d/go-billy.v4"

	_ "github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/logging"
)

// find and replace all occurences of oldValue with newValue in the given file
// Returns a tuple of (replaced,error). replaced might not be empty even if there is an error, so don't rely on it for error checking!
func ReplaceValueInFile(file billy.File, oldValue string, newValue string) (string, error) {
	content, err := getFileContent(file)
	if err != nil {
		return "", err
	}

	replaced, err := findReplaceInString(content, oldValue, newValue)
	if err != nil {
		return replaced, err
	}

	err = rewindFile(file)
	if err != nil {
		return replaced, err
	}

	err = file.Truncate(int64(len(replaced)))
	if err != nil {
		log.WithError(err).Error("Error truncating file to fit new input")
		return replaced, err
	}

	_, err = file.Write([]byte(replaced))
	if err != nil {
		log.WithError(err).Error("Error writing file replacement")
		return replaced, err
	}

	return replaced, nil
}

// Finds all match groups for given regex in file
func FindValuesInFile(file billy.File, value string) ([]string, error) {
	if value == "" {
		err := errors.New("empty value given for search string")
		return nil, err
	}

	content, err := getFileContent(file)
	if err != nil {
		return nil, err
	}

	return findValuesInString(content, value)
}

func findValuesInString(content string, value string) ([]string, error) {
	re, err := regexp.Compile(value)
	if err != nil {
		log.WithError(err).Error("Error compiling regex")
		return nil, err
	}

	result := re.FindStringSubmatch(content)

	if len(result) == 0 {
		return nil, errors.New("no match found for regex")
	}

	return result, nil
}

// find and replace all occurences of oldValue with newValue in the given string and return it
// Logs a warning if nothing happened
func findReplaceInString(content string, oldValue string, newValue string) (string, error) {
	if oldValue == "" {
		err := errors.New("empty value given for oldValue")
		return "", err
	}

	//replaced := strings.ReplaceAll(content, oldValue, newValue)
	re, err := regexp.Compile(oldValue)
	if err != nil {
		log.WithError(err).Error("Error compiling regex")
		return "", err
	}
	replaced := re.ReplaceAllString(content, newValue)

	log.Debugf("'%s' => '%s'", content, replaced)

	if replaced == content {
		log.Warnf("No replacement happened for '%s'=>'%s'", oldValue, newValue)
	}

	return replaced, nil
}
