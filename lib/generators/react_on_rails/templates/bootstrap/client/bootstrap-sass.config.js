// See https://github.com/shakacode/bootstrap-sass-loader for more information

// IMPORTANT: Make sure to keep the customizations defined in this file
//            in-sync with the ones defined in app/assets/stylesheets/_bootstrap-custom.scss.

// For a reference on customizations,refer to:
//  https://github.com/twbs/bootstrap-sass/blob/master/assets/stylesheets/_bootstrap.scss

module.exports = {
  bootstrapCustomizations: './assets/stylesheets/_pre-bootstrap.scss',
  mainSass: './assets/stylesheets/_post-bootstrap.scss',

  // Default for the style loading is to put in your js files
  // styleLoader: 'style-loader!css-loader!sass-loader',

  // See: https://github.com/sass/node-sass#outputstyle
  //      https://github.com/sass/node-sass#imagepath
  styleLoader: 'style-loader!css-loader!sass-loader?imagePath=/assets/images',

  // ### Scripts
  // Any scripts here set to false will never make it to the client,
  // i.e. it's not packaged by webpack.
  scripts: {
    transition: true,
    alert: true,
    button: true,

    carousel: true,
    collapse: true,
    dropdown: true,

    modal: true,
    tooltip: true,
    popover: true,
    scrollspy: true,
    tab: true,
    affix: true,
  },

  // ### Styles
  // Enable or disable certain less components and thus remove
  // the css for them from the build.
  styles: {
    mixins: true,

    normalize: true,
    print: true,

    scaffolding: true,
    type: true,
    code: true,
    grid: true,
    tables: true,
    forms: true,
    buttons: true,

    'component-animations': true,
    glyphicons: true,
    dropdowns: true,
    'button-groups': true,
    'input-groups': true,
    navs: true,
    navbar: true,
    breadcrumbs: true,
    pagination: true,
    pager: true,
    labels: true,
    badges: true,

    jumbotron: true,
    thumbnails: true,
    alerts: true,

    'progress-bars': true,
    media: true,
    'list-group': true,
    panels: true,
    wells: true,
    close: true,

    modals: true,
    tooltip: true,
    popovers: true,
    carousel: true,

    utilities: true,
    'responsive-utilities': true,
  },
};
