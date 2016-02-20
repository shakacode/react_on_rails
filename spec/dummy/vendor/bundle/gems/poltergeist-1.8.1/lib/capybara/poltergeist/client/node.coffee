# Proxy object for forwarding method calls to the node object inside the page.

class Poltergeist.Node
  @DELEGATES = ['allText', 'visibleText', 'getAttribute', 'value', 'set', 'setAttribute', 'isObsolete',
                'removeAttribute', 'isMultiple', 'select', 'tagName', 'find', 'getAttributes',
                'isVisible', 'isInViewport', 'position', 'trigger', 'parentId', 'parentIds', 'mouseEventTest',
                'scrollIntoView', 'isDOMEqual', 'isDisabled', 'deleteText', 'containsSelection',
                'path', 'getProperty']

  constructor: (@page, @id) ->

  parent: ->
    new Poltergeist.Node(@page, this.parentId())

  for name in @DELEGATES
    do (name) =>
      this.prototype[name] = (args...) ->
        @page.nodeCall(@id, name, args)

  mouseEventPosition: ->
    viewport = @page.viewportSize()
    pos      = this.position()

    middle = (start, end, size) ->
      start + ((Math.min(end, size) - start) / 2)

    {
      x: middle(pos.left, pos.right,  viewport.width),
      y: middle(pos.top,  pos.bottom, viewport.height)
    }

  mouseEvent: (name) ->
    this.scrollIntoView()
    pos = this.mouseEventPosition()
    test = this.mouseEventTest(pos.x, pos.y)
    if test.status == 'success'
      if name == 'rightclick'
        @page.mouseEvent('click', pos.x, pos.y, 'right')
        this.trigger('contextmenu')
      else
        @page.mouseEvent(name, pos.x, pos.y)
      pos
    else
      throw new Poltergeist.MouseEventFailed(name, test.selector, pos)

  dragTo: (other) ->
    this.scrollIntoView()

    position      = this.mouseEventPosition()
    otherPosition = other.mouseEventPosition()

    @page.mouseEvent('mousedown', position.x,      position.y)
    @page.mouseEvent('mouseup',   otherPosition.x, otherPosition.y)

  dragBy: (x, y) ->
    this.scrollIntoView()

    position      = this.mouseEventPosition()

    final_pos =
      x: position.x + x
      y: position.y + y

    @page.mouseEvent('mousedown', position.x, position.y)
    @page.mouseEvent('mouseup', final_pos.x, final_pos.y)


  isEqual: (other) ->
    @page == other.page && this.isDOMEqual(other.id)

