
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

    // reload JS, then reload the properties.
    $.get("/js/maps.js", null, function(data) {
//        document.append(data);
        load_properties();
    });
}

function recalculate() {
    colourPinsByTime(properties);
}

function getPinImage(pinColor) {
    return new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + pinColor,
        new google.maps.Size(21, 34),
        new google.maps.Point(0,0),
        new google.maps.Point(10, 34));
}

var defaultPinImage = getPinImage('FE7569');
var currentPinImage = getPinImage('FF0000');
var lastPinImage = getPinImage('CCAAAA');
var pastPinImage = getPinImage('666666');
var nextPinImage = getPinImage('00FF00');
var futurePinImage = getPinImage('0000FF');


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

        var htmlString = "<span class='infoWindow'><a href=\"" + prop.url + "\"><b>" + prop.title + "</b><a/><br/>"
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

    // TODO after markers are loaded, re-process to change pin colour/icon.
    // TODO re-process again regularly with current time.
    colourPinsByTime(props);

    properties = props;
}

function colourPinsByTime(props) {
    var now = Date.now();
//    alert(now);
//    $.each(props, function(index, prop) {
//        if (now.compareTo(prop.inspections[0].endDate.addMinutes(10)) > 0) {
//            // remove from map
//            prop.marker.setMap(null);
//        } else {
//            prop.marker.setIcon(decidePinImage(now, prop.inspections));
//        }
//    });
    $.each(props, function(index, prop) {
        prop.marker.setIcon(decidePinImage(now, prop.inspections));
    });

//    prop.marker.setIcon(decidePinImage(now, props[0].inspections));
}

/*
inside a 30 minute time period eg 10-10:30  - current
ended up to 45 minutes ago - last
more than 45 minutes ago - old
starts less than 45 minutes in future - next
starts in more than 45 minutes in future - future
 */
function decidePinImage(now, inspections) {
    var open = getNextInspection(inspections);

    if (now.compareTo(open.startDate.addMinutes(30)) <= 0) {
        return futurePinImage;
    }

    if (now.compareTo(open.startDate) <= 0) {
        return nextPinImage;
    }

    if (now.between(open.startDate, open.endDate)) {
        return currentPinImage;
    }

    if (now.compareTo(open.endDate.addMinutes(10)) >= 0) {
        return lastPinImage;
    }

    if (now.compareTo(open.endDate.addMinutes(40)) > 0) {
        return pastPinImage;
    }
    return defaultPinImage;
}

function getNextInspection(inspections) {
    if (inspections.length == 1) return inspections[0];
    var now = Date.now();
    var value = inspections[0];
    $.each(inspections, function(index, inspection) {
        if (inspection.startDate.compareTo(value.startDate) < 0) value = inspection;
    });
    return value;
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
