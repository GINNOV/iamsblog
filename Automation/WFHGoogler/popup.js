// Working from Home Extension for Chrome desktop
// You can change the color of your HUE lights based on your Google calendar settings
// IAMSENSORIA.COM BLOG - SOURCE CODE
//

let changeColor = document.getElementById('changeColor');
let autoDetectInvites = document.getElementById('autoDetectInvites');

// sync with local storage
//
chrome.storage.sync.get('color', function(data) {
	changeColor.style.backgroundColor = data.color;
	changeColor.setAttribute('value', data.color);
});

chrome.storage.sync.get('detection', function(data) {
	autoDetectInvites.checked = data.detection;
	autoDetectInvites.setAttribute('value', data.value);
});

changeColor.onclick = function(element) {
	let color = element.target.value;
	chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
		chrome.tabs.executeScript(
			tabs[0].id,
			{code: 'document.body.style.backgroundColor = "' + color + '";'});
	});
	console.log("color changed")
};

  //  open links in a new tab if marked by _blank
  $('body').on('click', 'a[target="_blank"]', function(e){
    e.preventDefault();
    chrome.tabs.create({url: $(this).prop('href'), active: false});
    return false;
  });

  $(document).ready(function() {
        var apiBaseUrl  = "bridge ip plus userid for registered device here";  //http://192.x.x.x/API/token_here
     
        // onLoad
        $.getJSON(apiBaseUrl, function(data) {
          console.log(data);
          getLights();
      });

        var getLights = function() {
          $.getJSON(apiBaseUrl, function(data) {
            var lights = data["lights"];

            $.each(lights, function(index, light) {
              var template = $("#light-template").clone();
              template.removeAttr("id");
              template.css("display", "block");

              template.data("id", index);
              template.find(".name").text(light["name"]);
              template.find(".brightnessSlider").val(light["state"]["bri"]);
              template.find(".hueSlider").val(light["state"]["hue"]);

              $("#lights").append(template);

              console.log(index + ": " + JSON.stringify(light));
          });
        });
      };

      var setLightState = function(lightId, lightState) {
          var apiUrl = apiBaseUrl + "/lights/" + lightId + "/state";

          $.ajax({
            url:  apiUrl,
            type: "PUT",
            data: JSON.stringify(lightState)
        });
      };

      $(document).on("input", ".hueSlider", function(e) {
          var hue   = $(this).val() / 182;
          var sat   = "100%";
          var light = "50%";

          var lightState = {"hue": parseInt($(this).val()), "sat": 254};
          setLightState($(this).parent().data("id"), lightState);

          $("body").css("background-color", "hsl(" + [hue, sat, light].join(',') + ")");
      });

      $(document).on("input", ".brightnessSlider", function(e) {
          var lightState = {"on": true, "bri": parseInt($(this).val())};

          if ($(this).val() <= 0) {
            lightState["on"] = false;
        } else {
            lightState["on"] = true;
        }

        setLightState($(this).parent().data("id"), lightState);
    });
  });
