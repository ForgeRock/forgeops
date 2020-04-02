package main

import (
	"fmt"
	"os"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/pingdom"
)

// Note: This is proof-of-concept code, added here for reference.
//
// Challenge... If all we have is the name of a tenant environment, are we able to identify the
// associated Pingdom checks *and* Statuspage components?
//
// If so, can we then link the two together so that Pingdom checks notify Statuspage?

func main() {
	// Think! What information do we actually *need* in order to configure
	// Pingdom. We shall think out loud...
	type pubSubMessage struct {
		Subdomain       string
		ComponentName   string
		AutomationEmail string
	}

	msg := pubSubMessage{
		Subdomain:       "sy-master-11",
		ComponentName:   "Sy Master 11 API Gateway",
		AutomationEmail: "component+fc3987ae-6616-4bb5-9d90-440d3cc88bda@notifications.statuspage.io",
	}

	// Don't commit this!
	config := pingdom.Config{
		User:              "",
		Password:          "",
		APIKey:            "",
		AccountEmail:      "",
		NotificationUsers: []int{14397607},
		Integrations:      []int{},
	}

	// We can grab ourselves a new Pingdom CheckService
	pingdomCheckService, err := pingdom.NewCheckService(config)
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Component Name: '%s'\n", msg.ComponentName)

	// Get our uniqueTag, then search for it in Pingdom to identify the corresponding HTTP Check
	uniqueTag, err := pingdomCheckService.UniqueTagFromComponentName(msg.Subdomain, msg.ComponentName)
	if err != nil {
		fmt.Printf("ERROR uniqueTag: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Unique Tag: '%s'\n", uniqueTag)

	checkResponse, err := pingdomCheckService.GetCheckResponseFromUniqueTag(uniqueTag)
	if err != nil {
		fmt.Printf("ERROR checkId: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Pingdom Check ID: '%v'\n", checkResponse.ID)
}
