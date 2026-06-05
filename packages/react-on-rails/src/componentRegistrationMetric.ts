import type { RegisteredComponentValue } from './types/index.ts';

type RegistrationMetric = {
  label: string;
  value: number;
};

export default function componentRegistrationMetric(component: RegisteredComponentValue): RegistrationMetric {
  if (typeof component === 'function') {
    return { label: 'source chars', value: component.toString().length };
  }

  try {
    return { label: 'export keys', value: Object.keys(component as object).length };
  } catch {
    return { label: 'tag chars', value: Object.prototype.toString.call(component).length };
  }
}
