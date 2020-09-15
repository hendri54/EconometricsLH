# EconometricsLH

```@meta
CurrentModule = EconometricsLH
```

This package contains general purpose code related to regressions and their display.

## RegressorInfo

The [`RegressorInfo`](@ref) struct holds information about one regressor.

Access functions are: [`regr_name`](@ref), [`regr_coeff`](@ref), and [`regr_se`](@ref).

[`scale_regressor`](@ref) can be used to rescale a regressor. It just multiplies coefficient and standard error by a scalar. 

[`reduce_regr_infos`](@ref) applies a function, such as `mean` to all coefficients and standard errors in a vector of regression coefficients. This can be used to average regressions.

```@docs
RegressorInfo
regr_name
regr_coeff
regr_se
scale_regressor
reduce_regr_infos
```


## RegressionTable

A container for storing regression results (currently coefficients and their standard errors).

The intended use cases are:

1. One receives regression results generated outside of Julia and needs to store them, for example as target moments in an indirect inference problem.
2. One would like to store the results from regressions run with `GLM.jl` without storing the associated data, fitted values, etc.

Regression tables are modified with [`add_regressor`](@ref), [`drop_regressor!`](@ref), [`change_regressor!`](@ref), and [`rename_regressor`](@ref).

Regressors can be retrieved by name using [`get_regressor`](@ref), where [`has_regressor`](@ref) checks whether a regressor exists. One can also directly retrieve regression coefficients using [`get_coefficient`](@ref) or standard errors with [`get_std_error`](@ref). 

A named collection of coefficients and standard errors is retrieved using [`get_coeff_se_multiple`](@ref)


```@docs
RegressionTable
```

### Retrieval

```@docs
get_regressor
has_regressor
get_coefficient
get_std_error
get_coeff_se
get_coeff_se_multiple
get_all_coeff_se
```

### Modification

```@docs
add_regressor
drop_regressor!
rename_regressor
change_regressor!
```

## Regression tests

The purpose is to test whether simulated values match theoretical expected values.

Example: Solve and simulate a model. Check the theoretical value function by comparing it with simulated values.

This is done by regressing simulated values on expected values. This is basically a regression with measurement error in the dependent variable. It should produce a 45 degree line as the OLS regression line. [`regression_test`](@ref) tests that.

```@docs
regression_test
```

---------