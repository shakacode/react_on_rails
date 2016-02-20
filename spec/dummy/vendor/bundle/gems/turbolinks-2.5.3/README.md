Turbolinks
===========

Turbolinks makes following links in your web application faster. Instead of letting the browser recompile the JavaScript and CSS between each page change, it keeps the current page instance alive and replaces only the body and the title in the head. Think CGI vs persistent process.

This is similar to [pjax](https://github.com/defunkt/jquery-pjax), but instead of worrying about what element on the page to replace, and tailoring the server-side response to fit, we replace the entire body. This means that you get the bulk of the speed benefits from pjax (no recompiling of the JavaScript or CSS) without having to tailor the server-side response. It just works.

Do note that this of course means that you'll have a long-running, persistent session with maintained state. That's what's making it so fast. But it also means that you may have to pay additional care not to leak memory or otherwise bloat that long-running state. That should rarely be a problem unless you're doing something really funky, but you do have to be aware of it. Your memory leaking sins will not be swept away automatically by the cleansing page change any more.


How much faster is it really?
-----------------------------

It depends. The more CSS and JavaScript you have, the bigger the benefit of not throwing away the browser instance and recompiling all of it for every page. Just like a CGI script that says "hello world" will be fast, but a CGI script loading Rails on every request will not.

In any case, the benefit can be up to [twice as fast](https://github.com/steveklabnik/turbolinks_test/tree/all_the_assets) in apps with lots of JS and CSS. Of course, your mileage may vary, be dependent on your browser version, the moon cycle, and all other factors affecting performance testing. But at least it's a yardstick.

The best way to find out just how fast it is? Try it on your own application. It hardly takes any effort at all.


No jQuery or any other library
--------------------------------

Turbolinks is designed to be as light-weight as possible (so you won't think twice about using it even for mobile stuff). It does not require jQuery or any other library to work. But it works great _with_ the jQuery or Prototype framework, or whatever else have you.


Events
------

With Turbolinks pages will change without a full reload, so you can't rely on `DOMContentLoaded` or `jQuery.ready()` to trigger your code. Instead Turbolinks fires events on `document` to provide hooks into the lifecycle of the page.

***Load* a fresh version of a page from the server:**
* `page:before-change` a Turbolinks-enabled link has been clicked *(see below for more details)*
* `page:fetch` starting to fetch a new target page
* `page:receive` the page has been fetched from the server, but not yet parsed
* `page:before-unload` the page has been parsed and is about to be changed
* `page:change` the page has been changed to the new version (and on DOMContentLoaded)
* `page:update` is triggered alongside both page:change and jQuery's ajaxSuccess (if jQuery is available - otherwise you can manually trigger it when calling XMLHttpRequest in your own code)
* `page:load` is fired at the end of the loading process.

Handlers bound to the `page:before-change` event may return `false`, which will cancel the Turbolinks process.

By default, Turbolinks caches 10 of these page loads. It listens to the [popstate](https://developer.mozilla.org/en-US/docs/DOM/Manipulating_the_browser_history#The_popstate_event) event and attempts to restore page state from the cache when it's triggered. When `popstate` is fired the following process happens:

***Restore* a cached page from the client-side cache:**
* `page:before-unload` page has been fetched from the cache and is about to be changed
* `page:change` page has changed to the cached page.
* `page:restore` is fired at the end of restore process.

The number of pages Turbolinks caches can be configured to suit your application's needs:

```javascript
// View the current cache size
Turbolinks.pagesCached();

// Set the cache size
Turbolinks.pagesCached(20);
```

When a page is removed from the cache due to the cache reaching its size limit, the `page:expire` event is triggered.  Listeners bound to this event can access the cached page object using `event.originalEvent.data`.  Keys of note for this page cache object include `url`, `body`, and `title`.  

To implement a client-side spinner, you could listen for `page:fetch` to start it and `page:receive` to stop it.

```javascript
// using jQuery for simplicity
    
$(document).on("page:fetch", startSpinner);
$(document).on("page:receive", stopSpinner);
```

DOM transformations that are idempotent are best. If you have transformations that are not, bind them to `page:load` (in addition to the initial page load) instead of `page:change` (as that would run them again on the cached pages):

```javascript
// using jQuery for simplicity

$(document).on("ready page:load", nonIdempotentFunction);
```

Transition Cache: A Speed Boost
-------------------------------

Transition Cache, added in v2.2.0, makes loading cached pages instantaneous. Once a user has visited a page, returning later to the page results in an instant load.

For example, if Page A is already cached by Turbolinks and you are on Page B, clicking a link to Page A will *immediately* display the cached copy of Page A. Turbolinks will then fetch Page A from the server and replace the cached page once the new copy is returned.

To enable Transition Cache, include the following in your javascript:
```javascript
Turbolinks.enableTransitionCache();
```

The one drawback is that dramatic differences in appearance between a cached copy and new copy may lead to a jarring affect for the end-user. This will be especially true for pages that have many moving parts (expandable sections, sortable tables, infinite scrolling, etc.).

If you find that a page is causing problems, you can have Turbolinks skip displaying the cached copy by adding `data-no-transition-cache` to any DOM element on the offending page.

Progress Bar
------------

Because Turbolinks skips the traditional full page reload, browsers won't display their native progress bar when changing pages. To fill this void, Turbolinks offers an optional JavaScript-and-CSS-based progress bar to display page loading progress.

To enable the progress bar, include the following in your JavaScript:
```javascript
Turbolinks.enableProgressBar();
```

The progress bar is implemented on the `<html>` element's pseudo `:before` element and can be **customized** by including CSS with higher specificity than the included styles. For example:

```css
html.turbolinks-progress-bar::before {
  background-color: red !important;
  height: 5px !important;
}
```

In Turbolinks 3.0, the progress bar will be turned on by default.


Initialization
--------------

Turbolinks will be enabled **only** if the server has rendered a `GET` request.

Some examples, given a standard RESTful resource:

* `POST :create` => resource successfully created => redirect to `GET :show`
  * Turbolinks **ENABLED**
* `POST :create` => resource creation failed => render `:new`
  * Turbolinks **DISABLED**

**Why not all request types?** Some browsers track the request method of each page load, but triggering pushState methods don't change this value.  This could lead to the situation where pressing the browser's reload button on a page that was fetched with Turbolinks would attempt a `POST` (or something other than `GET`) because the last full page load used that method.


Opting out of Turbolinks
------------------------

By default, all internal HTML links will be funneled through Turbolinks, but you can opt out by marking links or their parent container with `data-no-turbolink`. For example, if you mark a div with `data-no-turbolink`, then all links inside of that div will be treated as regular links. If you mark the body, every link on that entire page will be treated as regular links.

```html
<a href="/">Home (via Turbolinks)</a>
<div id="some-div" data-no-turbolink>
  <a href="/">Home (without Turbolinks)</a>
</div>
```

Note that internal links to files containing a file extension other than **.html** will automatically be opted out of Turbolinks. So links to /images/panda.gif will just work as expected.  To whitelist additional file extensions to be processed by Turbolinks, use `Turbolinks.allowLinkExtensions()`.

```javascript
Turbolinks.allowLinkExtensions();                 // => ['html']
Turbolinks.allowLinkExtensions('md');             // => ['html', 'md']
Turbolinks.allowLinkExtensions('coffee', 'scss'); // => ['html', 'md', 'coffee', 'scss']
```

Also, Turbolinks is installed as the last click handler for links. So if you install another handler that calls event.preventDefault(), Turbolinks will not run. This ensures that you can safely use Turbolinks with stuff like `data-method`, `data-remote`, or `data-confirm` from Rails.


jquery.turbolinks
-----------------

If you have a lot of existing JavaScript that binds elements on jQuery.ready(), you can pull the [jquery.turbolinks](https://github.com/kossnocorp/jquery.turbolinks) library into your project that will trigger ready() when Turbolinks triggers the `page:load` event. It may restore functionality of some libraries.

Add the gem to your project, then add the following line to your JavaScript manifest file, after `jquery.js` but before `turbolinks.js`:

``` js
//= require jquery.turbolinks
```

Additional details and configuration options can be found in the [jquery.turbolinks README](https://github.com/kossnocorp/jquery.turbolinks/blob/master/README.md).

Asset change detection
----------------------

You can track certain assets, like application.js and application.css, that you want to ensure are always of the latest version inside a Turbolinks session. This is done by marking those asset links with data-turbolinks-track, like so:

```html
<link href="/assets/application-9bd64a86adb3cd9ab3b16e9dca67a33a.css" rel="stylesheet"
      type="text/css" data-turbolinks-track>
```

If those assets change URLs (embed an md5 stamp to ensure this), the page will do a full reload instead of going through Turbolinks. This ensures that all Turbolinks sessions will always be running off your latest JavaScript and CSS.

When this happens, you'll technically be requesting the same page twice. Once through Turbolinks to detect that the assets changed, and then again when we do a full redirect to that page.


Evaluating script tags
----------------------

Turbolinks will evaluate any script tags in pages it visits, if those tags do not have a type or if the type is text/javascript. All other script tags will be ignored.

As a rule of thumb when switching to Turbolinks, move all of your javascript tags inside the `head` and then work backwards, only moving javascript code back to the body if absolutely necessary. If you have any script tags in the body you do not want to be re-evaluated then you can set the `data-turbolinks-eval` attribute to `false`:

```html
<script type="text/javascript" data-turbolinks-eval=false>
  console.log("I'm only run once on the initial page load");
</script>
```

Triggering a Turbolinks visit manually
---------------------------------------

You can use `Turbolinks.visit(path)` to go to a URL through Turbolinks.

You can also use `redirect_via_turbolinks_to` in Rails to perform a redirect via Turbolinks.


Full speed for pushState browsers, graceful fallback for everything else
------------------------------------------------------------------------

Like pjax, this naturally only works with browsers capable of pushState. But of course we fall back gracefully to full page reloads for browsers that do not support it.


Compatibility
-------------

Turbolinks is designed to work with any browser that fully supports pushState and all the related APIs. This includes Safari 6.0+ (but not Safari 5.1.x!), IE10, and latest Chromes and Firefoxes.

Do note that existing JavaScript libraries may not all be compatible with Turbolinks out of the box due to the change in instantiation cycle. You might very well have to modify them to work with Turbolinks' new set of events.  For help with this, check out the [Turbolinks Compatibility](http://reed.github.io/turbolinks-compatibility) project.


Installation
------------

1. Add `gem 'turbolinks'` to your Gemfile.
1. Run `bundle install`.
1. Add `//= require turbolinks` to your Javascript manifest file (usually found at `app/assets/javascripts/application.js`). If your manifest requires both turbolinks and jQuery, make sure turbolinks is listed *after* jQuery.
1. Restart your server and you're now using turbolinks!

Language Ports
--------------

*These projects are not affiliated with or endorsed by the Rails Turbolinks team.*

* [Flask Turbolinks](https://github.com/lepture/flask-turbolinks) (Python Flask)
* [Django Turbolinks](https://github.com/dgladkov/django-turbolinks) (Python Django)
* [ASP.NET MVC Turbolinks](https://github.com/kazimanzurrashid/aspnetmvcturbolinks)
* [PHP Turbolinks Component](https://github.com/helthe/Turbolinks) (Symfony Component)
* [PHP Turbolinks Package](https://github.com/frenzyapp/turbolinks) (Laravel Package)
* [Grails Turbolinks](http://grails.org/plugin/turbolinks) (Grails Plugin)

Credits
-------

Thanks to Chris Wanstrath for his original work on Pjax. Thanks to Sam Stephenson and Josh Peek for their additional work on Pjax and Stacker and their help with getting Turbolinks released. Thanks to David Estes and Nick Reed for handling the lion's share of post-release issues and feature requests. And thanks to everyone else who's fixed or reported an issue!
