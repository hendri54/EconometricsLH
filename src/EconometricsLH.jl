module EconometricsLH

using ArgCheck, DataFrames, DocStringExtensions, GLM, PrettyTables, StatsBase, StatsModels
import Base.isapprox, Base.show
import StatsBase.mean, StatsBase.std

export RegressorInfo, RegressionTable

# RegressorInfo
export validate_regressor, reduce_regr_infos, regr_name, regr_coeff, regr_se, scale_regressor

# RegressionTable
export add_regressor, get_regressor, has_regressor
export change_regressor!, drop_regressor!, drop_regressors!
export get_coefficient, get_std_error, get_coeff_se, get_coeff_se_multiple, get_all_coeff_se
export get_names, get_name_strings, assert_same_regressors, have_same_regressors
export n_regressors, reduce_regr_tables, rename_regressor, set_missing_regressors!

export regression_test

include("regressor_info.jl")
include("regression_table.jl")
include("regression_test.jl")

end # module
