package mail

import (
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/models/template"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/models/user"
)

const OrgMailerName = "org_mailer"

type OrgMailerMessage struct {
	Template     *template.DatastoreEntity `json:"template"`
	User         *user.User                `json:"user"`
	TemplateData map[string]interface{}    `json:"templateData"`
}
