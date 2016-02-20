class Poltergeist
  constructor: (port, width, height) ->
    @browser    = new Poltergeist.Browser(width, height)
    @connection = new Poltergeist.Connection(this, port)

    # The QtWebKit bridge doesn't seem to like Function.prototype.bind
    that = this
    phantom.onError = (message, stack) -> that.onError(message, stack)

    @running = false

  runCommand: (command) ->
    @running = true
    command = new Poltergeist.Cmd(this, command.id, command.name, command.args)
    try
      command.run(@browser)
    catch error
      if error instanceof Poltergeist.Error
        this.sendError(command.id, error)
      else
        this.sendError(command.id, new Poltergeist.BrowserError(error.toString(), error.stack))

  sendResponse: (command_id, response) ->
    this.send(command_id: command_id, response: response)

  sendError: (command_id, error) ->
    this.send(
      command_id: command_id,
      error:
        name: error.name || 'Generic',
        args: error.args && error.args() || [error.toString()]
    )

  send: (data) ->
    # Prevents more than one response being sent for a single
    # command. This can happen in some scenarios where an error
    # is raised but the script can still continue.
    if @running
      @connection.send(data)
      @running = false
      return true
    return false

# This is necessary because the remote debugger will wrap the
# script in a function, causing the Poltergeist variable to
# become local.
window.Poltergeist = Poltergeist

class Poltergeist.Error

class Poltergeist.ObsoleteNode extends Poltergeist.Error
  name: "Poltergeist.ObsoleteNode"
  args: -> []
  toString: -> this.name

class Poltergeist.InvalidSelector extends Poltergeist.Error
  constructor: (@method, @selector) ->
  name: "Poltergeist.InvalidSelector"
  args: -> [@method, @selector]

class Poltergeist.FrameNotFound extends Poltergeist.Error
  constructor: (@frameName) ->
  name: "Poltergeist.FrameNotFound"
  args: -> [@frameName]

class Poltergeist.MouseEventFailed extends Poltergeist.Error
  constructor: (@eventName, @selector, @position) ->
  name: "Poltergeist.MouseEventFailed"
  args: -> [@eventName, @selector, @position]

class Poltergeist.JavascriptError extends Poltergeist.Error
  constructor: (@errors) ->
  name: "Poltergeist.JavascriptError"
  args: -> [@errors]

class Poltergeist.BrowserError extends Poltergeist.Error
  constructor: (@message, @stack) ->
  name: "Poltergeist.BrowserError"
  args: -> [@message, @stack]

class Poltergeist.StatusFailError extends Poltergeist.Error
  constructor: (@url) ->
  name: "Poltergeist.StatusFailError"
  args: -> [@url]

class Poltergeist.NoSuchWindowError extends Poltergeist.Error
  name: "Poltergeist.NoSuchWindowError"
  args: -> []

# We're using phantom.libraryPath so that any stack traces
# report the full path.
phantom.injectJs("#{phantom.libraryPath}/web_page.js")
phantom.injectJs("#{phantom.libraryPath}/node.js")
phantom.injectJs("#{phantom.libraryPath}/connection.js")
phantom.injectJs("#{phantom.libraryPath}/cmd.js")
phantom.injectJs("#{phantom.libraryPath}/browser.js")

system = require 'system'
new Poltergeist(system.args[1], system.args[2], system.args[3])
