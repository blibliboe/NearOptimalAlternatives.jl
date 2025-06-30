export domination_model

using Plots
import MultiObjectiveAlgorithms as MOA
import HiGHS
using LazySets
import Gurobi

```
Find dominating 2d
```
function mddmodel()
    optimizer = Gurobi.Optimizer
    model = JuMP.Model(optimizer)
    # set_attribute(model, MOA.Algorithm(), algorithm)
    # if set_time
    #     set_attribute(model, MOI.TimeLimitSec(), 1)
    # end
    # set_attribute(model, MOA.SolutionLimit(), solutions)

    @variable(model, 0.0 <= x <= 10.0)
    @variable(model, 0.0 <= y <= 30.0)

    #constraints to make the problem a bit more difficult
    @constraint(model, 6x + y - 13 ≥ 0.0)
    @constraint(model, x + y - 3.5 ≥ 0.0)
    @constraint(model, 0.4x + y - 2 ≥ 0.0)
    @constraint(model, 3.5x + y -8.5 ≥ 0.0)
    # corner point (2, 2)
    @constraint(model, - 3x + y + 15.9 ≥ 0.0)
    # corner points (6, 0) , (6.67, 0)
    @constraint(model, - 3x + y + 2 ≤ 0.0)

    # @constraint(model, x + 3y ≤ 11.5)
    # corner point (1.67, 3)

    #When slack is 1 there are some new corner points with this slack constraint is the line y = -1/3x + 4
    # slack added points (1.8,3.4) (7.2, 1.6) 


    @objective(model, Min, x + 3y)


    # objective function should be (6.0, 0.0) with value 6.0
    JuMP.optimize!(model)
 
    return model
end

# Function to create the new model based on the old model
function domination_model(model::JuMP.Model, slack_factor::Float64)
    old_obj_expr = JuMP.objective_function(model)
    old_obj_value = JuMP.objective_value(model)
    variables = JuMP.all_variables(model)

    set_optimizer(model, (() -> MOA.Optimizer(HiGHS.Optimizer)))
    set_attribute(model, MOA.Algorithm(), MOA.KirlikSayin())

    # add the slack constraint
    @constraint(model, old_obj_expr <= (1 + slack_factor) * old_obj_value)
    # add the new objective function
    @objective(model, Min, variables)

    JuMP.optimize!(model)

    alternatives = []

    for index in 1:result_count(model)
        alternative = get_alternative(all_variables(model); index)
        push!(alternatives, alternative)
    end

    return alternatives
end

function output()
    model = mddmodel()
    variables = all_variables(model)
    results = MGA!(model, 1.3, 10, variables; method = :Min_Max)

    println(results)
    println("Solutions: ", results.solutions)
    for solution in results.solutions
        println("Solution: ", solution)
    end

    fronts, rank = fast_nondominated_sort_dict(variables, results.solutions)
    println("Fronts: ", fronts)
    println("Rank: ", rank)


    alternatives = zeros(length(results.solutions), length(all_variables(model)))

    for (i, solution) in enumerate(results.solutions)
        for (j, var) in enumerate(all_variables(model))
            alternatives[i, j] = solution[var]
        end
    end

    plot()  # Reset the plot
    unique_ranks = unique(rank)
    for r in reverse(unique_ranks)
        indices = findall(x -> x == r, rank)
        scatter!(alternatives[indices, 1], alternatives[indices, 2], label="Rank $r")
    end
    savefig("./plots/test.png")	

end

output()

function test()

    model = mddmodel()
    solutions = domination_model(model, 1.3)


    scatter(solutions[:,1], solutions[:,2], xlabel="x", ylabel="y", title="MOO with dichotomy", legend=false, xaxis=[0, 8], yaxis=[0, 4])
    plot!(VPolygon(convex_hull([solutions[i, :] for i in 1:n])), xlabel="x", ylabel="y")

    savefig("./plots/Dominating of dichotomy new.png")

end



function old()

    # solutions = zeros((result_count(model), length(all_variables(model))))
    # @info "Solution count: " result_count(model)
    # for (k, v) in enumerate(all_variables(model))
    #     for i in 1:result_count(model)
    #         setindex!(solutions, value(v; result = i), i + (k - 1) * (result_count(model)))
    #     end
    # end


    algorithms = [
        MOA.Chalmet(),
        MOA.Dichotomy(),
        # MOA.DominguezRios(),
        MOA.EpsilonConstraint(),
        MOA.Hierarchical(),
        MOA.KirlikSayin(),
        MOA.Lexicographic(),
        # MOA.TambyVanderpooten()
    ]





    for algorithm in algorithms

        model = mddmodel()
    
        n = result_count(model)
        solutions = zeros((n, 2))
        @info "Solutions:"
        for (k, v) in enumerate(all_variables(model))
            for i in 1:n
                setindex!(solutions, value(v; result = i), i + (k - 1) * (n))
            end
        end
        println(solutions)

        scatter(solutions[:,1], solutions[:,2], xlabel="x", ylabel="y", title="MOO with $algorithm", legend=false, xaxis=[0, 8], yaxis=[0, 4])
        plot!(VPolygon(convex_hull([solutions[i, :] for i in 1:n])), xlabel="x", ylabel="y")

        savefig("./plots/Dominating of $algorithm.png")
    end

    time_algorithms = [
        MOA.DominguezRios(),
        MOA.TambyVanderpooten()
    ]

    for algorithm in time_algorithms

        model = mddmodel()
    
        n = result_count(model)
        solutions = zeros((n, 2))
        @info "Solutions:"
        for (k, v) in enumerate(all_variables(model))
            for i in 1:n
                setindex!(solutions, value(v; result = i), i + (k - 1) * (n))
            end
        end
        println(solutions)

        scatter(solutions[:,1], solutions[:,2], xlabel="x", ylabel="y", title="MOO with $algorithm", legend=false, xaxis=[0, 8], yaxis=[0, 4])
        plot!(VPolygon(convex_hull([solutions[i, :] for i in 1:n])), xlabel="x", ylabel="y")

        savefig("./plots/Dominating of $algorithm.png")
    end
end


