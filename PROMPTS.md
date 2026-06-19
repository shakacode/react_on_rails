# Canonical AI-agent prompts (`prompts.yml`)

[`prompts.yml`](./prompts.yml) is the single source of truth for the copy-able
"paste into your AI agent" prompts that ground an assistant at the official
React on Rails docs. [reactonrails.com](https://reactonrails.com) displays them
(home Quick Start + the [`/prompts`](https://reactonrails.com/prompts) page) and
publishes the machine-readable agent artifacts generated from this file.

This is **Part A** of shakacode/react_on_rails#3832 (make the framework repo the
canonical prompt source). The site-side sync + codegen that consumes this file is
tracked in shakacode/reactonrails.com#126; the original site display shipped in
shakacode/reactonrails.com#125. The empirical eval harness (Part B of #3832) is a
separate initiative and is **not** part of this file.

## Why the framework repo owns the prompts

The prompts must move in lockstep with the framework's own docs, commands, and
version requirements. Keeping them here (and having the site sync _from_ here)
means a docs route rename or a version bump is a one-place change in the repo
that already gates those docs, instead of drifting in a separate site constant.

## Schema

```yaml
schema_version: 1
site_url: https://reactonrails.com # canonical origin; matches the site's docusaurus url
agent_note: <string> # one-liner shown once per surface

categories: # display metadata, in display order
  - id: <category-id>
    eyebrow: <short label>
    heading: <one-line heading>

home_prompt_ids: # ordered subset for the home Quick Start
  - <prompt-id>

prompts:
  - id: <stable-slug> # React key + selects the home subset; never reuse
    title: <human title>
    category: <one of categories[].id>
    doc_route: <relative docs route> # e.g. /docs/pro/react-server-components (may end in #fragment; quote if so)
    prompt: <prompt body, may contain {{doc_url}}>
```

### Field rules

- **`id`** — stable slug. It is a public contract (React keys, `home_prompt_ids`,
  per-prompt eval reports). Renaming one is a breaking change for downstream
  consumers; prefer adding a new prompt.
- **`category`** — must reference a `categories[].id`.
- **`doc_route`** — a **relative** route only (starts with `/docs/`), optionally
  ending in a `#fragment` anchor (e.g.
  `/docs/api-reference/ruby-api-pro#async_react_component...`). This is the
  single home for each prompt's URL. Quote any value containing `#` in YAML so
  the fragment is never mistaken for a comment.
- **`prompt`** — the verbatim body a user pastes. Use the `{{doc_url}}`
  placeholder anywhere the absolute docs URL should appear.

## Build-time URL resolution (single-source URLs)

The absolute docs URL is **never hard-coded** in a prompt body. Consumers resolve
it at build time and substitute it for the placeholder:

```text
doc_url = site_url + doc_route
prompt_text = prompt.replace("{{doc_url}}", doc_url)
```

So the URL lives in exactly one place (`doc_route`) and cannot drift between the
prompt text and the rendered "Open guide" link.

## Artifact contract (consumed by reactonrails.com#126)

From `prompts.yml`, the site is expected to generate:

- **`prompts.json`** — the resolved prompt set (each prompt with `{{doc_url}}`
  expanded and an absolute `doc_url` field), for programmatic / agent fetching.
- **the site-published `llms.txt`** — the human-and-agent-readable prompt corpus
  served at `https://reactonrails.com/llms.txt`.

The site also regenerates its display component (`prompts.ts`) from this file so
the live page matches the canonical set. This file does not itself emit those
artifacts; generation lives with the consumer (the site, #126), and a future
validator can assert round-trip fidelity.

## `llms.txt` disambiguation

There are two distinct `llms.txt` artifacts — do not conflate them:

| Artifact                                    | Home           | Generated from                  | Purpose                                                          |
| ------------------------------------------- | -------------- | ------------------------------- | ---------------------------------------------------------------- |
| [`./llms.txt`](./llms.txt) (this repo root) | framework repo | `script/generate-llms-full.mjs` | machine-readable **doc route-map**, paired with `llms-full*.txt` |
| `https://reactonrails.com/llms.txt`         | the website    | `prompts.yml` (this file)       | published **prompt corpus** for agents                           |

The repo-root file is the framework's doc index; the site file is the prompt
corpus. They share a filename and nothing else.

## Editing prompts

1. Edit `prompts.yml` (add/modify an entry; keep `id` stable).
2. Use a **relative** `doc_route`; reference it in the body via `{{doc_url}}`.
3. If adding a category, add it to `categories` first.
4. The site (reactonrails.com#126) re-syncs and regenerates display + artifacts.
