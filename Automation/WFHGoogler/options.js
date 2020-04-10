// options logic
//

let colorButtonsDiv = document.getElementById('buttonColorsDiv');
let autoDetect = document.getElementById('autoDetectInvites');
let bridgeIP = document.getElementById('bridgeIP');
let registerHue = document.getElementById('saveOption')

let userID = document.getElementById('userID');
let save = document.getElementById('saveOption')



const kButtonColors = ['#3aa757', '#e8453c', '#f9bb2d', '#4688f1', '#46241'];


function setup() {
  constructOptions(kButtonColors);
  loadOptions();

  //  open links in a new tab if marked by _blank
  $('body').on('click', 'a[target="_blank"]', function(e){
    e.preventDefault();
    chrome.tabs.create({url: $(this).prop('href'), active: false});
    return false;
  });

  $(document).ready(function() {
  var apiBaseUrl = "http://YOUR_HUE_BRIDGE_IP_HERE/api";

  $("#registerHue").click(function(){
    var settings = {
      "url": apiBaseUrl,
      "method": "POST",
      "timeout": 0,
      "headers": {
        "Content-Type": "text/plain"
      },
      "data": "{\"devicetype\":\"myHue#WFHGoogler\"}",
    };

    $.ajax(settings).done(function (response) {
      userID.value = response["username"];
      console.log(response);
      document.getElementById('feedback').innerHTML = "<b>Device registered!</b>";
      setTimeout(clearFeedback, 2500);
    });
  })
});
}


// build UI and set event handlers
//
function constructOptions(kButtonColors) {
  for (let item of kButtonColors) {
    let button = document.createElement('button');
    button.style.backgroundColor = item;
    button.classList.add("buttonColor");

    button.addEventListener('click', function() {
      chrome.storage.sync.set({color: item}, function() {
        console.log('color is ' + item);
      })
    });
    colorButtonsDiv.appendChild(button);
  }

 // save settings on click
 //
 save.addEventListener('click', function() {
  saveAllOptions();
  console.log('settings stored ');
});
}

// load previously stored settings, including defaults on install
//
function loadOptions() {
  chrome.storage.sync.get('detection', function(data) {
    autoDetect.checked = data.detection;
    console.log('settings loaded from detection ' + data.detection);
  });

  chrome.storage.sync.get('bridgeIP', function(data) {
    bridgeIP.value = data.bridgeIP;
    console.log('settings loaded from bridgeIP ' + data.bridgeIP);
  });

  chrome.storage.sync.get('userID', function(data) {
    userID.value = data.userID;
    console.log('settings loaded from userID ' + data.userID);
  });
}

// save settings in local storage
//
function saveAllOptions() {

  chrome.storage.sync.set({bridgeIP: bridgeIP.value}, function() {
    console.log('bridgeIP is set to ' + bridgeIP.value);
  })
  chrome.storage.sync.set({userID: userID.value}, function() {
    console.log('userID is set to ' + userID.value);
  })

  chrome.storage.sync.set({detection: autoDetect.checked}, function() {
    console.log('Auto detection is set to ' + autoDetect.checked);
  })

  // let the user know that it's done
  document.getElementById('feedback').innerHTML = "saved.";
  setTimeout(clearFeedback, 2500);
}

// clear saved label as timeout expires
function clearFeedback() {
  document.getElementById('feedback').innerHTML = "";
}

// configure everything on load
setup();

