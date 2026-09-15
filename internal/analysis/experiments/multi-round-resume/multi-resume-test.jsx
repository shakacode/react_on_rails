// Multi-round pause/resume test — the NAIVE approach that CRASHES.
// Chain: prerender (abort) -> resumeAndPrerender (abort) -> resumeAndPrerender (abort) -> resume (final)
// Round 2 aborts while carried-over hole B/C is still pending -> React throws
// "It should not be possible to postpone at the root. This is a bug in React."
import React, { Suspense } from "react";
import { prerender, resumeAndPrerender } from "react-dom/static";
import { resume } from "react-dom/server";

// Gates we open one at a time between rounds
const gates = { A: false, B: false, C: false };
const pending = new Map(); // name -> promise (never resolves while gate closed)

function Wait({ name, children }) {
  if (!gates[name]) {
    // Suspend forever (until aborted). New promise identity per render round is fine:
    // aborting a prerender postpones the boundary.
    let p = pending.get(name);
    if (!p) {
      p = new Promise(() => {});
      pending.set(name, p);
    }
    React.use(p);
  }
  return children;
}

function App() {
  return (
    <div id="root">
      <p>Static shell</p>
      <Suspense fallback={<p>Loading A...</p>}>
        <Wait name="A">
          <p>Section A</p>
          <Suspense fallback={<p>Loading B...</p>}>
            <Wait name="B">
              <p>Section B</p>
            </Wait>
          </Suspense>
        </Wait>
      </Suspense>
      <Suspense fallback={<p>Loading C...</p>}>
        <Wait name="C">
          <p>Section C</p>
        </Wait>
      </Suspense>
    </div>
  );
}

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

function abortSoon(controller, ms = 50) {
  setTimeout(() => controller.abort(new Error("pause point")), ms);
}

async function round(label, fn) {
  const controller = new AbortController();
  abortSoon(controller);
  const result = await fn(controller);
  const html = await streamToString(result.prelude);
  const postponed = result.postponed;
  const serialized = postponed === null ? null : JSON.stringify(postponed);
  console.log(`\n=== ${label} ===`);
  console.log("HTML chunk:", JSON.stringify(html));
  console.log(
    "postponed is null?",
    postponed === null,
    serialized ? `(serialized ${serialized.length} bytes)` : "",
  );
  return serialized;
}

// ROUND 1: initial prerender, everything suspended
const errors1 = [];
const state1 = await round("ROUND 1: prerender (A,B,C closed)", (c) =>
  prerender(<App />, {
    signal: c.signal,
    onError(e) {
      errors1.push(String(e && e.message));
    },
  }),
);

// ROUND 2: open gate A only -> should render Section A, still pause at B and C
// !!! CRASHES HERE: hole C is replayed, still pending, and the abort tries to
// re-postpone a replayed boundary whose `tracked` field is null.
gates.A = true;
const errors2 = [];
const state2 = await round(
  "ROUND 2: resumeAndPrerender (A open, B,C closed)",
  (c) =>
    resumeAndPrerender(<App />, JSON.parse(state1), {
      signal: c.signal,
      onError(e) {
        errors2.push(String(e && e.message));
      },
    }),
);

// ROUND 3: open gate C only -> should render Section C, still pause at B
gates.C = true;
const errors3 = [];
const state3 = await round(
  "ROUND 3: resumeAndPrerender (A,C open, B closed)",
  (c) =>
    resumeAndPrerender(<App />, JSON.parse(state2), {
      signal: c.signal,
      onError(e) {
        errors3.push(String(e && e.message));
      },
    }),
);

// ROUND 4 (final): open everything, live resume to a stream
gates.B = true;
const finalStream = await resume(<App />, JSON.parse(state3));
const finalHtml = await streamToString(finalStream);
console.log("\n=== ROUND 4: live resume (all open) ===");
console.log("HTML chunk:", JSON.stringify(finalHtml));

console.log(
  "\nerrors r1:",
  errors1,
  "\nerrors r2:",
  errors2,
  "\nerrors r3:",
  errors3,
);
