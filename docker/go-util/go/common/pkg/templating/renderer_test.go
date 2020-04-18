package templating

import (
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/stretchr/testify/suite"
)

type templateRendererTestSuite struct {
	suite.Suite
	templatesPath string
}

func TestTemplateRendererSuite(t *testing.T) {
	suite.Run(t, &templateRendererTestSuite{})
}

func (s *templateRendererTestSuite) SetupSuite() {
	// create temporary directory to hold templates
	path, err := ioutil.TempDir("", "testSuiteTemplates")
	if err != nil {
		require.FailNowf(s.T(), "Failed to create temporary directory: %s", err.Error())
	}
	s.templatesPath = path
}

func (s *templateRendererTestSuite) TearDownSuite() {
	os.RemoveAll(s.templatesPath)
}

func (s *templateRendererTestSuite) TestRender() {
	// given
	kv := map[string]string{"name": "Bob"}
	templateBytes := []byte("Hello {{name}}")

	const expectedValue = "Hello Bob"
	const fileName = "testRender.mustasche"

	templatePath := filepath.Join(s.templatesPath, fileName)
	if err := ioutil.WriteFile(templatePath, templateBytes, 0666); err != nil {
		log.Fatal(err)
	}
	renderer, _ := NewMustacheTemplateRenderer(s.templatesPath)

	// when
	actualValue, err := renderer.RenderFileWithKeyValuePairs(fileName, kv)

	// then
	require.NoError(s.T(), err)
	require.Equal(s.T(), expectedValue, actualValue)
}

func (s *templateRendererTestSuite) TestErrCannotFindTemplatesDirectory() {
	// given
	path, err := ioutil.TempDir("", "directory_we_will_delete")
	if err != nil {
		require.FailNowf(s.T(), "Failed to create temporary directory: %s", err.Error())
	}
	os.RemoveAll(path)

	// when
	renderer, err := NewMustacheTemplateRenderer(path)

	// then
	require.Nil(s.T(), renderer)
	require.EqualError(s.T(), err, ErrCannotFindTemplatesDirectory.Error())
}

func (s *templateRendererTestSuite) TestTemplateDoesNotExist() {
	// given
	const fileName = "file_does_not_exist.mustache"
	kv := map[string]string{}

	renderer, _ := NewMustacheTemplateRenderer(s.templatesPath)

	// when
	_, err := renderer.RenderFileWithKeyValuePairs(fileName, kv)

	// then
	require.Error(s.T(), err)
}
