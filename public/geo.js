function setupSounds(latlng) {
  for (i in soundboard) {
    var sound = soundboard[i];
		var point;
		if (sound.latitude && sound.longitude) {
			point = new google.maps.LatLng(sound.latitude,sound.longitude);
		} else {
			point = randomPoint(latlng);
		}
    sound.marker = new google.maps.Marker({ 
      position: point,
      map: map, 
      title: sound.title,
      icon:'http://maps.google.com/mapfiles/ms/micons/orange.png',
    });
  }
}

function setupRandomSounds(latlng) {
  for (i in soundboard) {
    var sound = soundboard[i];
    var point = randomPoint(latlng);
    sound.marker = new google.maps.Marker({ 
      position: point,
      map: map, 
      title: sound.title,
      icon:'http://maps.google.com/mapfiles/ms/micons/orange.png',
    });
  }
}

function setupFacebookPlacesSounds(latlng) {
  var params = 'type=place&center='+latlng.lat()+','+latlng.lng()+'&distance=1000&access_token=<%= @fb_access_token %>'
  $.getJSON("https://graph.facebook.com/search?callback=?&"+params,
    function(json) {
      places = json.data;
      for (i in soundboard) {
        var sound = soundboard[i];
        if (places[i]) {
          var point = new google.maps.LatLng(places[i].location.latitude,places[i].location.longitude);
        } else {
          var point = randomPoint(latlng);
        }
        sound.marker = new google.maps.Marker({ 
          position: point,
          map: map, 
          title: sound.title,
          icon:'http://maps.google.com/mapfiles/ms/micons/orange.png',
        });
      }
    }
  );
}

function randomPoint(p) {
  var lat = p.lat() + (-0.0025 + Math.random() / 200.0);
  var lon = p.lng() + (-0.0025 + Math.random() / 200.0);
  return new google.maps.LatLng(lat,lon);
}

// from: http://www.movable-type.co.uk/scripts/latlong.html
if (typeof(Number.prototype.toRad) === "undefined") {
  Number.prototype.toRad = function() {
    return this * Math.PI / 180;
  }
}
function haversine(a, b) {
  var R = 6371; // km
  var dLat = (b.lat()-a.lat()).toRad();
  var dLon = (b.lng()-a.lng()).toRad(); 
  var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
          Math.cos(a.lat().toRad()) * Math.cos(b.lat().toRad()) * 
          Math.sin(dLon/2) * Math.sin(dLon/2); 
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  var d = R * c;
  return d;
}

function error(msg) {
  var s = document.querySelector('#status');
  s.innerHTML = typeof msg == 'string' ? msg : "failed";
  s.className = 'fail';
}
