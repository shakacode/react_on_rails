class Poltergeist.WebPage
  @CALLBACKS = ['onConsoleMessage','onError',
                'onLoadFinished', 'onInitialized', 'onLoadStarted',
                'onResourceRequested', 'onResourceReceived', 'onResourceError',
                'onNavigationRequested', 'onUrlChanged', 'onPageCreated',
                'onClosing']

  @DELEGATES = ['open', 'sendEvent', 'uploadFile', 'release', 'render',
                'renderBase64', 'goBack', 'goForward']

  @COMMANDS  = ['currentUrl', 'find', 'nodeCall', 'documentSize',
                'beforeUpload', 'afterUpload', 'clearLocalStorage']

  @EXTENSIONS = []

  constructor: (@_native) ->
    @_native or= require('webpage').create()

    @id              = 0
    @source          = null
    @closed          = false
    @state           = 'default'
    @urlBlacklist    = []
    @frames          = []
    @errors          = []
    @_networkTraffic = {}
    @_tempHeaders    = {}
    @_blockedUrls    = []

    for callback in WebPage.CALLBACKS
      this.bindCallback(callback)

  for command in @COMMANDS
    do (command) =>
      this.prototype[command] =
        (args...) -> this.runCommand(command, args)

  for delegate in @DELEGATES
    do (delegate) =>
      this.prototype[delegate] =
        -> @_native[delegate].apply(@_native, arguments)

  onInitializedNative: ->
    @id += 1
    @source = null
    @injectAgent()
    this.removeTempHeaders()
    this.setScrollPosition(left: 0, top: 0)

  onClosingNative: ->
    @handle = null
    @closed = true

  onConsoleMessageNative: (message) ->
    if message == '__DOMContentLoaded'
      @source = @_native.content
      false
    else
      console.log(message)

  onLoadStartedNative: ->
    @state = 'loading'
    @requestId = @lastRequestId

  onLoadFinishedNative: (@status) ->
    @state = 'default'
    @source or= @_native.content

  onErrorNative: (message, stack) ->
    stackString = message

    stack.forEach (frame) ->
      stackString += "\n"
      stackString += "    at #{frame.file}:#{frame.line}"
      stackString += " in #{frame.function}" if frame.function && frame.function != ''

    @errors.push(message: message, stack: stackString)
    return true

  onResourceRequestedNative: (request, net) ->
    abort = @urlBlacklist.some (blacklisted_url) ->
      request.url.indexOf(blacklisted_url) != -1

    if abort
      @_blockedUrls.push request.url unless request.url in @_blockedUrls
      net.abort()
    else
      @lastRequestId = request.id

      if @normalizeURL(request.url) == @redirectURL
        @redirectURL = null
        @requestId   = request.id

      @_networkTraffic[request.id] = {
        request:       request,
        responseParts: []
        error: null
      }
    return true

  onResourceReceivedNative: (response) ->
    @_networkTraffic[response.id]?.responseParts.push(response)

    if @requestId == response.id
      if response.redirectURL
        @redirectURL = @normalizeURL(response.redirectURL)
      else
        @statusCode = response.status
        @_responseHeaders = response.headers
    return true

  onResourceErrorNative: (errorResponse) ->
    @_networkTraffic[errorResponse.id]?.error = errorResponse
    return true

  injectAgent: ->
    if this.native().evaluate(-> typeof __poltergeist) == "undefined"
      this.native().injectJs "#{phantom.libraryPath}/agent.js"
      for extension in WebPage.EXTENSIONS
        this.native().injectJs extension
      return true
    return false

  injectExtension: (file) ->
    WebPage.EXTENSIONS.push file
    this.native().injectJs file

  native: ->
    if @closed
      throw new Poltergeist.NoSuchWindowError
    else
      @_native

  windowName: ->
    this.native().windowName

  keyCode: (name) ->
    this.native().event.key[name]

  keyModifierCode: (names) ->
    modifiers = this.native().event.modifier
    names = names.split(',').map ((name) -> modifiers[name])
    names[0] | names[1] # return codes for 1 or 2 modifiers

  keyModifierKeys: (names) ->
    names.split(',').map (name) =>
      this.keyCode(name.charAt(0).toUpperCase() + name.substring(1))

  waitState: (state, callback) ->
    if @state == state
      callback.call()
    else
      setTimeout (=> @waitState(state, callback)), 100

  setHttpAuth: (user, password) ->
    this.native().settings.userName = user
    this.native().settings.password = password
    return true

  networkTraffic: ->
    @_networkTraffic

  clearNetworkTraffic: ->
    @_networkTraffic = {}
    return true

  blockedUrls: ->
    @_blockedUrls

  clearBlockedUrls: ->
    @_blockedUrls = []
    return true

  content: ->
    this.native().frameContent

  title: ->
    this.native().frameTitle

  frameUrl: (frameNameOrId) ->
    query = (frameNameOrId) ->
      document.querySelector("iframe[name='#{frameNameOrId}'], iframe[id='#{frameNameOrId}']")?.src
    this.evaluate(query, frameNameOrId)

  clearErrors: ->
    @errors = []
    return true

  responseHeaders: ->
    headers = {}
    @_responseHeaders.forEach (item) ->
      headers[item.name] = item.value
    headers

  cookies: ->
    this.native().cookies

  deleteCookie: (name) ->
    this.native().deleteCookie(name)

  viewportSize: ->
    this.native().viewportSize

  setViewportSize: (size) ->
    this.native().viewportSize = size

  setZoomFactor: (zoom_factor) ->
    this.native().zoomFactor = zoom_factor

  setPaperSize: (size) ->
    this.native().paperSize = size

  scrollPosition: ->
    this.native().scrollPosition

  setScrollPosition: (pos) ->
    this.native().scrollPosition = pos

  clipRect: ->
    this.native().clipRect

  setClipRect: (rect) ->
    this.native().clipRect = rect

  elementBounds: (selector) ->
    this.native().evaluate(
      (selector) ->
        document.querySelector(selector).getBoundingClientRect()
      , selector
    )

  setUserAgent: (userAgent) ->
    this.native().settings.userAgent = userAgent

  getCustomHeaders: ->
    this.native().customHeaders

  setCustomHeaders: (headers) ->
    this.native().customHeaders = headers

  addTempHeader: (header) ->
    for name, value of header
      @_tempHeaders[name] = value
    @_tempHeaders

  removeTempHeaders: ->
    allHeaders = this.getCustomHeaders()
    for name, value of @_tempHeaders
      delete allHeaders[name]
    this.setCustomHeaders(allHeaders)

  pushFrame: (name) ->
    if this.native().switchToFrame(name)
      @frames.push(name)
      return true
    else
      frame_no = this.native().evaluate(
        (frame_name) ->
          frames = document.querySelectorAll("iframe, frame")
          (idx for f, idx in frames when f?['name'] == frame_name or f?['id'] == frame_name)[0]
        , name)
      if frame_no? and this.native().switchToFrame(frame_no)
        @frames.push(name)
        return true
      else
        return false

  popFrame: ->
    @frames.pop()
    this.native().switchToParentFrame()

  dimensions: ->
    scroll   = this.scrollPosition()
    viewport = this.viewportSize()

    top:    scroll.top,  bottom: scroll.top  + viewport.height,
    left:   scroll.left, right:  scroll.left + viewport.width,
    viewport: viewport
    document: this.documentSize()

  # A work around for http://code.google.com/p/phantomjs/issues/detail?id=277
  validatedDimensions: ->
    dimensions = this.dimensions()
    document   = dimensions.document

    if dimensions.right > document.width
      dimensions.left  = Math.max(0, dimensions.left - (dimensions.right - document.width))
      dimensions.right = document.width

    if dimensions.bottom > document.height
      dimensions.top    = Math.max(0, dimensions.top - (dimensions.bottom - document.height))
      dimensions.bottom = document.height

    this.setScrollPosition(left: dimensions.left, top: dimensions.top)

    dimensions

  get: (id) ->
    new Poltergeist.Node(this, id)

  # Before each mouse event we make sure that the mouse is moved to where the
  # event will take place. This deals with e.g. :hover changes.
  mouseEvent: (name, x, y, button = 'left') ->
    this.sendEvent('mousemove', x, y)
    this.sendEvent(name, x, y, button)

  evaluate: (fn, args...) ->
    this.injectAgent()
    JSON.parse this.sanitize(this.native().evaluate("function() { return PoltergeistAgent.stringify(#{this.stringifyCall(fn, args)}) }"))

  sanitize: (potential_string) ->
    if typeof(potential_string) == "string"
      # JSON doesn't like \r or \n in strings unless escaped
      potential_string.replace("\n","\\n").replace("\r","\\r")
    else
      potential_string

  execute: (fn, args...) ->
    this.native().evaluate("function() { #{this.stringifyCall(fn, args)} }")

  stringifyCall: (fn, args) ->
    if args.length == 0
      "(#{fn.toString()})()"
    else
      # The JSON.stringify happens twice because the second time we are essentially
      # escaping the string.
      "(#{fn.toString()}).apply(this, PoltergeistAgent.JSON.parse(#{JSON.stringify(JSON.stringify(args))}))"

  # For some reason phantomjs seems to have trouble with doing 'fat arrow' binding here,
  # hence the 'that' closure.
  bindCallback: (name) ->
    that = this
    this.native()[name] = ->
      if that[name + 'Native']? # For internal callbacks
        result = that[name + 'Native'].apply(that, arguments)

      if result != false && that[name]? # For externally set callbacks
        that[name].apply(that, arguments)
    return true

  # Any error raised here or inside the evaluate will get reported to
  # phantom.onError. If result is null, that means there was an error
  # inside the agent.
  runCommand: (name, args) ->
    result = this.evaluate(
      (name, args) -> __poltergeist.externalCall(name, args),
      name, args
    )

    if result != null
      if result.error?
        switch result.error.message
          when 'PoltergeistAgent.ObsoleteNode'
            throw new Poltergeist.ObsoleteNode
          when 'PoltergeistAgent.InvalidSelector'
            [method, selector] = args
            throw new Poltergeist.InvalidSelector(method, selector)
          else
            throw new Poltergeist.BrowserError(result.error.message, result.error.stack)
      else
        result.value

  canGoBack: ->
    this.native().canGoBack

  canGoForward: ->
    this.native().canGoForward

  normalizeURL: (url) ->
    parser = document.createElement('a')
    parser.href = url
    return parser.href
