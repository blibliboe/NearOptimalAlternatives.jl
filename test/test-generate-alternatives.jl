@testset "Test generate alternatives using optimisation." begin
  @testset "Make sure error is thrown when JuMP model is not solved." begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 0 ≤ x_1 ≤ 1)
    @variable(model, 0 ≤ x_2 ≤ 1)
    @objective(model, Max, x_1 + x_2)

    @test_throws ArgumentError MGA.generate_alternatives!(model, 0.1, 5)
  end

  @testset "Make sure error is thrown when incorrect optimality_gap." begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 0 ≤ x_1 ≤ 1)
    @variable(model, 0 ≤ x_2 ≤ 1)
    @objective(model, Max, x_1 + x_2)
    optimize!(model)

    @test_throws ArgumentError MGA.generate_alternatives!(model, -0.1, 5)
  end

  @testset "Make sure error is thrown when incorrect n_alternatives." begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 0 ≤ x_1 ≤ 1)
    @variable(model, 0 ≤ x_2 ≤ 1)
    @objective(model, Max, x_1 + x_2)
    optimize!(model)

    @test_throws ArgumentError MGA.generate_alternatives!(model, 0.1, 0)
  end

  @testset "Test regular run with one alternative." begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 0 ≤ x_1 ≤ 1)
    @variable(model, 0 ≤ x_2 ≤ 1)
    @objective(model, Max, x_1 + x_2)
    optimize!(model)

    results = MGA.generate_alternatives!(model, 0.1, 1)

    @test length(results.solutions) == 1 &&
          length(results.solutions[1]) == 2 &&
          length(results.objective_values) == 1 &&
          isapprox(results.objective_values[1], 1.8) &&
          (
            isapprox(results.solutions[1][x_1], 0.8) && isapprox(results.solutions[1][x_2], 1.0) ||
            isapprox(results.solutions[1][x_2], 0.8) && isapprox(results.solutions[1][x_1], 1.0)
          )
  end

  @testset "Test regular run with one alternative with one selected variable." begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 0 ≤ x_1 ≤ 1)
    @variable(model, 0 ≤ x_2 ≤ 1)
    @objective(model, Max, x_1 + x_2)
    optimize!(model)

    results = MGA.generate_alternatives!(model, 0.1, 1, selected_variables = [x_1])

    @test length(results.solutions) == 1 &&
          length(results.solutions[1]) == 2 &&
          length(results.objective_values) == 1 &&
          results.objective_values[1] == 1.8 &&
          isapprox(results.solutions[1][x_1], 0.8) &&
          isapprox(results.solutions[1][x_2], 1.0)
  end

  @testset "Test regular run with two alternatives." begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 0 ≤ x_1 ≤ 1)
    @variable(model, 0 ≤ x_2 ≤ 1)
    @objective(model, Max, x_1 + x_2)
    optimize!(model)

    results = MGA.generate_alternatives!(model, 0.1, 2)
    println(results)

    @test length(results.solutions) == 2 &&
          length(results.solutions[2]) == 2 &&
          length(results.objective_values) == 2 &&
          results.objective_values[1] == 1.8 &&
          isapprox(results.objective_values[2], 1.8) &&
          (
            isapprox(results.solutions[1][x_1], 0.8) && isapprox(results.solutions[1][x_2], 1.0) ||
            isapprox(results.solutions[1][x_2], 0.8) && isapprox(results.solutions[1][x_1], 1.0)
          )
    (
      isapprox(results.solutions[2][x_1], 0.8) && isapprox(results.solutions[2][x_2], 1.0) ||
      isapprox(results.solutions[2][x_2], 0.8) && isapprox(results.solutions[2][x_1], 1.0)
    )
  end

  @testset "Test regular run with one alternative and a weighted metric." begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 0 ≤ x_1 ≤ 1)
    @variable(model, 0 ≤ x_2 ≤ 1)
    @objective(model, Max, x_1 + x_2)
    optimize!(model)

    results = MGA.generate_alternatives!(model, 0.1, 1, metric = WeightedSqEuclidean([0.5, 1]))
    println(results)

    @test length(results.solutions) == 1 &&
          length(results.solutions[1]) == 2 &&
          length(results.objective_values) == 1 &&
          isapprox(results.objective_values[1], 1.8) &&
          isapprox(results.solutions[1][x_2], 0.8) &&
          isapprox(results.solutions[1][x_1], 1.0)
  end
end
