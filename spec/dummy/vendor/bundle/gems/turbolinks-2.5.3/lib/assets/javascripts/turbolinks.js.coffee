pageCache               = {}
cacheSize               = 10
transitionCacheEnabled  = false
progressBar             = null

currentState            = null
loadedAssets            = null

referer                 = null

xhr                     = null

EVENTS =
  BEFORE_CHANGE:  'page:before-change'
  FETCH:          'page:fetch'
  RECEIVE:        'page:receive'
  CHANGE:         'page:change'
  UPDATE:         'page:update'
  LOAD:           'page:load'
  RESTORE:        'page:restore'
  BEFORE_UNLOAD:  'page:before-unload'
  EXPIRE:         'page:expire'

fetch = (url) ->
  url = new ComponentUrl url

  rememberReferer()
  cacheCurrentPage()
  progressBar?.start()

  if transitionCacheEnabled and cachedPage = transitionCacheFor(url.absolute)
    fetchHistory cachedPage
    fetchReplacement url, null, false
  else
    fetchReplacement url, resetScrollPosition

transitionCacheFor = (url) ->
  cachedPage = pageCache[url]
  cachedPage if cachedPage and !cachedPage.transitionCacheDisabled

enableTransitionCache = (enable = true) ->
  transitionCacheEnabled = enable

enableProgressBar = (enable = true) ->
  return unless browserSupportsTurbolinks
  if enable
    progressBar ?= new ProgressBar 'html'
  else
    progressBar?.uninstall()
    progressBar = null

fetchReplacement = (url, onLoadFunction, showProgressBar = true) ->
  triggerEvent EVENTS.FETCH, url: url.absolute

  xhr?.abort()
  xhr = new XMLHttpRequest
  xhr.open 'GET', url.withoutHashForIE10compatibility(), true
  xhr.setRequestHeader 'Accept', 'text/html, application/xhtml+xml, application/xml'
  xhr.setRequestHeader 'X-XHR-Referer', referer

  xhr.onload = ->
    triggerEvent EVENTS.RECEIVE, url: url.absolute

    if doc = processResponse()
      reflectNewUrl url
      reflectRedirectedUrl()
      changePage extractTitleAndBody(doc)...
      manuallyTriggerHashChangeForFirefox()
      onLoadFunction?()
      triggerEvent EVENTS.LOAD
    else
      document.location.href = crossOriginRedirect() or url.absolute

  if progressBar and showProgressBar
    xhr.onprogress = (event) =>
      percent = if event.lengthComputable
        event.loaded / event.total * 100
      else
        progressBar.value + (100 - progressBar.value) / 10
      progressBar.advanceTo(percent)

  xhr.onloadend = -> xhr = null
  xhr.onerror   = -> document.location.href = url.absolute

  xhr.send()

fetchHistory = (cachedPage) ->
  xhr?.abort()
  changePage cachedPage.title, cachedPage.body
  recallScrollPosition cachedPage
  triggerEvent EVENTS.RESTORE


cacheCurrentPage = ->
  currentStateUrl = new ComponentUrl currentState.url

  pageCache[currentStateUrl.absolute] =
    url:                      currentStateUrl.relative,
    body:                     document.body,
    title:                    document.title,
    positionY:                window.pageYOffset,
    positionX:                window.pageXOffset,
    cachedAt:                 new Date().getTime(),
    transitionCacheDisabled:  document.querySelector('[data-no-transition-cache]')?

  constrainPageCacheTo cacheSize

pagesCached = (size = cacheSize) ->
  cacheSize = parseInt(size) if /^[\d]+$/.test size

constrainPageCacheTo = (limit) ->
  pageCacheKeys = Object.keys pageCache

  cacheTimesRecentFirst = pageCacheKeys.map (url) ->
    pageCache[url].cachedAt
  .sort (a, b) -> b - a

  for key in pageCacheKeys when pageCache[key].cachedAt <= cacheTimesRecentFirst[limit]
    triggerEvent EVENTS.EXPIRE, pageCache[key]
    delete pageCache[key]

changePage = (title, body, csrfToken, runScripts) ->
  triggerEvent EVENTS.BEFORE_UNLOAD
  document.title = title
  document.documentElement.replaceChild body, document.body
  CSRFToken.update csrfToken if csrfToken?
  setAutofocusElement()
  executeScriptTags() if runScripts
  currentState = window.history.state
  progressBar?.done()
  triggerEvent EVENTS.CHANGE
  triggerEvent EVENTS.UPDATE

executeScriptTags = ->
  scripts = Array::slice.call document.body.querySelectorAll 'script:not([data-turbolinks-eval="false"])'
  for script in scripts when script.type in ['', 'text/javascript']
    copy = document.createElement 'script'
    copy.setAttribute attr.name, attr.value for attr in script.attributes
    copy.async = false unless script.hasAttribute 'async'
    copy.appendChild document.createTextNode script.innerHTML
    { parentNode, nextSibling } = script
    parentNode.removeChild script
    parentNode.insertBefore copy, nextSibling
  return

removeNoscriptTags = (node) ->
  node.innerHTML = node.innerHTML.replace /<noscript[\S\s]*?<\/noscript>/ig, ''
  node

# Firefox bug: Doesn't autofocus fields that are inserted via JavaScript
setAutofocusElement = ->
  autofocusElement = (list = document.querySelectorAll 'input[autofocus], textarea[autofocus]')[list.length - 1]
  if autofocusElement and document.activeElement isnt autofocusElement
    autofocusElement.focus()

reflectNewUrl = (url) ->
  if (url = new ComponentUrl url).absolute isnt referer
    window.history.pushState { turbolinks: true, url: url.absolute }, '', url.absolute

reflectRedirectedUrl = ->
  if location = xhr.getResponseHeader 'X-XHR-Redirected-To'
    location = new ComponentUrl location
    preservedHash = if location.hasNoHash() then document.location.hash else ''
    window.history.replaceState window.history.state, '', location.href + preservedHash

crossOriginRedirect = ->
  redirect if (redirect = xhr.getResponseHeader('Location'))? and (new ComponentUrl(redirect)).crossOrigin()

rememberReferer = ->
  referer = document.location.href

rememberCurrentUrl = ->
  window.history.replaceState { turbolinks: true, url: document.location.href }, '', document.location.href

rememberCurrentState = ->
  currentState = window.history.state

# Unlike other browsers, Firefox doesn't trigger hashchange after changing the
# location (via pushState) to an anchor on a different page.  For example:
#
#   /pages/one  =>  /pages/two#with-hash
#
# By forcing Firefox to trigger hashchange, the rest of the code can rely on more
# consistent behavior across browsers.
manuallyTriggerHashChangeForFirefox = ->
  if navigator.userAgent.match(/Firefox/) and !(url = (new ComponentUrl)).hasNoHash()
    window.history.replaceState currentState, '', url.withoutHash()
    document.location.hash = url.hash

recallScrollPosition = (page) ->
  window.scrollTo page.positionX, page.positionY

resetScrollPosition = ->
  if document.location.hash
    document.location.href = document.location.href
  else
    window.scrollTo 0, 0


clone = (original) ->
  return original if not original? or typeof original isnt 'object'
  copy = new original.constructor()
  copy[key] = clone value for key, value of original
  copy

popCookie = (name) ->
  value = document.cookie.match(new RegExp(name+"=(\\w+)"))?[1].toUpperCase() or ''
  document.cookie = name + '=; expires=Thu, 01-Jan-70 00:00:01 GMT; path=/'
  value

triggerEvent = (name, data) ->
  if typeof Prototype isnt 'undefined'
    Event.fire document, name, data, true

  event = document.createEvent 'Events'
  event.data = data if data
  event.initEvent name, true, true
  document.dispatchEvent event

pageChangePrevented = (url) ->
  !triggerEvent EVENTS.BEFORE_CHANGE, url: url

processResponse = ->
  clientOrServerError = ->
    400 <= xhr.status < 600

  validContent = ->
    (contentType = xhr.getResponseHeader('Content-Type'))? and
      contentType.match /^(?:text\/html|application\/xhtml\+xml|application\/xml)(?:;|$)/

  extractTrackAssets = (doc) ->
    for node in doc.querySelector('head').childNodes when node.getAttribute?('data-turbolinks-track')?
      node.getAttribute('src') or node.getAttribute('href')

  assetsChanged = (doc) ->
    loadedAssets ||= extractTrackAssets document
    fetchedAssets  = extractTrackAssets doc
    fetchedAssets.length isnt loadedAssets.length or intersection(fetchedAssets, loadedAssets).length isnt loadedAssets.length

  intersection = (a, b) ->
    [a, b] = [b, a] if a.length > b.length
    value for value in a when value in b

  if not clientOrServerError() and validContent()
    doc = createDocument xhr.responseText
    if doc and !assetsChanged doc
      return doc

extractTitleAndBody = (doc) ->
  title = doc.querySelector 'title'
  [ title?.textContent, removeNoscriptTags(doc.querySelector('body')), CSRFToken.get(doc).token, 'runScripts' ]

CSRFToken =
  get: (doc = document) ->
    node:   tag = doc.querySelector 'meta[name="csrf-token"]'
    token:  tag?.getAttribute? 'content'

  update: (latest) ->
    current = @get()
    if current.token? and latest? and current.token isnt latest
      current.node.setAttribute 'content', latest

createDocument = (html) ->
  doc = document.documentElement.cloneNode()
  doc.innerHTML = html
  doc.head = doc.querySelector 'head'
  doc.body = doc.querySelector 'body'
  doc

# The ComponentUrl class converts a basic URL string into an object
# that behaves similarly to document.location.
#
# If an instance is created from a relative URL, the current document
# is used to fill in the missing attributes (protocol, host, port).
class ComponentUrl
  constructor: (@original = document.location.href) ->
    return @original if @original.constructor is ComponentUrl
    @_parse()

  withoutHash: -> @href.replace(@hash, '').replace('#', '')

  # Intention revealing function alias
  withoutHashForIE10compatibility: -> @withoutHash()

  hasNoHash: -> @hash.length is 0

  crossOrigin: ->
    @origin isnt (new ComponentUrl).origin

  _parse: ->
    (@link ?= document.createElement 'a').href = @original
    { @href, @protocol, @host, @hostname, @port, @pathname, @search, @hash } = @link
    @origin = [@protocol, '//', @hostname].join ''
    @origin += ":#{@port}" unless @port.length is 0
    @relative = [@pathname, @search, @hash].join ''
    @absolute = @href

# The Link class derives from the ComponentUrl class, but is built from an
# existing link element.  Provides verification functionality for Turbolinks
# to use in determining whether it should process the link when clicked.
class Link extends ComponentUrl
  @HTML_EXTENSIONS: ['html']

  @allowExtensions: (extensions...) ->
    Link.HTML_EXTENSIONS.push extension for extension in extensions
    Link.HTML_EXTENSIONS

  constructor: (@link) ->
    return @link if @link.constructor is Link
    @original = @link.href
    @originalElement = @link
    @link = @link.cloneNode false
    super

  shouldIgnore: ->
    @crossOrigin() or
      @_anchored() or
      @_nonHtml() or
      @_optOut() or
      @_target()

  _anchored: ->
    (@hash.length > 0 or @href.charAt(@href.length - 1) is '#') and
      (@withoutHash() is (new ComponentUrl).withoutHash())

  _nonHtml: ->
    @pathname.match(/\.[a-z]+$/g) and not @pathname.match(new RegExp("\\.(?:#{Link.HTML_EXTENSIONS.join('|')})?$", 'g'))

  _optOut: ->
    link = @originalElement
    until ignore or link is document
      ignore = link.getAttribute('data-no-turbolink')?
      link = link.parentNode
    ignore

  _target: ->
    @link.target.length isnt 0


# The Click class handles clicked links, verifying if Turbolinks should
# take control by inspecting both the event and the link. If it should,
# the page change process is initiated. If not, control is passed back
# to the browser for default functionality.
class Click
  @installHandlerLast: (event) ->
    unless event.defaultPrevented
      document.removeEventListener 'click', Click.handle, false
      document.addEventListener 'click', Click.handle, false

  @handle: (event) ->
    new Click event

  constructor: (@event) ->
    return if @event.defaultPrevented
    @_extractLink()
    if @_validForTurbolinks()
      visit @link.href unless pageChangePrevented(@link.absolute)
      @event.preventDefault()

  _extractLink: ->
    link = @event.target
    link = link.parentNode until !link.parentNode or link.nodeName is 'A'
    @link = new Link(link) if link.nodeName is 'A' and link.href.length isnt 0

  _validForTurbolinks: ->
    @link? and not (@link.shouldIgnore() or @_nonStandardClick())

  _nonStandardClick: ->
    @event.which > 1 or
      @event.metaKey or
      @event.ctrlKey or
      @event.shiftKey or
      @event.altKey


class ProgressBar
  className = 'turbolinks-progress-bar'

  constructor: (@elementSelector) ->
    @value = 0
    @content = ''
    @speed = 300
    # Setting the opacity to a value < 1 fixes a display issue in Safari 6 and
    # iOS 6 where the progress bar would fill the entire page.
    @opacity = 0.99
    @install()

  install: ->
    @element = document.querySelector(@elementSelector)
    @element.classList.add(className)
    @styleElement = document.createElement('style')
    document.head.appendChild(@styleElement)
    @_updateStyle()

  uninstall: ->
    @element.classList.remove(className)
    document.head.removeChild(@styleElement)

  start: ->
    @advanceTo(5)

  advanceTo: (value) ->
    if value > @value <= 100
      @value = value
      @_updateStyle()

      if @value is 100
        @_stopTrickle()
      else if @value > 0
        @_startTrickle()

  done: ->
    if @value > 0
      @advanceTo(100)
      @_reset()

  _reset: ->
    originalOpacity = @opacity

    setTimeout =>
      @opacity = 0
      @_updateStyle()
    , @speed / 2

    setTimeout =>
      @value = 0
      @opacity = originalOpacity
      @_withSpeed(0, => @_updateStyle(true))
    , @speed

  _startTrickle: ->
    return if @trickling
    @trickling = true
    setTimeout(@_trickle, @speed)

  _stopTrickle: ->
    delete @trickling

  _trickle: =>
    return unless @trickling
    @advanceTo(@value + Math.random() / 2)
    setTimeout(@_trickle, @speed)

  _withSpeed: (speed, fn) ->
    originalSpeed = @speed
    @speed = speed
    result = fn()
    @speed = originalSpeed
    result

  _updateStyle: (forceRepaint = false) ->
    @_changeContentToForceRepaint() if forceRepaint
    @styleElement.textContent = @_createCSSRule()

  _changeContentToForceRepaint: ->
    @content = if @content is '' then ' ' else ''

  _createCSSRule: ->
    """
    #{@elementSelector}.#{className}::before {
      content: '#{@content}';
      position: fixed;
      top: 0;
      left: 0;
      z-index: 2000;
      background-color: #0076ff;
      height: 3px;
      opacity: #{@opacity};
      width: #{@value}%;
      transition: width #{@speed}ms ease-out, opacity #{@speed / 2}ms ease-in;
      transform: translate3d(0,0,0);
    }
    """


# Delay execution of function long enough to miss the popstate event
# some browsers fire on the initial page load.
bypassOnLoadPopstate = (fn) ->
  setTimeout fn, 500

installDocumentReadyPageEventTriggers = ->
  document.addEventListener 'DOMContentLoaded', ( ->
    triggerEvent EVENTS.CHANGE
    triggerEvent EVENTS.UPDATE
  ), true

installJqueryAjaxSuccessPageUpdateTrigger = ->
  if typeof jQuery isnt 'undefined'
    jQuery(document).on 'ajaxSuccess', (event, xhr, settings) ->
      return unless jQuery.trim xhr.responseText
      triggerEvent EVENTS.UPDATE

installHistoryChangeHandler = (event) ->
  if event.state?.turbolinks
    if cachedPage = pageCache[(new ComponentUrl(event.state.url)).absolute]
      cacheCurrentPage()
      fetchHistory cachedPage
    else
      visit event.target.location.href

initializeTurbolinks = ->
  rememberCurrentUrl()
  rememberCurrentState()

  document.addEventListener 'click', Click.installHandlerLast, true

  window.addEventListener 'hashchange', (event) ->
    rememberCurrentUrl()
    rememberCurrentState()
  , false
  bypassOnLoadPopstate ->
    window.addEventListener 'popstate', installHistoryChangeHandler, false

# Handle bug in Firefox 26/27 where history.state is initially undefined
historyStateIsDefined =
  window.history.state != undefined or navigator.userAgent.match /Firefox\/2[6|7]/

browserSupportsPushState =
  window.history and window.history.pushState and window.history.replaceState and historyStateIsDefined

browserIsntBuggy =
  !navigator.userAgent.match /CriOS\//

requestMethodIsSafe =
  popCookie('request_method') in ['GET','']

browserSupportsTurbolinks = browserSupportsPushState and browserIsntBuggy and requestMethodIsSafe

browserSupportsCustomEvents =
  document.addEventListener and document.createEvent

if browserSupportsCustomEvents
  installDocumentReadyPageEventTriggers()
  installJqueryAjaxSuccessPageUpdateTrigger()

if browserSupportsTurbolinks
  visit = fetch
  initializeTurbolinks()
else
  visit = (url) -> document.location.href = url

# Public API
#   Turbolinks.visit(url)
#   Turbolinks.pagesCached()
#   Turbolinks.pagesCached(20)
#   Turbolinks.enableTransitionCache()
#   Turbolinks.allowLinkExtensions('md')
#   Turbolinks.supported
#   Turbolinks.EVENTS
@Turbolinks = {
  visit,
  pagesCached,
  enableTransitionCache,
  enableProgressBar,
  allowLinkExtensions: Link.allowExtensions,
  supported: browserSupportsTurbolinks,
  EVENTS: clone(EVENTS)
}
