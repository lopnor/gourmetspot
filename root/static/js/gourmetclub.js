var map;
var mapClickListener;
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
        $('form input[name="address"]').change(function() {
                var geocoder = new GClientGeocoder();
                geocoder.getLatLng(
                    $(this).val(),
                    function(point) {
                        if ( point ) {
                            map.closeInfoWindow();
                            map.clearOverlays();
                            map.setCenter(point,17);
                            createMarker(map, point, {draggable: true});
                            GEvent.removeListener(mapClickListener);
                            fillLatLng(point);
                        }
                    }
                );
            }
        );
        if (GBrowserIsCompatible()) {
            var mapdiv = document.getElementById('map');
            if ( mapdiv ) {
                map = new GMap2(mapdiv, {
                    googleBarOptions: {showOnLoad: 0}
                });
                map.enableGoogleBar();
                map.addControl(new GMapTypeControl());
                map.addControl(new GLargeMapControl());
                var option = {draggable: false};
                if ($(mapdiv).hasClass('draggable'))
                    option.draggable = true;

                var lat_input = $('form input[name="latitude"]').val();
                var lng_input = $('form input[name="longitude"]').val();

                if ( lat_input && lng_input ) {
                    init_lat = lat_input;
                    init_lng = lng_input;
                }

                if ( init_lat && init_lng ) {
                    var restrantLatLng = new GLatLng(init_lat, init_lng);
                    map.setCenter(restrantLatLng, 17);
                    createMarker(map, restrantLatLng, option);
                } else {
                    var hachikoLatLng = new GLatLng(35.6590397, 139.7005660);
                    map.setCenter(hachikoLatLng, 18);
                    mapClickListener = GEvent.addListener(
                            map, "click", function(overlay, point) {
                                createMarker(map, point, option);
                                GEvent.removeListener(mapClickListener);
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
    var panodiv = document.createElement('div');
    $(panodiv).css({height: '200px', width: '300px'});
    marker.openInfoWindow(panodiv);
    setTimeout(function() {setupPanorama(marker, panodiv)}, 300);
    if ( option.draggable ) {
        GEvent.addListener(marker, "dragend", function() {
                    fillLatLng(marker.getLatLng());
                }
            );
        GEvent.addListener(marker, "dragstart", function() {
                    map.closeInfoWindow();
                }
            );
    }
    GEvent.addListener(marker, "click", function() {
            marker.openInfoWindow(panodiv);
            setTimeout(function() {setupPanorama(marker, panodiv)}, 300);
        }
    );
}

function fillLatLng(point) {

    var lat_input = $('form input[name="latitude"]');
    var lng_input = $('form input[name="longitude"]');

    if ( lat_input && lng_input ) {
        lat_input.val(point.lat());
        lng_input.val(point.lng());
    }
}

function setupPanorama(marker, div) {
    var option = {latlng: marker.getLatLng()};
    if (init_lat && init_lng && init_pano) {
        if (marker.getLatLng().equals(new GLatLng(init_lat,init_lng))) {
            option = {
                latlng: new GLatLng(init_pano.latlng.lat, init_pano.latlng.lng),
                pov: init_pano.pov,
            };
        }
    }
    var gsvp = new GStreetviewPanorama(div, option);
    GEvent.addListener(gsvp, "initialized", function (loc) {
            var input = $('form input[name="panorama"]');
            if (input) {
                var option = {
                    latlng: {
                        lat: loc.latlng.lat() || 0,
                        lng: loc.latlng.lng() || 0,
                    },
                    pov: {
                        yaw: loc.pov.yaw || 0,
                        pitch: loc.pov.pitch || 0,
                        zoom: loc.pov.zoom || 0,
                    }
                };
                input.val($.toJSON(option));
            }
        }
    );
    $.each(["yaw", "pitch", "zoom"], function(index, item) {
            GEvent.addListener(gsvp, item+"changed", function (o) {
                    var input = $('form input[name="panorama"]');
                    if (input) {
                        var option = $.evalJSON($(input).val());
                        option.pov[item] = o;
                        input.val($.toJSON(option));
                    }
                }
            );
        }
    );
}


function append_hours(data) {
    var count = $(".week_input").size()-1;
    var mydiv = $("#operation_hours")
        .clone()   
        .removeAttr('id')
        .css({display: 'block'});
    mydiv.find('input').each(function(){
            $(this).attr(
                'name', $(this).attr('name').replace(/\[\]/,"["+count+"]")
                )
            });
    $('#hours_cell').find('a[class="append_hours"]').remove();
    $("#hours_cell").append(mydiv);
    if (data) {
        $.each(data.day_of_week.split(','), function() {
                mydiv.find('input[value='+this+']').attr('checked', true);
        });
        mydiv.find('input[name$=.id]').val(data.id);
        mydiv.find('input[name$=.holiday]').attr('checked', data.holiday);
        mydiv.find('input[name$=.pre_holiday]').attr('checked', data.holiday);
        mydiv.find('input[name$=.opens_at_hour]').val((data.opens_at.split(':'))[0]);
        mydiv.find('input[name$=.opens_at_minute]').val((data.opens_at.split(':'))[1]);
        mydiv.find('input[name$=.closes_at_hour]').val((data.closes_at.split(':'))[0]);
        mydiv.find('input[name$=.closes_at_minute]').val((data.closes_at.split(':'))[1]);
    }
    mydiv.find('input:first').focus();
    mydiv.find('input[class="minutes"]').bind("keydown", function(event) {
            timeval($(this),event,{max: 60,step: 5});
            }
            );
    mydiv.find('input[class="hours"]').bind("keydown",function(event) {
            timeval($(this),event,{max: 24,step: 1});
            }
            );
    mydiv.find("a[class='append_hours']").bind('click',function(event) {
            append_hours();
            }
            );
    mydiv.find("input[class='checkbox']").bind('click',function(event) {
            $(this).focus();
            }
            );
}

function timeval(j,event,option) {  
    var nextval = parseInt($(j).val(), 10);
    if (event.keyCode == 38) {
        nextval += option.step;
        if (nextval >= option.max) nextval = 00;
        nextval = '0' + nextval;
        $(j).val(nextval.slice(-2));
    } else if (event.keyCode == 40) {
        nextval -= option.step;
        if (nextval < 0) nextval = option.max - option.step;
        nextval = '0' + nextval;
        $(j).val(nextval.slice(-2));
    }
}
