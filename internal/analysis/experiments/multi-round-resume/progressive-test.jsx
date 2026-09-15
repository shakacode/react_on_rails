// Progressive-deepening multi-round pause/resume:
// each round completes ALL previous holes; new pauses only in newly rendered content.
// Round 1: A,C closed -> holes {A, C}
// Round 2: A,C open, B (new, nested in A) closed -> holes {B}
// Round 3: B open -> live resume
import React, { Suspense } from "react";
import { prerender, resumeAndPrerender } from "react-dom/static";
import { resume } from "react-dom/server";

const gates = { A: false, B: false, C: false };

function Wait({ name, children }) {
  if (!gates[name]) React.use(new Promise(() => {}));
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

async function round(label, fn) {
  const controller = new AbortController();
  setTimeout(() => controller.abort(new Error("pause point")), 50);
  const result = await fn(controller);
  const html = await streamToString(result.prelude);
  const serialized =
    result.postponed === null ? null : JSON.stringify(result.postponed);
  console.log(`\n=== ${label} ===`);
  console.log("HTML:", JSON.stringify(html));
  console.log(
    "postponed null?",
    result.postponed === null,
    serialized ? `(${serialized.length} bytes)` : "",
  );
  return serialized;
}

const state1 = await round("ROUND 1: prerender (A,C closed)", (c) =>
  prerender(<App />, {
    signal: c.signal,
    onError() {
      /* pause */
    },
  }),
);

console.log("\nstate1 =", state1);

gates.A = true;
gates.C = true;
const state2 = await round(
  "ROUND 2: resumeAndPrerender (A,C open; B new+closed)",
  (c) =>
    resumeAndPrerender(<App />, JSON.parse(state1), {
      signal: c.signal,
      onError() {
        /* pause */
      },
    }),
);

console.log("\nstate2 =", state2);

gates.B = true;
const finalStream = await resume(<App />, JSON.parse(state2));
console.log("\n=== ROUND 3: live resume (B open) ===");
console.log("HTML:", JSON.stringify(await streamToString(finalStream)));
