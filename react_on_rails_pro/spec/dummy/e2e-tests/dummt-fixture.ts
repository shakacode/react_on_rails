import { test as base } from '@playwright/test';

type F = {
  h: string;
}

type F2 = {
  h2: string;
}

export const test1 = base.extend<F>({
  h: [async({}, use) => {
    console.log('F1')
    await use('F1');
    console.log('F1 end');
  }, { auto: true }]
})

export const testmid = base.extend<F>({
  h: [async({}, use) => {
    console.log('Fm')
    await use('Fm');
    console.log('Fm end');
  }, { auto: true }]
})

export const test2 = testmid.extend<F2>({
  h2: [async({ h }, use) => {
    console.log('F2')
    await use(h + 'F2');
    console.log('F2 end');
  }, { auto: true }]
})
