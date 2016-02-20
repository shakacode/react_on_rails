class Poltergeist.Cmd
  constructor: (@owner, @id, @name, @args)->

  sendResponse: (response) ->
    errors = @browser.currentPage.errors
    @browser.currentPage.clearErrors()

    if errors.length > 0 && @browser.js_errors
      @sendError(new Poltergeist.JavascriptError(errors))
    else
      @owner.sendResponse(@id, response)

  sendError: (errors) ->
    @owner.sendError(@id, errors)

  run: (@browser) ->
    @browser.runCommand(this)
