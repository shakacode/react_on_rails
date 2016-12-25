// @flow

export default {

  authenticityToken() {
    const token: ?HTMLElement = document.querySelector('meta[name="csrf-token"]');
    if (token && (token instanceof window.HTMLMetaElement)) {
      return token.content;
    }
    return null;
  },

  authenticityHeaders(otherHeaders: {[id:string]: string} = {}) {
    return Object.assign(otherHeaders, {
      'X-CSRF-Token': this.authenticityToken(),
      'X-Requested-With': 'XMLHttpRequest',
    });
  },
};
