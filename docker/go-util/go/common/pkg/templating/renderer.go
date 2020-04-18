package templating

import (
	"os"
	"path/filepath"

	"github.com/pkg/errors"

	"github.com/cbroglie/mustache"
)

// MustacheTemplateRenderer renders Mustache templates to strings.
type MustacheTemplateRenderer struct {
	// baseTemplatePath is an absolute file path containing template files
	baseTemplatePath string
}

// NewMustacheTemplateRenderer creates a new MustacheTemplateRenderer. The baseTemplatePath must
// be an existing directory where templates are located or ErrCannotFindTemplatesDirectory will
// be returned.
func NewMustacheTemplateRenderer(baseTemplatePath string) (*MustacheTemplateRenderer, error) {
	if stat, err := os.Stat(baseTemplatePath); err != nil || !stat.IsDir() {
		return nil, ErrCannotFindTemplatesDirectory
	}
	return &MustacheTemplateRenderer{
		baseTemplatePath: baseTemplatePath,
	}, nil
}

// RenderFileWithKeyValuePairs renders a template-file with the given key-value pairs for replacing fields.
func (r *MustacheTemplateRenderer) RenderFileWithKeyValuePairs(filename string, templateData map[string]string) (string, error) {
	filePath := filepath.Join(r.baseTemplatePath, filename)
	v, err := mustache.RenderFile(filePath, templateData)
	if err != nil {
		return "", errors.Wrap(err, RendererFailedTemplate)
	}
	return v, nil
}
