package identityupdate

import (
	"errors"
	"fmt"
	"path/filepath"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/logging"
	"gopkg.in/src-d/go-billy.v4"
	"gopkg.in/src-d/go-git.v4"
)

var log = logging.Record

const DefaultForgeopsGitBaseUrl = "https://stash.forgerock.org"
const DefaultForgeopsRepoPath = "scm/cloud/forgeops.git"

// Run update in the git repository contained in the filesystem
func DoUpdateOn(filesystem billy.Filesystem) error {
	repo, err := ShallowCloneRepo(fmt.Sprintf("%s/%s", DefaultForgeopsGitBaseUrl, DefaultForgeopsRepoPath), "stable", nil)
	if err != nil {
		log.Error("Fatal error cloning forgeops repo")
		return err
	}

	return DoUpdateOnWithRepo(filesystem, repo)
}

// Do an update with an already-cloned forgeops repo
func DoUpdateOnWithRepo(filesystem billy.Filesystem, repo *git.Repository) error {
	tree, err := repo.Worktree()
	if err != nil {
		log.WithError(err).Error("Error accessing local clone of forgeops")
		return err
	}

	update := hashUpdate{
		saasFs:       filesystem,
		forgeopsRepo: repo,
		forgeopsTree: tree,
	}

	return update.replaceAllHashReferences()
}

type hashUpdate struct {
	saasFs       billy.Filesystem
	forgeopsRepo *git.Repository
	// saves a few keystrokes, but also used for testing
	forgeopsTree *git.Worktree
}

func (u hashUpdate) replaceAllHashReferences() error {
	// Do codefresh replacement
	err := u.replaceCodefreshHash()
	if err != nil {
		log.WithError(err).Error("Fatal error replacing codefresh hash")
		return err
	}

	// Do dockerfile replacement
	err = u.replaceDockerfileHashes()
	if err != nil {
		log.WithError(err).Error("Fatal error replacing hashes in dockerfiles")
		return err
	}

	return nil
}

type dockerfileReplacementSpec struct {
	productName           string
	forgeopsProductFolder string
	localDockerPath       string
}

func (u hashUpdate) replaceDockerfileHashes() error {
	replacements := []dockerfileReplacementSpec{
		{
			productName:           "am",
			forgeopsProductFolder: "am",
			localDockerPath:       "services/forgecloud/default/am/am.Dockerfile",
		},
		{
			productName:           "ds",
			forgeopsProductFolder: "ds/idrepo",
			localDockerPath:       "services/forgecloud/default/userstore/Dockerfile",
		},
		{
			productName:           "ds",
			forgeopsProductFolder: "ds/idrepo",
			localDockerPath:       "services/forgecloud/default/ctsstore/Dockerfile",
		},
		{
			productName:           "ds",
			forgeopsProductFolder: "ds/idrepo",
			localDockerPath:       "services/forgecloud/default/ldif-importer/Dockerfile",
		},
		{
			productName:           "idm",
			forgeopsProductFolder: "idm",
			localDockerPath:       "services/forgecloud/default/idm/Dockerfile",
		},
	}

	var err error

	for _, d := range replacements {
		err = u.updateDockerfile(d)

		if err != nil {
			log.WithError(err).Error("error substituting new docker tags")
			return err
		}
	}

	return nil
}

func (u hashUpdate) updateDockerfile(d dockerfileReplacementSpec) error {
	localDockerFile, err := u.getLocalFile(d.localDockerPath)
	if err != nil {
		log.WithError(err).Error("Error opening dockerfile")
		return err
	}

	forgeopsDockerFile, err := u.getForgeopsFile(filepath.Join("docker/7.0", d.forgeopsProductFolder))
	if err != nil {
		return err
	}

	forgeopsFrom, err := FindValuesInFile(forgeopsDockerFile, "FROM (?P<repo>.*):(?P<tag>.*)")
	if err != nil {
		return err
	}
	if len(forgeopsFrom) != 3 {
		// We expect 3 elements - one for the whole thing, one for the repo, one for the tag
		return errors.New("did not match expected number of things in forgeops dockerfile")
	}

	newFrom := fmt.Sprintf("FROM %s:%s", forgeopsFrom[1], forgeopsFrom[2])

	_, err = ReplaceValueInFile(localDockerFile, fmt.Sprintf("FROM %s:.*", forgeopsFrom[1]), newFrom)
	if err != nil {
		return err
	}

	oldLabel := fmt.Sprintf("LABEL com.forgerock.%s.tag=.*", d.productName)
	newLabel := fmt.Sprintf("LABEL com.forgerock.%s.tag=%s", d.productName, forgeopsFrom[2])
	_, err = ReplaceValueInFile(localDockerFile, oldLabel, newLabel)
	if err != nil {
		return err
	}

	return nil
}

// Replace the old hash in the codefresh steps with the new hash
func (u hashUpdate) replaceCodefreshHash() error {
	newHash, err := GetLatestHash(u.forgeopsRepo)
	if err != nil {
		return err
	}

	asFile, err := u.getLocalFile("deploy/codefresh/customer-environment.steps.yml")
	if err != nil {
		return err
	}
	defer func() {
		err = asFile.Close()
		if err != nil {
			log.Warn("Error closing codefresh file")
		}
	}()

	oldHash, err := ReadYamlValueFromFile(asFile, "steps.CloneForgeopsGitRepo.revision")
	if err != nil {
		log.WithError(err).Error("Error finding old hash from codefresh steps")
		return err
	}

	_, err = ReplaceValueInFile(asFile, oldHash, newHash)

	if err != nil {
		log.WithError(err).Error("Error replacing in codefresh step file")
		return err
	}

	return nil
}

func (u hashUpdate) getLocalFile(relativeLocation string) (billy.File, error) {
	log.Debugf("Opening local file '%s'", relativeLocation)
	return GetFileIn(u.saasFs, relativeLocation)
}

func (u hashUpdate) getForgeopsFile(relativeLocation string) (billy.File, error) {
	location := filepath.Join(relativeLocation, "Dockerfile")
	log.Debugf("Opening forgeops dockerfile '%s'", location)

	return GetFileIn(u.forgeopsTree.Filesystem, location)
}
