/*
	SensorTag data logger with queue support from IAmSensoria.com blog
	Libraries:	
		Sandeep Mistry's sensortag library for node.js is leveraged to read data from a TI sensorTag.
		Kue
		Redis
*/


var SensorTag = require('sensortag'); // sensortag library
var kue = require('kue');
var queue = kue.createQueue({
	prefix: 'q',
	redis: {
		port: 6379,
		host: 'localhost',
		auth: '',
		db: 0, // if provided select a non-default redis db
		options: {
			// see https://github.com/mranney/node_redis#rediscreateclient
		}
	}
});

// listen for tags:
SensorTag.discover(function(tag) {

	// when you disconnect from a tag, exit the program:
	//
	tag.on('disconnect', function() {
		console.log('# Device Disconnected!');
	});

	//
	// Connect and setup
	//
	function connectAndSetUpMe() { // attempt to connect to the tag
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

		console.log('timestamp, X, Y, Z, ambientTemp');
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
			newSensorDataJob(getDateTime(), x.toFixed(1), y.toFixed(1), z.toFixed(1), at);
			// console.log('%s,%d,%d,%d,%d,%d', getDateTime(), x.toFixed(1), y.toFixed(1), z.toFixed(1), ot, at);
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
				process.once('SIGTERM', function(sig) {

					kue.shutdown(5000, function(err) {
						console.log('Kue shutdown: ', err || '');

						process.exit(0);
					});
				});
				tag.disconnect();
			}
		});
	}
	//
	// Build time stamp according to YYYY:MM:DD:HH:MM:SS:MS
	// 
	function getDateTime() {

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

		return year + ":" + month + ":" + day + ":" + hour + ":" + min + ":" + sec + ":" + ms;

	}


	// Now that you've defined all the functions, start the process:
	connectAndSetUpMe();
});
	//
	// Job - this is what actually queues your data
	//
	function newSensorDataJob(t, x, y, z, temp) {
		// x = x || 'Default_val';
		var job = queue.create('sleepia', {
			timestamp: t,
			x: x,
			y: y,
			z: z,
			t: temp
		});

		job.on('complete', function() {
				console.log('Job ID', job.id, 'with values', job.data.timestamp, job.data.x, job.data.y, job.data.z, job.data.t, 'is done');
			});

		job.on('failed', function() {
				console.log('Job ID', job.id, job.data.timestamp, 'with values', job.data.x, 'has failed');
			});

		job.save();
	}

	//
	// Close the transaction opened by the new job function
	//
	queue.process('sleepia', function(job, done) {
		/* carry out all the job function here */
		done && done();
	});