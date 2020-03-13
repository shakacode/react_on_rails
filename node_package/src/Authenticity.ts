export default {

  authenticityToken(): string | null {
    const token = document.querySelector('meta[name="csrf-token"]');
    if (token && (token instanceof window.HTMLMetaElement)) {
      return token.content;
    }
    return null;
  },

  authenticityHeaders(
    otherHeaders: {[id: string]: string} = {}
  ): { [id: string]: string } & { 'X-CSRF-Token': string; 'X-Requested-With': string } {
    return Object.assign(otherHeaders, {
      'X-CSRF-Token': this.authenticityToken(),
      'X-Requested-With': 'XMLHttpRequest',
    });
  },
};
