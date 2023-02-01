using EconometricsLH
using Random, Test

function regression_test_test()
    @testset "Regression test" begin
        rng = MersenneTwister(44);
        n = Int(1e4);
        trueM = randn(rng, n);
        simM  = trueM .+ 0.3 .* randn(rng, n);
        wtM = 1.0 .+ rand(rng, n);
        
        for useWeights in [false, true]
            if useWeights
                pValueV, betaV, seV = regression_test(trueM, simM; weights = wtM);
            else
                pValueV, betaV, seV = regression_test(trueM, simM);
            end

            @test size(betaV) == (2,)
            @test size(seV) == (2,)
            @test all(seV .> 0.0)
            @test abs(betaV[1]) < 2.2 * seV[1]
            @test abs(betaV[2] - 1.0) < 2.2 * seV[2]    
            @test all(pValueV .> 0.35);
        end
    end
end

@testset "Regression test" begin
    regression_test_test();
end

# ---------------