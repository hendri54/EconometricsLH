using EconometricsLH
using Test

@testset "RegressionTable" begin
    rt = RegressionTable();
    @test n_regressors(rt) == 0

    nameV = [:a, :b, :c];
    coeffV = [1.0, 2.0, 3.0];
    seV = [1.1, 2.2, 3.3];
    rt = RegressionTable(nameV, coeffV, seV);
    @test get_coefficient(rt, nameV[2]) ≈ coeffV[2]
    @test get_std_error(rt, nameV[3]) ≈ seV[3]
    @test all(get_coeff_se(rt, nameV[1]) .≈ (coeffV[1], seV[1]))

    coeff2V, se2V = get_coeff_se_multiple(rt, nameV[1:2]);
    @test all(coeff2V .≈ coeffV[1:2])
    @test all(se2V .≈ seV[1:2])

    coeff3V, se3V = get_all_coeff_se(rt);
    @test all(coeff3V .≈ coeffV)
    @test all(se3V .≈ seV)

    @test get_names(rt) == nameV

    Base.show(rt)
end

# ------------------