package main

import (
	"fmt"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/pingdom"

	"github.com/namsral/flag"
)

func main() {
	opts := parseArgs()

	svc, err := pingdom.NewCheckService(pingdom.Config{
		User:              opts.pingdomUser,
		Password:          opts.pingdomPass,
		APIKey:            opts.pingdomAPIKey,
		AccountEmail:      opts.pingdomEmail,
		NotificationUsers: []int{opts.notificationUserID},
		Integrations:      []int{opts.integrationID},
	})
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
	}
	if err := svc.CreateHTTPCheck(opts.endpoint, opts.endpointPath); err != nil {
		fmt.Printf("ERROR: %v\n", err)
	}
}

// Options are options
type Options struct {
	pingdomUser        string
	pingdomPass        string
	pingdomEmail       string
	pingdomAPIKey      string
	endpoint           string
	endpointPath       string
	notificationUserID int
	integrationID      int
}

func parseArgs() *Options {
	opts := &Options{}
	flag.StringVar(&opts.pingdomUser, "pingdom_username", "", "Pingdom Username")
	flag.StringVar(&opts.pingdomPass, "pingdom_password", "", "Pingdom password")
	flag.StringVar(&opts.pingdomEmail, "pingdom_account_email", "", "Pingdom account email")
	flag.StringVar(&opts.pingdomAPIKey, "pingdom_api_key", "", "Pingdom application api key")
	flag.StringVar(&opts.endpoint, "endpoint", "", "endpoint for to create a check")
	flag.StringVar(&opts.endpointPath, "endpoint_path", "", "url path the check should query")
	flag.IntVar(&opts.notificationUserID, "pingdom_user_id", 0, "pingdom user id to notify")
	flag.IntVar(&opts.integrationID, "pingdom_integration_id", 0, "pingdom integration id to notify")
	flag.Parse()
	return opts
}
