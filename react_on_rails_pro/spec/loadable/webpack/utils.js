const addOption = (shouldAdd, option) => (shouldAdd ? option() : undefined);

module.exports = {
  addOption,
  removeEmpty: (array) => array.filter((item) => !!item),
  getEnvVar: (ENV_VAR) => JSON.stringify(process.env[ENV_VAR]),
};
