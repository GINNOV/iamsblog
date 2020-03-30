// This detects that yo are on the page where you want to aplly logic
//
chrome.declarativeContent.onPageChanged.removeRules(undefined, function() {
      chrome.declarativeContent.onPageChanged.addRules([{
        conditions: [
        new chrome.declarativeContent.PageStateMatcher({
          pageUrl: {hostSuffix: 'developer.chrome.com'},
        }),
        new chrome.declarativeContent.PageStateMatcher({
          pageUrl: {hostSuffix: 'www.meethue.com'},
        })
        ],
            actions: [new chrome.declarativeContent.ShowPageAction()]
      }]);
    });

// set a variable to hold the default color
// this requires permission STORAGE in the manifest
chrome.runtime.onInstalled.addListener(function() {
    chrome.storage.sync.set({color: '#3aa757'}, function() {
      console.log("The color is green.");
    });

    chrome.storage.sync.set({userID: 'NONE'}, function() {
      console.log("userID is set to NONE");
    });

    chrome.storage.sync.set({bridgeIP: 'NONE'}, function() {
      console.log("bridgeIP is set to NONE");
    });

    chrome.storage.sync.set({detection: 'TRUE'}, function() {
      console.log("Automatic detection option is set on default true");
    });
  });