#!/bin/bash
# Hold one Slurm allocation for development so builds, tests, and benchmarks do
# not each wait in the queue. Hive etiquette allows one running job at a time,
# so every step runs inside this allocation via scripts/in_job.sh.
#
#   scripts/devjob.sh start cpu [hours]   # 8 CPUs, 32 GB
#   scripts/devjob.sh start gpu [hours]   # + one RTX PRO 6000 Blackwell
#   scripts/devjob.sh stop
#   scripts/devjob.sh status
set -euo pipefail
STATE="$HOME/.tforge_devjob"
cmd="${1:-status}"

case "$cmd" in
  start)
    mode="${2:-cpu}"; hours="${3:-8}"
    if [[ -s "$STATE" ]] && squeue -h -j "$(cut -d' ' -f1 "$STATE")" >/dev/null 2>&1 \
        && [[ -n "$(squeue -h -j "$(cut -d' ' -f1 "$STATE")")" ]]; then
      echo "devjob already running: $(cat "$STATE")"; exit 0
    fi
    res=(--cpus-per-task=8 --mem=32G)
    [[ "$mode" == "gpu" ]] && res+=(--gpus=6000_blackwell:1)
    mkdir -p "$HOME/TensorForge/logs"
    id=$(sbatch --parsable --account=publicgrp --partition=high --job-name="tf-dev-$mode" \
         --time="$hours:00:00" "${res[@]}" \
         --output="$HOME/TensorForge/logs/slurm-%j.out" --wrap="sleep infinity")
    echo "$id $mode" > "$STATE"
    echo "submitted $id ($mode)"
    ;;
  stop)
    [[ -s "$STATE" ]] && scancel "$(cut -d' ' -f1 "$STATE")" && rm -f "$STATE"
    echo "stopped"
    ;;
  status)
    [[ -s "$STATE" ]] && { cat "$STATE"; squeue -h -j "$(cut -d' ' -f1 "$STATE")"; } || echo "no devjob"
    ;;
esac
