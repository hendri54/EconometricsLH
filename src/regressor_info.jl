"""
    RegressorInfo

Holds information about one regressor: name, coefficient, std error.
"""
mutable struct RegressorInfo
    name :: Symbol
    coeff :: Float64
    se :: Float64
end

Base.show(io :: IO, ri :: RegressorInfo) = 
    print(io, "Regressor $(regr_name(ri)): ",  round(regr_coeff(ri), digits = 2),
        " (", round(regr_se(ri), digits = 2), ")")

"""
	$(SIGNATURES)

Validate regressor. Throws error if not valid.
"""
function validate_regressor(ri :: RegressorInfo)
    @argcheck ri.se >= 0.0
end

"""
	$(SIGNATURES)

Name of a regressor.
"""
regr_name(ri :: RegressorInfo) = ri.name;

"""
	$(SIGNATURES)

Returns the regression coefficient.
"""
regr_coeff(ri :: RegressorInfo) = ri.coeff;

"""
	$(SIGNATURES)

Returns the standard error.
"""
regr_se(ri :: RegressorInfo) = ri.se;


function Base.isapprox(r1 :: RegressorInfo, r2 :: RegressorInfo;
    rtol :: Float64 = 1e-5, atol :: Float64 = 1e-6)

    return Base.isapprox(r1.coeff, r2.coeff, rtol = rtol, atol = atol) &&
        Base.isapprox(r1.se, r2.se, rtol = rtol, atol = atol)
end


## ---------------  Modify

"""
    $(SIGNATURES)

Scale coefficient and std error (e.g. to change units).
"""
function scale_regressor(ri :: RegressorInfo, scaleFactor :: AbstractFloat)
    ri.coeff *= scaleFactor;
    ri.se *= scaleFactor;
end


"""
	$(SIGNATURES)

Applies `reduceFct` to vector of regression coefficients and std errors.

Returns a `RegressorInfo`. Do not validate this. The user may call a function that does not return a valid `RegressorInfo` but is still useful.

# Example
```
reduce_regr_infos([r1, r2, r3], sum)
```
"""
function reduce_regr_infos(rV :: Vector{RegressorInfo}, reduceFct :: Function)
    n = length(rV);
    @assert n > 1
    coeff = reduceFct([r.coeff  for r in rV]);
    se = reduceFct([r.se  for r in rV]);
    rOut = RegressorInfo(rV[1].name, coeff, se);
    return rOut;
end


# ------------------