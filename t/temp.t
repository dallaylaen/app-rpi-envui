use strict;
use warnings;

BEGIN {
    use lib 't/';
    use TestBase;
    set_testing();
}

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use App::RPi::EnvUI;
use HTTP::Request::Common;
use Plack::Test;

my $test = Plack::Test->create(App::RPi::EnvUI->to_app);

{
    my $res = $test->request(GET '/');
    ok $res->is_success, 'Successful request';
    like $res->content, qr/Temperature/, 'front page loaded ok';
}

print "exiting\n";

done_testing();
