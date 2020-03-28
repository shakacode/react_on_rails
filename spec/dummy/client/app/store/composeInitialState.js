// Real world is that you'll want to do lots of manipulations of the data you get back from Rails
// to coerce it into exactly what you want your initial redux state.
export default (props, railsContext) => Object.assign({}, props, { railsContext });
