package cluster

// Creates the cluster identifier used to get a cluster from GCP. This has the following format:
// projects/<projectID>/locations/<region>/clusters/<clusterName>
func GetClusterIdentifier(projectID string, region string, clusterName string) string {
	return "projects/" + projectID + "/locations/" + region + "/clusters/" + clusterName
}

// Creates the cluster parent location used to create a cluster in GCP. This has the following format:
// projects/<projectID>/locations/<region>
func GetClusterParentLocation(projectID string, region string) string {
	return "projects/" + projectID + "/locations/" + region
}
