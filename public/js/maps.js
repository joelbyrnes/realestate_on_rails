
var map;
var properties = [];

var infowindow = new google.maps.InfoWindow();

function initialize() {
    var myOptions = {
//        center: new google.maps.LatLng(-27.48, 153.01),
        zoom: 8,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);

    load_properties();
}

function reload() {
    // remove all markers from map
    for(var i=0; i < properties.length; i++){
        properties[i].marker.setMap(null);
    }
    
    clearUserLocation();

    // reload JS, then reload the properties.
    $.get("/js/maps.js", null, function(data) {
//        document.append(data);
        load_properties();
    });
}

window.setInterval(processPins, 30000);

function recalculate() {
    processPins(properties);
}

function getPinImage(pinColor) {
    return new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + pinColor,
        new google.maps.Size(21, 34),
        new google.maps.Point(0,0),
        new google.maps.Point(10, 34));
}

var defaultPinImage = getPinImage('FE7569');
var currentPinImage = getPinImage('00FF00');
var lastPinImage = getPinImage('EEAAAA');
var pastPinImage = getPinImage('AAAAAA');
var nextPinImage = getPinImage('FFCC00');
var futurePinImage = getPinImage('6666FF');

var pinShadow = new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_shadow",
    new google.maps.Size(40, 37),
    new google.maps.Point(0, 0),
    new google.maps.Point(12, 35));

// TODO load pin colours in advance

function handle_properties(props) {
    var marker;

    var prop;
    for (var i=0; i < props.length; i++) {
        prop = props[i];

        marker = new google.maps.Marker({
            map:map,
            draggable:false,
            position: new google.maps.LatLng(prop.latitude, prop.longitude),
            icon: defaultPinImage,
            shadow: pinShadow

        });
        prop.marker = marker;

        var insStr = "";
        $.each (prop.inspections, function(index, ins) {
            var start = new Date(ins.start);
            ins.startDate = start;
            var end = new Date(ins.end);
            ins.endDate = end;
            insStr = insStr + start.toString('ddd d MMM h:mm tt') + " - " + end.toString('h:mm tt');
            insStr = insStr + (ins.note? " (" + ins.note + ")" : "") + "<br/>";
        });

        var htmlString = "<span class='infoWindow'>"
            + "<a target='_blank' href=\"" + prop.url + "\"><img src='" + prop.photo_url + "' align='left' /></a>"
            + "<a target='_blank' href=\"" + prop.url + "\"><b>" + prop.title + "</b><a/>"
            + "&nbsp;<a target='_blank' href='/properties/" + prop.id + "'>Show</a><br/>"
            + "<a target='_blank' href=\"http://maps.google.com/maps?saddr=Current+Location&daddr=" + prop.title + "\">Get directions</a><br/>"
            + "Price: " + prop.display_price + "<br/>"
            + "Note: " + prop.note + "<br/>"
            + "Inspections:<br/>"
            + insStr
            + "</span>";

        addInfoWindow(marker, htmlString)
    }

    // if first load, auto center on the properties
    if (properties.length == 0) {
        auto_center(props);
    }

    processPins();

    properties = props;
}

function processPins() {
    if ($('#inspections_mode').attr('checked')) {
        colourPinsByTime(properties);
    } else {
        $.each(properties, function(index, prop) {
            prop.marker.setIcon(defaultPinImage);
            prop.marker.setMap(map);
        });
    }
}

function colourPinsByTime(props) {
    var now = Date.now();
    $.each(props, function(index, prop) {
//        if (now.compareTo(prop.inspections[0].endDate.clearTime()) > 0) {
//        if (false) {
            // remove from map
//            prop.marker.setMap(null);
//        } else {
            var image = null;
            if (prop.hasOwnProperty("inspections") && prop.inspections) { 
                image = decidePinImage(prop.inspections);
            }
            if (image == null || image == pastPinImage || prop.seen_date) {
                // remove from map
                prop.marker.setMap(null);
            } else {
                prop.marker.setIcon(image);
            }
//        }
    });
}

function decidePinImage(inspections) {
    var now = Date.now();

    var open = getNextInspection(inspections);
    if (open == null) return null;
    
    // if the inspection was before today, remove it
    //if (new Date(now).clearTime().compareTo(new Date(open).clearTime()) > 0) return null;

    // if the open time is more than 30 minutes away
    if (new Date(now).addMinutes(30).compareTo(open.startDate) <= 0) {
        return futurePinImage;
    }

    // if the open time is in future but less than 30 minutes
    if (now.compareTo(open.startDate) < 0) {
        return nextPinImage;
    }

    // if the start date was before now and the end date is after now
    if (now.between(new Date(open.startDate).addMinutes(-5), new Date(open.endDate).addMinutes(10))) {
        return currentPinImage;
    }

    // if the end was more than 30 minutes ago
    if (now.compareTo(new Date(open.endDate).addMinutes(30)) > 0) {
        return pastPinImage;
    }
    
    // if the end was less than 30 minutes ago
    if (now.compareTo(new Date(open.endDate).addMinutes(10)) >= 0) {
        return lastPinImage;
    }

    return defaultPinImage;
}

function getNextInspection(inspections) {
    if (inspections == null || inspections.length == 0) return null;
    if (inspections.length == 1) {
        return inspections[0];
    } else {
        var now = Date.now();
        var next_inspection = inspections[0];
        $.each(inspections, function(index, inspection) {
            // if this is in the past, ignore it if there are later values
            if (inspection.startDate.compareTo(now) >= 0) {
                // TODO skip if date is not today
                if (inspection.startDate.compareTo(next_inspection.startDate) < 0) next_inspection = inspection;
            }
        });
        return next_inspection;
    }
}

function addInfoWindow(marker, infocontent) {
    google.maps.event.addListener(marker, 'click', (function(theMarker, content) {
        return function() {
            // to do multiple windows open at once, create a new infowindow here instead of reusing the one.
            infowindow.setContent(content);
            infowindow.open(map, theMarker);
        }
    })(marker, infocontent));
}

function load_properties() {
    $.getJSON("/properties.json", null, handle_properties)
}

function auto_center(props) {
    //  Create a new viewpoint bound
    var bounds = new google.maps.LatLngBounds();
    //  Go through each...
    $.each(props, function (index, prop) {
        bounds.extend(prop.marker.position);
    });
    //  Fit these bounds to the map
    map.fitBounds(bounds);
}

var userLocation = null;
var userLocationRadius;
var userLocationImage = new google.maps.MarkerImage("/images/blue3.png",
    new google.maps.Size(30, 30), new google.maps.Point(0, 0),
    new google.maps.Point(7, 7), new google.maps.Size(15, 15));

navigator.geolocation.watchPosition(function(position) {
    var userPos = new google.maps.LatLng(position.coords.latitude,
        position.coords.longitude);

    if (!userLocation) {
        // Center the map on the new position
        //map.setCenter(userPos);

        // Marker does not exist - Create it
        userLocation = new google.maps.Marker({
            position: userPos,
            map: map,
            icon: userLocationImage
        });

        userLocationRadius = new google.maps.Circle({
            map: map,
            radius: position.coords.accuracy,    // in metres
            fillColor: '#5555FF',
            strokeColor:  '#5555FF',
            strokeWeight: 1
        });
    }

    userLocation.setPosition(userPos);
    userLocationRadius.setRadius(position.coords.accuracy);
    userLocationRadius.bindTo('center', userLocation, 'position');
});

function clearUserLocation() {
    if (userLocation) userLocation.setMap(null);
    if (userLocationRadius) userLocationRadius.setMap(null);
}
