package markdown

import (
	"regexp"
)

type regexOp struct {
	name       string
	regex      *regexp.Regexp
	defaultSub string
}

var mdRegexes = []regexOp{}

func init() {
	// Regexes originally from https://github.com/writeas/go-strip-markdown,
	// they have been modified (and in some cases, fixed)
	mdRegexes = []regexOp{
		// Headers: `### Header` to `Header`
		{"headerReg", regexp.MustCompile(`(?m)^\#{1,6}\s*([^#^\n]+)$`), "$1"},
		// Alternate H1 syntax (text underlined with "=")
		{"altH1HeaderReg", regexp.MustCompile(`[=]{2,}\s*?\n`), ""},
		// Alternate H2 syntax (text underlined with "=")
		{"altH2HeaderReg", regexp.MustCompile(`[\-]{2,}\s*?\n`), ""},
		// Strikethrough (~~text~~)
		{"strikeReg", regexp.MustCompile(`~~`), ""},
		// Code sections (```code```)
		{"codeReg", regexp.MustCompile("`{3}" + `(.*)\n`), "$1\n"},
		// Bold+italic (***text***)
		{"emphReg1", regexp.MustCompile(`\*{3}([^*^\n]+)\*{3}`), "$1"},
		// Bold (**text**)
		{"emphReg2", regexp.MustCompile(`\*{2}([^*^\n]+)\*{2}`), "$1"},
		// Italics (*text*)
		{"emphReg3", regexp.MustCompile(`\*{1}([^*^\n]+)\*{1}`), "$1"},
		// Bold+italic (___text___)
		{"emphReg4", regexp.MustCompile(`_{3}([^_^\n]+)_{3}`), "$1"},
		// Bold (__text__)
		{"emphReg5", regexp.MustCompile(`_{2}([^_^\n]+)_{2}`), "$1"},
		// Italics (_text_)
		{"emphReg6", regexp.MustCompile(`_{1}([^_^\n]+)_{1}`), "$1"},
		// Strip inline html tags
		{"htmlReg", regexp.MustCompile("<(.*?)>"), ""},
		// Footnotes: `[^1]: note` to `1: note`
		{"footnotesReg", regexp.MustCompile(`\[\^(.+?)\]\: (.*)`), "$1: $2"},
		// Footnotes: `[^1]` to `(1)`
		{"footnotes2Reg", regexp.MustCompile(`\[\^(.+?)\]`), "($1)"},
		// Image: ![image alt text](/href/of/image.gif) to `image alt text`
		{"imagesReg", regexp.MustCompile(`\!\[(.*?)\]\s?[\[\(].*?[\]\)]`), "$1"},
		// Link: [link](http://www.zelda.com) to `link`
		{"linksReg", regexp.MustCompile(`\[(.*?)\][\[\(](.*?)[\]\)]`), "$1"},
		// Blockquote: > to `  `
		{"blockquoteReg", regexp.MustCompile(`(?m)^[\t\f\v ]*>\s*`), "  "},
		// Inline code blocks: `code` to code
		{"atxHeaderReg5", regexp.MustCompile("`(.+?)`"), "$1"},
		// Collapse 2+ newlines to 2 newlines
		{"atxHeaderReg6", regexp.MustCompile(`\n{2,}`), "\n\n"},
		// Strip css attributes such as {.btn}
		{"cssAttribReg", regexp.MustCompile(`\{(.+?)\}`), ""}}
}

// Strip returns the given string stripped of Markdown.
// If preserveLinks is set to true, links will be converted from:
//     [link name!](http://link.com)
// to
//     link name! (http://link.com)
func Strip(s string, preserveLinks bool) string {
	for _, rx := range mdRegexes {
		if preserveLinks && rx.name == "linksReg" {
			// Link [link](http://www.zelda.com) to `link (http://www.zelda.com)`
			s = rx.regex.ReplaceAllString(s, "$1 ($2)")
		} else {
			s = rx.regex.ReplaceAllString(s, rx.defaultSub)
		}
	}

	return s
}
