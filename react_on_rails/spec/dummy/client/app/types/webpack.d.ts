declare const module: {
  hot?: {
    accept(dependencies: string[], callback: () => void): void;
  };
};
