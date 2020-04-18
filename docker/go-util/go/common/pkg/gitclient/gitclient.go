package gitclient

import (
	"os"
	"time"

	"golang.org/x/crypto/openpgp"
	"gopkg.in/src-d/go-git.v4/config"
	"gopkg.in/src-d/go-git.v4/plumbing"

	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing/object"
	"gopkg.in/src-d/go-git.v4/plumbing/transport/http"
)

// Config holds parameters for a Client.
type Config struct {
	GitURL      string
	DestDir     string
	Username    string
	Email       string
	AccessToken string
	SignKey     *openpgp.Entity
}

// Client represents a simple git client.
type Client struct {
	config Config
	repo   *git.Repository
}

const lastCommitDepth = 1

var allRefs = []config.RefSpec{
	"refs/*:refs/*",
	"HEAD:refs/heads/HEAD",
}

// Clone initializes a git repository and returns a new Client.
func Clone(config Config) (*Client, error) {
	repo, err := git.PlainClone(config.DestDir, false, &git.CloneOptions{
		Depth: lastCommitDepth,
		Auth: &http.BasicAuth{
			Username: config.Username,
			Password: config.AccessToken,
		},
		URL:      config.GitURL,
		Progress: os.Stdout,
	})
	if err != nil {
		return nil, err
	}

	// Fetch all refs to allow easy calls to Checkout.
	err = repo.Fetch(&git.FetchOptions{
		RefSpecs: allRefs,
		Depth:    lastCommitDepth,
		Auth: &http.BasicAuth{
			Username: config.Username,
			Password: config.AccessToken,
		},
	})
	if err != nil {
		return nil, err
	}

	return &Client{
		config: config,
		repo:   repo,
	}, nil
}

// Checkout switches to a new branch.
// Local changes will be lost.
func (client *Client) Checkout(branch string) error {
	worktree, err := client.repo.Worktree()
	if err != nil {
		return err
	}

	return worktree.Checkout(&git.CheckoutOptions{
		Branch: plumbing.NewBranchReferenceName(branch),
		Force:  true,
	})
}

// Add stages files at the specified path.
func (client *Client) Add(path string) error {
	worktree, err := client.repo.Worktree()
	if err != nil {
		return err
	}

	_, err = worktree.Add(path)
	return err
}

// Commit adds staged files to the local repository.
// If SignKey is nil, commits will not be signed.
func (client *Client) Commit(message string) error {
	worktree, err := client.repo.Worktree()
	if err != nil {
		return err
	}

	_, err = worktree.Commit(message, &git.CommitOptions{
		Author: &object.Signature{
			Name:  client.config.Username,
			Email: client.config.Email,
			When:  time.Now(),
		},
		SignKey: client.config.SignKey,
	})
	return err
}

// Push sends local commits to the remote repository.
func (client *Client) Push() error {
	return client.repo.Push(&git.PushOptions{
		Auth: &http.BasicAuth{
			Username: client.config.Username,
			Password: client.config.AccessToken,
		},
	})
}
