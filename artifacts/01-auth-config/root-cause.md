The issue occurs because the API key set in the environment might be overridden by `.env` configuration files. The `config.ts` file loads `.env` before starting the application, which can potentially replace the `API_KEY` set in the shell with values from `.env` or `.env.local`. Ensure that `.env.local` does not override `API_KEY`, or if it must, log it explicitly for clarity.

- `/Users/kam/development/KILO/app/server/src/server.ts:13` – mismatch warning indicates token comparison failure.
- `/Users/kam/development/KILO/app/server/src/server.ts:14` – returns HTTP 401 upon API token mismatch.