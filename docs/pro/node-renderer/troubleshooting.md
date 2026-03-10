# Node Renderer Troubleshooting

- If you enabled restarts (having `allWorkersRestartInterval` and `delayBetweenIndividualWorkerRestarts`), you should set it with a high number to avoid the app from crashing because all Node renderer workers are stopped/killed.

- If your app contains streamed pages that take too much time to be streamed to the client, ensure to not set the `gracefulWorkerRestartTimeout` parameter or set to a high number, so the worker is not killed while it's still serving an active request.
