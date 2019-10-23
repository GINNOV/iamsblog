/*
	Job queuing in support of a post from IAmSensoria.com blog
	
	the goal here is demonstrate how to leverage Kue Nodejs module
	to achieve job queing.

	Libraries:	
		Kue
		Redis

	created on Nov 25 2015
	forked from https://github.com/prateekbhatt/node-job-queue
*/

var kue = require('kue');
var jobs = kue.createQueue();

var kue = require('kue'),
	jobs = kue.createQueue();

//
// Job - this is what actually queues your data
//
function newJob(name) {
	name = name || 'Default_Name';
	var job = jobs.create('new job', {
		name: name
	});
	job
		.on('complete', function() {
			console.log('Job', job.id, 'with name', job.data.name, 'is    done');
		})
		.on('failed', function() {
			console.log('Job', job.id, 'with name', job.data.name, 'has  failed');
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

//
// Set an interval that every 3 seconds creates a job passing some arbitraty data
//
setInterval(function() {
	newJob('new sensor data received and stored');
}, 3000);