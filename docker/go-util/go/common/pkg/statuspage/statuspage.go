package statuspage

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

const ApiUrl = "https://api.statuspage.io/v1"

var httpClient *http.Client

func init() {
	httpClient = &http.Client{}
}

// Contains configuration information for communicating with Statuspage
type Config struct {
	APIKey string
	PageID string
}

// Contains
type Component struct {
	Id                 string `json:"id"`
	PageId             string `json:"page_id"`
	GroupId            string `json:"group_id"`
	CreatedAt          string `json:"created_at"`
	UpdatedAt          string `json:"updated_at"`
	Group              bool   `json:"group"`
	Name               string `json:"name"`
	Description        string `json:"description"`
	Position           int    `json:"position"`
	Status             string `json:"status"`
	Showcase           bool   `json:"showcase"`
	OnlyShowIfDegraded bool   `json:"only_show_if_degraded"`
	AutomationEmail    string `json:"automation_email"`
}

type Group struct {
	Id          string   `json:"id"`
	PageId      string   `json:"page_id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Components  []string `json:"components"`
	Position    int      `json:"position"`
	CreatedAt   string   `json:"created_at"`
	UpdatedAt   string   `json:"updated_at"`
}

type Page struct {
	Id              string `json:"id"`
	Name            string `json:"name"`
	PageDescription string `json:"page_description"`
	Headline        string `json:"headline"`
	Branding        string `json:"branding"`
	Subdomain       string `json:"subdomain"`
	ComponentNames  []string
	Options         Config
	log             *logrus.Entry
}

// Taking a (valid) config, we retrieve the Page definition.
// This definition allows us to query for additional features (Groups, Components) of that Page
// The organization (ForgeRock) only has a single page.
func NewPage(options Config) (*Page, error) {
	if len(options.PageID) == 0 {
		err := errors.New("ERROR Unable to instantiate Page: No Page ID provided")
		return nil, err
	}
	if len(options.APIKey) == 0 {
		err := errors.New("ERROR Unable to instantiate Page: No API Key provided")
		return nil, err
	}
	response, err := getRequest(httpClient, options, "profile")
	if err != nil {
		return nil, err
	}
	var page Page
	if err = json.Unmarshal(response, &page); err != nil {
		return nil, err
	}
	//Store the configuration options within the transmitted Page for re-use in later comms.
	page.Options = options
	//Create a logger for later use
	page.log = logrus.WithFields(logrus.Fields{"pkg": "statuspage"})
	return &page, nil
}

// Retrieve all the components of a Page
func (p *Page) GetComponents() ([]Component, error) {
	response, err := getRequest(httpClient, p.Options, "components")
	if err != nil {
		return nil, err
	}
	var components []Component
	if err = json.Unmarshal(response, &components); err != nil {
		return nil, err
	}
	return components, err
}

// Retrieve all the names of components on a Page
func (p *Page) GetComponentNames() ([]string, error) {
	var names []string
	components, err := p.GetComponents()
	if err != nil {
		return nil, err
	}
	for _, c := range components {
		names = append(names, c.Name)
	}
	return names, nil
}

// Create a new Component, returning a representation of that Component
func (p *Page) CreateComponent(name string) (*Component, error) {
	description := "Autocreated: " + name
	compJson := `{ "component": { "description": "` + description + `", "status": "operational", "name": "` + name + `", "only_show_if_degraded": false, "showcase": true } }`
	log := p.log.WithFields(logrus.Fields{
		"func": "CreateComponent",
		"name": name,
	})
	log.Debug("Creating new Statuspage Component")
	var component *Component
	response, err := postRequest(httpClient, p.Options, compJson, "newcomponent")
	if err != nil {
		return nil, err
	}
	if err = json.Unmarshal(response, &component); err != nil {
		return nil, err
	}
	log = p.log.WithFields(logrus.Fields{
		"id": component.Id,
	})
	log.Debug("Statuspage Component created")
	return component, nil
}

// Delete a page component by supplying its ID.
func (p *Page) DeleteComponent(componentId string) error {
	log := p.log.WithFields(logrus.Fields{
		"func": "DeleteComponent",
		"id":   componentId,
	})
	log.Debug("Deleting Statuspage Component")
	_, err := deleteRequest(httpClient, p.Options, "component", componentId)
	return err
}

//Retrieve all component groups in the page
func (p *Page) GetComponentGroups() ([]Group, error) {
	response, err := getRequest(httpClient, p.Options, "component_groups")
	if err != nil {
		return nil, err
	}
	var groups []Group
	if err = json.Unmarshal(response, &groups); err != nil {
		return nil, err
	}
	return groups, nil
}

//Retrieve the names of all the page's component groups
func (p *Page) GetComponentGroupNames() ([]string, error) {
	componentGroups, err := p.GetComponentGroups()
	if err != nil {
		return nil, err
	}
	var componentGroupNames []string
	for _, cg := range componentGroups {
		componentGroupNames = append(componentGroupNames, cg.Name)
	}
	return componentGroupNames, nil
}

// Create a new component group with the given name, compromising of the Components with the provided Ids
func (p *Page) CreateComponentGroup(name string, componentIds []string) (*Group, error) {
	description := "Autocreated: " + name
	quotedComponents := "\"" + strings.Join(componentIds[:], "\",\"") + "\""
	componentGroupJson := `{ "description": "` + description + `", "component_group": { "components": [ ` + quotedComponents + ` ], "name": "` + name + `" } }`
	log := p.log.WithFields(logrus.Fields{
		"func": "CreateComponentGroup",
		"name": name,
	})
	log.Debug("Creating new Statuspage Component group")
	response, err := postRequest(httpClient, p.Options, componentGroupJson, "newcomponentgroup")
	if err != nil {
		return nil, err
	}
	var group *Group
	if err = json.Unmarshal(response, &group); err != nil {
		return nil, err
	}
	log = p.log.WithFields(logrus.Fields{
		"id": group.Id,
	})
	log.Debug("Statuspage Component Group created")
	return group, nil
}

// The Statuspage API is rate-limited to 60 per minute. To reduce the chance of breaching
// this limit, we add a small delay between calls in the following functions.

func getRequest(client *http.Client, options Config, resourceType string) ([]byte, error) {
	//map of GET-able resourceTypes to URLs
	getUrls := map[string]string{
		"profile":             ApiUrl + "/pages/" + options.PageID + ".json",
		"pages":               ApiUrl + "/pages",
		"page_access_users":   ApiUrl + "/pages/" + options.PageID + "/page_access_users",
		"page_access_groups":  ApiUrl + "/pages/" + options.PageID + "/page_access_groups",
		"page_metrics":        ApiUrl + "/pages/" + options.PageID + "/page_metrics",
		"components":          ApiUrl + "/pages/" + options.PageID + "/components",
		"component_groups":    ApiUrl + "/pages/" + options.PageID + "/component-groups",
		"subscribers":         ApiUrl + "/pages/" + options.PageID + "/subscribers",
		"incidents":           ApiUrl + "/pages/" + options.PageID + "/incidents",
		"scheduled_incidents": ApiUrl + "/pages/" + options.PageID + "/incidents/scheduled",
		"incident_templates":  ApiUrl + "/pages/" + options.PageID + "/incident_templates",
	}
	url, ok := getUrls[resourceType]
	if !ok {
		err := fmt.Errorf("getRequest: unable to find URL associated with resourceType '%s'", resourceType)
		return nil, err
	}
	authHeader := "OAuth " + options.APIKey
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Add("Authorization", authHeader)
	time.Sleep(500 * time.Millisecond)
	response, err := client.Do(req)
	if err != nil || response.StatusCode != http.StatusOK {
		return nil, errors.New("GET request failed")
	}
	return ioutil.ReadAll(response.Body)
}

func postRequest(client *http.Client, options Config, payload string, resourceType string) ([]byte, error) {
	bytePayload := []byte(payload)
	//map of POST-able resource types to URLs
	postUrls := map[string]string{
		"newcomponent":      ApiUrl + "/pages/" + options.PageID + "/components",
		"newcomponentgroup": ApiUrl + "/pages/" + options.PageID + "/component-groups",
	}
	url, ok := postUrls[resourceType]
	if !ok {
		err := fmt.Errorf("postRequest: unable to find URL associated with resourceType '%s'", resourceType)
		return nil, err
	}
	authHeader := "OAuth " + options.APIKey
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(bytePayload))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", authHeader)
	req.Header.Set("Content-Type", "application/json")
	time.Sleep(500 * time.Millisecond)
	response, err := client.Do(req)
	if err != nil || response.StatusCode != http.StatusCreated {
		return nil, errors.New("POST request failed")
	}
	return ioutil.ReadAll(response.Body)
}

func deleteRequest(client *http.Client, options Config, resourceType string, resourceId string) ([]byte, error) {
	//map of DELETE-able resource types to URLs
	deleteUrls := map[string]string{
		"component":       ApiUrl + "/pages/" + options.PageID + "/components/" + resourceId,
		"component_group": ApiUrl + "/pages/" + options.PageID + "/component-groups/" + resourceId,
	}
	url, ok := deleteUrls[resourceType]
	if !ok {
		err := fmt.Errorf("deleteRequest: unable to find URL associated with resourceType '%s'", resourceType)
		return nil, err
	}
	authHeader := "OAuth " + options.APIKey
	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Add("Authorization", authHeader)
	time.Sleep(500 * time.Millisecond)
	response, err := client.Do(req)
	if err != nil || response.StatusCode != http.StatusNoContent {
		return nil, errors.New("DELETE request failed")
	}
	return ioutil.ReadAll(response.Body)
}
