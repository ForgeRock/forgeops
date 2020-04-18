package templating

import "errors"

var (
	// ErrCannotFindTemplatesDirectory note that templates directory cannot be found
	ErrCannotFindTemplatesDirectory = errors.New("cannot find templates directory (check BASE_RESOURCE_PATH)")

	// RendererFailedTemplate is an error message template, signaling template-renderer failure
	RendererFailedTemplate = "template renderer failed"
)
