### test ci example
const { events, Job, Group } = require('brigadier')

const helmTag = "v2.8.2"

function gitClone() {
    console.log("cloned")
}

function helmDeploy {
    console.log("deployed")
}


events.on("push", function(e, project) {
  console.log("received push for commit " + e.commit)
  
  gitClone()
  helmDeploy()
  
  console.log("complete")
  
)}