module EconometricsLH

using ArgCheck, DataFrames, DocStringExtensions, GLM, PrettyTables, StatsBase, StatsModels
import Base.isapprox, Base.show
import StatsBase.mean, StatsBase.std

export RegressorInfo, RegressionTable

# RegressorInfo
export reduce_regr_infos

# RegressionTable
export add_regressor, change_regressor!, drop_regressor!, drop_regressors!
export get_coefficient, get_std_error, get_coeff_se, get_coeff_se_multiple, get_all_coeff_se
export get_regressor, has_regressor
export get_names, get_name_strings, assert_same_regressors, have_same_regressors
export n_regressors, reduce_regr_tables, rename_regressor, set_missing_regressors!

include("regression_table.jl")

end # module
