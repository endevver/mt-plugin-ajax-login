package MT::Plugin::AJAXLogin;

use strict;
use parent qw( MT::Plugin );

sub ajax_login {
    my $app     = shift;
    my $q       = $app->can('query') ? $app->query : $app->param;
    my $name    = $q->param('username');
    my $blog_id = $q->param('blog_id');
    my $via     = 'via AjaxLogin';

    my $blog    = MT->model('blog')->load($blog_id)
      or return $app->errtrans( 'Can\'t load blog #[_1].', $blog_id );
    my $auths   = $blog->commenter_authenticators;

    $auths =~ /MovableType/
        or return $app->MT::Plugin::AJAXLogin::no_mt_authenticator;

    require MT::Auth;
    my ( $message, $error );
    my $ctx         = MT::Auth->fetch_credentials( { app => $app } );
    $ctx->{blog_id} = $blog_id;
    my $result      = MT::Auth->validate_credentials($ctx);

    if (   ( MT::Auth::NEW_LOGIN() == $result )
        || ( MT::Auth::NEW_USER() == $result )
        || ( MT::Auth::SUCCESS() == $result ) )
    {
        my $commenter = $app->user;

        if ( $q->param('external_auth') && !$commenter ) {
            $app->param( 'name', $name );
            if ( MT::Auth::NEW_USER() == $result ) {
                $commenter =
                  $app->_create_commenter_assign_role( $q->param('blog_id') );
                return $app->login_form(
                    error => $app->translate('Invalid login') )
                  unless $commenter;
            }
            elsif ( MT::Auth::NEW_LOGIN() == $result ) {
                my $registration = $app->config->CommenterRegistration;
                unless (
                       $registration
                    && $registration->{Allow}
                    && (   $app->config->ExternalUserManagement
                        || $blog->allow_commenter_regist )
                  )
                {
                    return $app->login_form(
                        error => $app->translate( 'Successfully authenticated but '
                                 . 'signing up is not allowed.  Please contact system '
                                 . 'administrator.' )
                    ) unless $commenter;
                }
                else {
                    return $app->signup(
                        error => $app->translate('You need to sign up first.') )
                      unless $commenter;
                }
            }
        }

        MT::Auth->new_login( $app, $commenter );

        if ( $app->_check_commenter_author( $commenter, $blog_id ) ) {
            $app->make_commenter_session($commenter);
            return _send_json_response( $app,
                { status => 1, message => "session created" } );

            #return $app->redirect_to_target;
        }
        $error = $app->translate("Permission denied.");
        $message = $app->translate(
              "Login failed: permission denied for user '[_1]' $via", $name );
    }
    elsif ( MT::Auth::INVALID_PASSWORD() == $result ) {
        $message = $app->translate(
            "Login failed: password was wrong for user '[_1]' $via", $name );
    }
    elsif ( MT::Auth::INACTIVE() == $result ) {
        $message = $app->translate(
            "Failed login attempt by disabled user '[_1]' $via", $name );
    }
    else {
        $message = $app->translate(
            "Failed login attempt by unknown user '[_1]' $via", $name );
    }
    $app->log(
        {
            message  => $message,
            level    => MT::Log::WARNING(),
            category => 'login_commenter',
        }
    );
    $ctx->{app} ||= $app;
    MT::Auth->invalidate_credentials($ctx);
    my $response = {
        status  => $result,
        message => $error || $app->translate("Invalid login"),
    };
    return _send_json_response( $app, $response );

}

sub _send_json_response {
    my ( $app, $result ) = @_;
    require JSON;
    my $json = JSON::objToJson($result);
    $app->send_http_header("");
    $app->print($json);
    return $app->{no_print_body} = 1;
    return undef;
}

sub no_mt_authenticator {
    my $app = shift;
    $app->log({
        message => $app->translate(
                        'Invalid commenter login attempt '.$via.' by '
                      . '[_1] to blog [_2](ID: [_3]) which does not allow '
                      . 'Movable Type native authentication.',
                      $name, $blog->name, $blog_id
                   ),
        level    => MT::Log::WARNING(),
        category => 'login_commenter',
    });
    return _send_json_response( $app,
        { status => 0, message => $app->translate('Invalid login.') } );
}

1;
__END__
