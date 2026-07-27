# Findings — evaluating stackabletech as an OSS contribution target

Date: 2026-07-28. Method: fresh local minikube cluster (Docker driver), installed
the Stackable Spark operator stack via Helm from the public `stackable-stable`
chart repo, ran a real `SparkApplication` (SparkPi) end to end, and reviewed the
org's contribution setup.

## What it actually is

Stackable (the company, Wedel, Germany) publishes a curated set of Kubernetes
operators for data-platform components: Spark, Kafka, Airflow, NiFi, Trino,
Druid, HBase, HDFS, Hive, ZooKeeper, OpenSearch, Superset, plus internal
support operators (commons, secret, listener, OPA). Each product is its own
repo under [github.com/stackabletech](https://github.com/stackabletech)
(176 repos total), written primarily in Rust using their shared `operator-rs`
framework, generated from a common `operator-templating` scaffold (so CI,
docs structure, lint config etc. are consistent across all of them).

## Hands-on test (spark-k8s-operator)

1. `minikube start --driver=docker` — clean local cluster.
2. `helm repo add stackable-stable https://repo.stackable.tech/repository/helm-stable/`
3. Installed, in order: `commons-operator`, `secret-operator`,
   `listener-operator`, `spark-k8s-operator` (all `25.3.0`, the latest tag
   published to the stable Helm repo — note the public docs currently
   reference `26.7.0`, which is not yet in that repo; use `helm search repo
   stackable-stable --versions` to find what is actually installable).
4. All 4 operator pods came up `Running` with no errors on the first try.
5. Applied a `SparkApplication` CR (the SparkPi example from their docs,
   cluster mode, one executor). The operator created a driver pod, which
   spawned an executor, ran the job, and completed:
   `Pi is roughly 3.1393156965784828` in the driver logs, both driver and
   submit pod finished as `Completed`.
6. No manual pod wiring, no hand-written Spark submit flags — the CRD-driven
   workflow (`spec.mainClass`, `spec.mainApplicationFile`, `spec.executor.replicas`)
   is basically what it advertises: get a working Spark job on k8s from ~25
   lines of YAML.

Aside/environment note: the local minikube control plane spontaneously
restarted mid-test (Docker-in-WSL instability, not a Stackable issue) and
wiped the first run's state; a `minikube update-context` plus reinstalling the
4 Helm releases and reapplying the CR fixed it and reproduced identical
results, confirming the first success wasn't a fluke.

## License and contribution mechanics

- **License is OSL-3.0** (Open Software License v3.0), not Apache-2.0 as
  the org's `operator-templating` repo (Apache-2.0) might suggest — this
  varies per repo, check each one. OSL-3.0 is a copyleft license with a
  patent grant; it's OSI-approved but far less common than Apache-2.0/MIT,
  worth being aware of before contributing code you care about reusing
  elsewhere.
- **CLA required** on every PR, enforced by a bot (standard for a
  company-backed project).
- Active: commits/PRs across the org within hours of checking, 71 stars /
  4 forks / 39 issues on spark-k8s-operator alone, 23 contributors.
- `spark-k8s-operator` and `airflow-operator` both have open
  `good first issue` labelled issues right now.
- Docs, contributor guide, and a public Discord/Discussions forum exist and
  are actively maintained.

## Verdict

Worth pursuing as a contribution target:
- Real, working, well-documented software (verified myself, not just reading
  docs) — low risk of "abandoned demo repo" surprises.
- Company-backed with a funded team means faster review turnaround than a
  typical volunteer OSS project, but also means CLA + house style
  (operator-templating conventions) to follow.
- Codebase is Rust, which raises the bar vs. Go/Python projects already in
  the existing goal-PR portfolio — plan for a slower ramp-up on a first PR.
- Good-first-issue labels exist right now on spark-k8s-operator and
  airflow-operator — a reasonable place to look first.

Main watch-outs before opening a PR: confirm per-repo license (OSL-3.0 vs
Apache-2.0 differ across their repos), and don't assume the Helm chart
version in the docs is already published — always check
`helm search repo stackable-stable --versions` (or use `stackablectl`, the
officially recommended tool, if it's installable in your environment).
