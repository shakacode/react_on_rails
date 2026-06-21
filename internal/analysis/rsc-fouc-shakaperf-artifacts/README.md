# RSC FOUC ShakaPerf Artifacts

These files support `../rsc-fouc-shakaperf-investigation.md`.

## ShakaPerf setup and tests

| Area                                    | Files                                                                                                                |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Setup/test bundle                       | [setup/README.md](setup/README.md)                                                                                   |
| Deterministic first-paint AB test       | [setup/ab-tests/rsc-fouc.abtest.ts](setup/ab-tests/rsc-fouc.abtest.ts)                                               |
| Natural first-visible assertion AB test | [setup/ab-tests/natural-first-visible-assertion.abtest.ts](setup/ab-tests/natural-first-visible-assertion.abtest.ts) |
| Main config                             | [setup/config/abtests.config.ts](setup/config/abtests.config.ts)                                                     |
| Twin server Dockerfile                  | [setup/twin-servers/Dockerfile](setup/twin-servers/Dockerfile)                                                       |
| Generated ShakaPerf instructions        | [setup/generated-shakaperf-skills/](setup/generated-shakaperf-skills/)                                               |

## Screenshots

| Evidence                                                     | Image                                                                                                                         |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| ShakaPerf report: old/pre-fix vs current/fixed first paint   | [shakaperf-first-paint-old-vs-current-report.png](images/shakaperf-first-paint-old-vs-current-report.png)                     |
| ShakaPerf report: current/fixed vs current/fixed first paint | [shakaperf-first-paint-current-vs-current-report.png](images/shakaperf-first-paint-current-vs-current-report.png)             |
| ShakaPerf report: natural first-visible assertion            | [shakaperf-natural-first-visible-old-vs-current-report.png](images/shakaperf-natural-first-visible-old-vs-current-report.png) |
| Old/pre-fix first paint: selector screenshot                 | [first-paint-old-unstyled-probe.png](images/first-paint-old-unstyled-probe.png)                                               |
| Current/fixed first paint: selector screenshot               | [first-paint-current-styled-probe.png](images/first-paint-current-styled-probe.png)                                           |
| First-paint selector diff                                    | [first-paint-old-vs-current-diff.png](images/first-paint-old-vs-current-diff.png)                                             |
| Old/pre-fix natural first-visible selector screenshot        | [natural-first-visible-old-unstyled-probe.png](images/natural-first-visible-old-unstyled-probe.png)                           |
| Current/fixed natural first-visible selector screenshot      | [natural-first-visible-current-styled-probe.png](images/natural-first-visible-current-styled-probe.png)                       |
| Natural first-visible selector diff                          | [natural-first-visible-old-vs-current-diff.png](images/natural-first-visible-old-vs-current-diff.png)                         |

## ShakaPerf reports

| Run                                                            | Report                                                                                | Log                                                      |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| Old/pre-fix vs current/fixed deterministic first paint         | [full-report.html](reports/first-paint-old-vs-current/full-report.html)               | [log](logs/first-paint-old-vs-current.log)               |
| Current/fixed vs current/fixed deterministic first paint       | [full-report.html](reports/first-paint-current-vs-current/full-report.html)           | [log](logs/first-paint-current-vs-current.log)           |
| Old/pre-fix vs current/fixed natural first-visible assertion   | [full-report.html](reports/natural-first-visible-old-vs-current/full-report.html)     | [log](logs/natural-first-visible-old-vs-current.log)     |
| Current/fixed vs current/fixed natural first-visible assertion | [full-report.html](reports/natural-first-visible-current-vs-current/full-report.html) | [log](logs/natural-first-visible-current-vs-current.log) |
