# Superseded CPU results

These files were measured with the first version of `tforge-cpu-bench`, which held the output in a `std::vector<float>` (16-byte aligned) while kernel temporaries were 64-byte aligned. Stage 5 showed that 512^3 timings depended on where the output buffer sat relative to the inputs (`results/cpu/align_experiment_24093215.log`: the same kernel took 446 ms at a 64-byte-aligned output and 377 ms at a 16-byte offset). The harness now allocates every buffer 64-byte aligned, and Stages 4 and 5 were re-measured; the current results are `results/cpu/stage4.csv` and `results/cpu/stage5.csv`.

These files are kept for provenance only and are not cited in the stage reports.

| File | Commit | Job |
|---|---|---|
| `stage4_vector_output.csv` | e03810d | 24093215 |
| `stage5_vector_output.csv` | a9205ce | 24093215 |
