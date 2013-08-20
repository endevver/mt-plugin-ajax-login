package MT::Plugin::AJAXLogin;

use strict;
use warnings;
use parent qw( MT::Plugin );

sub ajax_login {
    my $app     = shift;
    my $q       = $app->can('query') ? $app->query : $app->param;
    my $plugin  = $app->component('AJAXLogin');

    my $request = MT::Plugin::AJAXLogin::Request->new(
        map { $_ => $q->param($_) } qw( username blog_id external_auth )
    );

    
    return MT::Plugin::AJAXLogin::Response->new( $request )

    my $name    = $q->param('username');
    my $blog_id = $q->param('blog_id');
    my $blog    = MT->model('blog')->load( $blog_id )
        or return $app->errtrans( 'Can\'t load blog #[_1].', $blog_id );



    $plugin->has_authenticator( $blog )
        or return $plugin->no_authenticator( $name, $blog );

    my $ctx    = $plugin->check_credentials( $app );
    my $result = $ctx->{result};
    my $user   = $app->user;

    return
    $result == MT::Auth::SESSION_EXPIRED();
    $result == MT::Auth::INVALID_PASSWORD();

    my ( $result, $message, $error )
        = $plugin->_process_login( $ctx );

    my $response = {
        status  => $ctx->{result},
        message => $ctx->{error} || $app->translate("Invalid login"),
    };

    return $plugin->_send_json_response( $app, $response );
}

sub _process_login {
    my $app = shift;
    my $q       = $app->can('query') ? $app->query : $app->param;
    my $plugin  = $app->component('AJAXLogin');
    my $name    = $q->param('username');
    my $blog_id = $q->param('blog_id');
    my $blog    = MT->model('blog')->load($blog_id)
        or return $app->errtrans( 'Can\'t load blog #[_1].', $blog_id );

    my ( $message, $error );


    unless ( $plugin->is_ok_login( $result ) ) {
        $message = $result == MT::Auth::INVALID_PASSWORD() ? 'INVALID'
                 : $result == MT::Auth::INACTIVE()         ? 'INACTIVE'
                                                           : 'UNKNOWN'
        $message = $plugin->translate( $message, $name )
    }
    else {
        
    }

    if ( $plugin->is_ok_login( $result ) ) {
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
                        error => $plugin->translate('NO_SIGNUP')
                    ) unless $commenter;
                }
                else {
                    return $app->signup( error => $plugin->translate('SIGNUP') )
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
        $message = $plugin->translate('PERM_DENIED', $name);
    }

    $app->log({
            message  => $message,
            level    => MT::Log::WARNING(),
            category => 'login_commenter',
    });

    $ctx->{app} ||= $app;

    MT::Auth->invalidate_credentials($ctx);


    return ( $result, $message, $error );
}

sub process_terrible_login {
    my ( $plugin, $result, $name ) = @_;

    return $message;
}

sub check_credentials {
    my ( $plugin, $app ) = @_;
    my $q = $app->can('query') ? $app->query : $app->param;

    require MT::Auth;
    my $ctx         = MT::Auth->fetch_credentials( { app => $app } );
    $ctx->{blog_id} = $q->param('blog_id');
    $ctx->{result}  = MT::Auth->validate_credentials($ctx);
    $ctx;
}

sub _send_json_response {
    my ( $plugin, $app, $result ) = @_;
    require JSON;
    my $json = JSON::objToJson($result);
    $app->send_http_header("");
    $app->print($json);
    return $app->{no_print_body} = 1;
    return undef;
}

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

sub is_ok_login {
    my ( $plugin, $result ) = @_;
    return (    ( MT::Auth::NEW_LOGIN() == $result )
             || ( MT::Auth::NEW_USER()  == $result )
             || ( MT::Auth::SUCCESS()   == $result ) ) ? 1 : 0;
            
}

sub messages {
    my ( $plugin, $key, @vals ) = @_;

    my %msgs = (
    return $app->translate( $msgs{$key}, @vals );
}
1;
__END__









sub do_login {
    my $app     = shift;
    my $q       = $app->param;
    my $name    = $q->param('username');
    my $blog_id = $q->param('blog_id');
    my $blog    = MT::Blog->load($blog_id) if ( defined $blog_id );
    my $auths   = $blog->commenter_authenticators if $blog;
    if ( $blog && $auths !~ /MovableType/ ) {
        $app->log(
            {   message => $app->translate(
                    'Invalid commenter login attempt from [_1] to blog [_2](ID: [_3]) which does not allow Movable Type native authentication.',
                    $name, $blog->name, $blog_id
                ),
                level    => MT::Log::WARNING(),
                category => 'login_commenter',
            }
        );
        return $app->login_form( error => $app->translate('Invalid login.') );
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
                return $app->login_form(
                    error => $app->translate('Invalid login') )
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
                    return $app->login_form(
                        error => $app->translate(
                            'Successfully authenticated but signing up is not allowed.  Please contact system administrator.'
                        )
                    ) unless $commenter;
                }
                else {
                    return $app->login_form(
                        error => $app->translate('You need to sign up first.')
                    ) unless $commenter;
                }
            }
        }
        MT::Auth->new_login( $app, $commenter );
        if ( $app->_check_commenter_author( $commenter, $blog_id ) ) {
            my $return_to = $app->commenter_loggedin( $commenter, $blog_id );
            if ( !$return_to ) {
                return $app->load_tmpl(
                    'error.tmpl',
                    {   error              => $app->errstr,
                        hide_goback_button => 1,
                    }
                );
            }

            return $app->redirect($return_to);
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
    return $app->login_form( error => $error
            || $app->translate("Invalid login") );
}
