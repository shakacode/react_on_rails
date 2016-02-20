Poltergeist.Cmd = (function() {
  function Cmd(owner, id, name, args) {
    this.owner = owner;
    this.id = id;
    this.name = name;
    this.args = args;
  }

  Cmd.prototype.sendResponse = function(response) {
    var errors;
    errors = this.browser.currentPage.errors;
    this.browser.currentPage.clearErrors();
    if (errors.length > 0 && this.browser.js_errors) {
      return this.sendError(new Poltergeist.JavascriptError(errors));
    } else {
      return this.owner.sendResponse(this.id, response);
    }
  };

  Cmd.prototype.sendError = function(errors) {
    return this.owner.sendError(this.id, errors);
  };

  Cmd.prototype.run = function(browser) {
    this.browser = browser;
    return this.browser.runCommand(this);
  };

  return Cmd;

})();
