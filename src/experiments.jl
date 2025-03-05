using Plots
using Gurobi
using LazySets

```
Model for the 2d experiment
```
function ddmodel()
    optimizer = Gurobi.Optimizer
    model = Model(optimizer)

    @variable(model, 0.0 <= x <= 10.0)
    @variable(model, 0.0 <= y <= 10.0)

    #constraints to make the problem a bit more difficult
    @constraint(model, 3x + y - 8 ≥ 0.0)
    @constraint(model, x + 2y - 6 ≥ 0.0)
    # corner point (2, 2)
    @constraint(model, - 3x + y + 20 ≥ 0.0)
    # corner points (6, 0) , (6.67, 0)
    @constraint(model, - 3x + y + 2 ≤ 0.0)
    # corner point (1.67, 3)

    #When slack is 1 there are some new corner points with this slack constraint is the line y = -1/3x + 4
    # slack added points (1.8,3.4) (7.2, 1.6) 


    @objective(model, Min, x + 3*y)


    # objective function should be (6.0, 0.0) with value 6.0
    JuMP.optimize!(model)

    @info "Objective function:" objective_function(model)
    @info "Objective function value: " objective_value(model)
    @info "Variable values: " value.(all_variables(model))[1], value.(all_variables(model))[2]
    return model
end

```
Function that returns the minimum euclidean distance between each value at index i and each previous index.
```
function spread(a, alternative_solutions)
    min_distances = zeros(alternative_solutions)
    for i in 2:alternative_solutions
        min_distances[i] = min_distances[i-1] + minimum([sqeuclidean(a[i, :], a[j, :]) for j in 1:i-1])
    end
    return min_distances
end


function convex_hull_volume(solutions, alternative_solutions)
    volume = zeros(alternative_solutions)
    for i in 1:alternative_solutions
        points = [solutions[j, :] for j in 1:i]
        CH = convex_hull(points)
        volume[i] = LazySets.volume(VPolygon(CH))
    end
    return volume


end



model = ddmodel()

alternative_solutions = 100

# result = generate_alternatives!(model, 1.0, alternative_solutions)

result = generate_alternatives_HSJ!(model, 1.0, alternative_solutions)

solutions = zeros((alternative_solutions + 1, 2))

for (k,v) in enumerate(all_variables(model))
    for i in 1:alternative_solutions + 1
        setindex!(solutions, result.solutions[i][v] , i + (k - 1) * (alternative_solutions + 1))
    end
end

println(solutions)

# min_distances = spread(solutions, alternative_solutions + 1)

# println(min_distances)

volumes = convex_hull_volume(solutions, alternative_solutions + 1)
println(volumes)


# println(volume(VPolygon(convex_hull([[2, 2], [6, 0], [1.67, 3], [1.8, 3.4], [7.2, 1.6], [6.67, 0]]))))

# plot(VPolygon(CH), title="Convex Hull of Solutions", xlabel="x", ylabel="y")