use strict;
use warnings;

BEGIN {
    use lib 't/';
    use TestBase;
    config();
    db_create();
}

use App::RPi::EnvUI::API;
use App::RPi::EnvUI::DB;
use Data::Dumper;
use Test::More;

#FIXME: add tests to test overrides for hum and temp

my $api = App::RPi::EnvUI::API->new(
    testing => 1,
    config_file => 't/envui.json'
);

my $db = App::RPi::EnvUI::DB->new(testing => 1);

is ref $api, 'App::RPi::EnvUI::API', "new() returns a proper object";
is $api->{testing}, 1, "testing param to new() ok";

{ # aux()

    for (1..8){
        my $name = "aux$_";
        my $aux = $api->aux($name);

        is ref $aux, 'HASH', "aux() returns $name as an href";
        is keys %$aux, 9, "$name has proper key count";

        for (qw(id desc pin state override on_time last_on last_off)){
            is exists $aux->{$_}, 1, "$name has directive $_";
        }
    }

    my $aux = $api->aux('aux9');
    is $aux, undef, "only 8 auxs available";

    $aux = $api->aux('aux0');
    is $aux, undef, "aux0 doesn't exist";

}
{ # auxs()

    my $db_auxs = $db->auxs;
    my $api_auxs = $api->auxs;

    is keys %$api_auxs, 8, "eight auxs() total from auxs()";

    for my $db_k (keys %$db_auxs) {
        for (keys %{ $db_auxs->{$db_k} }) {
            is $db_auxs->{$db_k}{$_}, $api_auxs->{$db_k}{$_},
                "db and api return the same auxs() ($db_k => $_)";
        }
    }
}

{ # aux_id()

    # takes aux hash

    for (1..8){
        my $name = "aux$_";
        my $aux = $api->aux($name);
        my $id = $api->aux_id($aux);

        is $id, $name, "aux_id() returns proper ID for $name";


    }
}

{ # aux_state()

    for (1..8){
        my $aux_id = "aux$_";
        my $state = $api->aux_state($aux_id);

        my $time = DateTime->now(time_zone => 'local')->strftime(
            '%Y-%m-%d %H:%M'
        );

        is $state,
            0,
            "aux_state() returns correct default state value for $aux_id";

        # on

        $state = $api->aux_state($aux_id, 1);
        like $api->aux_last_on($aux_id), qr/$time/, "aux $aux_id last on ok" ;
        is $state, 1, "aux_state() correctly sets state for $aux_id";

        # off

        $state = $api->aux_state($aux_id, 0);
        like $api->aux_last_on($aux_id), qr/$time/, "aux $aux_id last off ok" ;
        is $state, 0, "aux_state() can re-set state for $aux_id";
    }

    my $ok = eval { $api->aux_state; 1; };

    is $ok, undef, "aux_state() dies if an aux ID not sent in";
    like $@, qr/requires an aux ID/, "...and has the correct error message";
}

{ #aux_time()

    my $time = time();

    for (1..8){
        my $id = "aux$_";

        is $api->aux_time($id), 0, "aux_time() has correct default for $id";

        $api->aux_time($id, $time);
    }

    sleep 1;

    for (1..8){
        my $id = "aux$_";
        my $elapsed = time() - $api->aux_time($id);
        ok $elapsed > 0, "aux_time() sets time correctly for $id";
        is $api->aux_time($id, 0), 0, "and resets it back again ok";
    }

    my $ok = eval { $api->aux_time(); 1; };

    is $ok, undef, "aux_time() dies if no aux id is sent in";
}

{ # aux_override()

    for (1..8){
        my $aux_id = "aux$_";
        my $o = $api->aux_override($aux_id);

        is
            $o,
            0,
            "aux_override() returns correct default override value for $aux_id";

        $o = $api->aux_override($aux_id, 1);

        if ($aux_id eq 'aux3'){
            is $o, -1, "aux_override() refuses to be set if toggle disabled ($aux_id)"; 
        }
        else { 
            is $o, 1, "aux_override() correctly sets override for $aux_id";
        }

        $o = $api->aux_override($aux_id, 0);

        if ($aux_id eq 'aux3'){
            is $o, -1, "aux_override() can't re-set override for $aux_id (toggle disabled)";
        }
        else {
            is $o, 0, "aux_override() can re-set override for $aux_id";
        }
    }

    my $ok = eval { $api->aux_override; 1; };

    is $ok, undef, "aux_override() dies if an aux ID not sent in";
    like $@, qr/requires an aux ID/, "...and has the correct error message";
}

{ # aux_pin()

    for (1..8){
        my $aux_id = "aux$_";
        my $p = $api->aux_pin($aux_id);

        is $p, -1, "aux_pin() returns correct default pin value for $aux_id";

        $p = $api->aux_pin($aux_id, 1);

        is $p, 1, "aux_pin() correctly sets pin for $aux_id";

        $p = $api->aux_pin($aux_id, -1);

        is $p, -1, "aux_pin() can re-set pin for $aux_id";
    }

    my $ok = eval { $api->aux_pin; 1; };

    is $ok, undef, "aux_pin() dies if an aux ID not sent in";
    like $@, qr/requires an aux ID/, "...and has the correct error message";
}

{ # aux_last_on

    my $ok;

    $ok = eval {$api->aux_last_on; 1;};
    is $ok, undef, "aux_last_on() requires an aux id";
    like $@, qr/aux_last_on/, "...and error is sane";

    $ok = eval {$api->aux_last_off; 1;};
    is $ok, undef, "aux_last_off() requires an aux id";
    like $@, qr/aux_last_off/, "...and error is sane";

    my $time = DateTime->now(time_zone => 'local')->strftime(
        '%Y-%m-%d %H:%M'
    );

    for (1..8){
        $api->aux_state("aux$_", 1);
        like $api->aux_last_on("aux$_"), qr/$time/, "last on time for aux$_ ok";

        $api->aux_state("aux$_", 0);
        like $api->aux_last_off("aux$_"), qr/$time/, "last off time for aux$_ ok";
    }

}
unconfig();
#db_remove();
done_testing();

