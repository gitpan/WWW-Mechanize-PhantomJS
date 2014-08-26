#!perl -w
use strict;
use Test::More;
use WWW::Mechanize::PhantomJS;
use lib 'inc', '../inc';
use Test::HTTP::LocalServer;

use lib 'inc', '../inc';
use Test::HTTP::LocalServer;
use t::helper;

# What instances of PhantomJS will we try?
my $instance_port = 8910;
my @instances = t::helper::browser_instances();

if (my $err = t::helper::default_unavailable) {
    plan skip_all => "Couldn't connect to PhantomJS: $@";
    exit
} else {
    plan skip_all => "POST requests via Selenium/ghostdriver/PhantomJS are currently unsupported :-/";
    exit
    plan tests => 2*@instances;
};

my $server = Test::HTTP::LocalServer->spawn(
    #debug => 1
);

sub new_mech {
    WWW::Mechanize::PhantomJS->new(
        autodie => 1,
        @_,
    );
};

t::helper::run_across_instances(\@instances, $instance_port, \&new_mech, sub {
    my($browser_instance, $mech)= @_;

    isa_ok $mech, 'WWW::Mechanize::PhantomJS';

    my ($site,$estatus) = ($server->url,200);
    my $res = $mech->post($site, params => { query => 'queryValue1', query2 => 'queryValue2' });
    isa_ok $res, 'HTTP::Response', "Response";

    is $mech->uri, $site, "Navigated to $site";

    is $res->code, $estatus, "POSTting $site returns HTTP code $estatus from response"
        or diag $mech->content;

    is $mech->status, $estatus, "POSTting $site returns HTTP status $estatus from mech"
        or diag $mech->content;

    ok $mech->success, 'We consider this response successful';

    like $mech->content, qr/queryValue1/, "We find our parameter 'query'";
    like $mech->content, qr/queryValue2/, "We find our parameter 'query2'";
});