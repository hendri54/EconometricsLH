using EconometricsLH
using Test

@testset "EconometricsLH" begin
    @testset "RegressorInfo" begin
        name = :r1;
        coeffV = [1.0, 2.0, 3.0];
        seV = [0.1, 0.2, 0.3];
        rV = [RegressorInfo(name, coeffV[j], seV[j])  for j = 1 : length(seV)];

        rSum = reduce_regr_infos(rV, sum);
        @test rSum.coeff ≈ sum(coeffV)
        @test rSum.se ≈ sum(seV)
    end

    @testset "RegressionTable" begin
        rt = RegressionTable();
        @test n_regressors(rt) == 0

        nameV = [:c, :b, :a];
        coeffV = [1.0, 2.0, 3.0];
        seV = [1.1, 2.2, 3.3];
        rt = RegressionTable(nameV, coeffV, seV);
        @test get_coefficient(rt, nameV[2]) ≈ coeffV[2]
        @test get_std_error(rt, nameV[3]) ≈ seV[3]
        @test all(get_coeff_se(rt, nameV[1]) .≈ (coeffV[1], seV[1]))

        coeff2V, se2V = get_coeff_se_multiple(rt, nameV[1:2]);
        @test all(coeff2V .≈ coeffV[1:2])
        @test all(se2V .≈ seV[1:2])

        # The order is indeterminate
        name3V, coeff3V, se3V = get_all_coeff_se(rt);
        @test all(sort(coeff3V) .≈ sort(coeffV))
        @test all(sort(se3V) .≈ sort(seV))

        @test sort(get_names(rt)) == sort(nameV)

        Base.show(rt)

        rt2 = RegressionTable([:b, :c, :a], [2.0, 3.0, 4.0], [0.1, 0.2, 0.3]);
        @test have_same_regressors([rt, rt2])

        rt3 = RegressionTable([:a, :b, :c, :d], [2.0, 3.0, 4.0, 5.0], [0.1, 0.2, 0.3, 0.4]);
        @test !have_same_regressors([rt, rt2, rt3])

        # Reduce
        rtOut = reduce_regr_tables([rt, rt2], sum);
        for name in [:a, :b, :c]
            coeffOut, seOut = get_coeff_se(rtOut, name);
            @test coeffOut ≈ get_coefficient(rt, name) + get_coefficient(rt2, name)
            @test seOut ≈ get_std_error(rt, name) + get_std_error(rt2, name)
        end
    end
end


# ------------------
