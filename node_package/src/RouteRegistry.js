// key = name used by react_on_rails
// value = { name, route }
const _routes = new Map();

export default {
  /**
   * @param routes { route1: route1, route2: route2, etc. }
   */
  register(routes) {
    Object.keys(routes).forEach(name => {
      if (_routes.has(name)) {
        console.warn('Called register for route that is already registered', name);
      }

      const route = routes[name];
      if (!route) {
        throw new Error(`Called register with null route named ${name}`);
      }

      _routes.set(name, {
        name,
        route,
      });
    });
  },

  /**
   * @param name
   * @returns { name, route, generatorFunction }
   */
  get(name) {
    if (_routes.has(name)) {
      return _routes.get(name);
    } else {
      const keys = Array.from(_routes.keys()).join(', ');
      throw new Error(`Could not find route registered with name ${name}. \
Registered route names include [ ${keys} ]. Maybe you forgot to register the route?`);
    }
  },

  /**
   * Get a Map containing all registered routes. Useful for debugging.
   * @returns Map where key is the route name and values are the
   * { name, route, generatorFunction}
   */
  routes() {
    return _routes;
  },
};
