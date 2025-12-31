import { expect } from '@playwright/test';
import { asyncPropsAtRouterPageTest } from './fixture';

asyncPropsAtRouterPageTest(
  'async props are streamed on request to the page',
  async ({ page, sendRedisValue, endRedisStream }) => {
    await expect(page.getByRole('heading', { name: 'Async Props Component' })).toBeVisible();
    await expect(page.getByText('Name: John Doe')).toBeVisible();
    await expect(page.getByText('Age: 30')).toBeVisible();
    await expect(page.getByText('Description: Software Engineer')).toBeVisible();
    await expect(page.getByText('Clean Code')).not.toBeVisible();
    await expect(page.getByText('Design Patterns')).not.toBeVisible();
    await expect(page.getByText('Engineering in software')).not.toBeVisible();
    await expect(page.getByText('The Need for Software Engineering')).not.toBeVisible();

    sendRedisValue('books', ['Clean Code', 'Design Patterns']);
    await expect(page.getByText('Clean Code')).toBeVisible();
    await expect(page.getByText('Design Patterns')).toBeVisible();
    await expect(page.getByText('Engineering in software')).not.toBeVisible();
    await expect(page.getByText('The Need for Software Engineering')).not.toBeVisible();

    sendRedisValue('researches', ['Engineering in software', 'The Need for Software Engineering']);
    await expect(page.getByText('Clean Code')).toBeVisible();
    await expect(page.getByText('Design Patterns')).toBeVisible();
    await expect(page.getByText('Engineering in software')).toBeVisible();
    await expect(page.getByText('The Need for Software Engineering')).toBeVisible();
    await endRedisStream();
  },
);
