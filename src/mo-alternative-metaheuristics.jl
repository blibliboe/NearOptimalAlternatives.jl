"""
    objective = create_objective(
        model::JuMP.Model,
        solution::OrderedDict{JuMP.VariableRef, Float64},
        optimality_gap::Float64,
        metric::Distances.SemiMetric,
        index_map::Dict{Int64, Int64},
        fixed_variables::Dict{VariableRef, Float64}
    )

Create an objective function supported by Metaheuristics.jl for the alternative generating problem.
Right now only creates multi objective problem in metaheuristics.jl

# Arguments
- `model::JuMP.Model`: solved JuMP model of the original lp problem.
- `solution::OrderedDict{JuMP.VariableRef, Float64}`: solution value of the original lp problem excluding fixed variables.
- `optimality_gap::Float64`: maximum difference between objective value of optimal solution and alternative solutions.
- `metric::Distances.SemiMetric`: distance metric used to measure distance between solutions.
- `index_map::Dict{Int64, Int64}`: dictionary mapping indices in the JuMP/MathOptInterface model to indices of `x`.
- `fixed_variables::Dict{VariableRef, Float64}`: dictionary containing the values of the fixed variables.
"""
function mo_create_objective(
  model::JuMP.Model,
  metric::Distances.SemiMetric,
  index_map::Dict{Int64, Int64},
  fixed_variables::Dict{MOI.VariableIndex, Float64},
)
  original_objectives = JuMP.objective_function(model)  
  constraints = JuMP.all_constraints(model, include_variable_in_set_constraints = true)
  constraint_functions = map(c -> MOI.get(model, MOI.ConstraintFunction(), c), constraints)
  constraint_sets = map(c -> MOI.get(model, MOI.ConstraintSet(), c), constraints)

  function f(x)

    fx = extract_multi_objective(original_objectives, x, index_map, fixed_variables)

    # fx = Vector{Float64}(undef, length(original_objectives))
    # for (i, obj) in enumerate(original_objectives)
    #     fx[i] = extract_objective(obj, x, index_map, fixed_variables)
    # end

    # Objective function for metaheuristic (= distance between individual x and solution values of original LP). Solution_values does not contain fixed_variables, these are not required in objective as the distance for these variables is zero.

    # Initialise set of inequality constraints.
    gx = Vector{Float64}(undef, 0)
    # Initialise set of equality constraints.
    hx = Vector{Float64}(undef, 0)

    for i in eachindex(constraint_functions)
      c_fun = constraint_functions[i]
      c_set = constraint_sets[i]

      # Check if constraint involves multiple variables or if it is a bound.
      if isa(c_fun, MathOptInterface.ScalarAffineFunction)
        # Add constraint to gx or hx, depending on equality or inequality.
        if isa(c_set, MOI.LessThan)
          resulting_constraint =
            extract_constraint(c_fun, x, index_map, fixed_variables) - MOI.constant(c_set)
          push!(gx, resulting_constraint)
        elseif isa(c_set, MOI.GreaterThan)
          resulting_constraint =
            MOI.constant(c_set) - extract_constraint(c_fun, x, index_map, fixed_variables)
          push!(gx, resulting_constraint)
        elseif isa(c_set, MOI.EqualTo)
          resulting_constraint =
            extract_constraint(c_fun, x, index_map, fixed_variables) - MOI.constant(c_set)
          push!(hx, resulting_constraint)
        elseif isa(c_set, MOI.Interval)
          constraint = extract_constraint(c_fun, x, index_map, fixed_variables)
          push!(gx, constraint - c_set.upper)
          push!(gx, c_set.lower - constraint)
        end
      elseif isa(c_fun, MathOptInterface.VariableIndex)
        # Skip variable if it is fixed.
        if !haskey(index_map, c_fun.value)
          continue
        end
        # Add bounds to gx or hx, depending on equality or inequality.
        if isa(c_set, MOI.LessThan)
          push!(gx, x[index_map[c_fun.value]] - MOI.constant(c_set))
        elseif isa(c_set, MOI.GreaterThan)
          push!(gx, MOI.constant(c_set) - x[index_map[c_fun.value]])
        elseif isa(c_set, MOI.EqualTo)
          push!(hx, x[index_map[c_fun.value]] - MOI.constant(c_set))
        elseif isa(c_set, MOI.Interval)
          push!(gx, x[index_map[c_fun.value]] - c_set.upper)
          push!(gx, c_set.lower - x[index_map[c_fun.value]])
        end
      else
        throw(ArgumentError("Only linear non-vector constraints are supported."))
      end
    end

    # gx and hx should contain 0.0 if no inequality constraints or equality constraints are in the original problem.
    if isempty(gx)
      push!(gx, 0.0)
    end

    if isempty(hx)
      push!(hx, 0.0)
    end

    return fx, gx, hx
  end

  return f
end

"""
    problem = create_alternative_generating_problem(
        model::JuMP.Model,
        algorithm::Metaheuristics.Algorithm,
        initial_solution::OrderedDict{VariableRef, Float64},
        optimality_gap::Float64,
        metric::Distances.SemiMetric,
        fixed_variables::Dict{VariableRef, Float64}
    )

Create the Multi objective Metaheuristic problem representing the alternative generating problem for the original LP.

# Arguments:
- `model::JuMP.Model`: JuMP model representing the original LP.
- `algorithm::Metaheuristics.Algorithm`: Metaheuristic algorithm to solve the alternative generating problem.
- `initial_solution::OrderedDict{VariableRef, Float64}`: (near-)optimal solution to `model`, for which alternatives are sought.
- `optimality_gap::Float64`: maximum gap in objective value between `initial_solution` and alternative solutions.
- `metric::Distances.SemiMetric`: distance metric used to compute distance between alternative solutions and `initial_solution`.
- `fixed_variables::Dict{MOI.VariableIndex, Float64}`: solution values for fixed variables of the original problem.
"""
function mo_create_alternative_generating_problem(
  model::JuMP.Model,
  algorithm::Metaheuristics.Algorithm,
  initial_solution::OrderedDict{VariableRef, Float64},
  metric::Distances.SemiMetric,
  fixed_variables::Dict{MOI.VariableIndex, Float64},
)
  # Create map between variable indices in JuMP model and indices in individuals of Metaheuristic problem.
  index_map = Dict{Int64, Int64}()
  k = collect(keys(initial_solution))
  for i in eachindex(k)
    index_map[k[i].index.value] = i
  end

  objective =
    mo_create_objective(model, metric, index_map, fixed_variables)
  bounds = extract_bounds(model, index_map)

  return MetaheuristicProblem(objective, bounds, algorithm)
end


