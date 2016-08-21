// @flow

export default {

  authenticityToken() {
    const token: {content?: string} = document.querySelector('meta[name="csrf-token"]');
    return token ? token.content : null;
  },

  authenticityHeaders(otherHeaders: Object = {}) {
    return Object.assign(otherHeaders, {
      'X-CSRF-Token': this.authenticityToken(),
      'X-Requested-With': 'XMLHttpRequest',
    });
  },
};
