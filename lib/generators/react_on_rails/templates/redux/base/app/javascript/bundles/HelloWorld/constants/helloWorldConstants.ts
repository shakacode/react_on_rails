/* eslint-disable import/prefer-default-export */

export const HELLO_WORLD_NAME_UPDATE = 'HELLO_WORLD_NAME_UPDATE' as const;

// Action type for TypeScript
export type HelloWorldActionType = typeof HELLO_WORLD_NAME_UPDATE;
