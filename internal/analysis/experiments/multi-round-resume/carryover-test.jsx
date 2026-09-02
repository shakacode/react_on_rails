// Carry-over surgery test: pause at multiple points where a hole stays
// unready across rounds, WITHOUT crashing.
//
// Round 1: prerender, A and C closed -> holes {A: B:0, C: B:1}
// Round 2: only A is ready. PRUNE C's replay path from state1, then
//          resumeAndPrerender (A open, B new+closed) -> state2 holes {B}
//          then GRAFT C's pruned node back into state2.
// Round 3: live resume with B and C open -> fills B:1 (C) and B:2 (B).
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

// --- Postponed-state surgery helpers -------------------------------------
// ReplayNode: [name, key, children, slots] (regular)
//          or [name, key, children, slots, fallbackNode, rootSegmentID] (suspense boundary)

// Remove the node whose path of [name,key] pairs matches; returns the pruned node (or null)
function pruneNode(replayNodes, path) {
  const [head, ...rest] = path;
  for (let i = 0; i < replayNodes.length; i++) {
    const node = replayNodes[i];
    if (node[0] === head[0] && node[1] === head[1]) {
      if (rest.length === 0) {
        replayNodes.splice(i, 1);
        return node;
      }
      const child = pruneNode(node[2], rest);
      if (child !== null) return child;
    }
  }
  return null;
}

// Graft `node` back at `path` (path = ancestors' [name,key] pairs, excluding node itself),
// creating intermediate nodes if they don't exist in target.
function graftNode(replayNodes, path, node) {
  let level = replayNodes;
  for (const [name, key] of path) {
    let found = level.find((n) => n[0] === name && n[1] === key);
    if (!found) {
      found = [name, key, [], null];
      level.push(found);
    }
    level = found[2];
  }
  level.push(node);
}

async function round(label, fn) {
  const controller = new AbortController();
  setTimeout(() => controller.abort(new Error("pause point")), 50);
  const result = await fn(controller);
  const html = await streamToString(result.prelude);
  console.log(`\n=== ${label} ===`);
  console.log("HTML:", JSON.stringify(html));
  const postponed = result.postponed;
  console.log("postponed null?", postponed === null);
  return postponed;
}

// ROUND 1
const state1 = await round("ROUND 1: prerender (A,C closed)", (c) =>
  prerender(<App />, { signal: c.signal, onError() {} }),
);
const s1 = JSON.parse(JSON.stringify(state1));

// SURGERY: prune the C boundary (path: App/div -> Suspense key 2)
const ancestors = [
  ["App", 0],
  ["div", 0],
];
const cNode = pruneNode(s1.replayNodes, [...ancestors, ["Suspense", 2]]);
console.log("\npruned C node:", JSON.stringify(cNode));
if (!cNode) throw new Error("failed to prune C");

// ROUND 2: A ready, C withheld, B (new) closed
gates.A = true;
const state2 = await round(
  "ROUND 2: resumeAndPrerender (A open; C pruned; B new+closed)",
  (c) => resumeAndPrerender(<App />, s1, { signal: c.signal, onError() {} }),
);
const s2 = JSON.parse(JSON.stringify(state2));

// SURGERY: graft C back
graftNode(s2.replayNodes, ancestors, cNode);
console.log("\nstate2 after graft:", JSON.stringify(s2.replayNodes));

// ROUND 3: everything ready, live resume
gates.B = true;
gates.C = true;
const finalStream = await resume(<App />, s2);
console.log("\n=== ROUND 3: live resume (B,C open) ===");
console.log("HTML:", JSON.stringify(await streamToString(finalStream)));
