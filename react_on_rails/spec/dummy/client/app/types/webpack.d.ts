// eslint-disable-next-line no-var -- webpack injects a mutable CommonJS module binding.
declare var module: {
  hot?: {
    accept(dependencies: string[], callback: () => void): void;
  };
};
