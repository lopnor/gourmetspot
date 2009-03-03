var map;
var mapClickListener;
$(function() {
        $('#review_select_scene').change(function(){
            if ($(this).children("option[selected]").val() == '-') {
                var new_scene = prompt("追加するシーンを入力してください")
                if ( new_scene ) {
                    $.post(
                        scene_url, 
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

var hours_count = 0;
function append_hours(data) {
    hours_count = hours_count + 1;
    var mydiv = $("#operation_hours")
        .clone()   
        .removeAttr('id')
        .css({display: 'block'});
    mydiv.find('input, select').each(function(){
            $(this).attr(
                'name', $(this).attr('name').replace(/\[\]/,"["+hours_count+"]")
                )
            });
    $('#hours_cell').append(mydiv);
    mydiv.find('select[class="hours"]').each(function() {
            create_time_option(this,31,1);
        }
    );
    mydiv.find('select[class="minutes"]').each(function() {
            create_time_option(this,60,5);
        }
    );
    if (data) {
        $.each(data.day_of_week.split(','), function() {
                mydiv.find('input[value='+this+']').attr('checked', true);
        });
        mydiv.find('input[name$=.id]').val(data.id);
        mydiv.find('input[name$=.holiday]').attr('checked', data.holiday);
        mydiv.find('input[name$=.pre_holiday]').attr('checked', data.pre_holiday);
        mydiv.find('select[name$=.opens_at_hour]').val((data.opens_at.split(':'))[0]);
        mydiv.find('select[name$=.opens_at_minute]').val((data.opens_at.split(':'))[1]);
        mydiv.find('select[name$=.closes_at_hour]').val((data.closes_at.split(':'))[0]);
        mydiv.find('select[name$=.closes_at_minute]').val((data.closes_at.split(':'))[1]);
    }
    mydiv.find('input:first').focus();
    mydiv.find("input[class='checkbox']").bind('click',function(event) {
            $(this).focus();
            }
            );
    update_links();
}

function remove_hours (item) {
    var p = $(item).parents();
    if (confirm("営業時間を削除します")) {
        p = $.grep(p, function(n,i){return $(n).hasClass('week_input');});
        var token = $(document).find('input[name="_token"]').val();
        var id = $(p).find('input[name$=".id"]').val();
        if (id) {
            $.post(open_hours_url + '/' + id + '/delete', 
                    {_token: token}
                  );
        }
        $(p).remove();
        update_links();
    }
}

function update_links () {
    $('#hours_cell').find('a[class="remove_hours"]').remove();
    $('#hours_cell').find('a[class="append_hours"]').remove();
    var count = $(".week_input").size()-1;
    if (count > 1) {
        $(".week_input").each(function() {
                var remove_link = $(document.createElement('a')).attr('href','#').addClass('remove_hours').text('-');
                remove_link.appendTo($(this).find("td[class='remove_hours']"));
                remove_link.bind(
                    'click', function(event) {
                        remove_hours(this);
                    }
                );
            }
        );
    }
    var append_link = $(document.createElement('a')).attr('href','#')
        .addClass('append_hours').text('+');
    append_link.appendTo($("#hours_cell .week_input:last").find("td[class='remove_hours']"));
    append_link.bind(
            'click', function(event) {
                append_hours();
            }
        );
}

function create_time_option (obj,max,step) {
    for (var i = 0;i < max; i = i + step) {
        var val = '00' + i;
        val = val.slice(-2);
        var o = document.createElement('option');
        o.value = val;
        o.appendChild(document.createTextNode(val));
        $(obj).append($(o));
    }
}
