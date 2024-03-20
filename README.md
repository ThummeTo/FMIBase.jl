![FMI.jl Logo](https://github.com/ThummeTo/FMI.jl/blob/main/logo/dark/fmijl_logo_640_320.png?raw=true "FMI.jl Logo")
# FMIBase.jl

## What is FMIBase.jl?
[*FMIBase.jl*](https://github.com/ThummeTo/FMIBase.jl) provides the foundation for the Julia packages [*FMIImport.jl*](https://github.com/ThummeTo/FMIImport.jl) and [*FMIExport.jl*](https://github.com/ThummeTo/FMIExport.jl).

[![Dev Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://ThummeTo.github.io/FMI.jl/dev)
[![Run Tests](https://github.com/ThummeTo/FMIBase.jl/actions/workflows/Test.yml/badge.svg)](https://github.com/ThummeTo/FMIBase.jl/actions/workflows/Test.yml)
[![Run PkgEval](https://github.com/ThummeTo/FMIBase.jl/actions/workflows/Eval.yml/badge.svg)](https://github.com/ThummeTo/FMIBase.jl/actions/workflows/Eval.yml)
[![Coverage](https://codecov.io/gh/ThummeTo/FMIBase.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ThummeTo/FMIBase.jl)

## How can I use FMIBase.jl?
**Please note:** [*FMIBase.jl*](https://github.com/ThummeTo/FMIBase.jl) is not meant to be used as it is, but as part of [*FMI.jl*](https://github.com/ThummeTo/FMI.jl), [*FMIImport.jl*](https://github.com/ThummeTo/FMIImport.jl), [*FMIExport.jl*](https://github.com/ThummeTo/FMIExport.jl) and [*FMIFlux.jl*](https://github.com/ThummeTo/FMIFlux.jl). However you can install [*FMIBase.jl*](https://github.com/ThummeTo/FMIBase.jl) by following these steps.

1\. Open a Julia-REPL, switch to package mode using `]`, activate your preferred environment.

2\. Install [*FMIBase.jl*](https://github.com/ThummeTo/FMIBase.jl):
```julia-repl
(@v1) pkg> add FMIBase
```

3\. If you want to check that everything works correctly, you can run the tests bundled with [*FMIBase.jl*](https://github.com/ThummeTo/FMIBase.jl):
```julia-repl
(@v1) pkg> test FMIBase
```

## What FMI.jl-Library should I use?
![FMI.jl Family](https://github.com/ThummeTo/FMI.jl/blob/main/docs/src/assets/FMI_JL_family.png?raw=true "FMI.jl Family")
To keep dependencies nice and clean, the original package [*FMI.jl*](https://github.com/ThummeTo/FMI.jl) had been split into new packages:
- [*FMI.jl*](https://github.com/ThummeTo/FMI.jl): High level loading, manipulating, saving or building entire FMUs from scratch
- [*FMIImport.jl*](https://github.com/ThummeTo/FMIImport.jl): Importing FMUs into Julia
- [*FMIExport.jl*](https://github.com/ThummeTo/FMIExport.jl): Exporting stand-alone FMUs from Julia Code
- [*FMIBase.jl*](https://github.com/ThummeTo/FMIBase.jl): Common concepts for import and export of FMUs
- [*FMICore.jl*](https://github.com/ThummeTo/FMICore.jl): C-code wrapper for the FMI-standard
- [*FMISensitivity.jl*](https://github.com/ThummeTo/FMISensitivity.jl): Static and dynamic sensitivities over FMUs
- [*FMIBuild.jl*](https://github.com/ThummeTo/FMIBuild.jl): Compiler/Compilation dependencies for FMIExport.jl
- [*FMIFlux.jl*](https://github.com/ThummeTo/FMIFlux.jl): Machine Learning with FMUs
- [*FMIZoo.jl*](https://github.com/ThummeTo/FMIZoo.jl): A collection of testing and example FMUs

## What Platforms are supported?
[*FMIBase.jl*](https://github.com/ThummeTo/FMIBase.jl) is tested (and testing) under Julia Versions *v1.6 LTS* and *v1 latest* on Windows *latest* (`x64` and `x86`) and Ubuntu *latest* (`x64`). MacOS is not CI-tested but should work with Mac-FMUs.

## How to cite?
Tobias Thummerer, Lars Mikelsons and Josef Kircher. 2021. **NeuralFMU: towards structural integration of FMUs into neural networks.** Martin Sjölund, Lena Buffoni, Adrian Pop and Lennart Ochel (Ed.). Proceedings of 14th Modelica Conference 2021, Linköping, Sweden, September 20-24, 2021. Linköping University Electronic Press, Linköping (Linköping Electronic Conference Proceedings ; 181), 297-306. [DOI: 10.3384/ecp21181297](https://doi.org/10.3384/ecp21181297)

## Related publications?
Tobias Thummerer, Johannes Stoljar and Lars Mikelsons. 2022. **NeuralFMU: presenting a workflow for integrating hybrid NeuralODEs into real-world applications.** Electronics 11, 19, 3202. [DOI: 10.3390/electronics11193202](https://doi.org/10.3390/electronics11193202)

Tobias Thummerer, Johannes Tintenherr, Lars Mikelsons. 2021. **Hybrid modeling of the human cardiovascular system using NeuralFMUs** Journal of Physics: Conference Series 2090, 1, 012155. [DOI: 10.1088/1742-6596/2090/1/012155](https://doi.org/10.1088/1742-6596/2090/1/012155)