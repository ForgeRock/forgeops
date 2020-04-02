package smtp

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

type Mailserver struct {
	Host         string `json:"host" binding:"required"`
	Port         int    `json:"port" binding:"required"`
	Username     string `json:"username" binding:"required"`
	Password     string `json:"password" binding:"required"`
	MandatoryTLS bool   `json:"mandatoryTLS" binding:"required"`
}

func GetSendgrid(sendGridAPIKey string) Mailserver {
	return Mailserver{
		Host:         "smtp.sendgrid.net",
		Port:         587,
		Username:     "apikey",
		Password:     strings.TrimSpace(sendGridAPIKey),
		MandatoryTLS: true,
	}
}

func GetServerUpdates(restURL string, polldelay int64, defaultServer Mailserver, smtpUpdates []chan<- Mailserver) {
	log := logrus.WithFields(logrus.Fields{
		"pkg":  "smtp",
		"func": "GetServerUpdates",
	})
	smtpServer := defaultServer

	// Do an immediate check, then sleep polldelay seconds next time
	last := time.Now().Add(time.Duration(-1*polldelay) * time.Second)
	for {
		sleep := time.Duration(polldelay)*time.Second - time.Since(last)
		time.Sleep(sleep)
		last = time.Now()

		// Build the request
		req, err := http.NewRequest("GET", restURL, nil)
		if err != nil {
			log.WithError(err).Error("Unable to create request")
			continue
		}
		req.Header = http.Header{
			"Accept-API-Version": []string{"resource=2.0"},
		}
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			log.WithError(err).WithField("url", restURL).Error("Error getting SMTP server information")
			continue
		}
		defer resp.Body.Close()

		var kv struct {
			Key   string `json:"key"`
			Value string `json:"value"`
		}
		var activeServer Mailserver
		if resp.StatusCode < 400 {
			if err := json.NewDecoder(resp.Body).Decode(&kv); err != nil {
				log.Println(err)
			}
			if err := json.NewDecoder(strings.NewReader(kv.Value)).Decode(&activeServer); err != nil {
				log.Println(err)
			}

			if smtpServer != activeServer {
				smtpServer = activeServer
				log.WithField("smtpServer", fmt.Sprintf("%s@%s:%d", smtpServer.Username, smtpServer.Host, smtpServer.Port)).
					Info("Custom SMTP configuration found")
				for _, channel := range smtpUpdates {
					channel <- smtpServer
				}
			}
		} else if smtpServer != defaultServer {
			smtpServer = defaultServer
			log.Info("No custom SMPT configurations, using sendgrid")
			for _, channel := range smtpUpdates {
				channel <- smtpServer
			}
		}
	}
}
