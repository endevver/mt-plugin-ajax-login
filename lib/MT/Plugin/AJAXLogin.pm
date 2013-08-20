package MT::Plugin::AJAXLogin;

use strict;
use base qw( MT::Plugin );

sub ajax_login {
    my $plugin = $_[0]->component('AJAXLogin');
    return $_[0]->product_version =~ m/^4/ ? $plugin->_ajax_login_mt4( @_ )
                                           : $plugin->_ajax_login_mt5( @_ );
}

# Mostly copied from MT 5.2.7's MT::App::Community::do_login
# with changes for proper JSON returned response
# Please do not perltidy or otherwise clean up the code below as this makes
# it difficult to compare with Six Apart's horrible formatting and coding
# choices.
sub _ajax_login_mt5 {
    my $plugin  = shift;
    my $app     = shift;
    my $q       = $app->param;
    my $name    = $q->param('username');
    my $blog_id = $q->param('blog_id');
    my $blog    = MT::Blog->load($blog_id) if ( defined $blog_id );
    my $auths   = $blog->commenter_authenticators if $blog;
    if ( $blog && $auths !~ /MovableType/ ) {
        $app->log(
            {   message => 'AJAXLogin: '. $app->translate(
                    'Invalid commenter login attempt from [_1] to blog [_2](ID: [_3]) which does not allow Movable Type native authentication.',
                    $name, $blog->name, $blog_id
                ),
                level    => MT::Log::WARNING(),
                category => 'login_commenter',
            }
        );
        return $plugin->_send_json_response( $app,
            { status => 0, message => $app->translate('Invalid login.') } );
    }

    require MT::Auth;
    my $ctx = MT::Auth->fetch_credentials( { app => $app } );
    $ctx->{blog_id} = $blog_id;
    my $result = MT::Auth->validate_credentials($ctx);
    my ( $message, $error );
    if (   ( MT::Auth::NEW_LOGIN() == $result )
        || ( MT::Auth::NEW_USER() == $result )
        || ( MT::Auth::SUCCESS() == $result ) )
    {
        my $commenter = $app->user;
        if ( $q->param('external_auth') && !$commenter ) {
            $app->param( 'name', $name );
            if ( MT::Auth::NEW_USER() == $result ) {
                $commenter = $app->_create_commenter_assign_role(
                    $q->param('blog_id') );
                return $plugin->_send_json_response( $app,
                    { status => 0, message => $app->translate('Invalid login.') } )
                    unless $commenter;
            }
            elsif ( MT::Auth::NEW_LOGIN() == $result ) {
                my $registration = $app->config->CommenterRegistration;
                unless (
                       $registration
                    && $registration->{Allow}
                    && ( $app->config->ExternalUserManagement
                        || ( $blog && $blog->allow_commenter_regist ) )
                    )
                {
                    return $plugin->_send_json_response( $app, {
                                status  => 0,
                                message => $app->translate(
                                     'Successfully authenticated but signing '
                                    .'up is not allowed.  Please contact '
                                    .'system administrator.' )
                           }
                    ) unless $commenter;
                }
                else {
                    return $plugin->_send_json_response( $app,
                            { status => 0,
                              message => $app->translate('You need to sign up first.') }
                    ) unless $commenter;
                }
            }
        }
        MT::Auth->new_login( $app, $commenter );
        if ( $app->_check_commenter_author( $commenter, $blog_id ) ) {
            $app->make_commenter_session($commenter);
            return $plugin->_send_json_response( $app,
                { status => 1, message => "session created" } );
        }
        $error   = $app->translate("Permission denied.");
        $message = $app->translate(
            "Login failed: permission denied for user '[_1]'", $name );
    }
    elsif ( MT::Auth::PENDING() == $result ) {

        # Login invalid; auth layer reports user was pending
        # Check if registration is allowed and if so send special message
        if ( my $registration = $app->config->CommenterRegistration ) {
            if ( $registration->{Allow} ) {
                $error = $app->login_pending();
            }
        }
        $error
            ||= $app->translate(
            'This account has been disabled. Please see your Movable Type system administrator for access.'
            );
        $app->user(undef);
        $app->log(
            {   message => $app->translate(
                    "Failed login attempt by pending user '[_1]'", $name
                ),
                level    => MT::Log::WARNING(),
                category => 'login_user',
            }
        );
    }
    elsif (MT::Auth::INVALID_PASSWORD() == $result
        || MT::Auth::SESSION_EXPIRED() == $result )
    {
        $message = $app->translate(
            "Login failed: password was wrong for user '[_1]'", $name );
    }
    elsif ( MT::Auth::INACTIVE() == $result ) {
        $message
            = $app->translate( "Failed login attempt by disabled user '[_1]'",
            $name );
    }
    elsif ( MT::Auth::LOCKED_OUT() == $result ) {
        $message = $app->translate('Invalid login.');
    }
    else {
        $message
            = $app->translate( "Failed login attempt by unknown user '[_1]'",
            $name );
    }
    $app->log(
        {   message  => $message,
            level    => MT::Log::SECURITY(),
            category => 'login_commenter',
        }
    ) if $message;
    $ctx->{app} ||= $app;
    MT::Auth->invalidate_credentials($ctx);
    my $response = {
        status  => $result,
        message => $error || $app->translate("Invalid login"),
    };
    return $plugin->_send_json_response( $app, $response );

}

# Mostly copied from MT 4.3.x's MT::App::Community::do_login
# with changes for proper JSON returned response
sub _ajax_login_mt4 {
    my $plugin  = shift;
    my $app     = shift;
    my $q       = $app->param;
    my $name    = $q->param('username');
    my $blog_id = $q->param('blog_id');
    my $blog    = MT->model('blog')->load($blog_id)
      or return $app->errtrans( 'Can\'t load blog #[_1].', $blog_id );
    my $auths   = $blog->commenter_authenticators;
 
    if ( $auths !~ /MovableType/ ) {
        $app->log(
            {
                message => 'AJAXLogin' . $app->translate(
                                'Invalid commenter login attempt from '
                              . '[_1] to blog [_2](ID: [_3]) which does not allow '
                              . 'Movable Type native authentication.',
                              $name, $blog->name, $blog_id
                           ),
                level    => MT::Log::WARNING(),
                category => 'login_commenter',
            }
        );
        return $plugin->_send_json_response( $app,
            { status => 0, message => $app->translate('Invalid login.') } );
    }
 
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
            return $plugin->_send_json_response( $app,
                { status => 1, message => "session created" } );
 
            #return $app->redirect_to_target;
        }
        $error = $app->translate("Permission denied.");
        $message = $app->translate(
              "Login failed: permission denied for user '[_1]'", $name );
    }
    elsif ( MT::Auth::INVALID_PASSWORD() == $result ) {
        $message = $app->translate(
            "Login failed: password was wrong for user '[_1]'", $name );
    }
    elsif ( MT::Auth::INACTIVE() == $result ) {
        $message = $app->translate(
            "Failed login attempt by disabled user '[_1]'", $name );
    }
    else {
        $message = $app->translate(
            "Failed login attempt by unknown user '[_1]'", $name );
    }
    $app->log(
        {
            message  => 'AJAXLogin: '.$message,
            level    => MT::Log::WARNING(),
            category => 'login_commenter',
        }
    ) if $message;
    $ctx->{app} ||= $app;
    MT::Auth->invalidate_credentials($ctx);
    my $response = {
        status  => $result,
        message => $error || $app->translate("Invalid login"),
    };
    return $plugin->_send_json_response( $app, $response );
 
}
 
sub _send_json_response {
    my $plugin           = shift;
    my ( $app, $result ) = @_;
    require JSON;
    my $json = JSON::objToJson($result);
    $app->send_http_header("");
    $app->print($json);
    return $app->{no_print_body} = 1;
    return undef;
}

1;
__END__
