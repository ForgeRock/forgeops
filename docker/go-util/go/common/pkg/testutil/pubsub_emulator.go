package testutil

import (
	"log"
	"os"
	"os/exec"
	"syscall"
	"time"

	"github.com/sethgrid/pester"
)

// SetupPubsubEmulator starts the pub/sub emulator unless PUBSUB_EMULATOR_ENABLED=false
// environment variable is set. This function returns a function that should later be invoked to stop the
// emulator process.
func SetupPubsubEmulator() func() {
	emulatorEnabled, _ := os.LookupEnv("PUBSUB_EMULATOR_ENABLED")
	if emulatorEnabled != "false" {
		log.Println("Starting emulator")
		hostport := "localhost:17714"
		os.Setenv("PUBSUB_EMULATOR_HOST", hostport)
		os.Setenv("PUBSUB_PROJECT_ID", "hello-beau-world")
		cmd := exec.Command("gcloud", "beta", "emulators", "pubsub", "start", "--host-port", hostport)
		cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
		err := cmd.Start()
		if err != nil {
			log.Printf("could not start command %v %s", cmd, err.Error())
		}
		// spin for OK on health endpoint
		client := pester.New()
		client.KeepLog = true
		client.Concurrency = 1
		client.MaxRetries = 5
		client.Backoff = pester.LinearBackoff
		client.Timeout = time.Second * 60

		resp, err := client.Get("http://" + hostport)
		log.Println(resp)
		if err != nil {
			log.Fatalf("Error starting pubsub emulator: %v\n", client.LogString())
		}
		defer resp.Body.Close()
		return func() {
			if cmd != nil {
				if err := syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL); err != nil {
					log.Printf("could not kill process %v, %s", cmd.Process.Pid, err.Error())
				}
			}
		}
	}
	return func() {}
}
