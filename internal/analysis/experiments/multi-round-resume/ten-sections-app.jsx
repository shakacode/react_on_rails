// Demo app: 10 vertically stacked sibling sections, section i gated on round i.
// The app only knows the `rounds` prop contract: rounds.waitForRound(i) -> Promise.
import React, { Suspense } from "react";
import { renderAppInRounds } from "./render-in-rounds.jsx";

function Section({ index, rounds }) {
  React.use(rounds.waitForRound(index)); // suspend until round `index`
  return (
    <section id={`section-${index}`} style={{ minHeight: "100vh" }}>
      <h2>Section {index}</h2>
      <p>Content of section {index}</p>
    </section>
  );
}

function App({ rounds }) {
  return (
    <main>
      <h1>Ten sections</h1>
      {Array.from({ length: 10 }, (_, i) => (
        <Suspense
          key={`sec-${i}`}
          fallback={<div className="skeleton">Loading section {i}…</div>}
        >
          <Section index={i} rounds={rounds} />
        </Suspense>
      ))}
    </main>
  );
}

const outDir = new URL("./rounds-out/", import.meta.url).pathname;
const { report, totalHoles, unfinished } = await renderAppInRounds(App, 10, {
  outDir,
});
console.log(
  `holes after round 0: ${totalHoles}, unfinished at end: ${unfinished}`,
);
for (const r of report)
  console.log(
    `round ${r.round} -> ${r.file}  holes filled: ${r.holesFilled}${r.errors?.length ? "  errors: " + r.errors : ""}`,
  );
