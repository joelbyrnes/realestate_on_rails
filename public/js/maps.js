
var map;
var markers = [];

var infowindow = new google.maps.InfoWindow();

function initialize() {
    var myOptions = {
//              center: new google.maps.LatLng(-27.48, 153.01),
        zoom: 8,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);

    load_properties();
}

function reload() {
    // TODO remove all markers from map
    for(var i=0; i < markers.length; i++){
        markers[i].setMap(null);
    }
    markers = []

    // reload JS, then reload the properties.
    $.get("/js/maps.js", null, function(data) {
//        document.append(data);
        load_properties();
    });
}

function handle_properties(props) {
    var marker, content;

//          $.each([52, 97], function(index, value) {
//              alert(index + ': ' + value);
//          });

    var prop;
    for (var i=0; i < props.length; i++) {
        prop = props[i];

        marker = new google.maps.Marker({
            map:map,
            draggable:false,
            position: new google.maps.LatLng(prop.latitude, prop.longitude)
        });
        markers.push(marker);

        var insStr = "";
        $.each (prop.inspections, function(index, ins) {
            insStr = insStr + ins.start + " - " +  ins.end + "<br/>";
            insStr = insStr + new Date(ins.start.replace("Z", "")) + " - " +  new Date(ins.end) + "<br/>";
            insStr = insStr + ins.note + "<br/>";
        });

        var htmlString = "<a href=\"" + prop.url + "\"><b>" + prop.title + "</b><a/><br/>"
            + prop.display_price + "<br/>"
            + prop.note + "<br/>"
            + "Inspections:<br/>"
            + insStr;

        addInfoWindow(marker, htmlString)
    }

    auto_center();
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

function auto_center() {
    //  Create a new viewpoint bound
    var bounds = new google.maps.LatLngBounds();
    //  Go through each...
    $.each(markers, function (index, marker) {
        bounds.extend(marker.position);
    });
    //  Fit these bounds to the map
    map.fitBounds(bounds);
}
