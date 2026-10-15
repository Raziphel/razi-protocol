# Performance audit: Razi Protocol Dev 2.1.110

All seven asteroid/starmap performance switches are **disabled by default**.
The two existing optional settings added since 2.1.106 are space-explosion
smoke reduction and compact route overlays. The latest additional switch
is **Reduce asteroid spawning dust**.

The creation-dust filter visits existing asteroid and chunk prototype
`created_effect` trees and removes only particle/trivial-smoke nodes.
It deliberately retains script triggers, damage, actual spawned entities
and chunks. Razi's quality-carrier replacement therefore remains active.

General performance improvement (always enabled): the static starmap
renderer now resolves its difficulty module once at load and the startup
difficulty preset once per rendering pass, instead of repeating that
lookup for every 128-direction ribbon segment. Color and geometry are
unchanged.

For best evidence, compare the same late-game space-platform save with
F4 update timings and one option at a time. Disabling visual effects
usually helps FPS or graphics workload, not necessarily simulation UPS.
Changing hostile density or fragment counts affects gameplay and drops.

Validation added:
- tests/test_asteroid_performance.py
- tests/lua/test_asteroid_performance.lua

In-game Factorio 2.1 validation and benchmarks are still required.
