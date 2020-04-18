package main

import (
	"fmt"
	"os"
	"time"

	"github.com/ForgeCloud/saas/tree/master/services/go/common/pkg/statuspage"
)

// Note: This is proof-of-concept code, added here for reference.

func main() {
	// Note: The following API key is no longer valid
	conf := statuspage.Config{
		APIKey: "<AddStatuspageApiKeyHere>",
		PageID: "<AddStatuspagePageIdHere>",
	}

	// Create a new "object" for the statuspage with this id
	p, err := statuspage.NewPage(conf)

	if err != nil {
		fmt.Print(err, "\n")
		os.Exit(1)
	}

	fmt.Printf("Page ID: %s\n", p.Id)
	fmt.Printf("Page Name: %s\n", p.Name)

	fmt.Printf("Page Description: %s\n", p.PageDescription)
	fmt.Printf("Page Headline: %s\n", p.Headline)
	fmt.Printf("Page Branding: %s\n", p.Branding)
	fmt.Printf("Page Subdomain: %s\n", p.Subdomain)

	time.Sleep(500 * time.Millisecond)

	// Get a list of component groups for this statuspage
	//componentGroups := p.GetComponentGroups()
	//for _, g := range componentGroups {
	//	fmt.Println(g.Id, g.Name, g.Components)
	//}

	// Define four new components to create, with an associated component group
	newComponentNames := []string{"PoC4 User Interface", "PoC4 API Gateway", "PoC4 API", "PoC4 Access Manager"}
	componentGroupName := "PoC4 Component Group"

	// Var to store component IDs for later use
	var newComponentIds []string

	// Create the new components
	for _, componentName := range newComponentNames {
		component, err := p.CreateComponent(componentName)
		if err != nil {
			fmt.Print(err, "\n")
		} else {
			fmt.Printf("DEBUG Component Name: %v\n", component.Name)
			fmt.Printf("DEBUG Automation Email: %v\n", component.AutomationEmail)
			newComponentIds = append(newComponentIds, component.Id)
		}
		// Be nice, and add a small delay between calls
		time.Sleep(500 * time.Millisecond)
	}

	fmt.Printf("DEBUG newComponentIds: %v\n", newComponentIds)

	// If we have some new component IDs (as anticipated) then we can go ahead
	// and add them to a new component group.
	if len(newComponentIds) != 0 {
		cg, err := p.CreateComponentGroup(componentGroupName, newComponentIds)
		if err != nil {
			fmt.Print(err, "\n")
		} else {
			fmt.Printf("DEBUG new component group created: %s\n", cg.Name)
		}
	} else {
		fmt.Println("WARN newComponentIds is empty, so no component group created. Exiting.")
		os.Exit(2)
	}

	// Tidy up after ourselves
	// Delete the components, (component group is auto-deleted)
	fmt.Println("Deleting components...")
	for _, componentId := range newComponentIds {
		dcErr := p.DeleteComponent(componentId)
		if dcErr != nil {
			fmt.Printf("Deletion of %s was unsuccessful. Error: %v", componentId, dcErr)
		} else {
			fmt.Printf("Successfully deleted component %s", componentId)
		}
	}

}
