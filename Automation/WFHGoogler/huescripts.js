var HubAddress = "";
var LightOn = true;
var LightsToChange = [1, 2, 3];
var x;
var y;
var hue;
var saturation;
var brightness;

function UpdateLights() {
    var UpdateSettings =
        '{' +
        '"on" : ' + LightOn + ', ' +
        '"bri": ' + brightness * 2 + ', ' +
        '"hue": ' + hue + ', ' +
        '"sat": ' + saturation + ', ' +
        '"xy": [' + x + ',' + y + ']' +
        '}';
    for (index = 0; index < LightsToChange.length; index++) {
        $.ajax({
            async: false,
            type: 'PUT',
            url: 'http://' + HubAddress + '/api/newdeveloper/lights/' + LightsToChange[index] + '/state',
            data: UpdateSettings,
            success: function (data) {
                //console.log(JSON.stringify(data));
            }
        });
    }
}

$(function() {
        var apiBaseUrl  = null;
        var username    = "newdeveloper";

        // onLoad
        $.getJSON("http://192.168.86.84/api/nupnp", function(data) {
          console.log(data);
          
          var internalIpAddress = data[0].internalipaddress;
          apiBaseUrl = "http://" + internalIpAddress + "/api/" + username;
          console.log("onLoad - api url: " + apiBaseUrl);   

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












