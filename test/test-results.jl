@testset "Update solutions of MGA optimisation" begin
  optimizer = SCIP.Optimizer
  model = JuMP.Model(optimizer)

  @testset "Make sure using an unsolved MGA model fails." begin
    results = MGA.AlternativeSolutions([], [])
    @test_throws ErrorException MGA.update_solutions!(results, model)
  end

  # Initialise simple `square` JuMP model
  @variable(model, 0 ≤ x_1 ≤ 1)
  @variable(model, 0 ≤ x_2 ≤ 1)
  @objective(model, Max, (x_1 - 1)^2 + (x_2 - 1)^2)
  constr = @constraint(model, x_1 + x_2 ≥ 1.8)

  @testset "Test error when no `original_objective` constraint present." begin
    results = MGA.AlternativeSolutions([], [])
    JuMP.optimize!(model)
    @test_throws ErrorException MGA.update_solutions!(results, model)
  end

  @testset "Test correct flow for updating the set of results using a solved JuMP model." begin
    results = MGA.AlternativeSolutions([], [])
    JuMP.set_name(constr, "original_objective")
    JuMP.optimize!(model)
    MGA.update_solutions!(results, model)
    @test length(results.solutions) == 1 &&
          length(results.solutions[1]) == 2 &&
          length(results.objective_values) == 1 &&
          results.objective_values[1] >= 1.8 &&
          results.objective_values[1] <= 2.0
  end
end
