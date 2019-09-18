"""
    RegressorInfo

Holds info about one regressor
"""
mutable struct RegressorInfo
    name :: Symbol
    coeff :: Float64
    se :: Float64
end



"""
    RegressionTable

Holds regression coefficients and std errors
"""
struct RegressionTable
    d :: Dict{Symbol, RegressorInfo}
    # df :: DataFrame
    # function RegressionTable(dfIn :: DataFrame)
    #     (nRows, nCols) = size(dfIn);
    #     @assert nRows == 2
    #     if dfIn.stat != ["coeff", "se"]
    #         error("stat column has wrong values: $(dfIn.stat)")
    #     end
    #     return new(dfIn)
    # end
end


## -----------  Constructors

function RegressionTable()
    return RegressionTable(Dict{Symbol, RegressorInfo}());
end


function RegressionTable(nameV :: Vector{Symbol}, coeffV :: Vector{Float64}, seV :: Vector{Float64})
    rt = RegressionTable();
    for i1 = 1 : length(nameV)
        add_regressor(rt, nameV[i1], coeffV[i1], seV[i1]);
    end
    return rt
end


## ----------  Modification

function add_regressor(rt :: RegressionTable, name :: Symbol, coeff :: Float64, se :: Float64)
    @assert !has_regressor(rt, name)  "Regressor $name exists"
    rt.d[name] = RegressorInfo(name, coeff, se);
    return nothing
end


## -----------  Retrieval 

function n_regressors(rt :: RegressionTable)
    return length(rt.d)
end

function has_regressor(rt :: RegressionTable, name :: Symbol)
    return haskey(rt.d, name)
end

function get_regressor(rt :: RegressionTable, name :: Symbol)
    @assert has_regressor(rt, name)  "Regressor $name not found"
    return rt.d[name]
end

function get_regressor(rt :: RegressionTable, name :: String)
    return rt.d[Symbol(name)]
end


# Return coefficient
# Coefficient name may be Symbol or String
function get_coefficient(rt :: RegressionTable, name)
    ri = get_regressor(rt, name);
    return ri.coeff
end

function get_std_error(rt :: RegressionTable, name)
    ri = get_regressor(rt, name);
    return ri.se
end

function get_coeff_se(rt :: RegressionTable, name)
    ri = get_regressor(rt, name);
    return ri.coeff, ri.se
end

function get_coeff_se_multiple(rt :: RegressionTable,  names :: Vector)
    n = length(names);
    coeffV = Vector{Float64}(undef, n);
    seV = Vector{Float64}(undef, n);
    for i1 = 1 : n
        coeffV[i1], seV[i1] = get_coeff_se(rt, names[i1]);
    end
    return coeffV, seV
end

function get_all_coeff_se(rt :: RegressionTable)
    return get_coeff_se_multiple(rt, get_names(rt))
end

function get_names(rt :: RegressionTable)
    return Symbol.(keys(rt.d))
end

function get_name_strings(rt :: RegressionTable)
    return string.(keys(rt.d));
end

function make_table(rt)
    if n_regressors(rt) < 1
        dataM = Matrix{Any}();
    else
        coeffV, seV = get_all_coeff_se(rt);
        nameV = get_name_strings(rt);
        dataM = hcat(nameV, coeffV, seV)
    end
    return dataM :: Matrix
end


## --------------  Display

function Base.show(rt :: RegressionTable)
    if n_regressors(rt) < 1
        println("Empty RegressionTable")
    else
        dataM = make_table(rt);
        pretty_table(dataM, ["Regressor", "Coefficient", "StdError"]);
    end
    return nothing
end

# ------------