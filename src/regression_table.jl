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

Holds regression coefficients and std errors.
The order is indeterminate, but will usually be sorted by name.
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


## -------------  RegressorInfo

# """
# 	$(SIGNATURES)

# Returns `RegressorInfo` with mean regression coefficient and std error.
# """
# function mean(rV :: Vector{RegressorInfo})
#     n = length(rV);
#     @assert n > 0
#     coeffSum = 0.0;
#     seSum = 0.0;
#     for r in rV
#         coeffSum += r.coeff;
#         seSum += r.se;
#     end
#     rOut = RegressorInfo(rV[1].name, coeffSum ./ n, seSum ./ n);
#     return rOut;
# end


"""
	$(SIGNATURES)

Applies `reduceFct` to vector of regression coefficients and std errors.

Returns a `RegressorInfo`.
"""
function reduce_regr_infos(rV :: Vector{RegressorInfo}, reduceFct :: Function)
    n = length(rV);
    @assert n > 1
    coeff = reduceFct([r.coeff  for r in rV]);
    se = reduceFct([r.se  for r in rV]);
    rOut = RegressorInfo(rV[1].name, coeff, se);
    return rOut;
end


"""
	$(SIGNATURES)

Are two regressors approximately equal?
"""
function isapprox(r1 :: RegressorInfo, r2 :: RegressorInfo;
    rtol :: Float64 = 1e-5, atol :: Float64 = 1e-6)

    return Base.isapprox(r1.coeff, r2.coeff, rtol = rtol, atol = atol) &&
        Base.isapprox(r1.se, r2.se, rtol = rtol, atol = atol)
end


## -----------  RegressionTable

"""
	RegressionTable()

Initialize empty table
"""
function RegressionTable()
    return RegressionTable(Dict{Symbol, RegressorInfo}());
end


"""
	RegressionTable(nameV, coeffV, seV)

Initialize using vectors of names, coefficients, and std errors.
"""
function RegressionTable(nameV :: Vector{Symbol}, coeffV :: Vector{Float64}, seV :: Vector{Float64})
    rt = RegressionTable();
    for i1 = 1 : length(nameV)
        add_regressor(rt, nameV[i1], coeffV[i1], seV[i1]);
    end
    return rt
end


"""
	$(SIGNATURES)

Construct RegressionTable from `LinearModel`.

Renames the intercept into :constant.

Renames categorical regressors from "school: 3" to :school3
"""
function RegressionTable(lm :: StatsModels.TableRegressionModel; 
    interceptName :: Symbol = :constant)

    # Names are strings in GLM
    nameV = coefnames(lm);
    nameV[findfirst(nameV .== "(Intercept)")] = String(interceptName);
    # Normalize categorical variable names
    for i1 = 1 : length(nameV)
        nameV[i1] = replace(nameV[i1], ": " => "");
    end
    return RegressionTable(Symbol.(nameV), coef(lm), stderror(lm))
end


## ----------  Modification

"""
	$(SIGNATURES)

Add a regressor that does not already exist.
"""
function add_regressor(rt :: RegressionTable, name :: Symbol, coeff :: Float64, se :: Float64)
    @assert !has_regressor(rt, name)  "Regressor $name exists"
    rt.d[name] = RegressorInfo(name, coeff, se);
    return nothing
end

function add_regressor(rt :: RegressionTable, ri :: RegressorInfo)
    @assert !has_regressor(rt, ri.name)  "Regressor $(ri.name) exists"
    rt.d[ri.name] = ri;
    return nothing
end


"""
	$(SIGNATURES)

Drop regressors by name.
"""
function drop_regressor!(rt :: RegressionTable, name :: Symbol)
    delete!(rt.d, name)
end

function drop_regressors!(rt :: RegressionTable, nameV :: Vector{Symbol})
    for name in nameV
        drop_regressor!(rt, name)
    end
end


"""
	$(SIGNATURES)

Change regressor.
"""
function change_regressor!(rt :: RegressionTable, ri :: RegressorInfo)
    drop_regressor!(rt, ri.name);
    add_regressor(rt, ri);
    return nothing
end


"""
	$(SIGNATURES)

Rename a regressor.
"""
function rename_regressor(rt :: RegressionTable, oldName :: Symbol, newName :: Symbol)
    @assert has_regressor(rt, oldName)

    ri = get_regressor(rt, oldName);
    ri.name = newName;
    drop_regressor!(rt, oldName);
    add_regressor(rt, ri);
    return nothing
end


"""
	$(SIGNATURES)

Set missing regressors to 0. Useful for cases where dummies have no values.

test this +++++
"""
function set_missing_regressors!(rt :: RegressionTable, nameV :: Vector{Symbol})
    for name in nameV
        if !has_regressor(rt, name)
            add_regressor(rt, name, 0.0, 1.0);
        end
    end
    return nothing
end



## -----------  Retrieval 

function n_regressors(rt :: RegressionTable)
    return length(rt.d)
end

function has_regressor(rt :: RegressionTable, name :: Symbol)
    return haskey(rt.d, name)
end

"""
	get_regressor(rt, name)

Retrieve a [`RegressorInfo`](@ref) object.
"""
function get_regressor(rt :: RegressionTable, name :: Symbol)
    @assert has_regressor(rt, name)  "Regressor $name not found"
    return rt.d[name]
end

function get_regressor(rt :: RegressionTable, name :: String)
    return rt.d[Symbol(name)]
end


"""
	get_coefficient(rt, name)

Return coefficient
Coefficient name may be Symbol or String
"""
function get_coefficient(rt :: RegressionTable, name)
    ri = get_regressor(rt, name);
    return ri.coeff
end

function get_std_error(rt :: RegressionTable, name)
    ri = get_regressor(rt, name);
    return ri.se
end

"""
	get_coeff_se(rt, name)

Return coefficient and std error as tuple.
"""
function get_coeff_se(rt :: RegressionTable, name)
    ri = get_regressor(rt, name);
    return ri.coeff, ri.se
end


"""
	get_coeff_se_multiple(rt, names)

Return multiple coefficients and std errors.
"""
function get_coeff_se_multiple(rt :: RegressionTable,  names :: Vector)
    n = length(names);
    coeffV = Vector{Float64}(undef, n);
    seV = Vector{Float64}(undef, n);
    for i1 = 1 : n
        coeffV[i1], seV[i1] = get_coeff_se(rt, names[i1]);
    end
    return coeffV, seV
end


"""
	get_all_coeff_se(rt)

Return all coefficients and std errors.
"""
function get_all_coeff_se(rt :: RegressionTable)
    nameV = get_names(rt);
    coeffV, seV = get_coeff_se_multiple(rt, nameV);
    return nameV, coeffV, seV
end


"""
	$(SIGNATURES)

Get regressor names.
"""
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
        nameV, coeffV, seV = get_all_coeff_se(rt);
        nameV = string.(nameV);
        dataM = hcat(nameV, coeffV, seV)
    end
    return dataM :: Matrix
end


## ----------  Comparison

"""
	$(SIGNATURES)

Checks whether all regression coefficients and std errors are approximately the same.
"""
function isapprox(rt1 :: RegressionTable, rt2 :: RegressionTable;
    atol :: Float64 = 1e-6,  rtol :: Float64 = 1e-6)

    @assert(have_same_regressors([rt1, rt2]))
    areEqual = true;
    nameV = get_names(rt1);
    for name in nameV
        if !Base.isapprox(get_coefficient(rt1, name), get_coefficient(rt2, name),
                atol = atol, rtol = rtol)
            areEqual = false;
            break;
        end
        if !Base.isapprox(get_std_error(rt1, name), get_std_error(rt2, name),
                atol = atol, rtol = rtol)
            areEqual = false;
            break;
        end
    end
    return areEqual
end


## --------------  Display

"""
	Base.show(rt)

Pretty print a regression table to `stdio`
"""
function Base.show(rt :: RegressionTable)
    if n_regressors(rt) < 1
        println("Empty RegressionTable")
    else
        dataM = make_table(rt);
        pretty_table(dataM, ["Regressor", "Coefficient", "StdError"]);
    end
    return nothing
end


## ------------  Vectors of RegressionTables

"""
	$(SIGNATURES)

Check whether all regressions have the same regressors.
"""
function have_same_regressors(rtV :: Vector{RegressionTable})
    areSame = true;
    nameV = sort(get_names(rtV[1]));
    for rt in rtV
        if !isequal(nameV, sort(get_names(rt)))
            areSame = false;
            break;
        end
    end
    return areSame
end


"""
	$(SIGNATURES)

Apply a function to all regressors and std errors in a vector of RegressionTables.

All must have the same coefficients.

Use case: Compute the means of all coefficients and std errors across several regressions.

`reduceFct` takes a vector of scalars and returns a scalar. Example: `mean`.
"""
function reduce_regr_tables(rtV :: Vector{RegressionTable}, reduceFct :: Function)
    @assert have_same_regressors(rtV)
    nameV = get_names(rtV[1]);
    rtOut = RegressionTable();

    n = length(rtV);
    for name in nameV
        ri = reduce_regr_infos([get_regressor(rtV[j], name)  for j = 1 : n], reduceFct);
        add_regressor(rtOut, ri);
    end

    return rtOut
end


"""
	$(SIGNATURES)

Defines the `mean` for a `Vector{RegressionTable}` as a convenience method.
"""
function mean(rtV :: Vector{RegressionTable})
    return reduce_regr_tables(rtV, StatsBase.mean);
end

"""
	$(SIGNATURES)

Defines the `std` for a `Vector{RegressionTable}`
"""
function std(rtV :: Vector{RegressionTable})
    return reduce_regr_tables(rtV, StatsBase.std);
end


# ------------