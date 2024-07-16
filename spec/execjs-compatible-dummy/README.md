# Example of React on Rails Pro Using Default @rails/webpacker Configuration and ExecJS as the JS Renderer

## Installation

```sh
cd react_on_rails_pro
bundle && yarn && cd spec/execjs-compatible-dummy && bundle && yarn
```

## Running
Run one of these Procfiles:

1. [Procfile.dev](./Procfile.dev): Development setup with HMR and with loadable-components.
2. [Procfile.static](./Procfile.static): Development setup using `webpack --watch`. No HMR, but loadable-components is used.

## Profiling Server-Side Code Running On ExecJS Renderer
Read the profiling guide [here](../../docs/profiling-server-side-rendering-code.md).
