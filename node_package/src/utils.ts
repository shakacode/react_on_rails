// Override the fetch function to make it easier to test and for future use
const customFetch = (...args: Parameters<typeof fetch>) => {
  const res = fetch(...args);
  return res;
}

// eslint-disable-next-line import/prefer-default-export
export { customFetch as fetch };
