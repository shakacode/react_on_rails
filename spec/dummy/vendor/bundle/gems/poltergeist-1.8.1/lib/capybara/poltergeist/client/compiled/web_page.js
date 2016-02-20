var slice = [].slice,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Poltergeist.WebPage = (function() {
  var command, delegate, fn1, fn2, i, j, len, len1, ref, ref1;

  WebPage.CALLBACKS = ['onConsoleMessage', 'onError', 'onLoadFinished', 'onInitialized', 'onLoadStarted', 'onResourceRequested', 'onResourceReceived', 'onResourceError', 'onNavigationRequested', 'onUrlChanged', 'onPageCreated', 'onClosing'];

  WebPage.DELEGATES = ['open', 'sendEvent', 'uploadFile', 'release', 'render', 'renderBase64', 'goBack', 'goForward'];

  WebPage.COMMANDS = ['currentUrl', 'find', 'nodeCall', 'documentSize', 'beforeUpload', 'afterUpload', 'clearLocalStorage'];

  WebPage.EXTENSIONS = [];

  function WebPage(_native) {
    var callback, i, len, ref;
    this._native = _native;
    this._native || (this._native = require('webpage').create());
    this.id = 0;
    this.source = null;
    this.closed = false;
    this.state = 'default';
    this.urlBlacklist = [];
    this.frames = [];
    this.errors = [];
    this._networkTraffic = {};
    this._tempHeaders = {};
    this._blockedUrls = [];
    ref = WebPage.CALLBACKS;
    for (i = 0, len = ref.length; i < len; i++) {
      callback = ref[i];
      this.bindCallback(callback);
    }
  }

  ref = WebPage.COMMANDS;
  fn1 = function(command) {
    return WebPage.prototype[command] = function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return this.runCommand(command, args);
    };
  };
  for (i = 0, len = ref.length; i < len; i++) {
    command = ref[i];
    fn1(command);
  }

  ref1 = WebPage.DELEGATES;
  fn2 = function(delegate) {
    return WebPage.prototype[delegate] = function() {
      return this._native[delegate].apply(this._native, arguments);
    };
  };
  for (j = 0, len1 = ref1.length; j < len1; j++) {
    delegate = ref1[j];
    fn2(delegate);
  }

  WebPage.prototype.onInitializedNative = function() {
    this.id += 1;
    this.source = null;
    this.injectAgent();
    this.removeTempHeaders();
    return this.setScrollPosition({
      left: 0,
      top: 0
    });
  };

  WebPage.prototype.onClosingNative = function() {
    this.handle = null;
    return this.closed = true;
  };

  WebPage.prototype.onConsoleMessageNative = function(message) {
    if (message === '__DOMContentLoaded') {
      this.source = this._native.content;
      return false;
    } else {
      return console.log(message);
    }
  };

  WebPage.prototype.onLoadStartedNative = function() {
    this.state = 'loading';
    return this.requestId = this.lastRequestId;
  };

  WebPage.prototype.onLoadFinishedNative = function(status) {
    this.status = status;
    this.state = 'default';
    return this.source || (this.source = this._native.content);
  };

  WebPage.prototype.onErrorNative = function(message, stack) {
    var stackString;
    stackString = message;
    stack.forEach(function(frame) {
      stackString += "\n";
      stackString += "    at " + frame.file + ":" + frame.line;
      if (frame["function"] && frame["function"] !== '') {
        return stackString += " in " + frame["function"];
      }
    });
    this.errors.push({
      message: message,
      stack: stackString
    });
    return true;
  };

  WebPage.prototype.onResourceRequestedNative = function(request, net) {
    var abort, ref2;
    abort = this.urlBlacklist.some(function(blacklisted_url) {
      return request.url.indexOf(blacklisted_url) !== -1;
    });
    if (abort) {
      if (ref2 = request.url, indexOf.call(this._blockedUrls, ref2) < 0) {
        this._blockedUrls.push(request.url);
      }
      net.abort();
    } else {
      this.lastRequestId = request.id;
      if (this.normalizeURL(request.url) === this.redirectURL) {
        this.redirectURL = null;
        this.requestId = request.id;
      }
      this._networkTraffic[request.id] = {
        request: request,
        responseParts: [],
        error: null
      };
    }
    return true;
  };

  WebPage.prototype.onResourceReceivedNative = function(response) {
    var ref2;
    if ((ref2 = this._networkTraffic[response.id]) != null) {
      ref2.responseParts.push(response);
    }
    if (this.requestId === response.id) {
      if (response.redirectURL) {
        this.redirectURL = this.normalizeURL(response.redirectURL);
      } else {
        this.statusCode = response.status;
        this._responseHeaders = response.headers;
      }
    }
    return true;
  };

  WebPage.prototype.onResourceErrorNative = function(errorResponse) {
    var ref2;
    if ((ref2 = this._networkTraffic[errorResponse.id]) != null) {
      ref2.error = errorResponse;
    }
    return true;
  };

  WebPage.prototype.injectAgent = function() {
    var extension, k, len2, ref2;
    if (this["native"]().evaluate(function() {
      return typeof __poltergeist;
    }) === "undefined") {
      this["native"]().injectJs(phantom.libraryPath + "/agent.js");
      ref2 = WebPage.EXTENSIONS;
      for (k = 0, len2 = ref2.length; k < len2; k++) {
        extension = ref2[k];
        this["native"]().injectJs(extension);
      }
      return true;
    }
    return false;
  };

  WebPage.prototype.injectExtension = function(file) {
    WebPage.EXTENSIONS.push(file);
    return this["native"]().injectJs(file);
  };

  WebPage.prototype["native"] = function() {
    if (this.closed) {
      throw new Poltergeist.NoSuchWindowError;
    } else {
      return this._native;
    }
  };

  WebPage.prototype.windowName = function() {
    return this["native"]().windowName;
  };

  WebPage.prototype.keyCode = function(name) {
    return this["native"]().event.key[name];
  };

  WebPage.prototype.keyModifierCode = function(names) {
    var modifiers;
    modifiers = this["native"]().event.modifier;
    names = names.split(',').map((function(name) {
      return modifiers[name];
    }));
    return names[0] | names[1];
  };

  WebPage.prototype.keyModifierKeys = function(names) {
    return names.split(',').map((function(_this) {
      return function(name) {
        return _this.keyCode(name.charAt(0).toUpperCase() + name.substring(1));
      };
    })(this));
  };

  WebPage.prototype.waitState = function(state, callback) {
    if (this.state === state) {
      return callback.call();
    } else {
      return setTimeout(((function(_this) {
        return function() {
          return _this.waitState(state, callback);
        };
      })(this)), 100);
    }
  };

  WebPage.prototype.setHttpAuth = function(user, password) {
    this["native"]().settings.userName = user;
    this["native"]().settings.password = password;
    return true;
  };

  WebPage.prototype.networkTraffic = function() {
    return this._networkTraffic;
  };

  WebPage.prototype.clearNetworkTraffic = function() {
    this._networkTraffic = {};
    return true;
  };

  WebPage.prototype.blockedUrls = function() {
    return this._blockedUrls;
  };

  WebPage.prototype.clearBlockedUrls = function() {
    this._blockedUrls = [];
    return true;
  };

  WebPage.prototype.content = function() {
    return this["native"]().frameContent;
  };

  WebPage.prototype.title = function() {
    return this["native"]().frameTitle;
  };

  WebPage.prototype.frameUrl = function(frameNameOrId) {
    var query;
    query = function(frameNameOrId) {
      var ref2;
      return (ref2 = document.querySelector("iframe[name='" + frameNameOrId + "'], iframe[id='" + frameNameOrId + "']")) != null ? ref2.src : void 0;
    };
    return this.evaluate(query, frameNameOrId);
  };

  WebPage.prototype.clearErrors = function() {
    this.errors = [];
    return true;
  };

  WebPage.prototype.responseHeaders = function() {
    var headers;
    headers = {};
    this._responseHeaders.forEach(function(item) {
      return headers[item.name] = item.value;
    });
    return headers;
  };

  WebPage.prototype.cookies = function() {
    return this["native"]().cookies;
  };

  WebPage.prototype.deleteCookie = function(name) {
    return this["native"]().deleteCookie(name);
  };

  WebPage.prototype.viewportSize = function() {
    return this["native"]().viewportSize;
  };

  WebPage.prototype.setViewportSize = function(size) {
    return this["native"]().viewportSize = size;
  };

  WebPage.prototype.setZoomFactor = function(zoom_factor) {
    return this["native"]().zoomFactor = zoom_factor;
  };

  WebPage.prototype.setPaperSize = function(size) {
    return this["native"]().paperSize = size;
  };

  WebPage.prototype.scrollPosition = function() {
    return this["native"]().scrollPosition;
  };

  WebPage.prototype.setScrollPosition = function(pos) {
    return this["native"]().scrollPosition = pos;
  };

  WebPage.prototype.clipRect = function() {
    return this["native"]().clipRect;
  };

  WebPage.prototype.setClipRect = function(rect) {
    return this["native"]().clipRect = rect;
  };

  WebPage.prototype.elementBounds = function(selector) {
    return this["native"]().evaluate(function(selector) {
      return document.querySelector(selector).getBoundingClientRect();
    }, selector);
  };

  WebPage.prototype.setUserAgent = function(userAgent) {
    return this["native"]().settings.userAgent = userAgent;
  };

  WebPage.prototype.getCustomHeaders = function() {
    return this["native"]().customHeaders;
  };

  WebPage.prototype.setCustomHeaders = function(headers) {
    return this["native"]().customHeaders = headers;
  };

  WebPage.prototype.addTempHeader = function(header) {
    var name, value;
    for (name in header) {
      value = header[name];
      this._tempHeaders[name] = value;
    }
    return this._tempHeaders;
  };

  WebPage.prototype.removeTempHeaders = function() {
    var allHeaders, name, ref2, value;
    allHeaders = this.getCustomHeaders();
    ref2 = this._tempHeaders;
    for (name in ref2) {
      value = ref2[name];
      delete allHeaders[name];
    }
    return this.setCustomHeaders(allHeaders);
  };

  WebPage.prototype.pushFrame = function(name) {
    var frame_no;
    if (this["native"]().switchToFrame(name)) {
      this.frames.push(name);
      return true;
    } else {
      frame_no = this["native"]().evaluate(function(frame_name) {
        var f, frames, idx;
        frames = document.querySelectorAll("iframe, frame");
        return ((function() {
          var k, len2, results;
          results = [];
          for (idx = k = 0, len2 = frames.length; k < len2; idx = ++k) {
            f = frames[idx];
            if ((f != null ? f['name'] : void 0) === frame_name || (f != null ? f['id'] : void 0) === frame_name) {
              results.push(idx);
            }
          }
          return results;
        })())[0];
      }, name);
      if ((frame_no != null) && this["native"]().switchToFrame(frame_no)) {
        this.frames.push(name);
        return true;
      } else {
        return false;
      }
    }
  };

  WebPage.prototype.popFrame = function() {
    this.frames.pop();
    return this["native"]().switchToParentFrame();
  };

  WebPage.prototype.dimensions = function() {
    var scroll, viewport;
    scroll = this.scrollPosition();
    viewport = this.viewportSize();
    return {
      top: scroll.top,
      bottom: scroll.top + viewport.height,
      left: scroll.left,
      right: scroll.left + viewport.width,
      viewport: viewport,
      document: this.documentSize()
    };
  };

  WebPage.prototype.validatedDimensions = function() {
    var dimensions, document;
    dimensions = this.dimensions();
    document = dimensions.document;
    if (dimensions.right > document.width) {
      dimensions.left = Math.max(0, dimensions.left - (dimensions.right - document.width));
      dimensions.right = document.width;
    }
    if (dimensions.bottom > document.height) {
      dimensions.top = Math.max(0, dimensions.top - (dimensions.bottom - document.height));
      dimensions.bottom = document.height;
    }
    this.setScrollPosition({
      left: dimensions.left,
      top: dimensions.top
    });
    return dimensions;
  };

  WebPage.prototype.get = function(id) {
    return new Poltergeist.Node(this, id);
  };

  WebPage.prototype.mouseEvent = function(name, x, y, button) {
    if (button == null) {
      button = 'left';
    }
    this.sendEvent('mousemove', x, y);
    return this.sendEvent(name, x, y, button);
  };

  WebPage.prototype.evaluate = function() {
    var args, fn;
    fn = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    this.injectAgent();
    return JSON.parse(this.sanitize(this["native"]().evaluate("function() { return PoltergeistAgent.stringify(" + (this.stringifyCall(fn, args)) + ") }")));
  };

  WebPage.prototype.sanitize = function(potential_string) {
    if (typeof potential_string === "string") {
      return potential_string.replace("\n", "\\n").replace("\r", "\\r");
    } else {
      return potential_string;
    }
  };

  WebPage.prototype.execute = function() {
    var args, fn;
    fn = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    return this["native"]().evaluate("function() { " + (this.stringifyCall(fn, args)) + " }");
  };

  WebPage.prototype.stringifyCall = function(fn, args) {
    if (args.length === 0) {
      return "(" + (fn.toString()) + ")()";
    } else {
      return "(" + (fn.toString()) + ").apply(this, PoltergeistAgent.JSON.parse(" + (JSON.stringify(JSON.stringify(args))) + "))";
    }
  };

  WebPage.prototype.bindCallback = function(name) {
    var that;
    that = this;
    this["native"]()[name] = function() {
      var result;
      if (that[name + 'Native'] != null) {
        result = that[name + 'Native'].apply(that, arguments);
      }
      if (result !== false && (that[name] != null)) {
        return that[name].apply(that, arguments);
      }
    };
    return true;
  };

  WebPage.prototype.runCommand = function(name, args) {
    var method, result, selector;
    result = this.evaluate(function(name, args) {
      return __poltergeist.externalCall(name, args);
    }, name, args);
    if (result !== null) {
      if (result.error != null) {
        switch (result.error.message) {
          case 'PoltergeistAgent.ObsoleteNode':
            throw new Poltergeist.ObsoleteNode;
            break;
          case 'PoltergeistAgent.InvalidSelector':
            method = args[0], selector = args[1];
            throw new Poltergeist.InvalidSelector(method, selector);
            break;
          default:
            throw new Poltergeist.BrowserError(result.error.message, result.error.stack);
        }
      } else {
        return result.value;
      }
    }
  };

  WebPage.prototype.canGoBack = function() {
    return this["native"]().canGoBack;
  };

  WebPage.prototype.canGoForward = function() {
    return this["native"]().canGoForward;
  };

  WebPage.prototype.normalizeURL = function(url) {
    var parser;
    parser = document.createElement('a');
    parser.href = url;
    return parser.href;
  };

  return WebPage;

})();
