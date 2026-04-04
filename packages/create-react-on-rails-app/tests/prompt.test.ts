import readline from 'readline';
import { promptForMode } from '../src/prompt';

jest.mock('readline');

const mockedReadline = jest.mocked(readline);

describe('promptForMode', () => {
  let consoleLogSpy: jest.SpyInstance;
  let mockRl: { question: jest.Mock; close: jest.Mock; on: jest.Mock; once: jest.Mock };
  let eventHandlers: Record<string, ((...args: unknown[]) => void)[]>;

  beforeEach(() => {
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    eventHandlers = {};
    mockRl = {
      question: jest.fn(),
      close: jest.fn(),
      on: jest.fn((event: string, handler: (...args: unknown[]) => void) => {
        (eventHandlers[event] ??= []).push(handler);
        return mockRl;
      }),
      once: jest.fn((event: string, handler: (...args: unknown[]) => void) => {
        (eventHandlers[event] ??= []).push(handler);
        return mockRl;
      }),
    };
    mockedReadline.createInterface.mockReturnValue(mockRl as unknown as readline.Interface);
  });

  afterEach(() => {
    consoleLogSpy.mockRestore();
  });

  it('returns rsc when user enters 3', async () => {
    mockRl.question.mockImplementation((_prompt: string, cb: (answer: string) => void) => cb('3'));

    const result = await promptForMode();

    expect(result).toEqual({ pro: false, rsc: true });
    expect(mockRl.close).toHaveBeenCalled();
  });

  it('returns pro when user enters 2', async () => {
    mockRl.question.mockImplementation((_prompt: string, cb: (answer: string) => void) => cb('2'));

    const result = await promptForMode();

    expect(result).toEqual({ pro: true, rsc: false });
  });

  it('returns standard when user enters 1', async () => {
    mockRl.question.mockImplementation((_prompt: string, cb: (answer: string) => void) => cb('1'));

    const result = await promptForMode();

    expect(result).toEqual({ pro: false, rsc: false });
  });

  it('defaults to rsc when user presses Enter without input', async () => {
    mockRl.question.mockImplementation((_prompt: string, cb: (answer: string) => void) => cb(''));

    const result = await promptForMode();

    expect(result).toEqual({ pro: false, rsc: true });
  });

  it('defaults to rsc on invalid input', async () => {
    mockRl.question.mockImplementation((_prompt: string, cb: (answer: string) => void) => cb('9'));

    const result = await promptForMode();

    expect(result).toEqual({ pro: false, rsc: true });
  });

  it('trims whitespace from input', async () => {
    mockRl.question.mockImplementation((_prompt: string, cb: (answer: string) => void) => cb('  1  '));

    const result = await promptForMode();

    expect(result).toEqual({ pro: false, rsc: false });
  });

  it('rejects when user presses Ctrl+C (SIGINT)', async () => {
    mockRl.question.mockImplementation(() => {});
    const promise = promptForMode();
    for (const handler of eventHandlers['SIGINT'] ?? []) handler();
    await expect(promise).rejects.toThrow('Prompt cancelled by user (SIGINT)');
    expect(mockRl.close).toHaveBeenCalled();
  });

  it('defaults to rsc when stdin closes (EOF/Ctrl+D)', async () => {
    mockRl.question.mockImplementation(() => {});
    const promise = promptForMode();
    for (const handler of eventHandlers['close'] ?? []) handler();
    const result = await promise;
    expect(result).toEqual({ pro: false, rsc: true });
  });

  it('displays mode options to the user', async () => {
    mockRl.question.mockImplementation((_prompt: string, cb: (answer: string) => void) => cb('3'));

    await promptForMode();

    expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('Standard'));
    expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('Pro'));
    expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('RSC'));
  });
});
