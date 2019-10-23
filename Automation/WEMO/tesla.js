/*
	WEMO switch from IAmSensoria.com blog
	
    Libraries used:
    wemo-client by Timon Reinhard https://github.com/timonreinhard/wemo-client/
	to install wemo client just use: npm install wemo-client
    
    created on 18 Nov 2016
	by Mario Esposito
*/

var Wemo = require('wemo-client');
var wemo = new Wemo();
var fs = require('fs');

//
// If no parameters are provided post usage
//
if (process.argv.length < 3) {
    console.log("Help:");
    console.log("node tesla.js list - Shows all the available switches and their states");
    console.log("node tesla.js switch <friendly name> on|off - change state of the switch");
    process.exit(0);
}

//
//  Main function
//
if (process.argv[2] === 'list') {
    // Find all devices
    wemo.discover(foundDevice);
    
} else if (process.argv[2] === 'switch') {
    
    var fileName = process.argv[3] +'.json';
    
    fs.exists(fileName, function (exists) {
        if (exists) {
            fs.readFile(fileName, function(err, data) { 
            if(err)
                throw err;
            
            var deviceInfo = JSON.parse(data);
            var urlSetup = "http://" + deviceInfo.host + ':' + deviceInfo.port + '/setup.xml';
            // use Setup url to learn about IP and port number. Once done call the callback function
            wemo.load(urlSetup, discoverCompleted);
        });
        }
    });
}

//
// Callback function for setting the state
//
function discoverCompleted(deviceInfo) {
    var client = wemo.client(deviceInfo);
    
    // turn on/off the switch state
    if(process.argv[4] === 'on')
        client.setBinaryState(1);
    else
        client.setBinaryState(0);
    
    // wait for the state to change and then exit
    client.on('binaryState', function (value) {
        process.exit(0);
    }
        )
};

//
// Discover all devices
//
function foundDevice(deviceInfo) {
    console.log('Device Found: %s (%s) host:%s port:%s %s',
        deviceInfo.friendlyName, deviceInfo.deviceType, deviceInfo.host, deviceInfo.port, deviceInfo.firmwareVersion);
    var obj = JSON.stringify(deviceInfo);


    fs.writeFile("./" + deviceInfo.friendlyName + ".json", obj, function (err) {
        if (err) {
            return console.log(err);
        }

        console.log("The file was saved!");
    }); 

    // Get the client for the found device
    var client = wemo.client(deviceInfo);

    // Handle binaryState events
    client.on('binaryState', function (value) {
        var states = {
            0: 'off',
            1: 'on',
            8: 'standby'
        };
        console.log('Binary State of %s is %s', this.device.friendlyName, states[value]);
    });
}

// Repeat discovery as some devices may appear late
// setInterval(function() {
//   wemo.discover(foundDevice);
// }, 15000);