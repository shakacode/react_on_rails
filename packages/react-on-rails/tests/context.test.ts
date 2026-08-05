/**
 * @jest-environment jsdom
 */

import { getRailsContext, resetRailsContext } from '../src/context.ts';

function installRailsContext(pathname: string): void {
  document.body.innerHTML = `<div id="js-react-on-rails-context">${JSON.stringify({ pathname })}</div>`;
}

describe('RailsContext cache', () => {
  beforeEach(() => {
    resetRailsContext();
    document.body.innerHTML = '';
  });

  afterEach(() => {
    resetRailsContext();
  });

  it('reuses the parsed context while its DOM source is unchanged', () => {
    installRailsContext('/posts/1');

    expect(getRailsContext()).toBe(getRailsContext());
  });

  it('reads replacement context before page-loaded callbacks run', () => {
    installRailsContext('/posts/1');
    expect(getRailsContext()?.pathname).toBe('/posts/1');

    installRailsContext('/posts/2');

    expect(getRailsContext()?.pathname).toBe('/posts/2');
  });

  it('reads context text morphed in place before page-loaded callbacks run', () => {
    installRailsContext('/posts/1');
    expect(getRailsContext()?.pathname).toBe('/posts/1');

    const contextElement = document.getElementById('js-react-on-rails-context');
    if (!contextElement) throw new Error('Expected RailsContext element');
    contextElement.textContent = JSON.stringify({ pathname: '/posts/2' });

    expect(getRailsContext()?.pathname).toBe('/posts/2');
  });
});
