This plugin provides a JSON interface to theme developers who wish to enable AJAX logins on their web site. What good is an AJAX login experience you ask? Well, such an experience would allow for a login form to be presented in a lightbox, or through some other javascript effect. It would allow your readers to login to a page without ever leaving the page.

We have provided sample HTML, template code, and javascript to make integration easier. If you need additional assistance we recommend contacting a qualified Movable Type consultant.

# Known Issues

Here is a list of known issues and things this plugin has not been tested with:

* This has not been tested against an non-native MT login auth driver (e.g. LDAP or otherwise). For these drivers, this plugin is almost certainly not going to work in certain circumstances. Please consult Endevver for help.

# JSON Interface

## Input Parameters

* `__mode` - This must be set to `do_ajax_login`.
* `username` - The username of the user logging in.
* `password` - The password of the user logging in.
* `blog_id` - The ID of the blog being logged into.
* `entry_id` - The ID of the entry being logged into in the event that the user is on an entry page.

## Output Parameters

* `status` - Either "1" if successful, or "0" otherwise. If 0, then "message" will contain helpful debug information to indicate what might have happened.
* `message` - A simple text message returned by the system to indicate what happened as a result of trying to login. 

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
          <p class="forgot"><a href="<$mt:AdminCGIPath$><$mt:CommentScript$>?__mode=start_recover&amp;blog_id=<$mt:BlogID escape="url"$>&amp;return_to=<$mt:EntryPermalink escape="url"$>">Forgot your password?</a></p>
        </div>
      </div><!-- //end sign-in -->
    </form>

## jQuery/Javascript

To make this example work, you will need to add the following to your `<html>` head section:

    <script src="<mt:StaticWebPath>jquery/jquery.js" type="text/javascript"></script>   
    <script type="text/javascript" src="<$mt:StaticWebPath$>jquery/jquery.form.js"></script>

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
              var u = $.fn.movabletype.fetchUser();
              f.fadeOut('fast',function() { f.parent().find('form.logged-in').fadeIn('fast'); });
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

This following CSS will help produce the spinner graphic that appears during login:

*The spinner-login.gif file is packaged with this plugin*

    /* Spinners ---------------------------------------------------------------- */
    
    .spinner,
    .spinner-status {
      display: none;
      position: absolute;
      top: 0;
      left: 0;
      width: 100% !important;
      height: 100% !important;
      background: transparent url(../images/spinner-login.gif) no-repeat center center;
    }
    .spinner {
      filter:alpha(opacity=5);
      -moz-opacity:.5;
      opacity:.5;
      background: #fff;
    }

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

Copyright 2010, Endevver, LLC. All rights reserved.

# License

This plugin is licensed under the same terms as Perl itself.