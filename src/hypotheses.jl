"""
	$(SIGNATURES)

P-values for all regression coefficients with sample size `n` and H0 coefficients `beta0V`.
"""
function regr_pvalues(regrS, n :: Integer, beta0V :: AbstractVector{F1}) where 
        F1 <: Number
    betaV = coef(regrS);
    seV = stderror(regrS);
    pValueV = similar(betaV);
    for j in eachindex(betaV)
        pValueV[j] = regr_coeff_pvalue(betaV[j], seV[j], n, beta0V[j]);
    end
    return pValueV
end

"""
	$(SIGNATURES)

P-value for testing the hypothesis that the regression coefficient `beta` with std error `seBeta` equals `beta0`. With `n` observations
"""
function regr_coeff_pvalue(beta :: F1, seBeta :: F1, n :: Integer, 
        beta0 :: F1) where F1 <: Number
    tTest = OneSampleTTest(beta, seBeta * sqrt(n), n, beta0);
    return HypothesisTests.pvalue(tTest);
end


# ------------------