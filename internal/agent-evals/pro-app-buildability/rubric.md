# Rubric

Review captured command output and workspace files, never solely the agent's
report. The harness records bounded facts but does not interpret application
source, shell syntax, test names, or framework conventions.

| ID                  | Required evidence                                    | Passing evidence                                                            |
| ------------------- | ---------------------------------------------------- | --------------------------------------------------------------------------- |
| `install.pro`       | manifests/config and install log                     | Pro is enabled through the public onboarding path without human file repair |
| `rsc.route`         | route, server component, build/runtime output        | an RSC route renders data supplied on the server                            |
| `form.validation`   | controller/action and integration/system test output | invalid input is rejected server-side and valid input succeeds              |
| `tests.page`        | test source and test command output                  | page/RSC behavior has a passing automated test                              |
| `tests.form`        | test source and test command output                  | both form outcomes have passing automated coverage                          |
| `build.production`  | exact production build command and output            | production assets build with exit status 0                                  |
| `tests.green`       | exact relevant test commands and output              | relevant Ruby and JavaScript tests exit 0                                   |
| `unaided`           | runner-owned invocation record                       | runner sent no human follow-up input after the immutable prompt             |
| `evidence.complete` | metadata, hashes, inventory, report, verification    | run artifacts validate and contain no unresolved `UNKNOWN` required result  |

New runs use overall status `needs-review`, with every semantic row `unknown`,
until a human reviews the cited command and artifact evidence. Command exit
codes, truncation, omitted evidence, and collection-limit failures remain facts
for that review; they are not converted into semantic pass/fail judgments.

Historical bundles retain their original `pass`, `fail`, or `incomplete`
statuses for byte-for-byte replay compatibility. Those legacy statuses describe
the retired classifier's output and do not substitute for current manual review.
