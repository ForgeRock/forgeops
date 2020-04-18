package testutil

import (
	"context"
	"log"
	"os"
	"os/exec"
	"syscall"
	"time"

	"cloud.google.com/go/datastore"
	"github.com/sethgrid/pester"
	"google.golang.org/api/option"
)

// SetupDatastoreEmulator starts the datastore emulator unless DATASTORE_EMULATOR_ENABLED=false
// environment variable is set. This function returns a function that should later be invoked to stop the
// emulator process.
func SetupDatastoreEmulator() func() {
	client := pester.New()
	client.KeepLog = true
	client.Concurrency = 1
	client.MaxRetries = 5
	client.Backoff = pester.LinearBackoff
	client.Timeout = time.Second * 60

	emulatorEnabled, _ := os.LookupEnv("DATASTORE_EMULATOR_ENABLED")
	if emulatorEnabled != "false" {
		log.Println("Starting emulator")
		hostport := "localhost:17713"
		os.Setenv("DATASTORE_EMULATOR_HOST", hostport)
		os.Setenv("DATASTORE_NAMESPACE", "foomanchoo")
		os.Setenv("DATASTORE_PROJECT_ID", "hello-beau-world")
		os.Setenv("DATASTORE_EMULATOR_HOST_PATH", "localhost:17713/datastore")
		os.Setenv("export DATASTORE_DATASET", "hello-beau-world")
		// we turn off eventual-consistency simulation, and no-store-on-disk allows use of /reset endpoint
		cmd := exec.Command("gcloud", "beta", "emulators", "datastore", "start",
			"--no-store-on-disk", "--consistency=1.0", "--host-port", hostport)
		cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
		err := cmd.Start()
		if err != nil {
			log.Printf("could not start command %v %s", cmd, err.Error())
		}
		// spin for OK on health endpoint
		resp, err := client.Get("http://" + hostport)
		log.Println(resp)
		if err != nil {
			log.Fatalf("Error starting datastore emulator: %v\n", client.LogString())
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

	// This allows us to use an externally running datastore emulator.
	// This is used for the integration tests in codefresh.
	dsEmulatorHost, ok := os.LookupEnv("DATASTORE_EMULATOR_HOST")
	if ok && dsEmulatorHost != "" {
		resp, err := client.Post("http://"+dsEmulatorHost+"/reset", "", nil)
		if err != nil {
			log.Fatalf("Error resetting datastore emulator: %v\n", client.LogString())
		}
		defer resp.Body.Close()
	}
	return func() {}
}

func NewDatastoreClient() *datastore.Client {
	client, err := datastore.NewClient(context.Background(), "hello-beau-world", option.WithGRPCConnectionPool(2))
	if err != nil {
		log.Fatalf("Failed to create datastore client: %v", err)
	}
	return client
}
