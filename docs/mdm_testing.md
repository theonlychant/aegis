Enterprise MDM testing checklist

- Prepare supervised device images and enrollment test plan.
- Test policy push and verify `rules` sync, forced update, and rollback flows.
- Verify that managed configurations override local settings where required.
- Test App Attest/DeviceCheck flows on supervised devices and verify attestation tokens are accepted by the backend.
- Verify that content filter or VPN policies deployed via MDM are applied system-wide on supervised devices per Apple's documented capabilities.

Test cases

- Policy rollout: push new rulepack, validate devices fetch and apply, verify signature checks and backups.
- Policy rollback: simulate a bad rule and ensure prior working rules are restored.
- Managed restrictions: ensure policy cannot be overridden on supervised devices.
