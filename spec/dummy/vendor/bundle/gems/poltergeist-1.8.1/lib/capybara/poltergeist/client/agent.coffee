# This is injected into each page that is loaded

class PoltergeistAgent
  # Since this code executes in the sites browser space - copy needed JSON functions
  # in case user code messes with JSON (early mootools for instance)
  @.JSON ||= { parse: JSON.parse, stringify: JSON.stringify }

  constructor: ->
    @elements = []
    @nodes    = {}

  externalCall: (name, args) ->
    try
      { value: this[name].apply(this, args) }
    catch error
      { error: { message: error.toString(), stack: error.stack } }

  @stringify: (object) ->
    try
      PoltergeistAgent.JSON.stringify object, (key, value) ->
        if Array.isArray(this[key])
          return this[key]
        else
          return value
    catch error
      if error instanceof TypeError
        '"(cyclic structure)"'
      else
        throw error

  # Somehow PhantomJS returns all characters(brackets, etc) properly encoded
  # except whitespace character in pathname part of the location. This hack
  # is intended to fix this up.
  currentUrl: ->
    window.location.href.replace(/\ /g, '%20')

  find: (method, selector, within = document) ->
    try
      if method == "xpath"
        xpath   = document.evaluate(selector, within, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null)
        results = (xpath.snapshotItem(i) for i in [0...xpath.snapshotLength])
      else
        results = within.querySelectorAll(selector)

      this.register(el) for el in results
    catch error
      # DOMException.INVALID_EXPRESSION_ERR is undefined, using pure code
      if error.code == DOMException.SYNTAX_ERR || error.code == 51
        throw new PoltergeistAgent.InvalidSelector
      else
        throw error

  register: (element) ->
    @elements.push(element)
    @elements.length - 1

  documentSize: ->
    height: document.documentElement.scrollHeight || document.documentElement.clientHeight,
    width:  document.documentElement.scrollWidth  || document.documentElement.clientWidth

  get: (id) ->
    @nodes[id] or= new PoltergeistAgent.Node(this, @elements[id])

  nodeCall: (id, name, args) ->
    node = this.get(id)
    throw new PoltergeistAgent.ObsoleteNode if node.isObsolete()
    node[name].apply(node, args)

  beforeUpload: (id) ->
    this.get(id).setAttribute('_poltergeist_selected', '')

  afterUpload: (id) ->
    this.get(id).removeAttribute('_poltergeist_selected')

  clearLocalStorage: ->
    localStorage.clear()

class PoltergeistAgent.ObsoleteNode
  toString: -> "PoltergeistAgent.ObsoleteNode"

class PoltergeistAgent.InvalidSelector
  toString: -> "PoltergeistAgent.InvalidSelector"

class PoltergeistAgent.Node
  @EVENTS = {
    FOCUS: ['blur', 'focus', 'focusin', 'focusout'],
    MOUSE: ['click', 'dblclick', 'mousedown', 'mouseenter', 'mouseleave', 'mousemove',
            'mouseover', 'mouseout', 'mouseup', 'contextmenu'],
    FORM: ['submit']
  }

  constructor: (@agent, @element) ->

  parentId: ->
    @agent.register(@element.parentNode)

  parentIds: ->
    ids = []
    parent = @element.parentNode
    while parent != document
      ids.push @agent.register(parent)
      parent = parent.parentNode
    ids

  find: (method, selector) ->
    @agent.find(method, selector, @element)

  isObsolete: ->
    obsolete = (element) =>
      if (parent = element.parentNode)?
        if parent == document
          return false
        else
          obsolete parent
      else
        return true
    obsolete @element

  changed: ->
    event = document.createEvent('HTMLEvents')
    event.initEvent('change', true, false)

    # In the case of an OPTION tag, the change event should come
    # from the parent SELECT
    if @element.nodeName == 'OPTION'
      element = @element.parentNode
      element = element.parentNode if element.nodeName == 'OPTGROUP'
      element
    else
      element = @element

    element.dispatchEvent(event)

  input: ->
    event = document.createEvent('HTMLEvents')
    event.initEvent('input', true, false)
    @element.dispatchEvent(event)

  keyupdowned: (eventName, keyCode) ->
    event = document.createEvent('UIEvents')
    event.initEvent(eventName, true, true)
    event.keyCode  = keyCode
    event.which    = keyCode
    event.charCode = 0
    @element.dispatchEvent(event)

  keypressed: (altKey, ctrlKey, shiftKey, metaKey, keyCode, charCode) ->
    event = document.createEvent('UIEvents')
    event.initEvent('keypress', true, true)
    event.window   = @agent.window
    event.altKey   = altKey
    event.ctrlKey  = ctrlKey
    event.shiftKey = shiftKey
    event.metaKey  = metaKey
    event.keyCode  = keyCode
    event.charCode = charCode
    event.which    = keyCode
    @element.dispatchEvent(event)

  insideBody: ->
    @element == document.body ||
    document.evaluate('ancestor::body', @element, null, XPathResult.BOOLEAN_TYPE, null).booleanValue

  allText: ->
    @element.textContent

  visibleText: ->
    if this.isVisible()
      if @element.nodeName == "TEXTAREA"
        @element.textContent
      else
        @element.innerText || @element.textContent

  deleteText: ->
    range = document.createRange()
    range.selectNodeContents(@element)
    window.getSelection().removeAllRanges()
    window.getSelection().addRange(range)
    window.getSelection().deleteFromDocument()

  getProperty: (name) ->
    @element[name]

  getAttributes: ->
    attrs = {}
    for attr in @element.attributes
      attrs[attr.name] = attr.value.replace("\n","\\n");
    attrs

  getAttribute: (name) ->
    if name == 'checked' || name == 'selected'
      @element[name]
    else
      @element.getAttribute(name)

  scrollIntoView: ->
    @element.scrollIntoViewIfNeeded()
    #Sometimes scrollIntoViewIfNeeded doesn't seem to work, not really sure why.
    #Just calling scrollIntoView doesnt work either, however calling scrollIntoView
    #after scrollIntoViewIfNeeded when element is not in the viewport does appear to work
    @element.scrollIntoView() unless this.isInViewport()

  value: ->
    if @element.tagName == 'SELECT' && @element.multiple
      option.value for option in @element.children when option.selected
    else
      @element.value

  set: (value) ->
    return if @element.readOnly

    if (@element.maxLength >= 0)
      value = value.substr(0, @element.maxLength)

    this.trigger('focus')
    @element.value = ''

    if @element.type == 'number'
      @element.value = value
    else
      for char in value
        keyCode = this.characterToKeyCode(char)
        this.keyupdowned('keydown', keyCode)
        @element.value += char

        this.keypressed(false, false, false, false, char.charCodeAt(0), char.charCodeAt(0))
        this.keyupdowned('keyup', keyCode)

    this.changed()
    this.input()
    this.trigger('blur')

  isMultiple: ->
    @element.multiple

  setAttribute: (name, value) ->
    @element.setAttribute(name, value)

  removeAttribute: (name) ->
    @element.removeAttribute(name)

  select: (value) ->
    if @isDisabled()
      false
    else if value == false && !@element.parentNode.multiple
      false
    else
      this.trigger('focus', @element.parentNode)

      @element.selected = value
      this.changed()

      this.trigger('blur', @element.parentNode)
      true

  tagName: ->
    @element.tagName

  isVisible: (element = @element) ->
    while (element)
      style = window.getComputedStyle(element)
      return false if style.display == 'none' or
                      style.visibility == 'hidden' or
                      parseFloat(style.opacity) == 0
      element = element.parentElement

    return true

  isInViewport: ->
    rect = @element.getBoundingClientRect();

    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <= window.innerHeight &&
    rect.right <= window.innerWidth

  isDisabled: ->
    @element.disabled || @element.tagName == 'OPTION' && @element.parentNode.disabled

  path: ->
    elements = @parentIds().reverse().map((id) => @agent.get(id))
    elements.push(this)
    selectors = elements.map (el)->
      prev_siblings = el.find('xpath', "./preceding-sibling::#{el.tagName()}")
      "#{el.tagName()}[#{prev_siblings.length + 1}]"
    "//" + selectors.join('/')

  containsSelection: ->
    selectedNode = document.getSelection().focusNode

    return false if !selectedNode

    if selectedNode.nodeType == 3
      selectedNode = selectedNode.parentNode

    @element.contains(selectedNode)

  frameOffset: ->
    win    = window
    offset = { top: 0, left: 0 }

    while win.frameElement
      rect  = win.frameElement.getClientRects()[0]
      style = win.getComputedStyle(win.frameElement)
      win   = win.parent

      offset.top  += rect.top + parseInt(style.getPropertyValue("padding-top"), 10)
      offset.left += rect.left + parseInt(style.getPropertyValue("padding-left"), 10)

    offset

  position: ->
    # Elements inside an SVG return underfined for getClientRects???
    rect = @element.getClientRects()[0] || @element.getBoundingClientRect()
    throw new PoltergeistAgent.ObsoleteNode unless rect
    frameOffset = this.frameOffset()

    pos = {
      top:    rect.top    + frameOffset.top,
      right:  rect.right  + frameOffset.left,
      left:   rect.left   + frameOffset.left,
      bottom: rect.bottom + frameOffset.top,
      width:  rect.width,
      height: rect.height
    }

    pos

  trigger: (name, element = @element) ->
    if Node.EVENTS.MOUSE.indexOf(name) != -1
      event = document.createEvent('MouseEvent')
      event.initMouseEvent(
        name, true, true, window, 0, 0, 0, 0, 0,
        false, false, false, false, 0, null
      )
    else if Node.EVENTS.FOCUS.indexOf(name) != -1
      event = this.obtainEvent(name)
    else if Node.EVENTS.FORM.indexOf(name) != -1
      event = this.obtainEvent(name)
    else
      throw "Unknown event"

    element.dispatchEvent(event)

  obtainEvent: (name) ->
    event = document.createEvent('HTMLEvents')
    event.initEvent(name, true, true)
    event

  mouseEventTest: (x, y) ->
    frameOffset = this.frameOffset()

    x -= frameOffset.left
    y -= frameOffset.top

    el = origEl = document.elementFromPoint(x, y)

    while el
      if el == @element
        return { status: 'success' }
      else
        el = el.parentNode

    { status: 'failure', selector: origEl && this.getSelector(origEl) }
  getSelector: (el) ->
    selector = if el.tagName != 'HTML' then this.getSelector(el.parentNode) + ' ' else ''
    selector += el.tagName.toLowerCase()
    selector += "##{el.id}" if el.id

    #PhantomJS < 2.0 doesn't support classList for SVG elements - so get classes manually
    classes = el.classList || (el.getAttribute('class')?.trim()?.split(/\s+/)) || []
    for className in classes when className != ''
      selector += ".#{className}"
    selector

  characterToKeyCode: (character) ->
    code = character.toUpperCase().charCodeAt(0)
    specialKeys =
      96: 192  #`
      45: 189  #-
      61: 187  #=
      91: 219  #[
      93: 221  #]
      92: 220  #\
      59: 186  #;
      39: 222  #'
      44: 188  #,
      46: 190  #.
      47: 191  #/
      127: 46  #delete
      126: 192 #~
      33: 49   #!
      64: 50   #@
      35: 51   ##
      36: 52   #$
      37: 53   #%
      94: 54   #^
      38: 55   #&
      42: 56   #*
      40: 57   #(
      41: 48   #)
      95: 189  #_
      43: 187  #+
      123: 219 #{
      125: 221 #}
      124: 220 #|
      58: 186  #:
      34: 222  #"
      60: 188  #<
      62: 190  #>
      63: 191 #?

    specialKeys[code] || code

  isDOMEqual: (other_id) ->
    @element == @agent.get(other_id).element

window.__poltergeist = new PoltergeistAgent

document.addEventListener(
  'DOMContentLoaded',
  -> console.log('__DOMContentLoaded')
)
