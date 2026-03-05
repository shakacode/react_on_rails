export function normalizeSearch(search: string | null | undefined): string {
  if (!search) {
    return '';
  }

  return search.startsWith('?') ? search : `?${search}`;
}

export function locationSearch(
  location: { search?: unknown; searchStr?: unknown } | null | undefined,
): string | undefined {
  if (!location) {
    return undefined;
  }

  if (typeof location.search === 'string') {
    return location.search;
  }

  if (typeof location.searchStr === 'string') {
    return location.searchStr;
  }

  return undefined;
}
