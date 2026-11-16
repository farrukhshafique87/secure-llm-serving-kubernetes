#!/usr/bin/env python3
"""CPU throttling per load run, read back from Prometheus (cAdvisor counters).

Usage (no extra packages needed):
    python3 scripts/throttle_table.py results/exp-04-gateway-cpu [--prom URL]

Needs ./scripts/monitoring-forward.sh running (default URL
http://localhost:9090). Prometheus keeps the counters for 120 days, so run this
soon after an experiment and commit the CSV it writes.

For every <config>-health-rate<R>-r<N>.meta.txt the script takes the measured
window (start= and end=) and asks Prometheus for the share of CFS periods in
which each container on the request path was throttled: 1-minute rates, sampled
every 15 s from one minute after the start to the end, so warm-up and cool-down
are not included. Per run it keeps the mean and the maximum of these samples.

Writes throttling.csv into the result folder and prints one table per
container: mean and maximum per configuration and rate (maximum over runs).

Runs recorded since EXP-03 also carry the CPU use of the whole host during the
measured run (host_cpu= in the .meta.txt, written by run-experiment.sh). For
those the script also writes host-cpu.csv and prints a table per level.
"""

import csv
import json
import re
import sys
import urllib.parse
import urllib.request
from collections import defaultdict
from datetime import datetime
from pathlib import Path

# /health runs at one rate, and the load-step runs of EXP-03 (rate shown as
# "step", stored as 0).
META_FILE = re.compile(
    r"^(?P<config>c\d-[a-z0-9-]+?)-(?:health-rate(?P<rate>\d+)|step)"
    r"-r(?P<rep>\d+)\.meta\.txt$"
)
NAMESPACE = {
    "c0-baseline": "llm-baseline",
    "c1-rbac": "llm-c1-rbac",
    "c2-netpol": "llm-c2-netpol",
    "c3-mtls": "llm-c3-mtls",
    "c4-tls": "llm-c4-tls",
    "c5-gateway": "llm-c5-gateway",
    "c5-gateway-cpu1000": "llm-c5-gateway",
    "c6-all": "llm-secure",
    "c0-baseline-r2": "llm-baseline",
    "c0-baseline-r3": "llm-baseline",
    "c5-gateway-cpu1000-r2": "llm-c5-gateway",
    "c5-gateway-cpu1000-r3": "llm-c5-gateway",
    "c5-gateway-cpu1000-hpa": "llm-c5-gateway",
}
CONTAINERS = ["gateway", "fastapi", "linkerd-proxy"]
HOST_CPU = re.compile(
    r"busy (?P<busy>[\d.]+)% steal (?P<steal>[\d.]+)% of (?P<cpus>\d+)"
)
QUERY = (
    "sum by (container) (rate(container_cpu_cfs_throttled_periods_total{{{sel}}}[1m]))"
    " / sum by (container) (rate(container_cpu_cfs_periods_total{{{sel}}}[1m]))"
)


def read_meta(path: Path) -> dict[str, str]:
    out = {}
    for line in path.read_text().splitlines():
        key, _, value = line.partition("=")
        out[key.strip()] = value.strip()
    return out


def epoch(stamp: str) -> float:
    return datetime.fromisoformat(stamp.replace("Z", "+00:00")).timestamp()


def query_range(prom: str, expr: str, start: float, end: float) -> dict[str, list]:
    params = urllib.parse.urlencode(
        {"query": expr, "start": start, "end": end, "step": "15"}
    )
    with urllib.request.urlopen(f"{prom}/api/v1/query_range?{params}", timeout=30) as r:
        body = json.load(r)
    if body.get("status") != "success":
        sys.exit(f"Prometheus error: {body}")
    return {
        s["metric"].get("container", "?"): [float(v) for _, v in s["values"]]
        for s in body["data"]["result"]
    }


def main() -> None:
    args = sys.argv[1:]
    prom = "http://localhost:9090"
    if "--prom" in args:
        i = args.index("--prom")
        prom = args[i + 1]
        del args[i : i + 2]
    if len(args) != 1:
        sys.exit(__doc__)
    directory = Path(args[0])

    rows = []
    host_rows = []
    for path in sorted(directory.glob("*.meta.txt")):
        m = META_FILE.match(path.name)
        if not m or m["config"] not in NAMESPACE:
            continue
        meta = read_meta(path)
        host = HOST_CPU.search(meta.get("host_cpu", ""))
        if host:
            host_rows.append(
                {
                    "config": m["config"],
                    "rate": int(m["rate"] or 0),
                    "rep": int(m["rep"]),
                    "busy_pct": float(host["busy"]),
                    "steal_pct": float(host["steal"]),
                    "cpus": int(host["cpus"]),
                }
            )
        start, end = epoch(meta["start"]) + 60, epoch(meta["end"])
        sel = (
            f'namespace="{NAMESPACE[m["config"]]}", container=~"{"|".join(CONTAINERS)}"'
        )
        series = query_range(prom, QUERY.format(sel=sel), start, end)
        if not series:
            print(f"warning: no data for {path.name}", file=sys.stderr)
        for container, values in sorted(series.items()):
            rows.append(
                {
                    "config": m["config"],
                    "rate": int(m["rate"] or 0),
                    "rep": int(m["rep"]),
                    "container": container,
                    "samples": len(values),
                    "mean": round(sum(values) / len(values), 4),
                    "max": round(max(values), 4),
                }
            )
    if not rows:
        sys.exit(f"no /health runs with data in {directory}")

    with (directory / "throttling.csv").open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    groups = defaultdict(list)
    for r in rows:
        groups[(r["container"], r["config"], r["rate"])].append(r)
    for container in CONTAINERS:
        keys = sorted(k for k in groups if k[0] == container)
        if not keys:
            continue
        print(f"### CPU throttling of `{container}` (share of CFS periods)\n")
        print("Mean: average over runs of the per-run mean. Max: highest 1-minute")
        print("value in any run of that level.\n")
        print("| Config | Rate req/s | Runs | Mean % | Max % |")
        print("| --- | --- | --- | --- | --- |")
        for key in keys:
            rs = groups[key]
            mean = sum(r["mean"] for r in rs) / len(rs) * 100
            peak = max(r["max"] for r in rs) * 100
            rate = key[2] or "step"
            print(f"| {key[1]} | {rate} | {len(rs)} | {mean:.1f} | {peak:.1f} |")
        print()
    print(f"wrote {directory / 'throttling.csv'}", file=sys.stderr)

    if host_rows:
        with (directory / "host-cpu.csv").open("w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=list(host_rows[0]))
            writer.writeheader()
            writer.writerows(host_rows)
        levels = defaultdict(list)
        for r in host_rows:
            levels[(r["config"], r["rate"])].append(r)
        print("### Host CPU during the measured run (all CPUs of the WSL host)\n")
        print("| Config | Rate req/s | Runs | Busy mean % | Busy max % | Steal max % |")
        print("| --- | --- | --- | --- | --- | --- |")
        for (config, rate), rs in sorted(levels.items()):
            busy = [r["busy_pct"] for r in rs]
            steal = max(r["steal_pct"] for r in rs)
            print(
                f"| {config} | {rate or 'step'} | {len(rs)} "
                f"| {sum(busy) / len(busy):.1f} "
                f"| {max(busy):.1f} | {steal:.1f} |"
            )
        print()
        print(f"wrote {directory / 'host-cpu.csv'}", file=sys.stderr)


if __name__ == "__main__":
    main()
