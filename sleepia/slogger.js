/*
	SLEEPIA PROJECT
	Author: Mario Esposito

	Libraries:	
		Sandeep Mistry's sensortag
		Kue
		Redis

	References:
		https://www.npmjs.com/package/kue-mod
*/


var DEBUG = false;

var SensorTag = require('sensortag'); 	// sensortag library
var kue = require('kue'); 				// queue management library
var redis = require('redis')			// the db man

// ----------------------------------------------------------------------

//
//  Create a queue object
//
var queue = kue.createQueue({
	prefix: 'sleepia',
	redis: {
		port: 6379,
		host: 'localhost',
		auth: '', 						// use a password even if not exposed to the Internet!!
		db: 0,							// database ID
		options: {
										// see https://github.com/mranney/node_redis#rediscreateclient
		}
	}
 });


//
// START HERE
//
console.log('# Turn on the device...');

if (process.argv[2] == "-debug") {
	DEBUG = true;
}

// ----------------------------------------------------------------------


//
// listen for tags:
//
SensorTag.discover(function(tag) {

	//
	// when you disconnect from a tag, exit the program:
	//
	tag.on('disconnect', function() {

		console.log('# Device Disconnected!');
		// this crashes due to a bug in Kue - issue 783
		queue.shutdown(2000, function(err) {
			console.log('# Shutting down: ', err || '');
            process.exit();
		});
	});

	//
	// Connect and setup
	//
	function connectAndSetUp() { // attempt to connect to the tag
		console.log('# Connecting...');
		tag.connectAndSetUp(enableSensors); // when you connect and device is setup, call enableAccelMe
	}

	//
	// This function enables the accelerometer stream
	//
	function enableSensors() { // attempt to enable the accelerometer
		console.log('# Enabled Sensors (Acc, IR Temp)');
		// when you enable the accelerometer, start accelerometer notifications:
		tag.enableAccelerometer(notifyMe); // start the accelerometer listner
		tag.enableIrTemperature(notifyMe); // start the IR temp sensor listner
		if (DEBUG) {
			console.log('timestamp, X, Y, Z, temp');
		}
	}

	//
	// Activate which service we want to be notified by
	//
	function notifyMe() {
		tag.notifyAccelerometer(notificationManager); // setup call back for accelerometer
		tag.notifyIrTemperature(notificationManager); // setup call back for IR temp
		tag.notifySimpleKey(listenForButton); // setup call back for button/switches
	}

	//
	// When you get an accelermeter change, print it out:
	//
	function notificationManager() {
		var at = 0;
		var ot = 0;

		tag.on('irTemperatureChange', function(objectTemp, ambientTemp) {
			ot = objectTemp.toFixed(1);
			at = ambientTemp.toFixed(1);
		});

		tag.on('accelerometerChange', function(x, y, z) {
			// timestamp, 3 axes, temperature
			newSensorDataJob(getTimeStamp(), x.toFixed(1), y.toFixed(1), z.toFixed(1), at);
			
            if(DEBUG) {
                console.log('%s,%d,%d,%d,%d,%d', getTimeStamp(), x.toFixed(1), y.toFixed(1), z.toFixed(1), ot, at);
            }
		});
	}

	//
	// when you get a button change, print it out:
	//
	function listenForButton() {

		tag.on('simpleKeyChange', function(left, right) {

			if (left) {
				console.log('marker1: ' + left);
			}

			if (right) {
				console.log('marker2: ' + right);
			}

			// if both buttons are pressed, disconnect:
			if (left && right) {
				tag.disconnect();
			}
		});
	}

	// Start seeking for the tags:
	connectAndSetUp();
});

//
// Build time stamp according to YYYY:MM:DD:HH:MM:SS:MS
// 
function getTimeStamp() {

	var date = new Date();

	var hour = date.getHours();
	hour = (hour < 10 ? "0" : "") + hour;

	var min = date.getMinutes();
	min = (min < 10 ? "0" : "") + min;

	var sec = date.getSeconds();
	sec = (sec < 10 ? "0" : "") + sec;

	var ms = date.getMilliseconds();
	ms = (ms < 10 ? "0" : "") + ms

	var year = date.getFullYear();

	var month = date.getMonth() + 1;
	month = (month < 10 ? "0" : "") + month;

	var day = date.getDate();
	day = (day < 10 ? "0" : "") + day;

	return year + "-" + month + "-" + day + " " + hour + ":" + min + ":" + sec + ":" + ms;

}

//
// Job - this is what actually queues your data
//
function newSensorDataJob(t, x, y, z, temp) {

	var job = queue.create('sleepia_queue', {
		timestamp: t,
		x: x,
		y: y,
		z: z,
		t: temp
	});

	job.on('complete', function() {
		if (DEBUG) {
			console.log('Job ID', job.id, 'with values', job.data.timestamp, job.data.x, job.data.y, job.data.z, job.data.t, 'is done');
		}
	});

	job.on('failed', function() {
		if (DEBUG) {
			console.log('Job ID', job.id, job.data.timestamp, 'with values', job.data.x, 'has failed');
		}
	});

	job.save();
}

//
// Close the transaction opened by the new job function
//
queue.process('sleepia_queue', function(job, done) {
	/* carry out all the job function here */
	done && done();
});

//
// Shutdown grecefully if CTRL+C is pressed
//
process.once('SIGTERM', function(sig) {

	queue.shutdown(5000, function(err) {
		console.log('# Graceful shutdown started: ', err || '');
		process.exit(0);
	});
});