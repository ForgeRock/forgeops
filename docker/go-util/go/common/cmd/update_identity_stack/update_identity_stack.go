package main

import (
	"flag"

	"gopkg.in/src-d/go-billy.v4/osfs"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/identityupdate"
	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/logging"
)

var (
	log     = logging.Record
	gitRoot string
)

func main() {
	parseArgs()

	fs := osfs.New(gitRoot)

	err := identityupdate.DoUpdateOn(fs)
	if err != nil {
		log.WithError(err).Fatal("Error doing identity stack upgrade")
	}
}

func parseArgs() {
	flag.StringVar(&gitRoot, "git-root", "", "Root of saas repository")

	flag.Parse()

	if gitRoot == "" {
		log.Fatal("No argument set for git root")
	}
}
