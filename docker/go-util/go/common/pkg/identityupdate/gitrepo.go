package identityupdate

import (
	"errors"
	"fmt"

	"gopkg.in/src-d/go-billy.v4/memfs"
	"gopkg.in/src-d/go-git.v4/plumbing"
	"gopkg.in/src-d/go-git.v4/plumbing/transport"

	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/storage/memory"
)

func ShallowCloneRepo(gitUrl string, ref string, auth transport.AuthMethod) (*git.Repository, error) {
	referenceName := plumbing.ReferenceName(fmt.Sprintf("refs/heads/%s", ref))

	cloneOptions := git.CloneOptions{
		URL:               gitUrl,
		Auth:              auth,
		ReferenceName:     referenceName,
		SingleBranch:      true,
		NoCheckout:        false,
		Depth:             1,
		RecurseSubmodules: 0,
	}

	storage := memory.NewStorage()

	log.WithField("url", gitUrl).Info("Cloning repo")

	repo, err := git.Clone(storage, memfs.New(), &cloneOptions)
	if err != nil {
		log.WithField("url", gitUrl).WithError(err).Error("Error cloning repo")
		return nil, err
	}

	return repo, nil
}

func GetLatestHash(repo *git.Repository) (string, error) {
	ref, err := repo.Head()
	if err != nil {
		log.WithError(err).Fatal("Error getting head from repo")
		return "", err
	}
	if ref == nil {
		return "", errors.New("ref was nil even though there was no error")
	}

	hash := ref.Hash().String()

	return hash, nil
}
