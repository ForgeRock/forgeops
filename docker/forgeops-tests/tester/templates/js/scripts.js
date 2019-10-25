$(document).ready(function(){  
  $("#runTestButton").click(function(){
      busifyButton($("#runTestButton"))
      runTests()
      document.getElementById("toastContent").innerHTML = "Test job submitted";
      $('.toast').toast('show');
  });
  pingServerForStatus();
});

function reloadIframe(){
  // document.getElementById('reportArea').contentDocument.location.reload(true);
  try{
    document.getElementById('reportArea').src = document.getElementById('reportArea').src
  }
  catch(error){ }
}

// ping the server every 15 secs
var intervalID = window.setInterval(pingServerForStatus, 15000);
var serverBusy = false

async function pingServerForStatus(){
  await fetch("{{ url_for('.status') }}", {method: "GET", credentials: "include"})
  .then(resp => resp.json())
  .then(status => {
    if (status.busy == true){
      busifyButton($("#runTestButton"))
    } 
    else {
      debusifyButton($("#runTestButton"))
      //if server was busy, reload the iframe
      if (serverBusy){
        reloadIframe()
      }
    }
    reloadIframe()
    serverBusy = status.busy;
  })
}

function busifyButton(el){
  $(el).prop("disabled", true)
  .addClass('button_loading')
  .text("Tests Running");
}

function debusifyButton(el){
  $(el).prop("disabled", false)
  .removeClass('button_loading')
  .text("Rerun Tests");
}

function handleErrors(response) {
  if (!response.ok) {
      document.getElementById("toastContent").innerHTML = "A job is already scheduled. I can only support one job at a time";
      reloadIframe()
      $('.toast').toast('show');
      throw Error(response.statusText);
  }
  return response;
}

async function runTests() {
 await fetch("{{ url_for('.runTests') }}", {method: "GET", credentials: "include"})
 .then(handleErrors)
 .then(response => {
  //  reloadIframe()
   console.log("Testing submitted");
  })
 .catch(error => console.log(error) )
 .finally(blah => {
 });
 
}