#!/usr/bin/env python3

import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

OPTIMIZATIONS = ["-O0", "-O1", "-O2", "-O3", "-Ofast"]

def main():
    for opt in OPTIMIZATIONS:

        subprocess.run(["make", "clean"], cwd=PROJECT_ROOT, check=True)

        print(opt)

        subprocess.run(
            ["make", "benchmark", f"OPT={opt}", "ITERATIONS=1000"],
            cwd=PROJECT_ROOT,
            check=True
        )

        subprocess.run(["./benchmark"], cwd=PROJECT_ROOT, check=True)

if __name__ == "__main__":
    main()