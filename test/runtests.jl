using EconometricsLH, CategoricalArrays, DataFrames, GLM, StatsBase
using Test

function make_regr_table(startValue :: Float64,  nameV :: Vector{Symbol})
    n = length(nameV);
    coeffV = collect(range(startValue, startValue .+ 3.0, length = n));
    seV = collect(range(startValue .* 0.1, startValue .* 0.4, length = n));
    rt = RegressionTable(nameV, coeffV, seV);
    return rt
end

function make_regr_info(j)
    ri = RegressorInfo(Symbol("r$j"),  0.5 + j,  0.1 + j);
    validate_regressor(ri);
    return ri
end


function regressor_info_test()
    @testset "RegressorInfo" begin
        n = 3;
        rV = [make_regr_info(j)  for j = 1 : n];
        coeffV = [regr_coeff(rV[j])  for j = 1 : n];
        seV = [regr_se(rV[j])  for j = 1 : n];

        rSum = reduce_regr_infos(rV, sum);
        @test regr_coeff(rSum) ≈ sum(coeffV)
        @test regr_se(rSum) ≈ sum(seV)


        r1 = make_regr_info(1);
        r2 = make_regr_info(1);
        @test isapprox(r1, r2)
        scale_regressor(r2, 3.0);
        @test !isapprox(r1, r2)
        @test isapprox(regr_coeff(r1) * 3.0, regr_coeff(r2))
        println(r1);
    end
end


function regression_table_test()
    @testset "RegressionTable" begin
        rt = RegressionTable();
        @test n_regressors(rt) == 0

        nameV = [:c, :b, :a];
        rt = make_regr_table(1.0, nameV);
        coeff2 = get_coefficient(rt, nameV[2])
        se2 = get_std_error(rt, nameV[2])
        @test all(get_coeff_se(rt, nameV[2]) .≈ (coeff2, se2))

        coeff2V, se2V = get_coeff_se_multiple(rt, nameV[1:2]);
        @test coeff2V[2] ≈ coeff2
        @test se2V[2] ≈ se2

        # The order is indeterminate
        coeff2V, se2V = get_coeff_se_multiple(rt, nameV);
        name3V, coeff3V, se3V = get_all_coeff_se(rt);
        @test all(sort(coeff3V) .≈ sort(coeff2V))
        @test all(sort(se3V) .≈ sort(se2V))

        @test sort(get_names(rt)) == sort(nameV)

        # Rename
        rt3 = make_regr_table(3.0, [:a, :b, :c]);
        rt4 = make_regr_table(3.0, [:a, :b, :c]);
        rename_regressor(rt4, :a, :aNew);
        @test isapprox(get_regressor(rt3, :a), get_regressor(rt4, :aNew))

        # Set missing regressors
        rt5 = make_regr_table(3.0, [:a, :b, :c]);
        set_missing_regressors!(rt3, [:a, :c]);
        @test have_same_regressors([rt3, rt5])
        set_missing_regressors!(rt3, [:a, :d]);
        @test sort(get_names(rt3)) == [:a, :b, :c, :d]

        println(rt)

        # Drop regressor
        drop_regressor!(rt5, :a);
        @test !has_regressor(rt5, :a)
    end
end

function regr_table_mult_test()
    @testset "Multiple RegressionTables" begin
        rt1 = make_regr_table(2.0, [:a, :c, :b]);
        rt2 = make_regr_table(2.0, [:b, :c, :a]);
        @test have_same_regressors([rt1, rt2])
        @test !isapprox(rt1, rt2)

        rt3 = make_regr_table(2.1, [:a, :b, :c, :d]);
        @test !have_same_regressors([rt1, rt2, rt3])

        # Reduce
        rtOut = reduce_regr_tables([rt1, rt2], mean);
        for name in [:a, :b, :c]
            coeffOut, seOut = get_coeff_se(rtOut, name);
            @test coeffOut ≈ (get_coefficient(rt1, name) + get_coefficient(rt2, name)) / 2.0;
            @test seOut ≈ (get_std_error(rt1, name) + get_std_error(rt2, name)) / 2.0
        end

        rtOut2 = mean([rt1, rt2]);
        @test isapprox(rtOut, rtOut2)
        for name in [:a, :b, :c]
            @test get_coefficient(rtOut, name) ≈ get_coefficient(rtOut2, name)
            @test get_std_error(rtOut, name) ≈ get_std_error(rtOut2, name)
        end

        rtOut3 = reduce_regr_tables([rt1, rt2], StatsBase.std);
        rtOut4 = StatsBase.std([rt1, rt2]);
        @test isapprox(rtOut3, rtOut4)
    end
end


function from_lin_model_test()
    @testset "From linear model" begin
        n = 16;
        zV = categorical(round.(Int, collect(range(1, 4, length = n))));
        data = DataFrame(X = collect(range(1.0, 3.0, length = n)) .^ 2, 
            Y = collect(range(0.1, 3.5, length = n)),
            Z = zV);
        ols = lm(@formula(Y ~ X + Z), data);
        coeffV = coef(ols);

        rt = RegressionTable(ols);
        @test get_coefficient(rt, :X) ≈ coeffV[2]
        @test get_coefficient(rt, :constant) ≈ coeffV[1]
        @test get_coefficient(rt, :Z2) ≈ coeffV[3]
    end
end


@testset "EconometricsLH" begin
    regressor_info_test();
    regression_table_test();
    regr_table_mult_test();
    from_lin_model_test();
    include("regression_test_test.jl");
end


# ------------------
