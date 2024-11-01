import fs from 'fs';
import { env } from 'process';

const BUNDLE_PATH = './tmp/node-renderer-bundles-test';
if (fs.existsSync(BUNDLE_PATH)) {
  fs.rmSync(BUNDLE_PATH, { recursive: true, force: true });
}

const config = {
  // This is the default but avoids searching for the Rails root
  bundlePath: BUNDLE_PATH,
  port: env.RENDERER_PORT || 3800, // Listen at RENDERER_PORT env value or default port 3800
  logLevel: env.RENDERER_LOG_LEVEL || 'info',

  // See value in /config/initializers/react_on_rails_pro.rb. Should use env value in real app.
  password: 'myPassword1',
  // This is a test account for React on Rails Pro. Substitute your own.
  honeybadgerApiKey: 'a602365c',

  // If set to true, `supportModules` enables the server-bundle code to call a default set of NodeJS modules
  // that get added to the VM context: { Buffer, process, setTimeout, setInterval, clearTimeout, clearInterval }.
  // This option is required to equal `true` if you want to use loadable components.
  // Setting this value to false causes the NodeRenderer to behave like ExecJS
  supportModules: true,

  // additionalContext enables you to specify additional NodeJS modules to add to the VM context in
  // addition to our supportModules defaults.
  additionalContext: { URL, AbortController },

  // Required to use setTimeout, setInterval, & clearTimeout during server rendering
  includeTimerPolyfills: false,

  // If set to true, replayServerAsyncOperationLogs will replay console logs from async server operations.
  // If set to false, replayServerAsyncOperationLogs will replay console logs from sync server operations only.
  replayServerAsyncOperationLogs: true,
};

export default config;
