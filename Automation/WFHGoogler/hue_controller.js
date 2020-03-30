
var hue_controller = function() {};
var user_id = "001788fffe614b57";

hue_controller.prototype = {

	bridgeURL: "http://192.168.86.84/api/" + user_id,

	allLightsToggle: function(status) {
		$.ajax(
		  {
		    url: this.bridgeURL + "/groups/0/action",
		    type: "PUT",
		    data: "{\"on\": " + status + "}"
		  }

		).done(function(data) {
		  console.log(data);
		});
	},

	allLightsBri: function(level) {
		$.ajax(
		  {
		    url: this.bridgeURL + "/groups/0/action",
		    type: "PUT",
		    data: "{\"bri\": " + level + "}"
		  }

		).done(function(data) {
		  //console.log(data);
		});
	}
}


