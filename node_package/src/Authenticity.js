export default {

  authenticityToken() {
    const token = document.querySelector('meta[name="csrf-token"]');
    return token ? token.content : null;
  },

  authenticityHeaders(otherHeaders = {}) {
    return Object.assign(otherHeaders, {
      'X-CSRF-Token': this.authenticityToken(),
      'X-Requested-With': 'XMLHttpRequest',
    });
  },
};
