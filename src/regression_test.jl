"""
    $(SIGNATURES)

Test by regression that simulated data are consistent with "true" outcomes.

Regress simulated on true.
Check for 0 intercept, 1 slope.

Note: If data are very far from 0, then intercept can be quite a bit off.

# Arguments
- trueM
    true outcome by state
- simM
    simulated outcome by state
- wtM
    weights (e.g. to downweight rare states or states that cannot be solved precisely)
    scalar weights are expanded. Provide wtM = []

# Outputs
- pValueV
    p-values for testing hypothesis that intercept is 0 and slope is 1
    Low p value implies high confidence that coefficients of [0, 1] can be rejected.
- betaV
    regression coefficients; should be [0;1]
- seV
    std errors
"""
function regression_test(trueM :: AbstractArray{F1}, simM :: AbstractArray{F1};
    weights = similar(trueM, 0), silent = true) where F1 <: AbstractFloat

    @assert size(trueM) == size(simM)
    n = length(trueM);
    @assert n > 2  "Too few observations: $n"

    m = fit(LinearModel, 
        @formula(xSim ~ xTrue), 
        DataFrame(xSim = vec(simM), xTrue = vec(trueM)),  
        wts = weights);

    pValueV = regr_pvalues(m, n, [zero(F1), one(F1)]);

    # For intercept: use prediction at mean instead
    betaV = coef(m);
    seV = stderror(m);
    # dev = maximum(abs.(betaV .- [zero(F1), one(F1)]) ./ max.(F1(0.01), seV));

    if !silent
        @info "Regression test result: \n  $m \n  $pValueV";
    end

    return pValueV, betaV, seV
end

"""
	$(SIGNATURES)

Std error of predicted values.
There is no direct method for this. Therefore, construct the 95pct confidence interval and use the fact that its width is `1.96 * se`.
"""
function prediction_se(m, df)
    dfPred = predict(m, df; interval = :confidence, level = 0.95);
    predSe = (dfPred.upper .- dfPred.prediction) ./ 1.96;
    return predSe
end

# ---------------
