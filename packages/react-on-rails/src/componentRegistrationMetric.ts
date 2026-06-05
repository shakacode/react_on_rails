import type { RegisteredComponentValue } from './types/index.ts';

type RegistrationMetric = {
  label: string;
  value: number;
};

export default function componentRegistrationMetric(component: RegisteredComponentValue): RegistrationMetric {
  if (typeof component === 'function') {
    return { label: 'source chars', value: component.toString().length };
  }

  return { label: 'export keys', value: Object.keys(component as object).length };
}
