export DWV_initial!, DWV_update!

"""
    DWV_initial!(
        model::JuMP.Model,
        variables::AbstractArray{T,N},
        fixed_variables::Vector{VariableRef};
        weights::Vector{Float64} = zeros(length(variables)),
        metric::Distances.SemiMetric = SqEuclidean(),
    ) where {T<:Union{VariableRef,AffExpr},N}
"""
function DWV_initial!(
  model::JuMP.Model,
  variables::AbstractArray{T, N},
  fixed_variables::Vector{VariableRef};
  weights::Vector{Float64} = zeros(length(variables)),
  metric::Distances.SemiMetric = SqEuclidean(),
) where {T <: Union{VariableRef, AffExpr}, N}
  # Get the current objective as an affine expression
  obj = JuMP.objective_function(model)
  @assert obj isa AffExpr "Objective must be linear (AffExpr)"

  # Assign weights depending on coefficient sign
  for (i, v) in enumerate(variables)
    c = get(obj.terms, v, 0.0)  # 0.0 if variable not in objective
    if c > 0
      weights[i] = rand([0, 1])
    elseif c < 0
      weights[i] = rand([-1, 0])
    else
      weights[i] = rand([-1, 0, 1])
    end
  end

  # Fix the variables that are fixed
  fix.(fixed_variables, value.(fixed_variables), force = true)

  # update these variables based on their sign
  objective_function = [v * weights[i] for (i, v) in enumerate(variables)]

  # Update objective by adding the distance between variables and the previous optimal solution.
  @objective(model, Min, sum(objective_function))
end

"""
    DWV_update!(
        model::JuMP.Model,
        variables::AbstractArray{T,N},
        weights::Vector{Float64}
    ) where {T<:Union{VariableRef,AffExpr},N}
"""
function DWV_update!(
  model::JuMP.Model,
  variables::AbstractArray{T, N};
  weights::Vector{Float64} = zeros(length(variables)),
  metric::Distances.SemiMetric = SqEuclidean(),
) where {T <: Union{VariableRef, AffExpr}, N}

  # Get the current objective as an affine expression
  obj = JuMP.objective_function(model)
  @assert obj isa AffExpr "Objective must be linear (AffExpr)"

  # Assign weights depending on coefficient sign
  for (i, v) in enumerate(variables)
    c = get(obj.terms, v, 0.0)  # 0.0 if variable not in objective
    if c > 0
      weights[i] = rand([0, 1])
    elseif c < 0
      weights[i] = rand([-1, 0])
    else
      weights[i] = rand([-1, 0, 1])
    end
  end

  # Apply weights to variables
  objective_function = [v * weights[i] for (i, v) in enumerate(variables)]

  # Update model objective
  set_objective_sense(model, FEASIBILITY_SENSE)
  @objective(model, Min, sum(objective_function))
end
