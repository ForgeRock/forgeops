package mail

import tts "github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/token"

// EmailKind is used primarily to determine which email template(s) to use
type EmailKind string

const (
	EmailKindTeamMemberInvite               EmailKind = "team-member-invite"
	EmailKindTeamMemberPasswordResetRequest EmailKind = "team-member-password-reset-request"
	EmailKindTeamMemberPasswordResetConfirm EmailKind = "team-member-password-reset-confirm"
)

// TokenKindFromEmail provides a lookup of a transactional TokenKind given an EmailKind
func TokenKindFromEmailKind(emailKind EmailKind) tts.TokenKind {
	EmailKindToTokenKind := map[EmailKind]tts.TokenKind{
		EmailKindTeamMemberPasswordResetRequest: tts.TokenKindPasswordResetRequest,
	}

	return EmailKindToTokenKind[emailKind]
}
