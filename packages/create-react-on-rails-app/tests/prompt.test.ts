import readline from 'readline';
import { promptForMode } from '../src/prompt';

jest.mock('readline');

const mockedReadline = jest.mocked(readline);

describe('promptForMode', () => {
  let consoleLogSpy: jest.SpyInstance;
  let mockRl: { question: jest.Mock; close: jest.Mock };

  beforeEach(() => {
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    mockRl = {
      question: jest.fn(),
      close: jest.fn(),
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

  it('displays mode options to the user', async () => {
    mockRl.question.mockImplementation((_prompt: string, cb: (answer: string) => void) => cb('3'));

    await promptForMode();

    expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('Standard'));
    expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('Pro'));
    expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('RSC'));
  });
});
