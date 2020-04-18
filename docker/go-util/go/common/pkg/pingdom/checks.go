package pingdom

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"

	"github.com/russellcardullo/go-pingdom/pingdom"
)

const UserIDSAASServices = "14375195"
const MaintenanceDurationMinutes = 5

// If not otherwise overridden, use these values when creating or updating HTTP Checks
const (
	DefaultIntegrationIDs   = "" // no integration by default
	DefaultFRaaSResolution  = 1
	DefaultNotifyAgainEvery = 60
	DefaultNotifyWhenBackup = true
	DefaultEncryption       = true
)

type CheckService struct {
	client *pingdom.Client
	Config Config
	log    *logrus.Entry
}

type Config struct {
	User              string
	Password          string
	APIKey            string
	AccountEmail      string
	NotificationUsers []int
	Integrations      []int
}

const (
	ErrorFailedToCreateCheck  = "failed to create http check in pingdom"
	ErrorFailedToDeleteCheck  = "failed to delete extra http check in pingdom"
	ErrorTooManyChecksFound   = "found multiple http checks defined in pingdom for same tag set"
	ErrorClientCreationFailed = "failed to create pingdom client"
	ErrorFailedToCountChecks  = "failed to query for pre-existing checks"
)

func NewCheckService(conf Config) (*CheckService, error) {
	pc, err := pingdom.NewClientWithConfig(pingdom.ClientConfig{
		User:         conf.User,
		Password:     conf.Password,
		APIKey:       conf.APIKey,
		AccountEmail: conf.AccountEmail,
	})
	if err != nil {
		return nil, errors.Wrap(err, ErrorClientCreationFailed)
	}
	return &CheckService{
		client: pc,
		Config: conf,
		log: logrus.WithFields(logrus.Fields{
			"pkg": "pingdom",
			"svc": "CheckService",
		}),
	}, nil
}

func (c *CheckService) CreateHTTPCheck(endpoint string, path string) error {
	if err := c.validateEndpoint(endpoint); err != nil {
		return err
	}
	check := c.newHTTPCheck(endpoint, path)
	log := c.log.WithFields(logrus.Fields{
		"func":     "CreateHTTPCheck",
		"hostname": check.Hostname,
		"tags":     check.Tags,
	})
	log.Debug("Creating new Pingdom HTTP Check")
	// Explanation for loop:
	// The Pingdom api does not provide an idempotent way to create http checks.
	// So we have to compensate for possible race conditions during the creation of
	// any new checks (it's likely this will be executed by a worker process at least once).
	// Hence this loop with the extra logic.
	maxTries := 5
	for i := 0; i < maxTries; i++ {
		// If we have exactly one instance of this check, we're done.
		count, err := c.checkCount(c.endpointTag(endpoint, path))
		if err != nil {
			log.WithError(errors.Wrap(err, ErrorFailedToCountChecks)).Error()
			continue
		}
		if count >= 1 {
			// log with error so that hopefully we'll get alerted to the issue.
			log.WithError(errors.New(ErrorTooManyChecksFound)).Error()
			// return nil because we don't want this to cause tenant creation to fail.
			return nil
		}
		// Create new check
		checkResponse, err := c.client.Checks.Create(check)
		if err != nil {
			log.WithError(err).Error("pingdom http check creation failed")
			// we'll either try again or return after the loop with error.
			continue
		}
		// -- Compensate for shitty api race condition --
		// See if we have duplicates of this check
		secondCount, err := c.checkCount(c.endpointTag(endpoint, path))
		if err != nil {
			log.WithError(errors.Wrap(err, ErrorFailedToCountChecks)).Error()
			continue
		}
		if secondCount > 1 {
			// if we have duplicates, delete the one we just created
			_, err = c.client.Checks.Delete(checkResponse.ID)
			if err != nil {
				log.WithError(errors.New(ErrorFailedToDeleteCheck)).Error()
				// return nil because we don't want this to cause tenant creation to fail.
				return nil
			}
		}
		// Set newly created check to maintenance mode for the next 30 minutes so
		// Pingdom doesn't alert that it's down while it's still coming up.
		if err := c.setCheckToMaintenance(checkResponse.ID); err != nil {
			return err
		}
		// Success!
		log.WithField("checkID", strconv.Itoa(checkResponse.ID)).Debug("Created Pingdom HTTP Check successfully")
		return nil
	}
	return errors.New(ErrorFailedToCreateCheck)
}

func (c *CheckService) setCheckToMaintenance(checkID int) error {
	id := strconv.Itoa(checkID)
	log := c.log.WithFields(logrus.Fields{
		"func":                "setCheckToMaintenance",
		"checkID":             id,
		"maintenanceDuration": time.Duration(MaintenanceDurationMinutes * time.Minute),
	})
	log.Debug("Setting Pingdom HTTP check to maintenance mode")
	now := time.Now()
	_, err := c.client.Maintenances.Create(&pingdom.MaintenanceWindow{
		Description: "New Tenant Delay",
		From:        now.Unix(),
		To:          now.Add(MaintenanceDurationMinutes * time.Minute).Unix(),
		UptimeIDs:   id,
	})
	if err != nil {
		log.WithError(err).Error("failed to create maintenance window")
		return err
	}
	log.Debug("Successfully set Pingdom HTTP check to maintenance mode")
	return nil
}

func (c *CheckService) DeleteHTTPCheck(endpoint string, path string) error {
	if err := c.validateEndpoint(endpoint); err != nil {
		return err
	}

	uniqueTag := c.endpointTag(endpoint, path)
	log := c.log.WithFields(logrus.Fields{
		"func": "DeleteHttpCheck",
		"tags": uniqueTag,
	})
	log.Debug("Deleting Pingdom HTTP Check")
	checkResponses, err := c.client.Checks.List(map[string]string{"tags": uniqueTag})
	if err != nil {
		return err
	}
	for _, checkResponse := range checkResponses {
		pingdomResponse, err := c.client.Checks.Delete(checkResponse.ID)
		if err != nil {
			pingdomResponseMessage := ""
			if pingdomResponse != nil {
				pingdomResponseMessage = pingdomResponse.Message
			}
			log.WithError(err).WithFields(logrus.Fields{
				"checkID":                checkResponse.ID,
				"pingdomResponseMessage": pingdomResponseMessage,
			}).Error("failed to delete http check")
			return errors.Wrap(err, "failed to delete all checks with specified tag")
		}
	}
	log.Debug("Successfully deleted Pingdom HTTP Checks")
	return nil
}

func (_ *CheckService) validateEndpoint(endpoint string) error {
	// Keep us from operating on potentially all endpoints
	if strings.TrimSpace(endpoint) == "" {
		return errors.New("no endpoint specified")
	}
	// Keep us from operating on anything that's not part of fraas
	if !strings.HasSuffix(endpoint, ".forgeblocks.com") {
		return errors.New("cannot operate on endpoint that excludes 'forgeblocks.com'")
	}
	if strings.TrimSpace(strings.Replace(endpoint, ".forgeblocks.com", "", -1)) == "" {
		return errors.New("no subdomain included in endpoint")
	}
	return nil
}

func (c *CheckService) newHTTPCheck(endpoint, path string) *pingdom.HttpCheck {
	tag := "autoCreated," + c.endpointTag(endpoint) + "," + c.endpointTag(path) + "," + c.endpointTag(endpoint, path)
	name := endpoint + path
	return &pingdom.HttpCheck{
		Name:             name,
		Hostname:         endpoint,
		Url:              path,
		Tags:             tag,
		UserIds:          c.Config.NotificationUsers,
		IntegrationIds:   c.Config.Integrations,
		Resolution:       DefaultFRaaSResolution,
		NotifyAgainEvery: DefaultNotifyAgainEvery,
		NotifyWhenBackup: DefaultNotifyWhenBackup,
		Encryption:       DefaultEncryption,
	}
}

// checkCount returns how many of this check exists in pingdom
// You may be wondering why we're using the tags instead of a more meaningful field
// It's because tags is the most meaningful field pingdom allows us to query by.
func (c *CheckService) checkCount(tags string) (int, error) {
	data, err := c.client.Checks.List(map[string]string{"tags": tags})
	if err != nil {
		return -1, err
	}
	return len(data), nil
}

// Make any input string tag-friendly
func (_ *CheckService) endpointTag(s ...string) string {
	excludedChars := regexp.MustCompile(`[./#]`)
	tag := strings.TrimPrefix(strings.Join(s, ""), "/")

	return string(excludedChars.ReplaceAll([]byte(tag), []byte("-")))
}

// Takes a *Statuspage* component name and a subdomain, and translates it back into a Pingdom
// Unique Tag, which we can then use to identify a specific HTTP Check.
//
// Example:
//
// Subdomain: msci-beta
// Component names:                Unique tags:
//   "Msci Beta API Gateway"     =>  "api-msci-beta-forgeblocks-com-health-self"
//   "Msci Beta API"             =>  "api-msci-beta-forgeblocks-com-health-internal"
//   "Msci Beta User Interface"  =>  "ui-msci-beta-forgeblocks-com-health"
//   "Msci Beta Access Manager"  =>  "openam-msci-beta-forgeblocks-com-am-isalive-jsp"
//
func (_ *CheckService) UniqueTagFromComponentName(subdomain string, componentName string) (string, error) {
	// Capitalise the subdomain, then subtract the result from the component name.
	// customerRef example: "Msci Beta "  (note the space at the end)
	// componentRef example: "API Gateway"
	customerRef := strings.Title(strings.Replace(subdomain, "-", " ", -1)) + " "
	componentRef := strings.Replace(componentName, customerRef, "", -1)

	prefixes := map[string]string{
		"API Gateway":    "api-",
		"API":            "api-",
		"User Interface": "ui-",
		"Access Manager": "openam-",
	}
	suffixes := map[string]string{
		"API Gateway":    "-forgeblocks-com-health-self",
		"API":            "-forgeblocks-com-health-internal",
		"User Interface": "-forgeblocks-com-health",
		"Access Manager": "-forgeblocks-com-am-isalive-jsp",
	}
	uniqueTag := prefixes[componentRef] + subdomain + suffixes[componentRef]
	var err error
	if prefixes[componentRef] == "" || suffixes[componentRef] == "" {
		err = fmt.Errorf("unable to construct unique tag from subdomain '%s' and componentName '%s'\n", subdomain, componentName)
	}
	return uniqueTag, err
}

// Retrieves the Check ID corresponding to a uniqueTag
func (c *CheckService) GetCheckResponseFromUniqueTag(uniqueTag string) (pingdom.CheckResponse, error) {
	var checkResponse pingdom.CheckResponse
	log := c.log.WithFields(logrus.Fields{
		"func": "GetCheckResponseFromUniqueTag",
		"tag":  uniqueTag,
	})
	log.Debug("Retrieving check response")
	fmt.Println("Retrieving check response")
	checkResponses, err := c.client.Checks.List(map[string]string{"tags": uniqueTag})
	if err != nil {
		log.WithError(err).Error("Failed to retrieve list of HTTP checks")
		return checkResponse, err
	}
	// We only expect one response, so throw an error if we receive anything else
	if len(checkResponses) > 1 {
		return checkResponse, fmt.Errorf("found more than one check with unique tag %s", uniqueTag)
	} else if len(checkResponses) == 0 {
		return checkResponse, fmt.Errorf("no check found with unique tag %s", uniqueTag)
	}
	checkResponse = checkResponses[0]
	return checkResponse, err
}

// Configures an existing HTTP Check to use a specific Alert Contact.
func (c *CheckService) AddAlertContactToHTTPCheck(checkResponse pingdom.CheckResponse, userId int) error {
	log := c.log.WithFields(logrus.Fields{
		"func":    "AddAlertContactToHTTPCheck",
		"checkid": checkResponse.ID,
		"userid":  userId,
	})
	userIds := append(c.Config.NotificationUsers, userId)

	// When updating an existing check, Pingdom needs to be reminded what the URL path should be. We will
	// determine the path from the name of the check, which consists of ("hostname" + "path").
	path := strings.Replace(checkResponse.Name, checkResponse.Hostname, "", -1)

	// And we need to form the tags again, otherwise go-pingdom will use its own default values
	endpoint := checkResponse.Hostname
	tag := "autoCreated," + c.endpointTag(endpoint) + "," + c.endpointTag(path) + "," + c.endpointTag(endpoint, path)

	log.Debug("Adding alert contact to HTTP check")
	updatedCheck := pingdom.HttpCheck{
		Name:             checkResponse.Name,
		Hostname:         checkResponse.Hostname,
		Url:              path,
		Tags:             tag,
		UserIds:          userIds,
		IntegrationIds:   c.Config.Integrations,
		Resolution:       DefaultFRaaSResolution,
		NotifyAgainEvery: DefaultNotifyAgainEvery,
		NotifyWhenBackup: DefaultNotifyWhenBackup,
		Encryption:       DefaultEncryption,
	}
	msg, err := c.client.Checks.Update(checkResponse.ID, &updatedCheck)
	if err != nil {
		err = fmt.Errorf("failed to add alert contact to http check: %s", msg)
	}
	return err
}
