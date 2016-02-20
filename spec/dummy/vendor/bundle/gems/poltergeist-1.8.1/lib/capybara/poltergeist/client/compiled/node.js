var slice = [].slice;

Poltergeist.Node = (function() {
  var fn, i, len, name, ref;

  Node.DELEGATES = ['allText', 'visibleText', 'getAttribute', 'value', 'set', 'setAttribute', 'isObsolete', 'removeAttribute', 'isMultiple', 'select', 'tagName', 'find', 'getAttributes', 'isVisible', 'isInViewport', 'position', 'trigger', 'parentId', 'parentIds', 'mouseEventTest', 'scrollIntoView', 'isDOMEqual', 'isDisabled', 'deleteText', 'containsSelection', 'path', 'getProperty'];

  function Node(page, id) {
    this.page = page;
    this.id = id;
  }

  Node.prototype.parent = function() {
    return new Poltergeist.Node(this.page, this.parentId());
  };

  ref = Node.DELEGATES;
  fn = function(name) {
    return Node.prototype[name] = function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return this.page.nodeCall(this.id, name, args);
    };
  };
  for (i = 0, len = ref.length; i < len; i++) {
    name = ref[i];
    fn(name);
  }

  Node.prototype.mouseEventPosition = function() {
    var middle, pos, viewport;
    viewport = this.page.viewportSize();
    pos = this.position();
    middle = function(start, end, size) {
      return start + ((Math.min(end, size) - start) / 2);
    };
    return {
      x: middle(pos.left, pos.right, viewport.width),
      y: middle(pos.top, pos.bottom, viewport.height)
    };
  };

  Node.prototype.mouseEvent = function(name) {
    var pos, test;
    this.scrollIntoView();
    pos = this.mouseEventPosition();
    test = this.mouseEventTest(pos.x, pos.y);
    if (test.status === 'success') {
      if (name === 'rightclick') {
        this.page.mouseEvent('click', pos.x, pos.y, 'right');
        this.trigger('contextmenu');
      } else {
        this.page.mouseEvent(name, pos.x, pos.y);
      }
      return pos;
    } else {
      throw new Poltergeist.MouseEventFailed(name, test.selector, pos);
    }
  };

  Node.prototype.dragTo = function(other) {
    var otherPosition, position;
    this.scrollIntoView();
    position = this.mouseEventPosition();
    otherPosition = other.mouseEventPosition();
    this.page.mouseEvent('mousedown', position.x, position.y);
    return this.page.mouseEvent('mouseup', otherPosition.x, otherPosition.y);
  };

  Node.prototype.dragBy = function(x, y) {
    var final_pos, position;
    this.scrollIntoView();
    position = this.mouseEventPosition();
    final_pos = {
      x: position.x + x,
      y: position.y + y
    };
    this.page.mouseEvent('mousedown', position.x, position.y);
    return this.page.mouseEvent('mouseup', final_pos.x, final_pos.y);
  };

  Node.prototype.isEqual = function(other) {
    return this.page === other.page && this.isDOMEqual(other.id);
  };

  return Node;

})();
