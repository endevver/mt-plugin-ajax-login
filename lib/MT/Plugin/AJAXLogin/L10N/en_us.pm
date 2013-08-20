package AJAXLogin::L10N::en_us;

use strict;

use base 'AJAXLogin::L10N';
use vars qw( %Lexicon $VIA );

$VIA = 'via AjaxLogin';

%Lexicon = (

    PERM_DENIED => "Login failed: permission denied for user '[_1]' $VIA",
    
    INVALID     => "Login failed: password was wrong for user '[_1]' $VIA",
    
    INACTIVE    => "Failed login attempt by disabled user '[_1]' $VIA",
    
    UNKNOWN     => "Failed login attempt by unknown user '[_1]' $VIA",
    
    SIGNUP      => 'You need to sign up first.',
    
    NO_SIGNUP   => 'Successfully authenticated but signing up is not '
                   . 'allowed.  Please contact system administrator.',
    
    NO_MTAUTH   => 'Invalid commenter login attempt '.$VIA.' by '
                   . '[_1] to blog [_2](ID: [_3]) which does not allow '
                   . 'Movable Type native authentication.',
);

1;