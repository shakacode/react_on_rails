// When does resume() hand you HTML? Promise resolution vs stream close.
import React, { Suspense } from "react";
import { prerender } from "react-dom/static";
import { resume } from "react-dom/server";

let releaseGate;
const gate = new Promise((r) => (releaseGate = r));
let open = false;

function Wait({ children }) {
  if (!open) React.use(gate);
  return children;
}

function App() {
  return (
    <div>
      <p>shell</p>
      <Suspense fallback={<p>loading</p>}>
        <Wait>
          <p>content</p>
        </Wait>
      </Suspense>
    </div>
  );
}

const t0 = Date.now();
const log = (m) =>
  console.log(`+${String(Date.now() - t0).padStart(4)}ms  ${m}`);

// Round 0: prerender + abort
const c = new AbortController();
setTimeout(() => c.abort(new Error("pause")), 50);
const pre = await prerender(<App />, { signal: c.signal, onError() {} });
log("prerender promise resolved (this is onAllReady — after the abort)");
const reader0 = pre.prelude.getReader();
let shell = "";
for (;;) {
  const { done, value } = await reader0.read();
  if (done) break;
  shell += Buffer.from(value).toString();
}
log(
  `prelude drained in full, ${shell.length} bytes (everything was already buffered)`,
);
const state = JSON.parse(JSON.stringify(pre.postponed));

// Resume the hole — but DON'T open the gate yet.
const stream = await resume(<App />, state);
log(
  "resume() promise resolved  <-- note: gate still closed, no content exists yet",
);

const reader = stream.getReader();
let received = 0;
const firstRead = reader.read().then(({ done, value }) => {
  received += value ? value.length : 0;
  log(
    `first chunk arrived (${value ? value.length : 0} bytes)${done ? " [stream ended]" : ""}`,
  );
  return { done };
});

// Show that nothing arrives while the gate is closed
await new Promise((r) => setTimeout(r, 300));
log(`300ms later: bytes received so far = ${received} (stream open, silent)`);

// Open the gate
open = true;
releaseGate();
log("gate opened");

await firstRead;
for (;;) {
  const { done, value } = await reader.read();
  if (done) break;
  received += value.length;
}
log(`stream closed; total ${received} bytes`);
