/*
	SensorTag data logger with queue support from IAmSensoria.com blog
	
	Although the sensortag library functions are all asynchronous,
	there is a sequence you need to follow in order to successfully
	read a tag:
		1) discover the tag
		2) connect to and set up the tag
		3) turn on the sensor you want to use (in this case, accelerometer)
		4) turn on notifications for the sensor
		5) listen for changes from the sensortag
	
	This example does all of those steps in sequence by having each function
	call the next as a callback. Discover calls connectAndSetUp, and so forth.
	This example is heavily indebted to Sandeep's test for the library, but
	achieves more or less the same thing without using the async library.

	Libraries:	
		Sandeep Mistry's sensortag library for node.js is leveraged to read data from a TI sensorTag.
		Kue
		Redis
	created on Nov 25 2015
*/


var SensorTag = require('sensortag'); // sensortag library
var kue = require('kue');
var jobs = kue.createQueue();

// listen for tags:
SensorTag.discover(function(tag) {

	// when you disconnect from a tag, exit the program:
	//
	tag.on('disconnect', function() {
		console.log('Device Disconnected!');
		process.exit(0);
	});

	//
	// Connect and setup
	//
	function connectAndSetUpMe() { // attempt to connect to the tag
		console.log('Connecting...');
		tag.connectAndSetUp(enableSensors); // when you connect and device is setup, call enableAccelMe
	}

	//
	// This function enables the accelerometer stream
	//
	function enableSensors() { // attempt to enable the accelerometer
		console.log('Enable Sensors (Acc, IR Temp)');
		// when you enable the accelerometer, start accelerometer notifications:
		tag.enableAccelerometer(notifyMe); // start the accelerometer listner
		tag.enableIrTemperature(notifyMe); // start the IR temp sensor listner
		console.log('Timestamp,X,Y,Z,Objtemp,AmbientTemp');
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
			newAccelDataJob(x.toFixed(1), y.toFixed(1), z.toFixed(1));
			console.log('%s,%d,%d,%d,%d,%d', getDateTime(), x.toFixed(1), y.toFixed(1), z.toFixed(1), ot, at);
		});
	}

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

	//
	// Build time stamp according to YYYY:MM:DD:HH:MM:SS
	// 
	function getDateTime() {

		var date = new Date();

		var hour = date.getHours();
		hour = (hour < 10 ? "0" : "") + hour;

		var min = date.getMinutes();
		min = (min < 10 ? "0" : "") + min;

		var sec = date.getSeconds();
		sec = (sec < 10 ? "0" : "") + sec;

		var year = date.getFullYear();

		var month = date.getMonth() + 1;
		month = (month < 10 ? "0" : "") + month;

		var day = date.getDate();
		day = (day < 10 ? "0" : "") + day;

		return year + ":" + month + ":" + day + ":" + hour + ":" + min + ":" + sec;

	}

	// Now that you've defined all the functions, start the process:
	connectAndSetUpMe();
});

	//
	// Job - this is what actually queues your data
	//
	function newAccelDataJob(x,y,z) {
		// x = x || 'Default_val';
		var job = jobs.create('accelermeter', {
			x: x,
			y: y,
			z: z
		});

		job
			.on('complete', function() {
				console.log('Job ID', job.id, 'with values', job.data.x, job.data.y, job.data.z, 'is done');
			})

			.on('failed', function() {
				console.log('Job ID', job.id, 'with values', job.data.x, 'has failed');
			});
		job.save();
	}

	//
	// Close the transaction opened by the new job function
	//
	jobs.process('new job', function(job, done) {
		/* carry out all the job function here */
		done && done();
	});