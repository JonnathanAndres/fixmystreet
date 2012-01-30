use strict;
use warnings;
use Test::More;
use Test::WWW::Mechanize::Catalyst 'FixMyStreet::App';
use mySociety::MaPit;

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

# Run the cron script that makes the data for /reports so we don't get an error.
system( "bin/cron-wrapper update-all-reports" );

# check that we can get the page
$mech->get_ok('/reports');
$mech->title_like(qr{Summary reports});
$mech->content_contains('Birmingham');
$mech->follow_link_ok( { text_regex => qr/Birmingham/ } );

SKIP: {
    skip( "Need 'emptyhomes' in ALLOWED_COBRANDS config", 8 )
      unless FixMyStreet::App->get_conf('ALLOWED_COBRANDS') =~ m{emptyhomes};
    ok $mech->host("reportemptyhomes.com"), 'change host to reportemptyhomes';
    $mech->get_ok('/reports');
    # EHA lacks one column the others have
    $mech->content_lacks('state unknown');

    skip( "Need 'fiksgatami' in ALLOWED_COBRANDS config", 8 )
      unless FixMyStreet::App->get_conf('ALLOWED_COBRANDS') =~ m{fiksgatami};

    my $config = FixMyStreet::App->model('DB::Config');
    my $mapit_conf = $config->find( { KEY => 'MAPIT_URL' });
    my $orig_MaPit_URL = $mapit_conf->value;

    $mapit_conf->value('http://mapit.nuug.no');
    $mapit_conf->update;

    ok $mech->host("fiksgatami.no"), 'change host to fiksgatami';
    $mech->get_ok('/reports');
    # There should only be one Oslo
    $mech->content_contains('Oslo');
    $mech->content_unlike(qr{Oslo">Oslo.*Oslo}s);

    $mapit_conf->value($orig_MaPit_URL);
    $mapit_conf->update;
}

done_testing();

