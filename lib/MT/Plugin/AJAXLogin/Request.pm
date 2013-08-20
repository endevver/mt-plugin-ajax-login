package MT::Plugin::AJAXLogin::Request;

use strict;
use warnings;
use Moo;

has 'app' => (

);

has 'username' => (

);

has 'blog_id' => (

);

has 'external_auth' => (

);

has 'authenticator' => (

);

has 'errstr' => (

);


has 'status' => (
);

foreach ( qw( UNKNOWN INACTIVE INVALID_PASSWORD DELETED PENDING LOCKED_OUT
              SUCCESS REDIRECT_NEEDED NEW_LOGIN NEW_USER SESSION_EXPIRED) ) {
    has 'status_is_'.lc($_) => (
        
    );
}

$plugin->has_authenticator( $blog )
    or return $plugin->no_authenticator( $name, $blog );

sub has_authenticator {
    return $_[1]->commenter_authenticators =~ m/MovableType/;
}

sub no_authenticator {
    my $plugin          = shift;
    my ( $name, $blog ) = @_;
    my $app             = MT->instance;

    $app->log({
        message  => $plugin->translate( 'NO_MTAUTH',
                                        $name, $blog->name, $blog->id),
        level    => MT::Log::WARNING(),
        category => 'login_commenter',
    });

    return $plugin->_send_json_response( $app,
        { status => 0, message => $app->translate('Invalid login.') } );
}


1;