import removeRSCChunkStack from './removeRSCChunkStack.ts';

const removeRSCStackFromAllChunks = (allChunks: string) => {
  return allChunks
    .split('\n')
    .map((chunk) => (chunk.trim().length > 0 ? removeRSCChunkStack(chunk) : chunk))
    .join('\n');
};

export default removeRSCStackFromAllChunks;
