Hi Acme Devtools Inc.,

We've identified an issue with how API keys are managed. It seems that your shell's API_KEY might be overwritten by our application's configuration files. As a workaround, please check if the `.env.local` file contains a different `API_KEY`. If it does, either change it to match your intended key or remove it to let the shell's variable take precedence. Our engineering team is working on a fix.

Thank you for your patience.

Ticket ID: SUPPORT-4815