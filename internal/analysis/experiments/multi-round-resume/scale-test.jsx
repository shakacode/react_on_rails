// Scale test: (1) 50 holes in a single pause; (2) a 6-round chain via nesting.
import React, { Suspense } from "react";
import { prerender, resumeAndPrerender } from "react-dom/static";
import { resume } from "react-dom/server";

const gates = new Map();
function Wait({ name, children }) {
  if (!gates.get(name)) React.use(new Promise(() => {}));
  return children;
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

async function pausedRound(fn) {
  const c = new AbortController();
  setTimeout(() => c.abort(new Error("pause")), 50);
  const r = await fn(c);
  const html = await streamToString(r.prelude);
  return {
    html,
    state: r.postponed && JSON.parse(JSON.stringify(r.postponed)),
  };
}

// ---- Test 1: 50 holes in one pause, all resumed in one round -------------
function Wide() {
  return (
    <div>
      {Array.from({ length: 50 }, (_, i) => (
        <Suspense key={`s${i}`} fallback={<i>...</i>}>
          <Wait name={`w${i}`}>
            <b>sec{i}</b>
          </Wait>
        </Suspense>
      ))}
    </div>
  );
}

const r1 = await pausedRound((c) =>
  prerender(<Wide />, { signal: c.signal, onError() {} }),
);
const holeCount = (r1.html.match(/template id="B:/g) || []).length;
for (let i = 0; i < 50; i++) gates.set(`w${i}`, true);
const wideFinal = await streamToString(await resume(<Wide />, r1.state));
const filled = (wideFinal.match(/\$RC\(/g) || []).length;
console.log(
  `WIDE: holes in shell=${holeCount}, filled on resume=${filled}, state bytes=${JSON.stringify(r1.state).length}`,
);

// ---- Test 2: 6-round chain, one new nested hole revealed per round -------
const DEPTH = 6;
function Nest({ level }) {
  if (level >= DEPTH) return <b>bottom</b>;
  return (
    <Suspense fallback={<i>loading {level}</i>}>
      <Wait name={`d${level}`}>
        <span>level {level}</span>
        <Nest level={level + 1} />
      </Wait>
    </Suspense>
  );
}
const Deep = () => (
  <div>
    <Nest level={0} />
  </div>
);

let state = null;
let htmlPieces = [];
{
  const r = await pausedRound((c) =>
    prerender(<Deep />, { signal: c.signal, onError() {} }),
  );
  htmlPieces.push(r.html);
  state = r.state;
}
for (let lvl = 0; lvl < DEPTH; lvl++) {
  gates.set(`d${lvl}`, true); // open exactly one more gate -> completes old hole, reveals one new
  if (lvl < DEPTH - 1) {
    const r = await pausedRound((c) =>
      resumeAndPrerender(<Deep />, state, { signal: c.signal, onError() {} }),
    );
    htmlPieces.push(r.html);
    if (r.state === null)
      throw new Error(`expected a new hole after round ${lvl + 2}`);
    state = r.state;
  } else {
    htmlPieces.push(await streamToString(await resume(<Deep />, state)));
  }
}
const doc = htmlPieces.join("");
// React inserts <!-- --> separators between adjacent text nodes, so match loosely.
const ok =
  doc.includes("bottom") &&
  [0, 1, 2, 3, 4, 5].every((l) =>
    new RegExp(`level (<!-- -->)?${l}`).test(doc),
  );
const dupB =
  (doc.match(/template id="(B:\d+)"/g) || []).length !==
  new Set(doc.match(/template id="(B:\d+)"/g)).size;
console.log(
  `DEEP: rounds=${DEPTH + 1}, all levels present=${ok}, duplicate boundary ids=${dupB}`,
);
