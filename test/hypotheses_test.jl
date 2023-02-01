using DataFrames, GLM, Random, Test, EconometricsLH;


function pvalues_test()
    @testset "P values" begin
        rng = MersenneTwister(43);
        n = 80;
        yV = randn(rng, n);
        df = DataFrame(y = yV, x = yV + randn(rng, n));
        regrS = fit(LinearModel, @formula(y ~ x), df);
        pValueV = regr_pvalues(regrS, n, [0.0, 1.0]);
        @test size(pValueV) == (2, );
        @test first(pValueV) > 0.1; # cannot reject beta1 = 0
        @test last(pValueV) < 0.01; # reject beta2 = 1

        pValueV = regr_pvalues(regrS, n, [0.0, 0.5]);
        @test all(pValueV .> 0.1);
    end
end

@testset "Hypotheses" begin
    pvalues_test();
end

# --------------------