# Previous generated RSC config fixtures

Verbatim `clientWebpackConfig.js` files as previous `rails g react_on_rails:rsc` versions
produced them, one per resolver era. Each era corresponds to one entry of
`ReactOnRails::Generators::RscSetup::ClientReferences::PREVIOUS_GENERATED_RSC_CLIENT_REFERENCES_DIGESTS`;
`rsc_generator_spec.rb` proves the generator upgrades each one in place and that the digest
table holds exactly these eras.

The files are byte-verbatim historical output — no added headers or comments — so digest
matching and migration-range detection in the specs see exactly what a real app contains.

| Fixture | Era | Source |
| --- | --- | --- |
| `manifest_era_b58d1fe8b.js` | Manifest-backed resolver (immediately pre-#5079) | Golden `webpack_rsc` fixture as committed at `b58d1fe8b` |
| `initial_graph_era_5c71c6a9c.js` | Initial graph-derived resolver (#3556) | Verbatim `rsc_client_references_js` heredoc of `5c71c6a9c`, with the era's surrounding imports and plugin wiring |
| `registration_entry_era_912d2a2b4.js` | Registration-entry override (#3712) | Verbatim `rsc_client_references_js` heredoc of `912d2a2b4`, unchanged through `d7a6025be` (#3721) |
