#!/bin/bash
# Submit a TensorForge command to Slurm. Modeled on KernelForge's scripts/run_gpu.sh.
#
#   scripts/run_job.sh gpu <cmd...>   # one RTX PRO 6000 Blackwell
#   scripts/run_job.sh cpu <cmd...>   # CPU only, 8 cores / 32 GB
#
# Extra sbatch options can be passed via TF_SBATCH_OPTS (e.g. "--time=02:00:00").
# The wrapper re-invokes itself inside the allocation with TF_IN_JOB=1.
set -euo pipefail

if [[ "${TF_IN_JOB:-0}" == "1" ]]; then
  cd ~/TensorForge
  source scripts/env.sh
  scripts/env_report.sh
  echo "== command: $*"
  exec "$@"
fi

mode="${1:?usage: run_job.sh gpu|cpu <cmd...>}"
shift
[[ $# -gt 0 ]] || { echo "usage: run_job.sh gpu|cpu <cmd...>" >&2; exit 2; }

common=(--account=publicgrp --partition=high --job-name=tf
        --output="$HOME/TensorForge/logs/slurm-%j.out" --export=ALL,TF_IN_JOB=1)
case "$mode" in
  gpu) res=(--gpus=6000_blackwell:1 --cpus-per-task=4 --mem=16G --time=00:30:00) ;;
  cpu) res=(--cpus-per-task=8 --mem=32G --time=01:00:00) ;;
  *) echo "mode must be gpu or cpu" >&2; exit 2 ;;
esac

mkdir -p "$HOME/TensorForge/logs"
# shellcheck disable=SC2086
sbatch "${common[@]}" "${res[@]}" ${TF_SBATCH_OPTS:-} "$0" "$@"
