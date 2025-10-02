import { request, expect } from '@playwright/test';
import config from '../../playwright.config';

const contextPromise = request.newContext({
  baseURL: config.use ? config.use.baseURL : 'http://localhost:5017',
});

const appCommands = async (data) => {
  const context = await contextPromise;
  const response = await context.post('/__e2e__/command', { data });

  expect(response.ok()).toBeTruthy();
  return response.body;
};

const app = (name, options = {}) => appCommands({ name, options }).then((body) => body[0]);
const appScenario = (name, options = {}) => app(`scenarios/${name}`, options);
const appEval = (code) => app('eval', code);
const appFactories = (options) => app('factory_bot', options);

const appVcrInsertCassette = async (cassetteName, options) => {
  const context = await contextPromise;
  // eslint-disable-next-line no-param-reassign
  if (!options) options = {};

  // eslint-disable-next-line no-param-reassign
  Object.keys(options).forEach((key) => (options[key] === undefined ? delete options[key] : {}));
  const response = await context.post('/__e2e__/vcr/insert', { data: [cassetteName, options] });
  expect(response.ok()).toBeTruthy();
  return response.body;
};

const appVcrEjectCassette = async () => {
  const context = await contextPromise;

  const response = await context.post('/__e2e__/vcr/eject');
  expect(response.ok()).toBeTruthy();
  return response.body;
};

export { appCommands, app, appScenario, appEval, appFactories, appVcrInsertCassette, appVcrEjectCassette };
