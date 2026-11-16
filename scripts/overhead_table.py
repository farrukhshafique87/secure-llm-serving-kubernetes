#!/usr/bin/env python3
"""Overhead tables (latency and resources) relative to the baseline configuration.

Usage:
    python3 scripts/overhead_table.py results/exp-06-final [baseline-config]

Reads the k6 summary files and resource samples written by run-experiment.sh.
A difference is marked "distinct" only when the min-max ranges of the
repetitions do not overlap with the baseline's; otherwise it is "within noise".
"""

import json
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path

RUN_FILE = re.compile(r"^(?P<config>.+)-r(?P<rep>\d+)\.json$")

# Pods that take part in a request on the lightweight /health path.
PATH_PODS = {
    "c0-baseline": ["fastapi"],
    "c1-rbac": ["fastapi"],
    "c2-netpol": ["fastapi"],
    "c3-mtls": [
        "fastapi",
        "linkerd-destination",
        "linkerd-identity",
        "linkerd-proxy-injector",
    ],
    "c4-tls": ["fastapi", "traefik"],
    "c5-gateway": ["fastapi", "gateway"],
    "c5-gateway-cpu1000": ["fastapi", "gateway"],
    "c0-baseline-r2": ["fastapi"],
    "c0-baseline-r3": ["fastapi"],
    "c5-gateway-cpu1000-r2": ["fastapi", "gateway"],
    "c5-gateway-cpu1000-r3": ["fastapi", "gateway"],
    "c5-gateway-cpu1000-hpa": ["fastapi", "gateway"],
    "c6-all": [
        "fastapi",
        "gateway",
        "traefik",
        "linkerd-destination",
        "linkerd-identity",
        "linkerd-proxy-injector",
    ],
}


def stat(data: dict, name: str, field: str) -> float | None:
    entry = data.get("metrics", {}).get(name, {})
    entry = entry.get("values", entry)
    return entry.get(field)


def load(directory: Path) -> dict[str, list[dict]]:
    runs: dict[str, list[dict]] = defaultdict(list)
    for path in sorted(directory.glob("*.json")):
        match = RUN_FILE.match(path.name)
        if match:
            runs[match["config"]].append(
                {"path": path, "data": json.loads(path.read_text())}
            )
    return runs


def values(runs: list[dict], metric: str, field: str) -> list[float]:
    out = [stat(r["data"], metric, field) for r in runs]
    return [v for v in out if v is not None]


def pod_cpu_mem(runs: list[dict]) -> dict[str, tuple[float, float]]:
    """Mean over runs of the per-run mean CPU (m) and memory (Mi) per Deployment
    (all replicas added up)."""
    per_pod: dict[str, dict[str, list[float]]] = defaultdict(
        lambda: {"cpu": [], "mem": []}
    )
    for run in runs:
        res = run["path"].with_name(run["path"].stem + ".resources.txt")
        if not res.exists():
            continue
        samples: dict[str, dict[str, list[float]]] = defaultdict(
            lambda: {"cpu": [], "mem": []}
        )
        for line in res.read_text().splitlines():
            _, _, rest = line.partition(" ")
            # Replicas of one Deployment are added up within a sample, so a
            # value is the total of the Deployment, not of a single pod.
            total: dict[str, list[float]] = defaultdict(lambda: [0.0, 0.0])
            for segment in rest.split(";"):
                parts = segment.split()
                if (
                    len(parts) == 3
                    and parts[1].endswith("m")
                    and parts[2].endswith("Mi")
                ):
                    pod = parts[0].rsplit("-", 2)[0]
                    total[pod][0] += float(parts[1][:-1])
                    total[pod][1] += float(parts[2][:-2])
            for pod, (cpu, mem) in total.items():
                samples[pod]["cpu"].append(cpu)
                samples[pod]["mem"].append(mem)
        for pod, s in samples.items():
            per_pod[pod]["cpu"].append(statistics.mean(s["cpu"]))
            per_pod[pod]["mem"].append(statistics.mean(s["mem"]))
    return {
        pod: (statistics.mean(v["cpu"]), statistics.mean(v["mem"]))
        for pod, v in per_pod.items()
        if v["cpu"]
    }


def verdict(base: list[float], other: list[float]) -> str:
    if not base or not other:
        return "-"
    if min(other) > max(base):
        return "distinct, higher"
    if max(other) < min(base):
        return "distinct, lower"
    return "within noise"


def latency_table(
    title: str, runs: dict[str, list[dict]], suffix: str, base: str, unit: str
) -> None:
    print(f"### {title}\n")
    header = ["Config", f"Avg {unit}", f"Δ {unit}", "Δ %", f"P95 {unit}"]
    header += [f"P99 {unit}", "Runs", "Verdict"]
    print("| " + " | ".join(header) + " |")
    print("| --- | --- | --- | --- | --- | --- | --- | --- |")
    base_runs = runs.get(base + suffix, [])
    base_avg = values(base_runs, "http_req_duration", "avg")
    base_mean = statistics.mean(base_avg) if base_avg else None
    for config in PATH_PODS:
        rs = runs.get(config + suffix, [])
        avg = values(rs, "http_req_duration", "avg")
        if not avg:
            continue
        mean = statistics.mean(avg)
        p95 = values(rs, "http_req_duration", "p(95)")
        p99 = values(rs, "http_req_duration", "p(99)")
        delta = (
            "-" if base_mean is None or config == base else f"{mean - base_mean:+.2f}"
        )
        pct = (
            "-"
            if base_mean is None or config == base
            else f"{(mean - base_mean) / base_mean * 100:+.1f}"
        )
        v = "reference" if config == base else verdict(base_avg, avg)
        p99s = f"{statistics.mean(p99):.2f}" if p99 else "-"
        spread = f"{mean:.2f} ({min(avg):.2f}-{max(avg):.2f})"
        p95s = f"{statistics.mean(p95):.2f}"
        cells = [config, spread, delta, pct, p95s, p99s, str(len(rs)), v]
        print("| " + " | ".join(cells) + " |")
    print(
        'A configuration marked "distinct, lower" is faster than the baseline, which '
        "cannot be a cost of the control. It shows drift between runs, not overhead.\n"
    )


def resource_table(runs: dict[str, list[dict]], base: str) -> None:
    print("### Resources on the /health path (50 requests/s)\n")
    print(
        "CPU in millicores, memory in MiB; mean over repetitions of the per-run mean."
    )
    print("Only pods that take part in the request path are summed; Linkerd's control")
    print("plane counts for the configurations that use the mesh.\n")
    print("| Config | Pods summed | CPU m | Δ CPU m | Memory Mi | Δ Memory Mi |")
    print("| --- | --- | --- | --- | --- | --- |")
    base_total = None
    for config, pods in PATH_PODS.items():
        rs = runs.get(config + "-health", [])
        if not rs:
            continue
        usage = pod_cpu_mem(rs)
        cpu = sum(usage.get(p, (0.0, 0.0))[0] for p in pods)
        mem = sum(usage.get(p, (0.0, 0.0))[1] for p in pods)
        if config == base:
            base_total = (cpu, mem)
        d_cpu = d_mem = "-"
        if base_total and config != base:
            d_cpu = f"{cpu - base_total[0]:+.0f}"
            d_mem = f"{mem - base_total[1]:+.0f}"
        names = ", ".join(p.replace("linkerd-", "l5d-") for p in pods)
        print(f"| {config} | {names} | {cpu:.0f} | {d_cpu} | {mem:.0f} | {d_mem} |")
    print()


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    directory = Path(sys.argv[1])
    base = sys.argv[2] if len(sys.argv) > 2 else "c0-baseline"
    runs = load(directory)
    latency_table(
        "Lightweight path (/health), no inference", runs, "-health", base, "ms"
    )
    latency_table("Inference path (/chat)", runs, "", base, "ms")
    resource_table(runs, base)


if __name__ == "__main__":
    main()
