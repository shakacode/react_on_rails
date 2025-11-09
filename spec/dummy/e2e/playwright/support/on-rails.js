import { request } from '@playwright/test';
import config from '../../playwright.config';

const contextPromise = request.newContext({
  baseURL: config.use ? config.use.baseURL : 'http://localhost:5017',
});

const appCommands = async (data) => {
  const context = await contextPromise;
  const response = await context.post('/__e2e__/command', { data });

  if (!response.ok()) {
    const text = await response.text();
    throw new Error(`Rails command '${data.name}' failed: ${response.status()} - ${text}`);
  }

  return response.json();
};

const app = (name, options = {}) => appCommands({ name, options }).then((body) => body[0]);
const appScenario = (name, options = {}) => app(`scenarios/${name}`, options);
const appEval = (code) => app('eval', code);
const appFactories = (options) => app('factory_bot', options);

const appVcrInsertCassette = async (cassetteName, options) => {
  const context = await contextPromise;
  const normalizedOptions = options || {};
  const cleanedOptions = Object.fromEntries(
    Object.entries(normalizedOptions).filter(([, value]) => value !== undefined),
  );

  const response = await context.post('/__e2e__/vcr/insert', { data: [cassetteName, cleanedOptions] });

  if (!response.ok()) {
    const text = await response.text();
    throw new Error(`VCR insert cassette '${cassetteName}' failed: ${response.status()} - ${text}`);
  }

  return response.json();
};

const appVcrEjectCassette = async () => {
  const context = await contextPromise;

  const response = await context.post('/__e2e__/vcr/eject');

  if (!response.ok()) {
    const text = await response.text();
    throw new Error(`VCR eject cassette failed: ${response.status()} - ${text}`);
  }

  return response.json();
};

export { appCommands, app, appScenario, appEval, appFactories, appVcrInsertCassette, appVcrEjectCassette };
