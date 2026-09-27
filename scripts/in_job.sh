#!/bin/bash
# Run a command inside the held development allocation (see scripts/devjob.sh),
# with the toolchain environment loaded and the provenance report printed.
#
#   scripts/in_job.sh <cmd...>              # foreground
#   TF_BG=logname scripts/in_job.sh <cmd>   # background; output in logs/<logname>.log
set -euo pipefail
STATE="$HOME/.tforge_devjob"
[[ -s "$STATE" ]] || { echo "no devjob; run scripts/devjob.sh start" >&2; exit 2; }
jobid="$(cut -d' ' -f1 "$STATE")"
mode="$(cut -d' ' -f2 "$STATE")"
gpuopt=()
[[ "$mode" == "gpu" ]] && gpuopt=(--gpus=6000_blackwell:1)
inner="cd ~/TensorForge && source scripts/env.sh && export SLURM_JOB_ID=$jobid && $(printf '%q ' "$@")"

if [[ -n "${TF_BG:-}" ]]; then
  log="$HOME/TensorForge/logs/${TF_BG}.log"
  setsid nohup srun --jobid="$jobid" --overlap "${gpuopt[@]}" bash -lc "$inner" \
    > "$log" 2>&1 < /dev/null &
  echo "background: $log"
else
  exec srun --jobid="$jobid" --overlap "${gpuopt[@]}" bash -lc "$inner"
fi
