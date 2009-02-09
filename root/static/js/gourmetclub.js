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
        })
    });
