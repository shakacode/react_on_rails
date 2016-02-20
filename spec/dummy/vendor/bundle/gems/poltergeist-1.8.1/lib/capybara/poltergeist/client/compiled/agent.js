var PoltergeistAgent;

PoltergeistAgent = (function() {
  PoltergeistAgent.JSON || (PoltergeistAgent.JSON = {
    parse: JSON.parse,
    stringify: JSON.stringify
  });

  function PoltergeistAgent() {
    this.elements = [];
    this.nodes = {};
  }

  PoltergeistAgent.prototype.externalCall = function(name, args) {
    var error, error1;
    try {
      return {
        value: this[name].apply(this, args)
      };
    } catch (error1) {
      error = error1;
      return {
        error: {
          message: error.toString(),
          stack: error.stack
        }
      };
    }
  };

  PoltergeistAgent.stringify = function(object) {
    var error, error1;
    try {
      return PoltergeistAgent.JSON.stringify(object, function(key, value) {
        if (Array.isArray(this[key])) {
          return this[key];
        } else {
          return value;
        }
      });
    } catch (error1) {
      error = error1;
      if (error instanceof TypeError) {
        return '"(cyclic structure)"';
      } else {
        throw error;
      }
    }
  };

  PoltergeistAgent.prototype.currentUrl = function() {
    return window.location.href.replace(/\ /g, '%20');
  };

  PoltergeistAgent.prototype.find = function(method, selector, within) {
    var el, error, error1, i, j, len, results, results1, xpath;
    if (within == null) {
      within = document;
    }
    try {
      if (method === "xpath") {
        xpath = document.evaluate(selector, within, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        results = (function() {
          var j, ref, results1;
          results1 = [];
          for (i = j = 0, ref = xpath.snapshotLength; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
            results1.push(xpath.snapshotItem(i));
          }
          return results1;
        })();
      } else {
        results = within.querySelectorAll(selector);
      }
      results1 = [];
      for (j = 0, len = results.length; j < len; j++) {
        el = results[j];
        results1.push(this.register(el));
      }
      return results1;
    } catch (error1) {
      error = error1;
      if (error.code === DOMException.SYNTAX_ERR || error.code === 51) {
        throw new PoltergeistAgent.InvalidSelector;
      } else {
        throw error;
      }
    }
  };

  PoltergeistAgent.prototype.register = function(element) {
    this.elements.push(element);
    return this.elements.length - 1;
  };

  PoltergeistAgent.prototype.documentSize = function() {
    return {
      height: document.documentElement.scrollHeight || document.documentElement.clientHeight,
      width: document.documentElement.scrollWidth || document.documentElement.clientWidth
    };
  };

  PoltergeistAgent.prototype.get = function(id) {
    var base;
    return (base = this.nodes)[id] || (base[id] = new PoltergeistAgent.Node(this, this.elements[id]));
  };

  PoltergeistAgent.prototype.nodeCall = function(id, name, args) {
    var node;
    node = this.get(id);
    if (node.isObsolete()) {
      throw new PoltergeistAgent.ObsoleteNode;
    }
    return node[name].apply(node, args);
  };

  PoltergeistAgent.prototype.beforeUpload = function(id) {
    return this.get(id).setAttribute('_poltergeist_selected', '');
  };

  PoltergeistAgent.prototype.afterUpload = function(id) {
    return this.get(id).removeAttribute('_poltergeist_selected');
  };

  PoltergeistAgent.prototype.clearLocalStorage = function() {
    return localStorage.clear();
  };

  return PoltergeistAgent;

})();

PoltergeistAgent.ObsoleteNode = (function() {
  function ObsoleteNode() {}

  ObsoleteNode.prototype.toString = function() {
    return "PoltergeistAgent.ObsoleteNode";
  };

  return ObsoleteNode;

})();

PoltergeistAgent.InvalidSelector = (function() {
  function InvalidSelector() {}

  InvalidSelector.prototype.toString = function() {
    return "PoltergeistAgent.InvalidSelector";
  };

  return InvalidSelector;

})();

PoltergeistAgent.Node = (function() {
  Node.EVENTS = {
    FOCUS: ['blur', 'focus', 'focusin', 'focusout'],
    MOUSE: ['click', 'dblclick', 'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseover', 'mouseout', 'mouseup', 'contextmenu'],
    FORM: ['submit']
  };

  function Node(agent, element1) {
    this.agent = agent;
    this.element = element1;
  }

  Node.prototype.parentId = function() {
    return this.agent.register(this.element.parentNode);
  };

  Node.prototype.parentIds = function() {
    var ids, parent;
    ids = [];
    parent = this.element.parentNode;
    while (parent !== document) {
      ids.push(this.agent.register(parent));
      parent = parent.parentNode;
    }
    return ids;
  };

  Node.prototype.find = function(method, selector) {
    return this.agent.find(method, selector, this.element);
  };

  Node.prototype.isObsolete = function() {
    var obsolete;
    obsolete = (function(_this) {
      return function(element) {
        var parent;
        if ((parent = element.parentNode) != null) {
          if (parent === document) {
            return false;
          } else {
            return obsolete(parent);
          }
        } else {
          return true;
        }
      };
    })(this);
    return obsolete(this.element);
  };

  Node.prototype.changed = function() {
    var element, event;
    event = document.createEvent('HTMLEvents');
    event.initEvent('change', true, false);
    if (this.element.nodeName === 'OPTION') {
      element = this.element.parentNode;
      if (element.nodeName === 'OPTGROUP') {
        element = element.parentNode;
      }
      element;
    } else {
      element = this.element;
    }
    return element.dispatchEvent(event);
  };

  Node.prototype.input = function() {
    var event;
    event = document.createEvent('HTMLEvents');
    event.initEvent('input', true, false);
    return this.element.dispatchEvent(event);
  };

  Node.prototype.keyupdowned = function(eventName, keyCode) {
    var event;
    event = document.createEvent('UIEvents');
    event.initEvent(eventName, true, true);
    event.keyCode = keyCode;
    event.which = keyCode;
    event.charCode = 0;
    return this.element.dispatchEvent(event);
  };

  Node.prototype.keypressed = function(altKey, ctrlKey, shiftKey, metaKey, keyCode, charCode) {
    var event;
    event = document.createEvent('UIEvents');
    event.initEvent('keypress', true, true);
    event.window = this.agent.window;
    event.altKey = altKey;
    event.ctrlKey = ctrlKey;
    event.shiftKey = shiftKey;
    event.metaKey = metaKey;
    event.keyCode = keyCode;
    event.charCode = charCode;
    event.which = keyCode;
    return this.element.dispatchEvent(event);
  };

  Node.prototype.insideBody = function() {
    return this.element === document.body || document.evaluate('ancestor::body', this.element, null, XPathResult.BOOLEAN_TYPE, null).booleanValue;
  };

  Node.prototype.allText = function() {
    return this.element.textContent;
  };

  Node.prototype.visibleText = function() {
    if (this.isVisible()) {
      if (this.element.nodeName === "TEXTAREA") {
        return this.element.textContent;
      } else {
        return this.element.innerText || this.element.textContent;
      }
    }
  };

  Node.prototype.deleteText = function() {
    var range;
    range = document.createRange();
    range.selectNodeContents(this.element);
    window.getSelection().removeAllRanges();
    window.getSelection().addRange(range);
    return window.getSelection().deleteFromDocument();
  };

  Node.prototype.getProperty = function(name) {
    return this.element[name];
  };

  Node.prototype.getAttributes = function() {
    var attr, attrs, j, len, ref;
    attrs = {};
    ref = this.element.attributes;
    for (j = 0, len = ref.length; j < len; j++) {
      attr = ref[j];
      attrs[attr.name] = attr.value.replace("\n", "\\n");
    }
    return attrs;
  };

  Node.prototype.getAttribute = function(name) {
    if (name === 'checked' || name === 'selected') {
      return this.element[name];
    } else {
      return this.element.getAttribute(name);
    }
  };

  Node.prototype.scrollIntoView = function() {
    this.element.scrollIntoViewIfNeeded();
    if (!this.isInViewport()) {
      return this.element.scrollIntoView();
    }
  };

  Node.prototype.value = function() {
    var j, len, option, ref, results1;
    if (this.element.tagName === 'SELECT' && this.element.multiple) {
      ref = this.element.children;
      results1 = [];
      for (j = 0, len = ref.length; j < len; j++) {
        option = ref[j];
        if (option.selected) {
          results1.push(option.value);
        }
      }
      return results1;
    } else {
      return this.element.value;
    }
  };

  Node.prototype.set = function(value) {
    var char, j, keyCode, len;
    if (this.element.readOnly) {
      return;
    }
    if (this.element.maxLength >= 0) {
      value = value.substr(0, this.element.maxLength);
    }
    this.trigger('focus');
    this.element.value = '';
    if (this.element.type === 'number') {
      this.element.value = value;
    } else {
      for (j = 0, len = value.length; j < len; j++) {
        char = value[j];
        keyCode = this.characterToKeyCode(char);
        this.keyupdowned('keydown', keyCode);
        this.element.value += char;
        this.keypressed(false, false, false, false, char.charCodeAt(0), char.charCodeAt(0));
        this.keyupdowned('keyup', keyCode);
      }
    }
    this.changed();
    this.input();
    return this.trigger('blur');
  };

  Node.prototype.isMultiple = function() {
    return this.element.multiple;
  };

  Node.prototype.setAttribute = function(name, value) {
    return this.element.setAttribute(name, value);
  };

  Node.prototype.removeAttribute = function(name) {
    return this.element.removeAttribute(name);
  };

  Node.prototype.select = function(value) {
    if (this.isDisabled()) {
      return false;
    } else if (value === false && !this.element.parentNode.multiple) {
      return false;
    } else {
      this.trigger('focus', this.element.parentNode);
      this.element.selected = value;
      this.changed();
      this.trigger('blur', this.element.parentNode);
      return true;
    }
  };

  Node.prototype.tagName = function() {
    return this.element.tagName;
  };

  Node.prototype.isVisible = function(element) {
    var style;
    if (element == null) {
      element = this.element;
    }
    while (element) {
      style = window.getComputedStyle(element);
      if (style.display === 'none' || style.visibility === 'hidden' || parseFloat(style.opacity) === 0) {
        return false;
      }
      element = element.parentElement;
    }
    return true;
  };

  Node.prototype.isInViewport = function() {
    var rect;
    rect = this.element.getBoundingClientRect();
    return rect.top >= 0 && rect.left >= 0 && rect.bottom <= window.innerHeight && rect.right <= window.innerWidth;
  };

  Node.prototype.isDisabled = function() {
    return this.element.disabled || this.element.tagName === 'OPTION' && this.element.parentNode.disabled;
  };

  Node.prototype.path = function() {
    var elements, selectors;
    elements = this.parentIds().reverse().map((function(_this) {
      return function(id) {
        return _this.agent.get(id);
      };
    })(this));
    elements.push(this);
    selectors = elements.map(function(el) {
      var prev_siblings;
      prev_siblings = el.find('xpath', "./preceding-sibling::" + (el.tagName()));
      return (el.tagName()) + "[" + (prev_siblings.length + 1) + "]";
    });
    return "//" + selectors.join('/');
  };

  Node.prototype.containsSelection = function() {
    var selectedNode;
    selectedNode = document.getSelection().focusNode;
    if (!selectedNode) {
      return false;
    }
    if (selectedNode.nodeType === 3) {
      selectedNode = selectedNode.parentNode;
    }
    return this.element.contains(selectedNode);
  };

  Node.prototype.frameOffset = function() {
    var offset, rect, style, win;
    win = window;
    offset = {
      top: 0,
      left: 0
    };
    while (win.frameElement) {
      rect = win.frameElement.getClientRects()[0];
      style = win.getComputedStyle(win.frameElement);
      win = win.parent;
      offset.top += rect.top + parseInt(style.getPropertyValue("padding-top"), 10);
      offset.left += rect.left + parseInt(style.getPropertyValue("padding-left"), 10);
    }
    return offset;
  };

  Node.prototype.position = function() {
    var frameOffset, pos, rect;
    rect = this.element.getClientRects()[0] || this.element.getBoundingClientRect();
    if (!rect) {
      throw new PoltergeistAgent.ObsoleteNode;
    }
    frameOffset = this.frameOffset();
    pos = {
      top: rect.top + frameOffset.top,
      right: rect.right + frameOffset.left,
      left: rect.left + frameOffset.left,
      bottom: rect.bottom + frameOffset.top,
      width: rect.width,
      height: rect.height
    };
    return pos;
  };

  Node.prototype.trigger = function(name, element) {
    var event;
    if (element == null) {
      element = this.element;
    }
    if (Node.EVENTS.MOUSE.indexOf(name) !== -1) {
      event = document.createEvent('MouseEvent');
      event.initMouseEvent(name, true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
    } else if (Node.EVENTS.FOCUS.indexOf(name) !== -1) {
      event = this.obtainEvent(name);
    } else if (Node.EVENTS.FORM.indexOf(name) !== -1) {
      event = this.obtainEvent(name);
    } else {
      throw "Unknown event";
    }
    return element.dispatchEvent(event);
  };

  Node.prototype.obtainEvent = function(name) {
    var event;
    event = document.createEvent('HTMLEvents');
    event.initEvent(name, true, true);
    return event;
  };

  Node.prototype.mouseEventTest = function(x, y) {
    var el, frameOffset, origEl;
    frameOffset = this.frameOffset();
    x -= frameOffset.left;
    y -= frameOffset.top;
    el = origEl = document.elementFromPoint(x, y);
    while (el) {
      if (el === this.element) {
        return {
          status: 'success'
        };
      } else {
        el = el.parentNode;
      }
    }
    return {
      status: 'failure',
      selector: origEl && this.getSelector(origEl)
    };
  };

  Node.prototype.getSelector = function(el) {
    var className, classes, j, len, ref, ref1, selector;
    selector = el.tagName !== 'HTML' ? this.getSelector(el.parentNode) + ' ' : '';
    selector += el.tagName.toLowerCase();
    if (el.id) {
      selector += "#" + el.id;
    }
    classes = el.classList || ((ref = el.getAttribute('class')) != null ? (ref1 = ref.trim()) != null ? ref1.split(/\s+/) : void 0 : void 0) || [];
    for (j = 0, len = classes.length; j < len; j++) {
      className = classes[j];
      if (className !== '') {
        selector += "." + className;
      }
    }
    return selector;
  };

  Node.prototype.characterToKeyCode = function(character) {
    var code, specialKeys;
    code = character.toUpperCase().charCodeAt(0);
    specialKeys = {
      96: 192,
      45: 189,
      61: 187,
      91: 219,
      93: 221,
      92: 220,
      59: 186,
      39: 222,
      44: 188,
      46: 190,
      47: 191,
      127: 46,
      126: 192,
      33: 49,
      64: 50,
      35: 51,
      36: 52,
      37: 53,
      94: 54,
      38: 55,
      42: 56,
      40: 57,
      41: 48,
      95: 189,
      43: 187,
      123: 219,
      125: 221,
      124: 220,
      58: 186,
      34: 222,
      60: 188,
      62: 190,
      63: 191
    };
    return specialKeys[code] || code;
  };

  Node.prototype.isDOMEqual = function(other_id) {
    return this.element === this.agent.get(other_id).element;
  };

  return Node;

})();

window.__poltergeist = new PoltergeistAgent;

document.addEventListener('DOMContentLoaded', function() {
  return console.log('__DOMContentLoaded');
});
