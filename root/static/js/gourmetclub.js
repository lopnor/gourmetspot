$(function() {
        $('#review_select_scene').change(function(){
            if ($(this).children("option[selected]").val() == '-') {
                var new_scene = prompt("追加するシーンを入力してください")
                if ( new_scene ) {
                    $.post(
                        add_scene_url, 
                        {value: new_scene},
                        function(data) {
                            var s = document.createElement('option');
                            s.value = data.id;
                            s.appendChild(document.createTextNode(data.value));
                            $(s).insertBefore($('#review_select_scene option:selected'));
                            $('#review_select_scene').val(data.id);
                        },
                        'json'
                    );
                } else {
                    $(this).val('');
                }
            }
        });
        if (GBrowserIsCompatible()) {
            var mapdiv = document.getElementById('map');
            if ( mapdiv ) {
                var map = new GMap2(mapdiv, {
                    googleBarOptions: {showOnLoad: 1}
                });
                map.enableGoogleBar();
                map.addControl(new GMapTypeControl());
                map.addControl(new GLargeMapControl());
                if ( init_lat && init_lng ) {
                    var restrantLatLng = new GLatLng(init_lat, init_lng);
                    map.setCenter(restrantLatLng, 17);
                    var option = {draggable: false};
                    if ($(mapdiv).hasClass('draggable'))
                        option.draggable = true;
                    createMarker(map, restrantLatLng, option);
                } else {
                    var hachikoLatLng = new GLatLng(35.6590397, 139.7005660);
                    map.setCenter(hachikoLatLng, 18);
                    var myListener = GEvent.addListener(
                            map, "click", function(overlay, point) {
                                createMarker(map, point);
                                GEvent.removeListener(myListener);
                                fillLatLng(point);
                            }
                        );
                }
            }
        }
    }
);
$(window).unload = 'GUnload()';

function createMarker(map, point, option) {
    var marker = new GMarker(point, option);
    map.addOverlay(marker);
    GEvent.addListener(marker, "dragend", function() {
                fillLatLng(marker.getLatLng());
            }
        );
    GEvent.addListener(marker, "click", function() {
                var panodiv = document.createElement('div');
                $(panodiv).css({height: '200px', width: '300px'});
                marker.openInfoWindow(panodiv);
                setTimeout(function() {
                        new GStreetviewPanorama(panodiv,
                            {latlng: marker.getLatLng()}
                        );
                    }, 100);
            }
        );
}

function fillLatLng(point) {

    var latInput = $('form input[name="latitude"]');
    var lngInput = $('form input[name="longitude"]');

    if ( latInput && lngInput ) {
        latInput.val(point.lat());
        lngInput.val(point.lng());
    }
}
