module EconometricsLH

using DataFrames, PrettyTables
import Base.show

export RegressorInfo, RegressionTable
export get_coefficient, get_std_error, get_coeff_se, get_coeff_se_multiple, get_all_coeff_se
export get_regressor
export get_names, get_name_strings, have_same_regressors
export n_regressors

include("regression_table.jl")

end # module
