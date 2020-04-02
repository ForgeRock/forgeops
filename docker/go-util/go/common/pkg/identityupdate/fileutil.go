package identityupdate

import (
	"errors"
	"io/ioutil"
	"os"

	"gopkg.in/src-d/go-billy.v4"
)

// Rewind a file to the beginning
func rewindFile(file billy.File) error {
	_, err := file.Seek(0, 0)
	if err != nil {
		err := errors.New("error seeking in file")
		return err
	}
	return nil
}

// Get handle for a file from the given filesystem - could be a fake filesytem
func GetFileIn(fs billy.Filesystem, location string) (billy.File, error) {
	if _, err := fs.Stat(location); os.IsNotExist(err) {
		log.WithError(err).Errorf("file '%s' does not exist", location)
		return nil, err
	}

	asFile, err := fs.OpenFile(location, os.O_RDWR, 0644)

	if err != nil {
		log.WithError(err).Error("Error opening file")
		return nil, err
	}

	return asFile, nil
}

func getFileContent(file billy.File) (string, error) {
	if file == nil {
		err := errors.New("nil file given")
		return "", err
	}

	err := rewindFile(file)
	if err != nil {
		return "", err
	}

	content, err := ioutil.ReadAll(file)
	if err != nil {
		log.WithError(err).Error("error reading input file")
		return "", err
	}

	return string(content), nil
}
