## Escalation Ticket

### Severity
- High

### Affected Versions
- Latest commit of `app/server`

### Reproducibility
- Always

### Customer Impact
- Customers unable to log in using API keys set in the shell due to environment variable conflicts.

### References
- [Repro Note](../repro-note.md)
- [Root Cause](../root-cause.md)

### In Scope
- Investigating environmental variable precedence and correcting the loading order in the application.

### Not in Scope
- Modifications or updates to customer setup instructions.
