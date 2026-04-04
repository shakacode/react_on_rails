import readline from 'readline';
import chalk from 'chalk';

export interface ModeChoice {
  pro: boolean;
  rsc: boolean;
}

export const PROMPT_CANCELLED_BY_SIGINT = 'Prompt cancelled by user (SIGINT)';

const MODES = [
  {
    key: '1',
    label: 'Standard',
    desc: 'Open-source React on Rails with SSR',
    pro: false,
    rsc: false,
  },
  {
    key: '2',
    label: 'Pro',
    desc: 'Adds Node.js server rendering (requires react_on_rails_pro)',
    pro: true,
    rsc: false,
  },
  {
    key: '3',
    label: 'RSC',
    desc: 'React Server Components (requires react_on_rails_pro)',
    pro: false,
    rsc: true,
  },
] as const;

const DEFAULT_KEY = '3';

export function promptForMode(): Promise<ModeChoice> {
  return new Promise((resolve, reject) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    let answered = false;

    rl.on('SIGINT', () => {
      answered = true;
      rl.close();
      reject(new Error(PROMPT_CANCELLED_BY_SIGINT));
    });

    rl.once('close', () => {
      if (!answered) {
        resolve({ pro: false, rsc: true });
      }
    });

    console.log(chalk.bold('Select a setup mode:\n'));
    for (const mode of MODES) {
      const recommended = mode.key === DEFAULT_KEY ? chalk.cyan(' (recommended)') : '';
      console.log(`  ${mode.key}. ${chalk.bold(mode.label.padEnd(10))} ${mode.desc}${recommended}`);
    }
    console.log('');

    rl.question(`Choice (1-3) [${DEFAULT_KEY}]: `, (answer) => {
      answered = true;
      rl.close();
      const key = answer.trim() || DEFAULT_KEY;
      const selected = MODES.find((m) => m.key === key);
      if (!selected) {
        console.log(chalk.yellow(`Invalid choice "${key}", defaulting to RSC.`));
        resolve({ pro: false, rsc: true });
        return;
      }
      resolve({ pro: selected.pro, rsc: selected.rsc });
    });
  });
}
