# Contributing

Open an issue with a reproducible example before changing behavior. Keep SI units explicit, document assumptions, and add a regression test for meaningful logic changes. Run the MATLAB unit suite and the project benchmark/acceptance entry point. Never claim a simulation or laboratory result as field validation. Do not commit raw third-party datasets, credentials, personal account data, build caches or generated machine-specific files.

The text source is the reviewable source of truth. For Simulink changes, regenerate the model using `build_model` and include updated acceptance evidence. Contributions are accepted under the repository MIT license. GitHub Actions configuration is supplied but is not described as passing until a hosted run has actually completed.
