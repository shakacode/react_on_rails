#!/usr/bin/env node
/**
 * Test script to send HTTP/2 bidirectional streaming request to Node renderer
 * Similar to what React on Rails Pro sends via httpx
 *
 * Usage:
 *   node test_http2_bidi_request.mjs [options]
 *
 * Options:
 *   --url <url>               Node renderer URL (default: http://localhost:3800)
 *   --bundle-hash <hash>      Server bundle hash (default: test-bundle-hash)
 *   --rsc-bundle-hash <hash>  RSC bundle hash (required for RSC support)
 *   --delay <ms>              Delay before closing request (default: 0)
 *   --delay-after-send        Add delay after sending all data but before closing
 *
 * Examples:
 *   # Basic test - send request immediately and close
 *   node test_http2_bidi_request.mjs --bundle-hash <server-hash> --rsc-bundle-hash <rsc-hash>
 *
 *   # With delay before closing (simulates slow async props)
 *   node test_http2_bidi_request.mjs --bundle-hash <server-hash> --rsc-bundle-hash <rsc-hash> --delay 1000
 *
 *   # Against specific renderer
 *   node test_http2_bidi_request.mjs --url http://localhost:3800 --bundle-hash <hash> --rsc-bundle-hash <rsc-hash>
 */

import http2 from 'node:http2';
import { URL } from 'node:url';

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  url: 'http://localhost:3800',
  bundleHash: 'test-bundle-hash',
  rscBundleHash: null,  // Must be provided separately
  password: 'myPassword1',  // Default from dummy app
  delay: 0,
  delayAfterSend: false,
};

for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case '--url':
      options.url = args[++i];
      break;
    case '--bundle-hash':
      options.bundleHash = args[++i];
      break;
    case '--rsc-bundle-hash':
      options.rscBundleHash = args[++i];
      break;
    case '--password':
      options.password = args[++i];
      break;
    case '--delay':
      options.delay = parseInt(args[++i], 10);
      break;
    case '--delay-after-send':
      options.delayAfterSend = true;
      break;
    case '--help':
      console.log(`
Usage: node test_http2_bidi_request.mjs [options]

Options:
  --url <url>               Node renderer URL (default: http://localhost:3800)
  --bundle-hash <hash>      Server bundle hash for rendering
  --rsc-bundle-hash <hash>  RSC bundle hash (required for RSC support)
  --password <pwd>          Node renderer password (default: myPassword1)
  --delay <ms>              Delay before closing request (default: 0)
  --delay-after-send        Add delay after sending all data but before closing
`);
      process.exit(0);
  }
}

// Validate required arguments
if (!options.rscBundleHash) {
  console.error('ERROR: --rsc-bundle-hash is required');
  console.error('');
  console.error('To find bundle hashes, check the node-renderer logs for lines like:');
  console.error('  "Uploaded bundle server-bundle.js with hash abc123..."');
  console.error('  "Uploaded bundle rsc-server-bundle.js with hash def456..."');
  console.error('');
  console.error('Or check webpack output for the generated bundle filenames.');
  process.exit(1);
}

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function sendBidiRequest() {
  const parsedUrl = new URL(options.url);
  const requestDigest = 'test-request-digest-' + Date.now();
  const path = `/bundles/${options.bundleHash}/incremental-render/${requestDigest}`;

  console.log('='.repeat(70));
  console.log('HTTP/2 Bidirectional Streaming Test');
  console.log('='.repeat(70));
  console.log(`URL: ${options.url}${path}`);
  console.log(`Server bundle hash: ${options.bundleHash}`);
  console.log(`RSC bundle hash: ${options.rscBundleHash}`);
  console.log(`Delay before close: ${options.delay}ms`);
  console.log(`Delay after send: ${options.delayAfterSend}`);
  console.log('');

  return new Promise((resolve, reject) => {
    // Create HTTP/2 client session
    const client = http2.connect(options.url);

    client.on('error', (err) => {
      console.error('[CLIENT] Connection error:', err.message);
      reject(err);
    });

    // Create the request stream
    const req = client.request({
      ':method': 'POST',
      ':path': path,
      'content-type': 'application/x-ndjson',
    });

    let responseData = '';
    let responseHeaders = null;
    const startTime = Date.now();

    req.on('response', (headers) => {
      responseHeaders = headers;
      console.log(`[CLIENT] Received response headers (${Date.now() - startTime}ms):`);
      console.log(`  :status = ${headers[':status']}`);
      console.log(`  content-type = ${headers['content-type']}`);
    });

    req.on('data', (chunk) => {
      const chunkStr = chunk.toString();
      responseData += chunkStr;
      console.log(`[CLIENT] Received data chunk (${Date.now() - startTime}ms): ${chunk.length} bytes`);
      // Print first 200 chars of each chunk
      console.log(`  Preview: ${chunkStr.substring(0, 200)}${chunkStr.length > 200 ? '...' : ''}`);
    });

    req.on('end', () => {
      const elapsed = Date.now() - startTime;
      console.log('');
      console.log('='.repeat(70));
      console.log('RESULTS');
      console.log('='.repeat(70));
      console.log(`Total time: ${elapsed}ms`);
      console.log(`Response status: ${responseHeaders?.[':status'] || 'NO HEADERS RECEIVED'}`);
      console.log(`Response body length: ${responseData.length} bytes`);

      if (responseData.length === 0) {
        console.log('');
        console.log('*** FAILURE: Empty response! ***');
        console.log('This reproduces the bug where END_STREAM before HEADERS causes empty response.');
      } else {
        console.log('');
        console.log('*** SUCCESS: Received response data ***');
        console.log('');
        console.log('Response body (first 500 chars):');
        console.log(responseData.substring(0, 500));
      }

      client.close();
      resolve({
        status: responseHeaders?.[':status'],
        bodyLength: responseData.length,
        body: responseData,
      });
    });

    req.on('error', (err) => {
      console.error('[CLIENT] Request error:', err.message);
      client.close();
      reject(err);
    });

    // Build the request data (simulating React on Rails Pro format)
    const bundleTimestamp = options.bundleHash;
    const rscBundleTimestamp = options.rscBundleHash;

    // Generate rendering request EXACTLY matching ServerRenderingJsCode.render() format
    // The VM context provides: renderingRequest, sharedExecutionContext, runOnOtherBundle (via globalThis)
    const componentName = 'AsyncPropsComponent';
    const domNodeId = 'AsyncPropsComponent-react-component-0';
    // Props matching test_incremental_rendering.html.erb
    const propsString = JSON.stringify({
      name: "John Doe",
      age: 30,
      description: "Software Engineer"
    });

    // Base railsContext - additional properties are added by the JS code itself
    const railsContextObj = {
      serverSide: true,
      href: 'http://localhost:3000/test',
      location: '/test',
    };
    const railsContext = JSON.stringify(railsContextObj);

    // This EXACTLY matches the output of ServerRenderingJsCode.render() with:
    // - enable_rsc_support = true
    // - streaming? = true
    // - async_props_block present
    // - rsc_payload_streaming? = false (running on server bundle, not RSC bundle)
    const renderingRequest = `
(function(componentName = '${componentName}', props = undefined) {
  var railsContext = ${railsContext};

  // rsc_params: added when enable_rsc_support && streaming?
  railsContext.reactClientManifestFileName = 'react-client-manifest.json';
  railsContext.reactServerClientManifestFileName = 'react-server-client-manifest.json';

  // generate_rsc_payload_js_function: added when enable_rsc_support && streaming? && !rsc_payload_streaming?
  // Note: 'renderingRequest' is injected by the VM context (see vm.ts line 366)
  railsContext.serverSideRSCPayloadParameters = {
    renderingRequest,
    rscBundleHash: '${rscBundleTimestamp}',
  };
  const runOnOtherBundle = globalThis.runOnOtherBundle;
  const generateRSCPayload = function generateRSCPayload(componentName, props, railsContext) {
    const { renderingRequest, rscBundleHash } = railsContext.serverSideRSCPayloadParameters;
    const propsString = JSON.stringify(props);
    const newRenderingRequest = renderingRequest.replace(/\\(\\s*\\)\\s*$/, \`('\${componentName}', \${propsString})\`);
    return runOnOtherBundle(rscBundleHash, newRenderingRequest);
  };

  var usedProps = typeof props === 'undefined' ? ${propsString} : props;

  // async_props_setup_js: added when async_props_block is present
  if (ReactOnRails.isRSCBundle) {
    var { props: propsWithAsyncProps } = ReactOnRails.addAsyncPropsCapabilityToComponentProps(usedProps, sharedExecutionContext);
    usedProps = propsWithAsyncProps;
  }

  // render_function_name when enable_rsc_support && streaming?
  return ReactOnRails[ReactOnRails.isRSCBundle ? 'serverRenderRSCReactComponent' : 'streamServerRenderedReactComponent']({
    name: componentName,
    domNodeId: '${domNodeId}',
    props: usedProps,
    trace: false,
    railsContext: railsContext,
    throwJsErrors: false,
    renderingReturnsPromises: true,
    generateRSCPayload: typeof generateRSCPayload !== 'undefined' ? generateRSCPayload : undefined,
  });
})()
    `.trim();

    // End stream chunk - executed when request closes
    const endStreamChunk = `
(function(){
  var asyncPropsManager = ReactOnRails.getOrCreateAsyncPropsManager(sharedExecutionContext);
  asyncPropsManager.endStream();
})()
    `.trim();

    // Initial rendering request (first NDJSON line)
    const initialRequest = {
      gemVersion: '16.2.0-rc.0',
      protocolVersion: '2.0.0',
      password: options.password,
      dependencyBundleTimestamps: [bundleTimestamp, rscBundleTimestamp],
      railsEnv: 'test',
      renderingRequest: renderingRequest,
      onRequestClosedUpdateChunk: {
        bundleTimestamp: rscBundleTimestamp,  // RSC bundle handles async props
        updateChunk: endStreamChunk
      }
    };

    // Update chunks (simulating async props from AsyncPropsEmitter)
    // These run on the RSC bundle since that's where AsyncPropsManager lives
    // Matching test_incremental_rendering.html.erb emit calls
    const updateChunk1 = {
      bundleTimestamp: rscBundleTimestamp,
      updateChunk: `
(function(){
  var asyncPropsManager = ReactOnRails.getOrCreateAsyncPropsManager(sharedExecutionContext);
  asyncPropsManager.setProp("books", ["The Pragmatic Programmer", "Clean Code", "Design Patterns"]);
})()
      `.trim()
    };

    const updateChunk2 = {
      bundleTimestamp: rscBundleTimestamp,
      updateChunk: `
(function(){
  var asyncPropsManager = ReactOnRails.getOrCreateAsyncPropsManager(sharedExecutionContext);
  asyncPropsManager.setProp("researches", ["Machine Learning Study", "React Performance Optimization", "Database Indexing Strategies"]);
})()
      `.trim()
    };

    // Send data
    (async () => {
      console.log('[CLIENT] Sending initial request...');
      req.write(JSON.stringify(initialRequest) + '\n');
      console.log(`[CLIENT] Sent initial request (${Date.now() - startTime}ms)`);

      console.log('[CLIENT] Sending update chunk 1...');
      req.write(JSON.stringify(updateChunk1) + '\n');
      console.log(`[CLIENT] Sent update chunk 1 (${Date.now() - startTime}ms)`);

      console.log('[CLIENT] Sending update chunk 2...');
      req.write(JSON.stringify(updateChunk2) + '\n');
      console.log(`[CLIENT] Sent update chunk 2 (${Date.now() - startTime}ms)`);

      if (options.delayAfterSend && options.delay > 0) {
        console.log(`[CLIENT] Waiting ${options.delay}ms after sending data...`);
        await sleep(options.delay);
      }

      if (!options.delayAfterSend && options.delay > 0) {
        console.log(`[CLIENT] Waiting ${options.delay}ms before closing request...`);
        await sleep(options.delay);
      }

      console.log(`[CLIENT] Closing request (sending END_STREAM) (${Date.now() - startTime}ms)`);
      req.end();
      console.log(`[CLIENT] Request closed, END_STREAM sent (${Date.now() - startTime}ms)`);
    })();
  });
}

// Run the test
sendBidiRequest()
  .then((result) => {
    process.exit(result.bodyLength > 0 ? 0 : 1);
  })
  .catch((err) => {
    console.error('Test failed:', err);
    process.exit(1);
  });
