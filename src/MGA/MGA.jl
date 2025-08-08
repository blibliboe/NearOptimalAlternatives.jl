export MGA!

"""
    TODO
"""
function MGA!(
    model::JuMP.Model,
    optimality_gap::Float64,
    n_alternatives::Int64,
    variables::AbstractArray{T,N};
    method::Symbol = :HSJ,
    metric::Distances.SemiMetric = SqEuclidean(),
    fixed_variables::Vector{VariableRef} = VariableRef[],) where {T<:Union{VariableRef,AffExpr},N}

    if !is_solved_and_feasible(model)
        throw(ArgumentError("JuMP model has not been solved."))
    elseif optimality_gap < 0
        throw(ArgumentError("Optimality gap (= $optimality_gap) should be at least 0."))
    elseif n_alternatives < 1
        throw(ArgumentError("Number of alternatives (= $n_alternatives) should be at least 1."))
    end



    result = AlternativeSolutions([], [])
    weights = zeros(length(variables))
    

    @info "Adding the original solution to the result."
    update_solutions!(result, model)

    @info "Creating model for generating alternatives."
    MGA_initial!(model, optimality_gap, fixed_variables, variables, weights; method = method, metric = metric)

    @info "Solving model."
    JuMP.optimize!(model)
    @info "Solution #1/$n_alternatives found."# solution_summary(model)
    update_solutions!(result, model)

    # If n_solutions > 1, we repeat the solving process to generate multiple solutions.
    for i = 2:n_alternatives
        @info "Reconfiguring model for generating alternatives."
        if method == :HSJ
            MGA_HSJ_update!(model, variables, weights)
        elseif method == :Spores
            MGA_SPORES_update!(model, variables, weights)
        elseif method == :Min_Max
            MGA_MM_update!(model, variables, weights)
        elseif method == :Rand_Vec
            MGA_RV_update!(model, variables, weights)
        elseif method == :Dom_Vec
            MGA_DV_update!(model, variables, weights)
        elseif method == :Dist
            MGA_Dist_update!(model, variables; metric = metric)
        elseif method == :Exp_Vec
            MGA_EV_update!(model, variables, weights)
        else
            throw(ArgumentError("Method $method is not supported."))
        end

        # @info "Resetting the model"
        # MathOptInterface.Utilities.reset_optimizer(model)

        @info "Solving model."
        JuMP.optimize!(model)

        @info "Solution #$i/$n_alternatives found."# solution_summary(model)
        update_solutions!(result, model)
    end

    return result
end

function MGA_initial!(
    model::JuMP.Model,
    optimality_gap::Float64,
    fixed_variables::Vector{VariableRef},
    variables::AbstractArray{T,N},
    weights::Vector{Float64};
    method::Symbol = :HSJ,
    metric::Distances.SemiMetric = SqEuclidean(),
  ) where {T<:Union{VariableRef,AffExpr},N}
    optimal_value = objective_value(model)
    old_objective = objective_function(model)
    old_objective_sense = objective_sense(model)

    @info "Fixing the variables that are fixed"
    fix.(fixed_variables, value.(fixed_variables), force = true)
    # get random variables to minimize and maximize where there is no overlap between minimizing and maximizing
    @info "Creating the new objective function"
    if method == :HSJ
        MGA_HSJ_update!(model, variables, weights)
    elseif method == :Spores
        MGA_SPORES_update!(model, variables, weights)
    elseif method == :Min_Max
        MGA_MM_update!(model, variables, weights)
    elseif method == :Rand_Vec
        MGA_RV_update!(model, variables, weights)
    elseif method == :Dom_Vec
        MGA_DV_update!(model, variables, weights)
    elseif method == :Dist
        MGA_Dist_initial!(model, variables; metric = metric)
    elseif method == :Exp_Vec
        MGA_EV_update!(model, variables, weights)
    else
        throw(ArgumentError("Method $method is not supported."))
    end

    @info "Adding the old objective function as a constraint to the model"
    # Constraint ensuring maximum difference in objective value to optimal solution. The sign of `optimal_value` is used to ensure that a negative `optimal_value` does not lead to an infeasible bound requiring a better than optimal solution.
    if old_objective_sense == MAX_SENSE
    @constraint(
        model,
        original_objective,
        old_objective ≥ optimal_value * (1 - optimality_gap * sign(optimal_value))
    )
    else
    @constraint(
        model,
        original_objective,
        old_objective ≤ optimal_value * (1 + optimality_gap * sign(optimal_value))
    )
    end
end