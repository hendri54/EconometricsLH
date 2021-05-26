"""
    RegressionTable

Holds regression coefficients and std errors.
The order is determined at construction.
"""
struct RegressionTable
    d :: Vector{RegressorInfo}
end


## -----------  RegressionTable

"""
	RegressionTable()

Initialize empty table
"""
function RegressionTable()
    return RegressionTable(Vector{RegressorInfo}());
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

# Arguments
- `lm`: Output from `fit()`
- `interceptName`: new name of intercept
- `replaceNan`: replace NaN values of coefficients and std errors? This can be useful to deal with regressions that were, say, rank deficient. Coefficients are set to 0.0 and std errors are set to 1.0.
"""
function RegressionTable(lm :: StatsModels.TableRegressionModel; 
    interceptName :: Symbol = :constant,
    replaceNan :: Bool = false)

    # Names are strings in GLM
    nameV = coefnames(lm);
    nameV[findfirst(nameV .== "(Intercept)")] = String(interceptName);
    # Normalize categorical variable names
    for i1 = 1 : length(nameV)
        nameV[i1] = replace(nameV[i1], ": " => "");
    end

    coeffV = coef(lm);
    seV = stderror(lm);
    if replaceNan
        coeffV[isnan.(coeffV)] .= 0.0;
        seV[isnan.(seV)] .= 1.0;
    end
    return RegressionTable(Symbol.(nameV), coeffV, seV)
end


## ----------  Modification

"""
	$(SIGNATURES)

Add a regressor that does not already exist.
"""
function add_regressor(rt :: RegressionTable, name :: Symbol, coeff :: Float64, se :: Float64)
    @assert !has_regressor(rt, name)  "Regressor $name exists"
    ri = RegressorInfo(name, coeff, se);
    validate_regressor(ri);
    push!(rt.d, ri);
    return nothing
end

function add_regressor(rt :: RegressionTable, ri :: RegressorInfo)
    @assert !has_regressor(rt, ri.name)  "Regressor $(ri.name) exists"
    validate_regressor(ri);
    push!(rt.d, ri);
    return nothing
end


"""
	$(SIGNATURES)

Drop regressors by name. Option to ignore missing regressors instead of throwing an error.
"""
function drop_regressor!(rt :: RegressionTable, name :: Symbol;
    errorOnMissing :: Bool = true)
    idx = get_regressor_index(rt, name);
    if !isnothing(idx)
        deleteat!(rt.d, idx);
    elseif errorOnMissing
        error("Regressor $name does not exist");
    end
    return nothing
end

function drop_regressors!(rt :: RegressionTable, nameV :: Vector{Symbol};
    errorOnMissing :: Bool = true)
    for name in nameV
        drop_regressor!(rt, name; errorOnMissing = errorOnMissing);
    end
end


"""
	$(SIGNATURES)

Change regressor.
"""
function change_regressor!(rt :: RegressionTable, ri :: RegressorInfo)
    validate_regressor(ri);
    idx = get_regressor_index(rt, ri.name);
    @assert !isnothing(idx)  "Regressor $(ri.name) not found"
    rt.d[idx] = ri;
    return nothing
end


"""
	$(SIGNATURES)

Rename a regressor. Errors if `oldName` does not exist.
"""
function rename_regressor(rt :: RegressionTable, oldName :: Symbol, newName :: Symbol)
    @assert !has_regressor(rt, newName)

    idx = get_regressor_index(rt, oldName);
    @assert !isnothing(idx)
    rt.d[idx].name = newName;
    return nothing
end


"""
	$(SIGNATURES)

Set missing regressors to 0. Useful for cases where dummies have no values.

Does not ensure both regressions have the same variable ordering.
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

"""
	$(SIGNATURES)

Does a regressor name exist in a `RegressionTable`?
"""
function has_regressor(rt :: RegressionTable, name :: Symbol)
    return !isnothing(get_regressor_index(rt, name))
end

"""
	get_regressor(rt, name)

Retrieve a [`RegressorInfo`](@ref) object.
"""
function get_regressor(rt :: RegressionTable, name :: Symbol)
    idx = get_regressor_index(rt, name);
    @assert !isnothing(idx)  "Regressor $name not found"
    return rt.d[idx]
end

function get_regressor(rt :: RegressionTable, name :: String)
    return get_regressor(rt, Symbol(name))
end


"""
	$(SIGNATURES)

Get index of regressor by name. Returns `nothing` if not found.
"""
function get_regressor_index(rt :: RegressionTable, name :: Symbol)
    idx = findfirst(x -> x.name == name, rt.d);
    return idx
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

"""
	$(SIGNATURES)

Retrieve a standard error by name.
"""
function get_std_error(rt :: RegressionTable, name)
    ri = get_regressor(rt, name);
    return ri.se
end

"""
	get_coeff_se(rt, name)

Return coefficient and std error as tuple.  `name` can be Symbol or String.
"""
function get_coeff_se(rt :: RegressionTable, name)
    ri = get_regressor(rt, name);
    return ri.coeff, ri.se
end


"""
	get_coeff_se_multiple(rt, names)

Return multiple coefficients and std errors. `names` can be Symbol or String.
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
    nameV = [rt.d[idx].name  for idx in 1 : length(rt.d)];
    return nameV
end

function get_name_strings(rt :: RegressionTable)
    return string.(get_names(rt));
end


"""
	$(SIGNATURES)

Make table where columns are regressor names, coefficients, std errors.
"""
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

    assert_same_regressors([rt1, rt2]);
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

function Base.show(io :: IO, rt :: RegressionTable)
    if n_regressors(rt) < 1
        print(io, "Empty RegressionTable.")
    else
        dataM = make_table(rt);
        pretty_table(io, dataM; header = ["Regressor", "Coefficient", "StdError"]);
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

Assert that all regressions have the same regressors. Error if not.
"""
function assert_same_regressors(rtV :: Vector{RegressionTable})
    if !have_same_regressors(rtV)
        @warn "RegressionTables have different regressors"
        for rt in rtV
            println(get_names(rt));
        end
        error("Aborted.")
    end
    return nothing
end


"""
	$(SIGNATURES)

Apply a function to all regressors and std errors in a vector of RegressionTables.

All must have the same coefficients.

Use case: Compute the means of all coefficients and std errors across several regressions.

`reduceFct` takes a vector of scalars and returns a scalar. Example: `mean`.
"""
function reduce_regr_tables(rtV :: Vector{RegressionTable}, reduceFct :: Function)
    assert_same_regressors(rtV)
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