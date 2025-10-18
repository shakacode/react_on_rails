type LoadedJsonFile = Record<string, unknown>;
export default function loadJsonFile<T extends LoadedJsonFile = LoadedJsonFile>(fileName: string): Promise<T>;
export {};
