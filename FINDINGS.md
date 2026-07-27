# Findings — evaluating stackabletech as an OSS contribution target

Method: fresh local minikube cluster (Docker driver), installed the Stackable
Spark operator stack via Helm from their public `stackable-stable` chart repo,
ran a real `SparkApplication` (SparkPi) end to end, and poked around their
contribution setup.

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
   reference `26.7.0`, which isn't in that repo yet; use `helm search repo
   stackable-stable --versions` to see what's actually installable).
4. All 4 operator pods came up `Running` with no errors on the first try.
5. Applied a `SparkApplication` CR (the SparkPi example from their docs,
   cluster mode, one executor). The operator created a driver pod, which
   spawned an executor, ran the job, and completed:
   `Pi is roughly 3.1393156965784828` in the driver logs, both driver and
   submit pod finished as `Completed`.
6. No manual pod wiring, no hand-written spark-submit flags — the CRD-driven
   workflow (`spec.mainClass`, `spec.mainApplicationFile`, `spec.executor.replicas`)
   really is basically what it advertises: a working Spark job on k8s from
   ~25 lines of YAML.

Side note: the local minikube control plane spontaneously restarted mid-test
(Docker-in-WSL being flaky, not a Stackable thing) and wiped the first run's
state. A `minikube update-context` plus reinstalling the 4 Helm releases and
reapplying the CR fixed it and reproduced the exact same result, so the first
success wasn't a fluke.

## License and contribution mechanics

- **License is OSL-3.0** (Open Software License v3.0), not Apache-2.0 like
  the org's `operator-templating` repo might make you assume — this varies
  per repo, so check each one individually. OSL-3.0 is copyleft with a patent
  grant, OSI-approved but a lot less common than Apache-2.0/MIT, worth
  knowing before contributing code you'd want to reuse elsewhere.
- **CLA required** on every PR, enforced by a bot (pretty standard for a
  company-backed project).
- Active: commits/PRs across the org within hours of checking, 71 stars,
  4 forks, 39 issues on spark-k8s-operator alone, 23 contributors.
- `spark-k8s-operator` and `airflow-operator` both have open
  `good first issue` labelled issues right now.
- Docs, a contributor guide, and a public Discord/Discussions forum all
  exist and look actively maintained.

## Verdict

Worth pursuing as a contribution target:
- Real, working, well-documented software (verified myself, not just taking
  the docs' word for it) — low risk of it being an abandoned demo repo.
- Company-backed with a funded team probably means faster review turnaround
  than a typical volunteer OSS project, but also means CLA + house style
  (operator-templating conventions) to follow.
- Codebase is Rust, which raises the bar vs. the Go/Python projects already
  in the current PR portfolio — expect a slower ramp-up on a first PR.
- Good-first-issue labels exist right now on spark-k8s-operator and
  airflow-operator — a reasonable place to start looking.

Main watch-outs before opening a PR: confirm the license per-repo (OSL-3.0 vs
Apache-2.0 differ across their repos), and don't assume the Helm chart
version in the docs is already published — check
`helm search repo stackable-stable --versions` first (or use `stackablectl`,
their officially recommended tool, if it installs cleanly in your setup).
