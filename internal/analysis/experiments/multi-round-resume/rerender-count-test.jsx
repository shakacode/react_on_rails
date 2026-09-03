// Who actually re-executes on each round? Count every component execution.
//
// Layout:
//   <App>                     (root, on every replay path)
//     <Track name="shell" />  (completes in round 1 -> off-path afterwards)
//     <Suspense> <Wait A>
//        <Track name="inside-A" />   (completes in round 2; sibling of hole B afterwards)
//        <Suspense> <Wait B> <Track name="inside-B" /> (completes in round 3)
import React, { Suspense } from "react";
import { prerender, resumeAndPrerender } from "react-dom/static";
import { resume } from "react-dom/server";

const gates = { A: false, B: false };
let counts = {};
const bump = (n) => {
  counts[n] = (counts[n] || 0) + 1;
};

function Track({ name }) {
  bump(name);
  return <p>{name}</p>;
}

function Wait({ name, children }) {
  bump(`Wait(${name})`);
  if (!gates[name]) React.use(new Promise(() => {}));
  return children;
}

function App() {
  bump("App");
  return (
    <div>
      <Track name="shell" />
      <Suspense fallback={<p>loading A</p>}>
        <Wait name="A">
          <Track name="inside-A" />
          <Suspense fallback={<p>loading B</p>}>
            <Wait name="B">
              <Track name="inside-B" />
            </Wait>
          </Suspense>
        </Wait>
      </Suspense>
    </div>
  );
}

async function s2s(stream) {
  const r = stream.getReader();
  let o = "";
  for (;;) {
    const { done, value } = await r.read();
    if (done) break;
    o += Buffer.from(value).toString("utf8");
  }
  return o;
}
async function paused(fn) {
  const c = new AbortController();
  setTimeout(() => c.abort(new Error("pause")), 50);
  const r = await fn(c);
  return {
    html: await s2s(r.prelude),
    state: r.postponed && JSON.parse(JSON.stringify(r.postponed)),
  };
}

counts = {};
const r1 = await paused((c) =>
  prerender(<App />, { signal: c.signal, onError() {} }),
);
console.log("ROUND 1 executions:", counts);

gates.A = true;
counts = {};
const r2 = await paused((c) =>
  resumeAndPrerender(<App />, r1.state, { signal: c.signal, onError() {} }),
);
console.log("ROUND 2 executions:", counts);

gates.B = true;
counts = {};
const finalHtml = await s2s(await resume(<App />, r2.state));
console.log("ROUND 3 executions:", counts);
console.log("round 3 html:", JSON.stringify(finalHtml));
