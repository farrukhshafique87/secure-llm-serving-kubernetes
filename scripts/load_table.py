#!/usr/bin/env python3
"""EXP-02 load sweep tables: latency, achieved rate and CPU per load level.

Usage:
    python3 scripts/load_table.py results/exp-02-load [--csv out.csv]

Reads the files written by measure-load.sh:
    <config>-health-rate<R>-r<N>.json   /health at R requests per second
    <config>-chat-vus<V>-r<N>.json      /chat with V virtual users

A /health level is marked "saturated" when the system no longer keeps up with
the requested rate: achieved rate below 95 % of the target, any dropped
iterations, or more than 1 % failed requests. Saturated levels get no
overhead value in the overhead table. This is the rule stated before the runs
(methodology 9.3).

Post-hoc per-run view (methodology 9.6, added after the runs): every /health
run is classified on its own as
    collapse   achieved rate below 95 % of the target, more than 1 % failed
               requests, or at least 1 % of the requests dropped
    transient  some requests dropped, but less than 1 %
    stable     nothing dropped
and the overhead is also given from the median latency of the runs that did
not collapse, which is not distorted by a few seconds of host stall.
"""

import csv
import json
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path

from overhead_table import PATH_PODS, pod_cpu_mem, stat, verdict

RUN_FILE = re.compile(
    r"^(?P<config>c\d-[a-z0-9-]+?)-(?P<path>health|chat)-(?P<kind>rate|vus)"
    r"(?P<level>\d+)-r(?P<rep>\d+)\.json$"
)
BASE = "c0-baseline"
# Pods whose CPU is shown per level; their CPU limits are in the manifests.
DETAIL_PODS = ["fastapi", "gateway", "traefik"]


def load(directory: Path) -> dict[tuple[str, str, int], list[dict]]:
    runs: dict[tuple[str, str, int], list[dict]] = defaultdict(list)
    for path in sorted(directory.glob("*.json")):
        m = RUN_FILE.match(path.name)
        if m:
            key = (m["config"], m["path"], int(m["level"]))
            runs[key].append({"path": path, "data": json.loads(path.read_text())})
    return runs


def metric(runs: list[dict], name: str, field: str, default=None) -> list[float]:
    out = []
    for r in runs:
        v = stat(r["data"], name, field)
        if v is None:
            v = default
        if v is not None:
            out.append(v)
    return out


def mean(xs: list[float]) -> float | None:
    return statistics.mean(xs) if xs else None


def fmt(x: float | None, digits: int = 2) -> str:
    return "-" if x is None else f"{x:.{digits}f}"


def summarise(runs: list[dict], target: float | None) -> dict:
    avg = metric(runs, "http_req_duration", "avg")
    achieved = metric(runs, "http_reqs", "rate")
    failed = metric(runs, "http_req_failed", "value", 0.0)
    dropped = metric(runs, "dropped_iterations", "count", 0.0)
    usage = pod_cpu_mem(runs)
    row = {
        "runs": len(runs),
        "avg": mean(avg),
        "avg_min": min(avg) if avg else None,
        "avg_max": max(avg) if avg else None,
        "avg_list": avg,
        "p95": mean(metric(runs, "http_req_duration", "p(95)")),
        "p99": mean(metric(runs, "http_req_duration", "p(99)")),
        "achieved": mean(achieved),
        "failed_pct": (mean(failed) or 0.0) * 100,
        "dropped": sum(dropped),
        "tps": mean(metric(runs, "llm_tokens_per_second", "avg")),
        "pod_cpu": {p: usage.get(p, (None, None))[0] for p in DETAIL_PODS},
        "pod_mem": {p: usage.get(p, (None, None))[1] for p in DETAIL_PODS},
    }
    if target is not None:
        saturated = (
            (row["achieved"] or 0) < 0.95 * target
            or row["dropped"] > 0
            or row["failed_pct"] > 1
        )
        row["status"] = "saturated" if saturated else "ok"
    return row


def classify(run: dict, target: float) -> str:
    data = run["data"]
    achieved = stat(data, "http_reqs", "rate") or 0.0
    count = stat(data, "http_reqs", "count") or 0.0
    dropped = stat(data, "dropped_iterations", "count") or 0.0
    failed = stat(data, "http_req_failed", "value") or 0.0
    share = dropped / (count + dropped) if count + dropped else 0.0
    if achieved < 0.95 * target or failed > 0.01 or share >= 0.01:
        return "collapse"
    return "transient" if dropped > 0 else "stable"


def per_run(runs: list[dict], target: float) -> dict:
    classes = [classify(r, target) for r in runs]
    medians = [
        stat(r["data"], "http_req_duration", "med")
        for r, c in zip(runs, classes, strict=True)
        if c != "collapse"
    ]
    medians = [m for m in medians if m is not None]
    return {
        "stable": classes.count("stable"),
        "transient": classes.count("transient"),
        "collapse": classes.count("collapse"),
        "median": statistics.median(medians) if medians else None,
        "n_median": len(medians),
    }


def table(header: list[str], rows: list[list[str]]) -> None:
    print("| " + " | ".join(header) + " |")
    print("| " + " | ".join("---" for _ in header) + " |")
    for r in rows:
        print("| " + " | ".join(r) + " |")
    print()


def main() -> None:
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    directory = Path(args[0])
    csv_path = Path(args[args.index("--csv") + 1]) if "--csv" in args else None
    runs = load(directory)
    configs = [c for c in PATH_PODS if any(k[0] == c for k in runs)]
    summary: dict[tuple[str, str, int], dict] = {}
    for key, rs in runs.items():
        summary[key] = summarise(rs, float(key[2]) if key[1] == "health" else None)

    classes: dict[tuple[str, int], dict] = {
        (k[0], k[2]): per_run(rs, float(k[2]))
        for k, rs in runs.items()
        if k[1] == "health"
    }

    rates = sorted({k[2] for k in runs if k[1] == "health"})
    vus = sorted({k[2] for k in runs if k[1] == "chat"})

    if rates:
        print("### /health latency per request rate\n")
        rows = []
        for c in configs:
            for r in rates:
                s = summary.get((c, "health", r))
                if not s:
                    continue
                spread = f"{fmt(s['avg'])} ({fmt(s['avg_min'])}-{fmt(s['avg_max'])})"
                rows.append(
                    [
                        c,
                        str(r),
                        fmt(s["achieved"], 1),
                        spread,
                        fmt(s["p95"]),
                        fmt(s["p99"]),
                        fmt(s["failed_pct"], 2),
                        f"{s['dropped']:.0f}",
                        str(s["runs"]),
                        s["status"],
                    ]
                )
        table(
            [
                "Config",
                "Target req/s",
                "Achieved req/s",
                "Avg ms",
                "P95 ms",
                "P99 ms",
                "Failed %",
                "Dropped",
                "Runs",
                "Status",
            ],
            rows,
        )

        print("### /health overhead against the baseline at each rate\n")
        others = [c for c in configs if c != BASE]
        rows = []
        for r in rates:
            b = summary.get((BASE, "health", r))
            cells = [str(r), fmt(b["avg"]) if b else "-"]
            for c in others:
                s = summary.get((c, "health", r))
                if not (b and s):
                    cells.append("-")
                    continue
                if "saturated" in (b["status"], s["status"]):
                    # Methodology section 9.3: latency of a saturated level measures
                    # queueing, not the cost of a control.
                    cells.append("n/a (saturated)")
                    continue
                d = s["avg"] - b["avg"]
                cells.append(f"{d:+.2f} ({verdict(b['avg_list'], s['avg_list'])})")
            rows.append(cells)
        table(["Rate req/s", "Baseline avg ms"] + [f"Δ {c} ms" for c in others], rows)

        print("### /health runs per level (post-hoc, methodology 9.6)\n")
        rows = []
        for c in configs:
            for r in rates:
                k = classes.get((c, r))
                if k:
                    rows.append(
                        [
                            c,
                            str(r),
                            str(k["stable"]),
                            str(k["transient"]),
                            str(k["collapse"]),
                            fmt(k["median"]),
                        ]
                    )
        table(
            [
                "Config",
                "Rate req/s",
                "Stable",
                "Transient",
                "Collapse",
                "Median ms (runs without collapse)",
            ],
            rows,
        )

        print("### /health overhead from medians, runs without collapse (post-hoc)\n")
        print(
            "A cell needs at least 2 such runs for the configuration "
            "and the baseline.\n"
        )
        rows = []
        for r in rates:
            b = classes.get((BASE, r))
            cells = [str(r), fmt(b["median"]) if b else "-"]
            for c in others:
                k = classes.get((c, r))
                if not (b and k):
                    cells.append("-")
                elif k["n_median"] < 2:
                    total = k["stable"] + k["transient"] + k["collapse"]
                    cells.append(f"n/a ({k['collapse']} of {total} collapsed)")
                elif b["n_median"] < 2:
                    cells.append("n/a (baseline: fewer than 2 runs)")
                else:
                    cells.append(
                        f"{k['median'] - b['median']:+.2f} (n={k['n_median']})"
                    )
            rows.append(cells)
        table(
            ["Rate req/s", "Baseline median ms"] + [f"Δ {c} ms" for c in others], rows
        )

        print("### CPU per pod on the /health path (millicores, mean of run means)\n")
        print(
            "CPU limits in the manifests: fastapi 1000 m, gateway 500 m "
            "(1000 m in the c5-gateway-cpu1000 configurations), traefik none. "
            "A pod at its limit is throttled by the kernel.\n"
            "With more than one replica the value is the sum over all replicas.\n"
            "Pods that are not on the request path of a configuration show '-'.\n"
        )
        rows = []
        for c in configs:
            for r in rates:
                s = summary.get((c, "health", r))
                if s:
                    cpu = [
                        fmt(s["pod_cpu"][p], 0) if p in PATH_PODS[c] else "-"
                        for p in DETAIL_PODS
                    ]
                    rows.append([c, str(r)] + cpu)
        table(["Config", "Rate req/s"] + [f"{p} m" for p in DETAIL_PODS], rows)

        print("### Memory per pod on the /health path (Mi, mean of run means)\n")
        print("With more than one replica the value is the sum over all replicas.\n")
        rows = []
        for c in configs:
            for r in rates:
                s = summary.get((c, "health", r))
                if s:
                    mem = [
                        fmt(s["pod_mem"][p], 0) if p in PATH_PODS[c] else "-"
                        for p in DETAIL_PODS
                    ]
                    rows.append([c, str(r)] + mem)
        table(["Config", "Rate req/s"] + [f"{p} Mi" for p in DETAIL_PODS], rows)

    if vus:
        print("### /chat per number of virtual users\n")
        rows = []
        for c in configs:
            for v in vus:
                s = summary.get((c, "chat", v))
                if not s:
                    continue
                spread = f"{fmt(s['avg'])} ({fmt(s['avg_min'])}-{fmt(s['avg_max'])})"
                rows.append(
                    [
                        c,
                        str(v),
                        fmt(s["achieved"], 3),
                        spread,
                        fmt(s["p95"]),
                        fmt(s["p99"]),
                        fmt(s["failed_pct"], 2),
                        fmt(s["tps"], 1),
                        str(s["runs"]),
                    ]
                )
        table(
            [
                "Config",
                "VUs",
                "Throughput req/s",
                "Avg ms",
                "P95 ms",
                "P99 ms",
                "Failed %",
                "Tokens/s",
                "Runs",
            ],
            rows,
        )

    if csv_path:
        with csv_path.open("w", newline="") as f:
            w = csv.writer(f)
            w.writerow(
                [
                    "config",
                    "path",
                    "level",
                    "runs",
                    "avg_ms",
                    "avg_min_ms",
                    "avg_max_ms",
                    "p95_ms",
                    "p99_ms",
                    "achieved_rps",
                    "failed_pct",
                    "dropped",
                    "tokens_per_s",
                ]
                + [f"cpu_{p}_m" for p in DETAIL_PODS]
                + [
                    "runs_stable",
                    "runs_transient",
                    "runs_collapse",
                    "median_ms_no_collapse",
                ]
                + [f"mem_{p}_mi" for p in DETAIL_PODS]
            )
            for (c, p, lvl), s in sorted(summary.items()):
                w.writerow(
                    [
                        c,
                        p,
                        lvl,
                        s["runs"],
                        s["avg"],
                        s["avg_min"],
                        s["avg_max"],
                        s["p95"],
                        s["p99"],
                        s["achieved"],
                        s["failed_pct"],
                        s["dropped"],
                        s["tps"],
                    ]
                    + [s["pod_cpu"][q] for q in DETAIL_PODS]
                    + (
                        [
                            classes[(c, lvl)]["stable"],
                            classes[(c, lvl)]["transient"],
                            classes[(c, lvl)]["collapse"],
                            classes[(c, lvl)]["median"],
                        ]
                        if p == "health"
                        else ["", "", "", ""]
                    )
                    + [s["pod_mem"][q] for q in DETAIL_PODS]
                )


if __name__ == "__main__":
    main()
