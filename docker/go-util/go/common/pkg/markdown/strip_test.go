package markdown

import (
	"testing"

	"github.com/stretchr/testify/suite"
)

type markdownStripTestSuite struct {
	suite.Suite
}

func TestMarkdownStripSuite(t *testing.T) {
	s := &markdownStripTestSuite{}
	suite.Run(t, s)
}

func (s *markdownStripTestSuite) TestMarkdownStrip() {
	// given
	var tests = []struct {
		name          string
		in            string
		out           string
		preserveLinks bool
	}{
		{
			name: "full markdown test",
			in: `# Markdown is simple
It lets you _italicize words_ and **bold them**, too. You can ~~cross things out~~ and add __emphasis__ to your writing.

But you can also *link* to stuff, like [Write.as](https://write.as)!

## Organize text with headers
Create sections in your text just like this.

Insert an ![image](image.gif)

### Use lists
You might already write lists like this:

* Get groceries
* Go for a walk

Create sections
---------------
This is a section

Another section
===============
This is also a section

And sometimes you need to do things[^1] in a certain order:

1. Put on clothes
2. Put on shoes
3. Go for a walk

### Highlight text
You can quote interesting people:

> Live long and prosper.

` + "```" + `package main

import "fmt"

func main() {
	fmt.Println("Hello, world")
}` + "```" + `

You can even share ` + "`code stuff`." + `

[^1]: footnote`,
			out: `Markdown is simple
It lets you italicize words and bold them, too. You can cross things out and add emphasis to your writing.

But you can also link to stuff, like Write.as!

Organize text with headers
Create sections in your text just like this.

Insert an image

Use lists
You might already write lists like this:

* Get groceries
* Go for a walk

Create sections
This is a section

Another section
This is also a section

And sometimes you need to do things(1) in a certain order:

1. Put on clothes
2. Put on shoes
3. Go for a walk

Highlight text
You can quote interesting people:

  Live long and prosper.

package main

import "fmt"

func main() {
	fmt.Println("Hello, world")
}

You can even share code stuff.

1: footnote`,
			preserveLinks: false,
		},
		{
			name:          "link with no name",
			in:            "![] (https://write.as/favicon.ico)",
			out:           "",
			preserveLinks: false,
		},
		{
			name:          "space between text and link",
			in:            "![Some image] (https://write.as/favicon.ico)",
			out:           "Some image",
			preserveLinks: false,
		},
		{
			name:          "normal link",
			in:            "![Some image](https://write.as/favicon.ico)",
			out:           "Some image",
			preserveLinks: false,
		},
		{
			name:          "link preserved",
			in:            "[Some Link](http://www.forgerock.com)",
			out:           "Some Link (http://www.forgerock.com)",
			preserveLinks: true,
		},
		{
			name:          "link with button tag",
			in:            "[Confirm](http://www.test.com?query=string&token=ASDFHJKLITRUSTMEIMATOKEN){.btn}",
			out:           "Confirm (http://www.test.com?query=string&token=ASDFHJKLITRUSTMEIMATOKEN)",
			preserveLinks: true,
		},
	}

	for _, test := range tests {
		s.T().Log(test.name)

		// ----
		// when
		// ----
		res := Strip(test.in, test.preserveLinks)

		// ----
		// then
		// ----
		s.Equal(test.out, res)
	}
}
