$(document).ready(function(){

    var host = 'http://192.168.1.147:5000';

    display_env();
    setInterval(display_env, 5000);

    $(function(){
        aux_update();
    });

    function aux_update(){
        for(i = 1; i < 5; i++){
            var aux = 'aux'+ i;
            aux_state(aux);
        }
    }
    function aux_state(aux){
        $.get(host +'/get_aux/' + aux, function(state){
            $('#'+ aux).switchbutton({
                checked: parseInt(state),
                onChange: function(checked){
                    $.get(host +'/set_aux/'+ aux +'/'+ checked, function(data){
                        // ...
                    });
                }
            });
        });
    }

    function display_env(){
        $.get(host +'/fetch_env', function(data){
            var json = $.parseJSON(data);
            display_temp(json.temp);
            display_humidity(json.humidity);
        });

        aux_update();
    };

    function display_temp(temp){
        if (temp > 78){
            $('#temp').css('color', 'red');
        }
        else {
            $('#temp').css('color', 'green')
        }
        $('#temp').text(temp);
    }

    function display_humidity(humidity){
        if (humidity < 22){
            $('#humidity').css('color', 'red');
        }
        else {
            $('#humidity').css('color', 'green')
        }
        $('#humidity').text(humidity);
    }
});
