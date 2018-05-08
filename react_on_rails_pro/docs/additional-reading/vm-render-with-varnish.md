# Using Varnish HTTP cache locally

It is possible to use **Varnish** HTTP cache to avoid repeating rendering requests. It can speed up rendering and reduce load on Node processes.
Unfortunately **Varnish** does not cache `POST` requests by default and supports `POST` requests caching only starting form v5.x.x. So to use renderer with **Varnish** you need to:

1. Install **Varnish v5+**. See [Varnish releases & downloads page](https://varnish-cache.org/releases/index.html) to find installation instructions for your OS.
2. Since **Varnish** does not cache `POST` requests by default, you have to configure it using [VCL](https://www.varnish-cache.org/docs/5.1/users-guide/vcl.html). See [Changes in Varnish 5.0](https://www.varnish-cache.org/docs/5.0/whats-new/changes-5.0.html#request-body-sent-always-cacheable-post) for additional info. Open your **default.vcl** file (usually at **/etc/varnish/default.vcl**) and put this config (replace matching methods if some empty examples already exist):

```sh
# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "3800";
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.

    if (req.method == "PRI") {
	/* We do not support SPDY or HTTP/2.0 */
	return (synth(405));
    }

    if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }

    if (req.method != "GET" && req.method != "HEAD" && req.method != "POST") {
        return (pass);
    }

    if (req.method == "POST") {
	set req.http.x-method = req.method;
    }

    if (req.http.Authorization || req.http.Cookie) {
        /* Not cacheable by default */
        return (pass);
    }

    return (hash);
}

sub vcl_backend_fetch {
    set bereq.method = bereq.http.x-method;
    return (fetch);
}
```

3. Restart/launch your **Varnish** service: `(sudo) service varnish (re)start`
4. Point your Rails client to **Varnish** standart port:

```ruby
ReactOnRailsPro.configure do |config|
  config.renderer_host = "localhost"
  config.renderer_port = 6081
end
```

Currently Rails client prints response headers to console so you should be able to check if **Varnish** caches Reails client requests by inspecting printed `x-varnish` header. For example `:x_varnish=>"37719 37717"` means that **Varnish** returned response from cache (result to your request `#37719` returned from cache created on request `#37717`) and `:x_varnish=>"37721"` (with single id) means request hit Node server. If everything set up correctly you should see cached requests starting form second render of the same page.
