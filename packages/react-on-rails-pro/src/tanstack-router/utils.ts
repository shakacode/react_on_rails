// eslint-disable-next-line import/prefer-default-export -- Keeping named export for consistency with the module's API.
export function normalizeSearch(search: string | null | undefined): string {
  if (!search || search === '?') {
    return '';
  }

  return search.startsWith('?') ? search : `?${search}`;
}
