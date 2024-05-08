@testset "Test create alternative problem" begin
  @testset "Test simple maximisation problem" begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 0 ≤ x_1 ≤ 1)
    @variable(model, 0 ≤ x_2 ≤ 1)
    @objective(model, Max, x_1 + x_2)
    optimize!(model)

    MGA.create_alternative_problem!(model, 0.1, SqEuclidean(), VariableRef[])
    @test objective_sense(model) == MAX_SENSE &&
          objective_function(model) == QuadExpr(
            AffExpr(2, x_1 => -2, x_2 => -2),
            UnorderedPair(x_1, x_1) => 1,
            UnorderedPair(x_2, x_2) => 1,
          ) &&
          constraint_object(model[:original_objective]).func == AffExpr(0, x_1 => 1, x_2 => 1) &&
          constraint_object(model[:original_objective]).set == MOI.GreaterThan(1.8)
  end

  @testset "Test simple minimisation problem" begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 1 ≤ x_1 ≤ 2)
    @variable(model, 1 ≤ x_2 ≤ 2)
    @objective(model, Min, x_1 + x_2)
    optimize!(model)

    MGA.create_alternative_problem!(model, 0.1, SqEuclidean(), VariableRef[])
    @test objective_sense(model) == MAX_SENSE &&
          objective_function(model) == QuadExpr(
            AffExpr(2, x_1 => -2, x_2 => -2),
            UnorderedPair(x_1, x_1) => 1,
            UnorderedPair(x_2, x_2) => 1,
          ) &&
          constraint_object(model[:original_objective]).func == AffExpr(0, x_1 => 1, x_2 => 1) &&
          constraint_object(model[:original_objective]).set == MOI.LessThan(2.2)
  end

  @testset "Test maximisation with selected variables" begin
    optimizer = SCIP.Optimizer
    model = JuMP.Model(optimizer)

    # Initialise simple `square` JuMP model
    @variable(model, 0 ≤ x_1 ≤ 1)
    @variable(model, 0 ≤ x_2 ≤ 1)
    @objective(model, Max, x_1 + x_2)
    optimize!(model)

    MGA.create_alternative_problem!(model, 0.1, SqEuclidean(), [x_1])
    @test objective_sense(model) == MAX_SENSE &&
          objective_function(model) == QuadExpr(
            AffExpr(2, x_1 => -2, x_2 => -2),
            UnorderedPair(x_1, x_1) => 1,
            UnorderedPair(x_2, x_2) => 1,
          ) &&
          constraint_object(model[:original_objective]).func == AffExpr(0, x_1 => 1, x_2 => 1) &&
          constraint_object(model[:original_objective]).set == MOI.GreaterThan(1.8) &&
          is_fixed(x_2)
  end
end

@testset "Test adding a solution to a model with an alternative found." begin
  optimizer = SCIP.Optimizer
  model = JuMP.Model(optimizer)

  # Initialise simple `square` JuMP model
  @variable(model, 0 ≤ x_1 ≤ 1)
  @variable(model, 0 ≤ x_2 ≤ 1)
  @objective(model, Max, (x_1 - 1)^2 + (x_2 - 1)^2)
  @constraint(model, original_objective, x_1 + x_2 ≥ 1.8)
  fix(x_1, 1, force = true) # so solution is x_1 = 1, x_2 = 0.8
  optimize!(model)

  MGA.add_solution!(model, SqEuclidean())
  @test objective_sense(model) == MAX_SENSE &&
        objective_function(model) == QuadExpr(
          AffExpr(3.64, x_1 => -4, x_2 => -3.6),
          UnorderedPair(x_1, x_1) => 2,
          UnorderedPair(x_2, x_2) => 2,
        ) &&
        constraint_object(model[:original_objective]).func == AffExpr(0, x_1 => 1, x_2 => 1) &&
        constraint_object(model[:original_objective]).set == MOI.GreaterThan(1.8)
end
