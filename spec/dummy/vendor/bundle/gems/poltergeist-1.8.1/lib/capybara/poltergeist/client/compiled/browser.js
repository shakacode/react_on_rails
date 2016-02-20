var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Poltergeist.Browser = (function() {
  function Browser(width, height) {
    this.width = width || 1024;
    this.height = height || 768;
    this.pages = [];
    this.js_errors = true;
    this._debug = false;
    this._counter = 0;
    this.processed_modal_messages = [];
    this.confirm_processes = [];
    this.prompt_responses = [];
    this.resetPage();
  }

  Browser.prototype.resetPage = function() {
    var ref;
    ref = [0, []], this._counter = ref[0], this.pages = ref[1];
    if (this.page != null) {
      if (!this.page.closed) {
        if (this.page.currentUrl() !== 'about:blank') {
          this.page.clearLocalStorage();
        }
        this.page.release();
      }
      phantom.clearCookies();
    }
    this.page = this.currentPage = new Poltergeist.WebPage;
    this.page.setViewportSize({
      width: this.width,
      height: this.height
    });
    this.page.handle = "" + (this._counter++);
    this.pages.push(this.page);
    this.processed_modal_messages = [];
    this.confirm_processes = [];
    this.prompt_responses = [];
    this.page["native"]().onAlert = (function(_this) {
      return function(msg) {
        _this.setModalMessage(msg);
      };
    })(this);
    this.page["native"]().onConfirm = (function(_this) {
      return function(msg) {
        var process;
        process = _this.confirm_processes.pop();
        if (process === void 0) {
          process = true;
        }
        _this.setModalMessage(msg);
        return process;
      };
    })(this);
    this.page["native"]().onPrompt = (function(_this) {
      return function(msg, defaultVal) {
        var response;
        response = _this.prompt_responses.pop();
        if (response === void 0 || response === false) {
          response = defaultVal;
        }
        _this.setModalMessage(msg);
        return response;
      };
    })(this);
    this.page.onPageCreated = (function(_this) {
      return function(newPage) {
        var page;
        page = new Poltergeist.WebPage(newPage);
        page.handle = "" + (_this._counter++);
        return _this.pages.push(page);
      };
    })(this);
  };

  Browser.prototype.getPageByHandle = function(handle) {
    return this.pages.filter(function(p) {
      return !p.closed && p.handle === handle;
    })[0];
  };

  Browser.prototype.runCommand = function(command) {
    this.current_command = command;
    this.currentPage.state = 'default';
    return this[command.name].apply(this, command.args);
  };

  Browser.prototype.debug = function(message) {
    if (this._debug) {
      return console.log("poltergeist [" + (new Date().getTime()) + "] " + message);
    }
  };

  Browser.prototype.setModalMessage = function(msg) {
    this.processed_modal_messages.push(msg);
  };

  Browser.prototype.add_extension = function(extension) {
    this.currentPage.injectExtension(extension);
    return this.current_command.sendResponse('success');
  };

  Browser.prototype.node = function(page_id, id) {
    if (this.currentPage.id === page_id) {
      return this.currentPage.get(id);
    } else {
      throw new Poltergeist.ObsoleteNode;
    }
  };

  Browser.prototype.visit = function(url) {
    var command, prevUrl;
    this.currentPage.state = 'loading';
    this.processed_modal_messages = [];
    this.confirm_processes = [];
    this.prompt_responses = [];
    prevUrl = this.currentPage.source === null ? 'about:blank' : this.currentPage.currentUrl();
    this.currentPage.open(url);
    if (/#/.test(url) && prevUrl.split('#')[0] === url.split('#')[0]) {
      this.currentPage.state = 'default';
      return this.current_command.sendResponse({
        status: 'success'
      });
    } else {
      command = this.current_command;
      this.currentPage.waitState('default', (function(_this) {
        return function() {
          if (_this.currentPage.statusCode === null && _this.currentPage.status === 'fail') {
            return command.sendError(new Poltergeist.StatusFailError(url));
          } else {
            return command.sendResponse({
              status: _this.currentPage.status
            });
          }
        };
      })(this));
    }
  };

  Browser.prototype.current_url = function() {
    return this.current_command.sendResponse(this.currentPage.currentUrl());
  };

  Browser.prototype.status_code = function() {
    return this.current_command.sendResponse(this.currentPage.statusCode);
  };

  Browser.prototype.body = function() {
    return this.current_command.sendResponse(this.currentPage.content());
  };

  Browser.prototype.source = function() {
    return this.current_command.sendResponse(this.currentPage.source);
  };

  Browser.prototype.title = function() {
    return this.current_command.sendResponse(this.currentPage.title());
  };

  Browser.prototype.find = function(method, selector) {
    return this.current_command.sendResponse({
      page_id: this.currentPage.id,
      ids: this.currentPage.find(method, selector)
    });
  };

  Browser.prototype.find_within = function(page_id, id, method, selector) {
    return this.current_command.sendResponse(this.node(page_id, id).find(method, selector));
  };

  Browser.prototype.all_text = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).allText());
  };

  Browser.prototype.visible_text = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).visibleText());
  };

  Browser.prototype.delete_text = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).deleteText());
  };

  Browser.prototype.property = function(page_id, id, name) {
    return this.current_command.sendResponse(this.node(page_id, id).getProperty(name));
  };

  Browser.prototype.attribute = function(page_id, id, name) {
    return this.current_command.sendResponse(this.node(page_id, id).getAttribute(name));
  };

  Browser.prototype.attributes = function(page_id, id, name) {
    return this.current_command.sendResponse(this.node(page_id, id).getAttributes());
  };

  Browser.prototype.parents = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).parentIds());
  };

  Browser.prototype.value = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).value());
  };

  Browser.prototype.set = function(page_id, id, value) {
    this.node(page_id, id).set(value);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.select_file = function(page_id, id, value) {
    var node;
    node = this.node(page_id, id);
    this.currentPage.beforeUpload(node.id);
    this.currentPage.uploadFile('[_poltergeist_selected]', value);
    this.currentPage.afterUpload(node.id);
    if (phantom.version.major === 2) {
      return this.click(page_id, id);
    } else {
      return this.current_command.sendResponse(true);
    }
  };

  Browser.prototype.select = function(page_id, id, value) {
    return this.current_command.sendResponse(this.node(page_id, id).select(value));
  };

  Browser.prototype.tag_name = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).tagName());
  };

  Browser.prototype.visible = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).isVisible());
  };

  Browser.prototype.disabled = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).isDisabled());
  };

  Browser.prototype.path = function(page_id, id) {
    return this.current_command.sendResponse(this.node(page_id, id).path());
  };

  Browser.prototype.evaluate = function(script) {
    return this.current_command.sendResponse(this.currentPage.evaluate("function() { return " + script + " }"));
  };

  Browser.prototype.execute = function(script) {
    this.currentPage.execute("function() { " + script + " }");
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.frameUrl = function(frame_name) {
    return this.currentPage.frameUrl(frame_name);
  };

  Browser.prototype.pushFrame = function(command, name, timeout) {
    var frame, ref;
    if (Array.isArray(name)) {
      frame = this.node.apply(this, name);
      name = frame.getAttribute('name') || frame.getAttribute('id');
      if (!name) {
        frame.setAttribute('name', "_random_name_" + (new Date().getTime()));
        name = frame.getAttribute('name');
      }
    }
    if (ref = this.frameUrl(name), indexOf.call(this.currentPage.blockedUrls(), ref) >= 0) {
      return command.sendResponse(true);
    } else if (this.currentPage.pushFrame(name)) {
      if (this.currentPage.currentUrl() === 'about:blank') {
        this.currentPage.state = 'awaiting_frame_load';
        return this.currentPage.waitState('default', (function(_this) {
          return function() {
            return command.sendResponse(true);
          };
        })(this));
      } else {
        return command.sendResponse(true);
      }
    } else {
      if (new Date().getTime() < timeout) {
        return setTimeout(((function(_this) {
          return function() {
            return _this.pushFrame(command, name, timeout);
          };
        })(this)), 50);
      } else {
        return command.sendError(new Poltergeist.FrameNotFound(name));
      }
    }
  };

  Browser.prototype.push_frame = function(name, timeout) {
    if (timeout == null) {
      timeout = (new Date().getTime()) + 2000;
    }
    return this.pushFrame(this.current_command, name, timeout);
  };

  Browser.prototype.pop_frame = function() {
    return this.current_command.sendResponse(this.currentPage.popFrame());
  };

  Browser.prototype.window_handles = function() {
    var handles;
    handles = this.pages.filter(function(p) {
      return !p.closed;
    }).map(function(p) {
      return p.handle;
    });
    return this.current_command.sendResponse(handles);
  };

  Browser.prototype.window_handle = function(name) {
    var handle, page;
    if (name == null) {
      name = null;
    }
    handle = name ? (page = this.pages.filter(function(p) {
      return !p.closed && p.windowName() === name;
    })[0], page ? page.handle : null) : this.currentPage.handle;
    return this.current_command.sendResponse(handle);
  };

  Browser.prototype.switch_to_window = function(handle) {
    var command, page;
    command = this.current_command;
    page = this.getPageByHandle(handle);
    if (page) {
      if (page !== this.currentPage) {
        return page.waitState('default', (function(_this) {
          return function() {
            _this.currentPage = page;
            return command.sendResponse(true);
          };
        })(this));
      } else {
        return command.sendResponse(true);
      }
    } else {
      throw new Poltergeist.NoSuchWindowError;
    }
  };

  Browser.prototype.open_new_window = function() {
    this.execute('window.open()');
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.close_window = function(handle) {
    var page;
    page = this.getPageByHandle(handle);
    if (page) {
      page.release();
      return this.current_command.sendResponse(true);
    } else {
      return this.current_command.sendResponse(false);
    }
  };

  Browser.prototype.mouse_event = function(page_id, id, name) {
    var command, node;
    node = this.node(page_id, id);
    this.currentPage.state = 'mouse_event';
    this.last_mouse_event = node.mouseEvent(name);
    command = this.current_command;
    return setTimeout((function(_this) {
      return function() {
        if (_this.currentPage.state === 'mouse_event') {
          _this.currentPage.state = 'default';
          return command.sendResponse({
            position: _this.last_mouse_event
          });
        } else {
          return _this.currentPage.waitState('default', function() {
            return command.sendResponse({
              position: _this.last_mouse_event
            });
          });
        }
      };
    })(this), 5);
  };

  Browser.prototype.click = function(page_id, id) {
    return this.mouse_event(page_id, id, 'click');
  };

  Browser.prototype.right_click = function(page_id, id) {
    return this.mouse_event(page_id, id, 'rightclick');
  };

  Browser.prototype.double_click = function(page_id, id) {
    return this.mouse_event(page_id, id, 'doubleclick');
  };

  Browser.prototype.hover = function(page_id, id) {
    return this.mouse_event(page_id, id, 'mousemove');
  };

  Browser.prototype.click_coordinates = function(x, y) {
    this.currentPage.sendEvent('click', x, y);
    return this.current_command.sendResponse({
      click: {
        x: x,
        y: y
      }
    });
  };

  Browser.prototype.drag = function(page_id, id, other_id) {
    this.node(page_id, id).dragTo(this.node(page_id, other_id));
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.drag_by = function(page_id, id, x, y) {
    this.node(page_id, id).dragBy(x, y);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.trigger = function(page_id, id, event) {
    this.node(page_id, id).trigger(event);
    return this.current_command.sendResponse(event);
  };

  Browser.prototype.equals = function(page_id, id, other_id) {
    return this.current_command.sendResponse(this.node(page_id, id).isEqual(this.node(page_id, other_id)));
  };

  Browser.prototype.reset = function() {
    this.resetPage();
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.scroll_to = function(left, top) {
    this.currentPage.setScrollPosition({
      left: left,
      top: top
    });
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.send_keys = function(page_id, id, keys) {
    var i, j, k, key, len, len1, len2, modifier_code, modifier_key, modifier_keys, sequence, target;
    target = this.node(page_id, id);
    if (!target.containsSelection()) {
      target.mouseEvent('click');
    }
    for (i = 0, len = keys.length; i < len; i++) {
      sequence = keys[i];
      key = sequence.key != null ? this.currentPage.keyCode(sequence.key) : sequence;
      if (sequence.modifier != null) {
        modifier_keys = this.currentPage.keyModifierKeys(sequence.modifier);
        modifier_code = this.currentPage.keyModifierCode(sequence.modifier);
        for (j = 0, len1 = modifier_keys.length; j < len1; j++) {
          modifier_key = modifier_keys[j];
          this.currentPage.sendEvent('keydown', modifier_key);
        }
        this.currentPage.sendEvent('keypress', key, null, null, modifier_code);
        for (k = 0, len2 = modifier_keys.length; k < len2; k++) {
          modifier_key = modifier_keys[k];
          this.currentPage.sendEvent('keyup', modifier_key);
        }
      } else {
        this.currentPage.sendEvent('keypress', key);
      }
    }
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.render_base64 = function(format, full, selector) {
    var encoded_image;
    if (selector == null) {
      selector = null;
    }
    this.set_clip_rect(full, selector);
    encoded_image = this.currentPage.renderBase64(format);
    return this.current_command.sendResponse(encoded_image);
  };

  Browser.prototype.render = function(path, full, selector) {
    var dimensions;
    if (selector == null) {
      selector = null;
    }
    dimensions = this.set_clip_rect(full, selector);
    this.currentPage.setScrollPosition({
      left: 0,
      top: 0
    });
    this.currentPage.render(path);
    this.currentPage.setScrollPosition({
      left: dimensions.left,
      top: dimensions.top
    });
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_clip_rect = function(full, selector) {
    var dimensions, document, rect, ref, viewport;
    dimensions = this.currentPage.validatedDimensions();
    ref = [dimensions.document, dimensions.viewport], document = ref[0], viewport = ref[1];
    rect = full ? {
      left: 0,
      top: 0,
      width: document.width,
      height: document.height
    } : selector != null ? this.currentPage.elementBounds(selector) : {
      left: 0,
      top: 0,
      width: viewport.width,
      height: viewport.height
    };
    this.currentPage.setClipRect(rect);
    return dimensions;
  };

  Browser.prototype.set_paper_size = function(size) {
    this.currentPage.setPaperSize(size);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_zoom_factor = function(zoom_factor) {
    this.currentPage.setZoomFactor(zoom_factor);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.resize = function(width, height) {
    this.currentPage.setViewportSize({
      width: width,
      height: height
    });
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.network_traffic = function() {
    return this.current_command.sendResponse(this.currentPage.networkTraffic());
  };

  Browser.prototype.clear_network_traffic = function() {
    this.currentPage.clearNetworkTraffic();
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.get_headers = function() {
    return this.current_command.sendResponse(this.currentPage.getCustomHeaders());
  };

  Browser.prototype.set_headers = function(headers) {
    if (headers['User-Agent']) {
      this.currentPage.setUserAgent(headers['User-Agent']);
    }
    this.currentPage.setCustomHeaders(headers);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.add_headers = function(headers) {
    var allHeaders, name, value;
    allHeaders = this.currentPage.getCustomHeaders();
    for (name in headers) {
      value = headers[name];
      allHeaders[name] = value;
    }
    return this.set_headers(allHeaders);
  };

  Browser.prototype.add_header = function(header, permanent) {
    if (!permanent) {
      this.currentPage.addTempHeader(header);
    }
    return this.add_headers(header);
  };

  Browser.prototype.response_headers = function() {
    return this.current_command.sendResponse(this.currentPage.responseHeaders());
  };

  Browser.prototype.cookies = function() {
    return this.current_command.sendResponse(this.currentPage.cookies());
  };

  Browser.prototype.set_cookie = function(cookie) {
    phantom.addCookie(cookie);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.remove_cookie = function(name) {
    this.currentPage.deleteCookie(name);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.clear_cookies = function() {
    phantom.clearCookies();
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.cookies_enabled = function(flag) {
    phantom.cookiesEnabled = flag;
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_http_auth = function(user, password) {
    this.currentPage.setHttpAuth(user, password);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_js_errors = function(value) {
    this.js_errors = value;
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_debug = function(value) {
    this._debug = value;
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.exit = function() {
    return phantom.exit();
  };

  Browser.prototype.noop = function() {};

  Browser.prototype.browser_error = function() {
    throw new Error('zomg');
  };

  Browser.prototype.go_back = function() {
    var command;
    command = this.current_command;
    if (this.currentPage.canGoBack) {
      this.currentPage.state = 'loading';
      this.currentPage.goBack();
      return this.currentPage.waitState('default', (function(_this) {
        return function() {
          return command.sendResponse(true);
        };
      })(this));
    } else {
      return command.sendResponse(false);
    }
  };

  Browser.prototype.go_forward = function() {
    var command;
    command = this.current_command;
    if (this.currentPage.canGoForward) {
      this.currentPage.state = 'loading';
      this.currentPage.goForward();
      return this.currentPage.waitState('default', (function(_this) {
        return function() {
          return command.sendResponse(true);
        };
      })(this));
    } else {
      return command.sendResponse(false);
    }
  };

  Browser.prototype.set_url_blacklist = function() {
    this.currentPage.urlBlacklist = Array.prototype.slice.call(arguments);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_confirm_process = function(process) {
    this.confirm_processes.push(process);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.set_prompt_response = function(response) {
    this.prompt_responses.push(response);
    return this.current_command.sendResponse(true);
  };

  Browser.prototype.modal_message = function() {
    return this.current_command.sendResponse(this.processed_modal_messages.shift());
  };

  return Browser;

})();
