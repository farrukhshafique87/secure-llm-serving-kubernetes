#!/usr/bin/env python3
"""EXP-03 autoscaling part: tables for the load-step runs (methodology 12.5).

Usage:
    python3 scripts/hpa_table.py results/exp-03-hpa

Reads the files written by measure-hpa.sh:
    <config>-step-r<N>.json           k6 summary with latency per phase
    <config>-step-r<N>.meta.txt       start of the measured run (start=)
    <config>-step-r<N>.replicas.txt   ready/desired replicas every 5 s
    <config>-step-r<N>.resources.txt  CPU and memory per pod every 15 s

Times are seconds since start= of the run. The step to 200 req/s begins at
180 s, the drop to 20 req/s at 490 s (ramp until 500 s). A run is classified
as in methodology 9.6, with the dropped share taken over the whole run:
collapse at 1 % or more dropped or more than 1 % failed requests, transient
when some were dropped, stable otherwise.
"""

import json
import re
import statistics
import sys
from datetime import datetime, timedelta
from pathlib import Path

RUN_FILE = re.compile(r"^(?P<config>c\d-[a-z0-9-]+?)-step-r(?P<rep>\d+)\.json$")
PHASES = ["pre", "surge", "high", "post"]
STEP_UP = 180
STEP_DOWN = 500
HIGH = (250, 490)
DEPLOYS = ["gateway", "fastapi"]


def table(header: list[str], rows: list[list[str]]) -> None:
    print("| " + " | ".join(header) + " |")
    print("| " + " | ".join("---" for _ in header) + " |")
    for row in rows:
        print("| " + " | ".join(row) + " |")
    print()


def fmt(value: float | None, digits: int = 2) -> str:
    return "-" if value is None else f"{value:.{digits}f}"


def seconds(clock: str, start: datetime) -> float:
    """Seconds from start to a HH:MM:SS UTC time on the same or the next day."""
    t = datetime.combine(start.date(), datetime.strptime(clock, "%H:%M:%S").time())
    if t < start - timedelta(hours=12):
        t += timedelta(days=1)
    return (t - start).total_seconds()


def replicas(path: Path, start: datetime) -> list[tuple[float, dict[str, int]]]:
    """(time, {deployment: ready replicas}) per sample."""
    samples = []
    for line in path.read_text().splitlines():
        clock, *fields = line.split()
        ready = {}
        for field in fields:
            name, _, value = field.partition("=")
            ready[name] = int(value.split("/")[0] or 0)
        samples.append((seconds(clock, start), ready))
    return samples


def first_time(samples, after: float, test) -> float | None:
    for t, ready in samples:
        if t >= after and test(ready):
            return t
    return None


def high_phase_cpu(path: Path, start: datetime) -> tuple[float | None, float | None]:
    """Mean CPU (m) in the high phase of the gateway pods present at the start
    and of the gateway pods added later, each summed."""
    lines = path.read_text().splitlines()
    first_pods: set[str] | None = None
    per_pod: dict[str, list[float]] = {}
    for line in lines:
        clock, _, rest = line.partition(" ")
        pods = {}
        for segment in rest.split(";"):
            parts = segment.split()
            if len(parts) == 3 and parts[0].startswith("gateway-"):
                pods[parts[0]] = float(parts[1].rstrip("m"))
        if first_pods is None:
            first_pods = set(pods)
        t = seconds(clock, start)
        if HIGH[0] <= t <= HIGH[1]:
            for pod, cpu in pods.items():
                per_pod.setdefault(pod, []).append(cpu)
    if not per_pod or not first_pods:
        return None, None
    means = {pod: statistics.mean(v) for pod, v in per_pod.items()}
    first = sum(v for pod, v in means.items() if pod in first_pods)
    added = [v for pod, v in means.items() if pod not in first_pods]
    return first, (sum(added) if added else None)


def run_row(path: Path, scaled: bool) -> dict:
    data = json.loads(path.read_text())["metrics"]
    meta = path.with_name(path.stem + ".meta.txt").read_text()
    start = datetime.strptime(
        re.search(r"^start=(\S+)", meta, re.M).group(1), "%Y-%m-%dT%H:%M:%SZ"
    )
    reqs = data["http_reqs"]["count"]
    dropped = data.get("dropped_iterations", {}).get("count", 0)
    failed = data["http_req_failed"]["value"] * 100
    dropped_pct = 100 * dropped / (reqs + dropped)
    if dropped_pct >= 1 or failed > 1:
        cls = "collapse"
    elif dropped:
        cls = "transient"
    else:
        cls = "stable"
    row = {
        "reqs": reqs,
        "dropped": dropped,
        "cls": cls,
        "phase": {p: data[f"http_req_duration{{phase:{p}}}"] for p in PHASES},
    }
    rep_file = path.with_name(path.stem + ".replicas.txt")
    samples = replicas(rep_file, start)
    # Scale-out and scale-in times only mean something with an autoscaler.
    row["gw2"] = row["gw3"] = row["back"] = None
    if scaled:
        row["gw2"] = first_time(samples, STEP_UP, lambda r: r.get("gateway", 0) >= 2)
        row["gw3"] = first_time(samples, STEP_UP, lambda r: r.get("gateway", 0) >= 3)
        row["back"] = first_time(
            samples, STEP_DOWN, lambda r: all(r.get(d, 0) == 1 for d in DEPLOYS)
        )
    row["max"] = {
        d: max(r.get(d, 0) for t, r in samples if 0 <= t <= STEP_DOWN) for d in DEPLOYS
    }
    row["cpu_first"], row["cpu_added"] = high_phase_cpu(
        path.with_name(path.stem + ".resources.txt"), start
    )
    return row


def main() -> None:
    directory = Path(sys.argv[1])
    runs: dict[tuple[str, int], dict] = {}
    for path in sorted(directory.glob("*.json")):
        m = RUN_FILE.match(path.name)
        if m:
            scaled = m["config"].endswith("-hpa")
            runs[(m["config"], int(m["rep"]))] = run_row(path, scaled)
    configs = sorted({c for c, _ in runs}, key=lambda c: (len(c), c))

    print("### /health latency per phase (ms)\n")
    print(
        "pre 0-180 s, surge 180-250 s, high 250-490 s, post 490-740 s. "
        "Median and p99 per run.\n"
    )
    rows = []
    for (c, r), s in sorted(runs.items()):
        cells = [c, str(r), s["cls"], str(int(s["dropped"]))]
        for p in PHASES:
            v = s["phase"][p]
            cells.append(f"{v['med']:.2f} / {v['p(99)']:.0f}")
        rows.append(cells)
    table(
        ["Config", "Rep", "Run", "Dropped"] + [f"{p} med / p99" for p in PHASES],
        rows,
    )

    print("### Median per phase over the runs (ms, median of run medians)\n")
    rows = []
    for c in configs:
        reps = [s for (cc, _), s in runs.items() if cc == c]
        cells = [c, str(len(reps))]
        for p in PHASES:
            cells.append(fmt(statistics.median(s["phase"][p]["med"] for s in reps)))
        rows.append(cells)
    table(["Config", "Runs"] + [f"{p} ms" for p in PHASES], rows)

    print("### Replicas (s after start; step up at 180 s, down at 490-500 s)\n")
    print(
        "Ready replicas from *.replicas.txt (5 s samples); times only for "
        "configurations with an HPA. Gateway CPU in the high phase from "
        "*.resources.txt: pods present at the start and pods added later, "
        "each summed.\n"
    )
    rows = []
    for (c, r), s in sorted(runs.items()):
        rows.append(
            [
                c,
                str(r),
                fmt(s["gw2"], 0),
                fmt(s["gw3"], 0),
                str(s["max"]["gateway"]),
                str(s["max"]["fastapi"]),
                fmt(s["back"], 0),
                fmt(s["cpu_first"], 0),
                fmt(s["cpu_added"], 0),
            ]
        )
    table(
        [
            "Config",
            "Rep",
            "gateway >= 2",
            "gateway 3",
            "gateway max",
            "fastapi max",
            "all back to 1",
            "gateway pods at start m",
            "gateway added pods m",
        ],
        rows,
    )


if __name__ == "__main__":
    main()
