# Security model

Inventory creates a customer service account, binds the roles documented in the
README, and permits only the configured Relyance scanner service account to
impersonate it using short-lived credentials. No service account key is created.
Use `relyance_env = "prod-eu"` for the EU scanner identity.

The default project inventory configuration does not enable the optional data
integrations. Setting `integrations` adds the documented data-content roles;
review those additions and the project scope before applying. The organization
submodule binds its inventory roles at organization scope, including project and
folder discovery. Inventory viewer roles can expose metadata and service-specific
information; inspect their current cloud definitions as part of your IAM review.

Destroying the module removes the service account and its managed bindings. Report
security issues privately through your Relyance support channel rather than
posting credentials or customer configuration in public issues.
