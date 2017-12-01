const { events, Job } = require('brigadier')
const util = require('util')

const helmTag = "v2.7.2"
const forgerockRepo = "https://storage.googleapis.com/forgerock-charts"

function doTest() {
    console.log("Running test...")

    var busybox = new Job("busybox", "busybox")
    busybox.storage.enabled = false
    busybox.tasks = [
        "ls -lR /"
    ]

    busybox.run().then( result => {
        console.log("Busybox =" + result)
    })

}

function helmDeploy() {
 var helm = new Job("helm", "lachlanevenson/k8s-helm:" + helmTag)
    helm.storage.enabled = false
    helm.tasks = [
      "ls -R /src"
      //"helm init --client-only",
      //"helm repo add forgerock " + forgerockRepo,
      //"helm search forgerock/"
      //"helm install --name dj --version 6.0.0 --repo  opendj"
      //"helm search nginx"
    ]

    console.log("Running helm...")

     helm.run().then( result => {
        console.log(" Result = " + result)

     })

}

events.on("exec", (brigadeEvent, project) => {
    console.log(util.inspect(brigadeEvent, false, null))
    console.log(util.inspect(project,false,null))
    //helmDeploy()
    doTest()

     console.log("done")
})


events.on("error", (e) => {  console.log("Error event " + util.inspect(e, false, null) )})