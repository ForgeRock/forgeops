// This is very experimental - use at your own risk, this may go away.
const { events, Job, Group } = require('brigadier')
const util = require('util')

const helmTag = "v2.7.2"
const forgerockRepo = "https://storage.googleapis.com/forgerock-charts"



function doTest() {
    console.log("Running test...")

    var busybox = new Job("busybox", "busybox")
    busybox.storage.enabled = false
    busybox.tasks = [
        "ls -lR /src"
    ]

    busybox.run().then( result => {
        console.log("Busybox =" + result)
    })

}

function helmDeploy() {
    var helm = new Job("helm", "lachlanevenson/k8s-helm:" + helmTag)
    helm.storage.enabled = false

    var newBranch = "f30f530565007cc0ec7fb6ec85cfb8599e79c87f"

    var upgrade = "helm upgrade --reuse-values --version 6.0.0 --set global.git.branch=" + newBranch + " openig forgerock/openig"

    console.log("cmd is " + upgrade)
    helm.tasks = [
       //"ls -R /src",
       "helm init --client-only",
       "helm repo add forgerock " + forgerockRepo,
       "helm search forgerock/",
       upgrade
      //"helm search nginx"
    ]


    var busybox = new Job("busybox", "busybox")
    busybox.storage.enabled = false
    busybox.tasks = [
        "ls -lR /src"
    ]

    var group = new Group([helm,busybox]);


    group.runEach().then(results => {
         console.log(" Result = " + result)
    });


    console.log("Running helm...")

//     helm.run().then( result => {
//        console.log(" Result = " + result)
//     })

}

events.on("exec", (brigadeEvent, project) => {
    console.log(util.inspect(brigadeEvent, false, null))
    console.log(util.inspect(project,false,null))
    //helmDeploy()
    doTest()
    console.log("done")
})


events.on("error", (e) => {
    console.log("Error event " + util.inspect(e, false, null) )
     console.log("==> Event " + e.type + " caused by " + e.provider + " cause class" + e.cause)
    })

events.on("after", (e) => {  console.log("After event fired " + util.inspect(e, false, null) )})