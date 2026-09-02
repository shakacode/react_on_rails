// renderAppInRounds(App, numRounds, {outDir}) — render an app in N rounds,
// writing each round's HTML chunk to its own file (round-0.html .. round-{N-1}.html).
//
// Contract with the app:
//   The harness creates a `rounds` object and passes it as a prop: <App rounds={rounds} />.
//   The app calls rounds.waitForRound(i) — a promise that resolves when round i starts —
//   typically via React.use() inside a <Suspense> boundary, so content gated on round i
//   suspends until that round.
//
// How it works (and why this shape):
//   Round 0   : prerender(<App/>) with round 0 already resolved; abort after a settle
//               window. The flushed prelude (shell + round-0 content + fallbacks) is
//               round-0.html. The returned `postponed` state records every hole.
//   Fan-out   : React crashes if a *replayed* (carried-over) hole is still pending when a
//               resumed prerender aborts ("It should not be possible to postpone at the
//               root"). So we never carry holes across aborts: the round-0 postponed state
//               is split into ONE state PER HOLE (keeping only the replay path to that
//               hole, with a disjoint nextSegmentId range), and a live resume() is started
//               for each, all at once. No further aborts are ever needed.
//   Rounds 1+ : resolving round r's promise lets exactly the holes gated on round r finish;
//               their resume streams close on their own. After each round's settle window,
//               every newly finished stream is written to round-r.html. The harness never
//               needs to know which hole belongs to which round.
//   Runtime   : all split states share ONE live resumableState object, so the ~900-byte
//               $RC/$RV client runtime (and its `$RB=[]` reveal-queue reset, which must not
//               re-run) is emitted by the first finishing round only.
//
// Serialization note: `postponed` is only read AFTER the prelude has fully flushed
// (facebook/react#36779). The split states here are passed in-process; to distribute
// rounds across processes, JSON-serialize each split state (they round-trip fine) but
// then each process re-emits the runtime — strip duplicates or use an external runtime.
import React from "react";
import { prerender } from "react-dom/static";
import { resume } from "react-dom/server";
import { writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const settle = (ms) => new Promise((r) => setTimeout(r, ms));

async function streamToString(stream) {
  const reader = stream.getReader();
  let out = "";
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    out += Buffer.from(value).toString("utf8");
  }
  return out;
}

// --- Postponed-state splitting --------------------------------------------
// ReplayNode: [name, key, children, slots]  (path node)
//          or [name, key, children, slots, fallbackNode, rootSegmentID]  (suspense boundary)
// A node is a resumable "hole unit" if it's a boundary or carries resume slots.
function collectHoles(replayNodes, ancestors = [], out = []) {
  for (const node of replayNodes) {
    if (node.length === 6 || node[3] !== null) {
      out.push({ node, ancestors: [...ancestors] });
    } else {
      collectHoles(node[2], [...ancestors, node], out);
    }
  }
  return out;
}

// Rebuild the ancestor chain around a single hole -> a minimal replayNodes tree.
function chainFor(hole) {
  let child = hole.node;
  for (let i = hole.ancestors.length - 1; i >= 0; i--) {
    const a = hole.ancestors[i];
    child = [a[0], a[1], [child], null];
  }
  return [child];
}

// --- The harness -----------------------------------------------------------
export async function renderAppInRounds(
  App,
  numRounds,
  { outDir, settleMs = 200 } = {},
) {
  mkdirSync(outDir, { recursive: true });

  // The rounds object handed to the app. One memoized promise per round index,
  // resolved by the harness as each round begins.
  const resolvers = [];
  const promises = Array.from(
    { length: numRounds },
    (_, i) => new Promise((res) => (resolvers[i] = res)),
  );
  const rounds = {
    waitForRound(i) {
      if (i < 0 || i >= numRounds) return new Promise(() => {}); // beyond schedule: never resolves
      return promises[i];
    },
  };

  const element = <App rounds={rounds} />;
  const report = [];

  // ---- ROUND 0: prerender, pause -----------------------------------------
  resolvers[0]();
  const controller = new AbortController();
  const prerenderPromise = prerender(element, {
    signal: controller.signal,
    onError() {
      /* pause, expected */
    },
  });
  await settle(settleMs);
  controller.abort(new Error("pause after round 0"));
  const result = await prerenderPromise;
  const shellHtml = await streamToString(result.prelude);
  writeFileSync(
    join(outDir, "round-0.html"),
    `<!-- round 0 (shell) -->\n${shellHtml}`,
  );
  report.push({ round: 0, file: "round-0.html", holesFilled: "(shell)" });
  // Only serialize postponed AFTER the prelude has fully flushed.
  const state0 = result.postponed
    ? JSON.parse(JSON.stringify(result.postponed))
    : null;

  // ---- Fan-out: one live resume per hole -----------------------------------
  let jobs = [];
  if (state0 !== null) {
    const sharedResumable = state0.resumableState; // shared: client runtime emitted once
    const holes =
      state0.replaySlots !== null
        ? [null] // root-level resume slots: not splittable, resume the whole state as one job
        : collectHoles(state0.replayNodes);
    jobs = holes.map((hole, k) => {
      const state =
        hole === null
          ? state0
          : {
              nextSegmentId: state0.nextSegmentId + 1000 * (k + 1), // disjoint id ranges
              rootFormatContext: JSON.parse(
                JSON.stringify(state0.rootFormatContext),
              ),
              progressiveChunkSize: state0.progressiveChunkSize,
              resumableState: sharedResumable,
              replayNodes: chainFor(hole),
              replaySlots: null,
            };
      const job = {
        hole: k,
        done: false,
        collected: false,
        html: "",
        error: null,
      };
      resume(element, state, {
        onError(e) {
          job.error = String(e && e.message);
        },
      })
        .then(streamToString)
        .then(
          (html) => {
            job.html = html;
            job.done = true;
          },
          (e) => {
            job.error = String(e && e.message);
            job.done = true;
          },
        );
      return job;
    });
  }

  // ---- ROUNDS 1..N-1: advance a round, collect what finished ---------------
  for (let r = 1; r < numRounds; r++) {
    resolvers[r]();
    await settle(settleMs);
    const ready = jobs.filter((j) => j.done && !j.collected);
    ready.forEach((j) => (j.collected = true));
    const html =
      ready.map((j) => j.html).join("") || `<!-- round ${r}: no content -->`;
    writeFileSync(
      join(outDir, `round-${r}.html`),
      `<!-- round ${r} -->\n${html}`,
    );
    report.push({
      round: r,
      file: `round-${r}.html`,
      holesFilled: ready.map((j) => j.hole).join(",") || "(none)",
      errors: ready.map((j) => j.error).filter(Boolean),
    });
  }

  const unfinished = jobs.filter((j) => !j.done).length;
  return { report, totalHoles: jobs.length, unfinished };
}
