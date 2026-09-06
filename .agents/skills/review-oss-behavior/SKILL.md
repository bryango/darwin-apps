---
name: review-oss-behavior
description: Perform a bounded, read-only check of an open-source checkout or version bump for obvious malicious behavior, especially in build scripts, plus metadata-only dependency advisory checks. Use for shallow trust reviews, not exhaustive security audits.
---

# Review OSS Behavior

Keep this a targeted sanity check. Do not start a formal security scan, produce threat-model artifacts, or expand into a general vulnerability audit.

## Scope and inspection

- Resolve the actual checkout, commit/tag, remote, and working-tree changes. For a bump, verify both revisions; for a current-checkout request, do not silently substitute a full historical diff. Read applicable repository instructions and any user-referenced review.
- Trace the build command the user actually uses, including parent-repository wrappers, sourced scripts, package manifests, Xcode phases, plugins/macros, packaging, signing, and post-build checks. Distinguish normal local builds from optional developer and release tooling.
- Look for unexpected credential reads, uploads, downloaded-code execution, obfuscation, broad destructive cleanup, privilege escalation, persistence, and changes to endpoints, entitlements, signing keys, or binary payloads. Follow suspicious hits far enough to establish their caller and purpose; keyword matches alone are not findings.
- Check whether packaging or tests launch the real app. A temporary app copy or sandbox that only denies checkout reads does not isolate user preferences, credentials, network access, or login items. Inspect startup statically and report these side effects and any existing opt-out.
- Sample runtime networking, credential/cookie access, process execution, updates, and persistence. Explain sensitive behavior consistent with the app's purpose; identify opt-in controls and consequential defaults. Do not claim exhaustive coverage of every provider or module.
- Use bounded subagents for independent build, runtime, or advisory passes when useful. Stop once high-signal paths and concrete concerns are covered.

## Dependency records

- Read manifests, locks, and vendored version metadata. Query current upstream advisories, GitHub Advisory Database, or OSV without fetching dependency source or release archives.
- Report the pinned version, affected range, patched version, and authoritative URL. Separate a version match from demonstrated reachability; check the imported product or selected runtime engine when cheap.
- Distinguish no record found, lookup failed/unverified, and outside the affected range. None proves safety. Do not carry forward old advisory conclusions without refreshing them.

## Boundaries and report

- Keep the review read-only: do not run builds, tests, installers, regeneration scripts, the app, or live account probes; do not resolve dependencies or read actual user secrets. Further execution or fixes require a separate user request.
- Lead with whether obvious malicious behavior was found, tied to the exact revision/range. List concrete concerns and explainable sensitive behavior with file/line links, then dependency records and limitations.
- State what was not inspected or executed, and whether files changed. Avoid calling a checkout safe or cleared based on this shallow review. Suggest narrow follow-ups without implementing them.
