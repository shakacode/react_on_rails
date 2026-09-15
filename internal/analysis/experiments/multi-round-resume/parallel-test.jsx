// Parallel fan-out test: one prerender with 2 holes; resume each hole
// INDEPENDENTLY (two resume calls off the same base state,
// each pruned to its own hole), with disjoint nextSegmentId ranges.
// Preludes concatenated in completion order.
import React, { Suspense } from "react";
import { prerender } from "react-dom/static";
import { resume } from "react-dom/server";

const gates = { A: false, C: false };

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

function keepOnly(replayNodes, path) {
  // Return a deep-filtered copy keeping only the branch that matches `path`
  // of [name,key] pairs; boundary nodes at the leaf are kept whole.
  const [head, ...rest] = path;
  const out = [];
  for (const node of replayNodes) {
    if (node[0] === head[0] && node[1] === head[1]) {
      if (rest.length === 0) {
        out.push(node);
      } else {
        const kept = keepOnly(node[2], rest);
        if (kept.length > 0) out.push([node[0], node[1], kept, node[3]]);
      }
    }
  }
  return out;
}

// ROUND 1: prerender with both holes
const controller = new AbortController();
setTimeout(() => controller.abort(new Error("pause")), 50);
const r1 = await prerender(<App />, {
  signal: controller.signal,
  onError() {},
});
const shell = await streamToString(r1.prelude);
const base = JSON.parse(JSON.stringify(r1.postponed));
console.log("shell:", JSON.stringify(shell));

// Split into two independent states with disjoint segment-id ranges
const ancestors = [
  ["App", 0],
  ["div", 0],
];
const stateA = {
  ...base,
  replayNodes: keepOnly(base.replayNodes, [...ancestors, ["Suspense", 1]]),
  nextSegmentId: 1000,
};
const stateC = {
  ...base,
  replayNodes: keepOnly(base.replayNodes, [...ancestors, ["Suspense", 2]]),
  nextSegmentId: 2000,
};

// Resume both in parallel; C finishes "first" here
gates.A = true;
gates.C = true;
const [htmlC, htmlA] = await Promise.all([
  resume(<App />, stateC).then(streamToString),
  resume(<App />, stateA).then(streamToString),
]);
console.log("\nresumed C prelude:", JSON.stringify(htmlC));
console.log("\nresumed A prelude:", JSON.stringify(htmlA));

// Simulated final document: shell + completion-order concatenation
const doc = `<!DOCTYPE html><html><body>${shell}${htmlC}${htmlA}</body></html>`;
console.log("\nfinal doc length:", doc.length);
// sanity: every $RC target template id must exist exactly once
const bIds = [...doc.matchAll(/template id="(B:\d+)"/g)].map((m) => m[1]);
const sIds = [...doc.matchAll(/div hidden id="(S:\d+)"/g)].map((m) => m[1]);
const rcPairs = [...doc.matchAll(/\$RC\("(B:\d+)","(S:\d+)"\)/g)].map((m) => [
  m[1],
  m[2],
]);
console.log(
  "template ids:",
  bIds,
  "| segment divs:",
  sIds,
  "| $RC pairs:",
  rcPairs,
);
const dup = (a) => a.filter((x, i) => a.indexOf(x) !== i);
console.log("duplicate B ids:", dup(bIds), "| duplicate S ids:", dup(sIds));
