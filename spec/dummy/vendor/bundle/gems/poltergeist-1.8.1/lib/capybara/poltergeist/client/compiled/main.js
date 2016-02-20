var Poltergeist, system,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Poltergeist = (function() {
  function Poltergeist(port, width, height) {
    var that;
    this.browser = new Poltergeist.Browser(width, height);
    this.connection = new Poltergeist.Connection(this, port);
    that = this;
    phantom.onError = function(message, stack) {
      return that.onError(message, stack);
    };
    this.running = false;
  }

  Poltergeist.prototype.runCommand = function(command) {
    var error, error1;
    this.running = true;
    command = new Poltergeist.Cmd(this, command.id, command.name, command.args);
    try {
      return command.run(this.browser);
    } catch (error1) {
      error = error1;
      if (error instanceof Poltergeist.Error) {
        return this.sendError(command.id, error);
      } else {
        return this.sendError(command.id, new Poltergeist.BrowserError(error.toString(), error.stack));
      }
    }
  };

  Poltergeist.prototype.sendResponse = function(command_id, response) {
    return this.send({
      command_id: command_id,
      response: response
    });
  };

  Poltergeist.prototype.sendError = function(command_id, error) {
    return this.send({
      command_id: command_id,
      error: {
        name: error.name || 'Generic',
        args: error.args && error.args() || [error.toString()]
      }
    });
  };

  Poltergeist.prototype.send = function(data) {
    if (this.running) {
      this.connection.send(data);
      this.running = false;
      return true;
    }
    return false;
  };

  return Poltergeist;

})();

window.Poltergeist = Poltergeist;

Poltergeist.Error = (function() {
  function Error() {}

  return Error;

})();

Poltergeist.ObsoleteNode = (function(superClass) {
  extend(ObsoleteNode, superClass);

  function ObsoleteNode() {
    return ObsoleteNode.__super__.constructor.apply(this, arguments);
  }

  ObsoleteNode.prototype.name = "Poltergeist.ObsoleteNode";

  ObsoleteNode.prototype.args = function() {
    return [];
  };

  ObsoleteNode.prototype.toString = function() {
    return this.name;
  };

  return ObsoleteNode;

})(Poltergeist.Error);

Poltergeist.InvalidSelector = (function(superClass) {
  extend(InvalidSelector, superClass);

  function InvalidSelector(method, selector) {
    this.method = method;
    this.selector = selector;
  }

  InvalidSelector.prototype.name = "Poltergeist.InvalidSelector";

  InvalidSelector.prototype.args = function() {
    return [this.method, this.selector];
  };

  return InvalidSelector;

})(Poltergeist.Error);

Poltergeist.FrameNotFound = (function(superClass) {
  extend(FrameNotFound, superClass);

  function FrameNotFound(frameName) {
    this.frameName = frameName;
  }

  FrameNotFound.prototype.name = "Poltergeist.FrameNotFound";

  FrameNotFound.prototype.args = function() {
    return [this.frameName];
  };

  return FrameNotFound;

})(Poltergeist.Error);

Poltergeist.MouseEventFailed = (function(superClass) {
  extend(MouseEventFailed, superClass);

  function MouseEventFailed(eventName, selector, position) {
    this.eventName = eventName;
    this.selector = selector;
    this.position = position;
  }

  MouseEventFailed.prototype.name = "Poltergeist.MouseEventFailed";

  MouseEventFailed.prototype.args = function() {
    return [this.eventName, this.selector, this.position];
  };

  return MouseEventFailed;

})(Poltergeist.Error);

Poltergeist.JavascriptError = (function(superClass) {
  extend(JavascriptError, superClass);

  function JavascriptError(errors) {
    this.errors = errors;
  }

  JavascriptError.prototype.name = "Poltergeist.JavascriptError";

  JavascriptError.prototype.args = function() {
    return [this.errors];
  };

  return JavascriptError;

})(Poltergeist.Error);

Poltergeist.BrowserError = (function(superClass) {
  extend(BrowserError, superClass);

  function BrowserError(message1, stack1) {
    this.message = message1;
    this.stack = stack1;
  }

  BrowserError.prototype.name = "Poltergeist.BrowserError";

  BrowserError.prototype.args = function() {
    return [this.message, this.stack];
  };

  return BrowserError;

})(Poltergeist.Error);

Poltergeist.StatusFailError = (function(superClass) {
  extend(StatusFailError, superClass);

  function StatusFailError(url) {
    this.url = url;
  }

  StatusFailError.prototype.name = "Poltergeist.StatusFailError";

  StatusFailError.prototype.args = function() {
    return [this.url];
  };

  return StatusFailError;

})(Poltergeist.Error);

Poltergeist.NoSuchWindowError = (function(superClass) {
  extend(NoSuchWindowError, superClass);

  function NoSuchWindowError() {
    return NoSuchWindowError.__super__.constructor.apply(this, arguments);
  }

  NoSuchWindowError.prototype.name = "Poltergeist.NoSuchWindowError";

  NoSuchWindowError.prototype.args = function() {
    return [];
  };

  return NoSuchWindowError;

})(Poltergeist.Error);

phantom.injectJs(phantom.libraryPath + "/web_page.js");

phantom.injectJs(phantom.libraryPath + "/node.js");

phantom.injectJs(phantom.libraryPath + "/connection.js");

phantom.injectJs(phantom.libraryPath + "/cmd.js");

phantom.injectJs(phantom.libraryPath + "/browser.js");

system = require('system');

new Poltergeist(system.args[1], system.args[2], system.args[3]);
