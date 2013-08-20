This plugin provides a JSON interface to theme developers who wish to enable
AJAX logins on their web site. What good is an AJAX login experience you ask?
Well, such an experience would allow for a login form to be presented in a
lightbox, or through some other javascript effect. It would allow your readers
to login to a page without ever leaving the page.

We have provided sample HTML, template code, and javascript to make
integration easier. If you need additional assistance we recommend contacting
a qualified Movable Type consultant.

# Why Use this Plugin?

Movable Type comes with what appears to be an ajax login experience. It
appears this way because when you click "login" on a blog, a little spinner
appears. Spinners mean AJAX right? Well yes. But what is happening is not
logging in. The system MT currently has was developed to assist users who were
accessing multiple blogs across multiple domains all from the same install.
Therefore what is actually happening while the spinner graphic spins is that a
little login gnome goes to the central MT install to see if an active session
exists for the current user. If it does, the session is magically transported
by unicorns to the blog you are on. If there is not, the user is redirected to
a login page.

This plugin on the other hand exposes an interface whereby a user can transmit
a username/password combo to the central install to actually be authenticated.
So if you want to be able to actually log a user in (e.g. enter a username and
password) via a lightbox, or someother form on your page, without requiring
them to go to the main MT install to do so, then this plugin will be required.

# Prerequisites 

This plugin requires a number of components and templates in order to work
properly. Many of these have been bundled and packaged with this plugin and
should be installed for you automatically, provided the necessary
prerequisites are installed.

* Config Assistant 2.0 or greater

You also need to create an index template required by the jquery.mtauth.js
plugin. This template can be called whatever you want. Its output filename is
recommended to be `mt-config.js`.

## MT Config Index Template

This file can also be found in `templates/javascript_mt.mtml`.

    //
    // This file defines blog variables and phrases which are used by 
    // javascript functions.
    //
    var mt;
    mt = {
      cookie: {
        name: "<$mt:UserSessionCookieName$>",
        domain: "<$mt:UserSessionCookieDomain$>",
        path: "<$mt:UserSessionCookiePath$>",
        timeout: <$mt:UserSessionCookieTimeout$>
      },
      links: {
        <mt:ignore>signUp: '<$mt:CGIPath$><$mt:CommunityScript$>?__mode=register&blog_id=<$mt:BlogID$>&return_to=<$mt:BlogURL$>',</mt:ignore>
        signIn: '<$mt:SignInLink$>',
        signOut: '<$mt:SignOutLink$>'
        <mt:ignore>,editProfile: '<$mt:CGIPath$><$mt:CommunityScript$>?__mode=edit&blog_id=<$mt:BlogID$>&return_to=' + encodeURIComponent(document.URL)</mt:ignore>
      },
      blog: {
        id: <$mt:BlogID$>,
        url: '<$mt:BlogURL encode_url="1"$>',
        staticWebPath: '<$mt:StaticWebPath$>',
        adminScript: '<$mt:AdminScript$>',
        comments: {
            script: '<$mt:CGIPath$><$mt:CommentScript$>',
            armor: '<$mt:BlogSitePath encode_sha1="1"$>',
            accepted: <mt:IfCommentsAccepted>1<mt:Else>0</mt:IfCommentsAccepted>,
            captchaFields: '<$mt:CaptchaFields$>'
        },
<mt:ignore>
        community: {
            script: '<$mt:CGIPath$><$mt:CommunityScript$>',
            ifAnonymousRecommendAllowed: <mt:IfAnonymousRecommendAllowed>1<mt:Else>0</mt:IfAnonymousRecommendAllowed>
        },
</mt:ignore>
        pings: {
            accepted: <mt:IfPingsAccepted>1<mt:Else>0</mt:IfPingsAccepted>
        },
        registration: {
            required: <mt:IfRegistrationRequired>1<mt:Else>0</mt:IfRegistrationRequired>,
            allowed: <mt:IfRegistrationAllowed>1<mt:Else>0</mt:IfRegistrationAllowed>
        }
      }
    };

# Known Issues

Here is a list of known issues and things this plugin has not been tested
with:

* This has not been tested against an non-native MT login auth driver (e.g.
  LDAP or otherwise). For these drivers, this plugin is almost certainly not
  going to work in certain circumstances. Please consult Endevver for help.

# JSON Interface

## Input Parameters

* `__mode` - This must be set to `do_ajax_login`.
* `username` - The username of the user logging in.
* `password` - The password of the user logging in.
* `blog_id` - The ID of the blog being logged into.
* `entry_id` - The ID of the entry being logged into in the event that the
  user is on an entry page.

## Output Parameters

* `status` - Either "1" if successful, or "0" otherwise. If 0, then "message"
  will contain helpful debug information to indicate what might have happened.
* `message` - A simple text message returned by the system to indicate what
  happened as a result of trying to login.

## Status Messages

Here is a listing of possible status messages this plugin might return.

* "session created"
* "Login failed: permission denied for user '[_1]'"
* "Login failed: password was wrong for user '[_1]'"
* "Failed login attempt by disabled user '[_1]'"
* "Failed login attempt by unknown user '[_1]'"
* "Invalid login"

# Creating Your Login Form

## HTML

    <form method="post" action="<$mt:AdminCGIPath$><$mt:CommentScript$>" id="login-form" class="logged-out">
      <div class="sign-in">
        <div class="inner pkg">
          <p class="error"></p>
          <input type="hidden" name="__mode" value="do_ajax_login" />
          <input type="hidden" name="blog_id" value="<$mt:BlogID$>" />
          <input type="hidden" name="entry_id" value="<$mt:EntryID$>" />
          <ul class="pkg">
            <li class="pkg"><label>Username</label><br /><input type="text" name="username" /></li>
            <li class="pkg"><label>Password</label><br /><input type="password" name="password" /></li>
            <li class="pkg"><input type="submit" value="Login" class="button" /></li>
          </ul>
        </div>
      </div><!-- //end sign-in -->
    </form>

## jQuery/Javascript

To make this example work, you will need to add the following to your `<html>`
head section:

    <script src="<mt:StaticWebPath>jquery/jquery.js" type="text/javascript"></script>   
    <script type="text/javascript" src="<$mt:StaticWebPath$>jquery/jquery.form.js"></script>
    <script type="text/javascript" src="<$mt:PluginStaticWebPath component="AJAXLogin"$>jquery.mtauth.js"></script>

Then add this in your theme's javascript:

    function signInSubmitHandler(e) {
      var f = $(this);
      var id = f.attr('id');
      $(this).append('<div class="spinner"></div><div class="spinner-status"></div>');
      var spinner_selector = '#'+id+' .spinner, #'+id+' .spinner-status';
      $(this).ajaxSubmit({
        contentType: 'application/x-www-form-urlencoded; charset=utf-8',
        iframe: false,
        type: 'post',
        dataType: 'json',
        clearForm: true,
        beforeSubmit: function(formData, jqForm, options) {
          $(spinner_selector).fadeIn('fast').css('height',f.height());
        },
        success: function(data) {
            if (data.status == 1) {
              alert("User successfully logged in.");
              var u = $.fn.movabletype.fetchUser();
              f.fadeOut('fast',function() { 
                f.parent().find('form.logged-in').fadeIn('fast'); 
              });
            } else {
              alert("login failure");
              $(spinner_selector).fadeOut('fast');
              f.find('p.error').html(data.message).fadeIn('fast');
            }
        }
      });
      return false;
    };
    $(document).ready( function() {
      $('form.logged-out').submit( signInSubmitHandler );
    });

## CSS

This following CSS will help produce the spinner graphic that appears during
login:

*The spinner-login.gif file is packaged with this plugin*

    /* Spinners ---------------------------------------------------------------- */
    #login-form li {
      list-style: none;
    }    
    .spinner,
    .spinner-status {
      display: none;
      position: absolute;
      top: 0;
      left: 0;
      width: 100% !important;
      height: 100% !important;
      background: transparent url(<$mt:PluginStaticWebPath component="AJAXLogin"$>spinner-login.gif) no-repeat center center;
    }
    .spinner {
      filter:alpha(opacity=5);
      -moz-opacity:.5;
      opacity:.5;
      background: #fff;
    }

# Sample Index Template

You can find a complete sample index template to test this plugin out for
yourself. The file is located in `templates/sample_index.mtml`. Install its
contents into an index template you create yourself. The only modification you
will need to make are the changes to necessary to point the web page at the MT
Config Javascript file you also installed. Look for this code:

    <script type="text/javascript" src="<$mt:BlogURL$>mt.js"></script>

And make any changes necessary to have it reference the `mt-config.js` file
you installed separately. Like so perhaps:

    <script type="text/javascript" src="<$mt:BlogURL$>mt-config.js"></script>

# Getting Help

Need help using this plugin? We can help:

   http://help.endevver.com/

# About Endevver

We design and develop web sites, products and services with a focus on 
simplicity, sound design, ease of use and community. We specialize in 
Movable Type and offer numerous services and packages to help customers 
make the most of this powerful publishing platform.

http://www.endevver.com/

# Copyright

Copyright 2010-2011, Endevver, LLC. All rights reserved.

# License

This plugin is licensed under the same terms as Perl itself.
