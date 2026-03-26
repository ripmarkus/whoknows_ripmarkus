# Post-Mortem: Bus Factor & Dependency Commit

**Author:** shuresm57  
**Date:**  
**Status:** <!-- Draft / Resolved -->

> Blameless — focused on systemic causes, not fault.

---

## What Happened

Two issues were identified:
1. **Bus factor of 1** — shuresm57 accounted for the vast majority of commits and contributions, creating a single point of failure.
2. **Accidental dependency commit** — `.bundle/` and `vendor/` were pushed, inflating line stats significantly.

---

## Root Causes

<!-- Why did the bus factor get this high? Why were the dependencies committed? Be honest. -->

---

## Impact

<!-- What could have gone wrong? What did go wrong? -->

---

## Resolution

`.bundle/` and `vendor/` have been added to `.gitignore`. Historical commits remain as evidence of the incident.

---

## Action Items

| Action | Owner | Status |
|--------|-------|--------|
| Fix `.gitignore` | shuresm57 | |
| Document architecture | shuresm57 | |
| Enforce PR reviews | All | |

---

## Lessons Learned

<!-- 2-3 genuine takeaways -->