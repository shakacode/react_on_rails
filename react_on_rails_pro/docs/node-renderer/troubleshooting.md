# Node Renderer Troubleshooting

- If you enabled restarts (having `allWorkersRestartInterval` and `delayBetweenIndividualWorkerRestarts`), you should set it with a high number to avoid the app from crashing because all Node renderer workers are stopped/killed.
