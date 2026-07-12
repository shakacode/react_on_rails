import fs from 'node:fs';

export const EVENT_LIMITS = Object.freeze({ max_bytes: 1_048_576, max_events: 5_000 });
export const ARTIFACT_LIMITS = Object.freeze({
  max_file_bytes: 65_536,
  max_files: 256,
  max_total_bytes: 2_097_152,
  max_visited_entries: 5_000,
  max_depth: 64,
});

export const readBoundedEvents = (eventsPath) => {
  const observedBytes = fs.statSync(eventsPath).size;
  const limits = {
    ...EVENT_LIMITS,
    observed_bytes: observedBytes,
    observed_events: null,
    exceeded: false,
    reason: null,
  };
  if (observedBytes > EVENT_LIMITS.max_bytes) {
    return { events: [], limits: { ...limits, exceeded: true, reason: 'events_bytes' } };
  }

  const lines = fs.readFileSync(eventsPath, 'utf8').split('\n').filter(Boolean);
  limits.observed_events = lines.length;
  if (lines.length > EVENT_LIMITS.max_events) {
    return { events: [], limits: { ...limits, exceeded: true, reason: 'events_count' } };
  }
  return { events: lines.map((line) => JSON.parse(line)), limits };
};
