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
- doShow
    show scatter plot?

# Outputs
dev = max(abs(beta - [0;1]) / se(beta))
    how many std deviations are regression coefficient from 45 degree line?
betaV
    regression coefficients; should be [0;1]
seV
    std errors

Change:
    test hypothesis of 0 intercept and unit slope. Return prob of reject
    GLM cannot do that yet.
"""
function regression_test(trueM :: AbstractArray{F1}, simM :: AbstractArray{F1};
    weights = similar(trueM, 0)) where F1 <: AbstractFloat

    @assert size(trueM) == size(simM)
    n = length(trueM);
    @assert n > 2  "Too few observations: $n"

    m = fit(LinearModel, hcat(ones(F1, n),  vec(trueM)),  vec(simM);
        wts = weights);
    betaV = coef(m);
    seV = stderror(m);
    dev = maximum(abs.(betaV .- [zero(F1), one(F1)]) ./ max.(F1(0.01), seV));
    return dev, betaV, seV
end

# ---------------
