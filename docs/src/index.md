# EconometricsLH

```@meta
CurrentModule = EconometricsLH
```

## RegressionTables

A container for storing regression results (currently coefficients and their standard errors).

The intended use cases are:

1. One receives regression results generated outside of Julia and needs to store them, for example as target moments in an indirect inference problem.
2. One would like to store the results from regressions run with `GLM.jl` without storing the associated data, fitted values, etc.

## Function Reference

```@autodocs
Modules = [EconometricsLH]
```

---------