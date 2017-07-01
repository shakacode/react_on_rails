# Node.js for Server Rendering

Node.js can be used as the backend for server-side rendering instead of [execJS](https://github.com/rails/execjs). Before you try this, consider the tradeoff of extra complexity with your deployments versus *potential* performance gains. While often ExecJS with [mini_racer](https://github.com/discourse/mini_racer) is "fast enough", we've heard of other large websites using Node.js for better server rendering performance.

If you want to use a node server for server rendering, [get in touch](mailto:justin@shakacode.com). ShakaCode has built a premium Node rendering server for React on Rails.
