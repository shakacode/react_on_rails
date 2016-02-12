function handleEvent(eventName, handler) {
  return document.addEventListener(eventName, handler, false);
}

function translateEvent(arg) {
  const from = arg.from;
  const to = arg.to;
  function handler(e) {
    const event = arg.dispatch(to, {
      target: e.target,
      cancelable: e.cancelable,
      data: e.data,
    });
    if (event.defaultPrevented) {
      return event.preventDefault();
    }
  }

  return handleEvent(from, handler);
}

export default function turbolinksShim() {
  const defer = Turbolinks.defer;
  const dispatch = Turbolinks.dispatch;
  let loaded = false;

  translateEvent({
    from: 'turbolinks:click',
    to: 'page:before-change',
    dispatch,
  });

  translateEvent({
    from: 'turbolinks:request-start',
    to: 'page:fetch',
    dispatch,
  });

  translateEvent({
    from: 'turbolinks:request-end',
    to: 'page:receive',
    dispatch,
  });

  translateEvent({
    from: 'turbolinks:before-cache',
    to: 'page:before-unload',
    dispatch,
  });

  translateEvent({
    from: 'turbolinks:render',
    to: 'page:update',
    dispatch,
  });

  translateEvent({
    from: 'turbolinks:load',
    to: 'page:change',
    dispatch,
  });

  translateEvent({
    from: 'turbolinks:load',
    to: 'page:update',
    dispatch,
  });

  handleEvent('DOMContentLoaded', () => {
    defer(() => {
      loaded = true;
      return;
    });
  });

  handleEvent('turbolinks:load', () => {
    if (loaded) {
      return dispatch('page:load');
    }
  });

  if (typeof jQuery === 'function') {
    jQuery(document).on('ajaxSuccess', (event, xhr) => {
      if (jQuery.trim(xhr.responseText).length > 0) {
        return dispatch('page:update');
      }
    });
  }
}
