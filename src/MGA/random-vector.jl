export MGA_RV_update!


"""
    TODO
"""
function MGA_RV_update!(model::JuMP.Model, variables::AbstractArray{T,N}, weights::Vector{Float64}) where {T<:Union{VariableRef,AffExpr},N}
    # new objective function consist of the n variables in variables
    for (i, v) in enumerate(variables)
      weights[i] = rand(Float64) * 2 - 1
    end

    while all(w -> w == 0, weights)
        # Ensure that the sum of weights is not zero
        for (i, v) in enumerate(variables)
          weights[i] = rand(Float64) * 2 - 1
        end
    end

    # update these variables based on their sign
    variables = [v * weights[i] for (i, v) in enumerate(variables)]
    set_objective_sense(model, FEASIBILITY_SENSE)

    # Update objective by adding the distance between variables and the previous optimal solution.
    @objective(model, Min, sum(variables))
end