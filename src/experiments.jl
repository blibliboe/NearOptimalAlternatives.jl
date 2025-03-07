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



model_distance = ddmodel()
model_HSJ = ddmodel()
model_Min_Max = ddmodel()
model_Rand_Vec = ddmodel()
model_SPORES = ddmodel()

alternative_solutions = 40

result_distances = generate_MGA_distances!(model_distance, 1.0, alternative_solutions)
result_HSJ = generate_MGA_HSJ!(model_HSJ, 1.0, alternative_solutions)
result_Min_Max = generate_MGA_Min_Max!(model_Min_Max, 1.0, alternative_solutions)
result_Rand_Vec = generate_MGA_Rand_Vec!(model_Rand_Vec, 1.0, alternative_solutions)
result_SPORES = generate_MGA_SPORES!(model_SPORES, 1.0, alternative_solutions)


solutions_distances = zeros((alternative_solutions + 1, 2))
solutions_HSJ = zeros((alternative_solutions + 1, 2))
solutions_Min_Max = zeros((alternative_solutions + 1, 2))
solutions_Rand_Vec = zeros((alternative_solutions + 1, 2))
solutions_SPORES = zeros((alternative_solutions + 1, 2))

for (k,v) in enumerate(all_variables(model_distance))
    for i in 1:alternative_solutions + 1
        setindex!(solutions_distances, result_distances.solutions[i][v] , i + (k - 1) * (alternative_solutions + 1))
    end
end


for (k,v) in enumerate(all_variables(model_HSJ))
    for i in 1:alternative_solutions + 1
        setindex!(solutions_HSJ, result_HSJ.solutions[i][v] , i + (k - 1) * (alternative_solutions + 1))
    end
end

for (k,v) in enumerate(all_variables(model_Min_Max))
    for i in 1:alternative_solutions + 1
        setindex!(solutions_Min_Max, result_Min_Max.solutions[i][v] , i + (k - 1) * (alternative_solutions + 1))
    end
end

for (k,v) in enumerate(all_variables(model_Rand_Vec))
    for i in 1:alternative_solutions + 1
        setindex!(solutions_Rand_Vec, result_Rand_Vec.solutions[i][v] , i + (k - 1) * (alternative_solutions + 1))
    end
end

for (k,v) in enumerate(all_variables(model_SPORES))
    for i in 1:alternative_solutions + 1
        setindex!(solutions_SPORES, result_SPORES.solutions[i][v] , i + (k - 1) * (alternative_solutions + 1))
    end
end

println(solutions_distances)
println(solutions_HSJ)
println(solutions_Min_Max)
println(solutions_Rand_Vec)
println(solutions_SPORES)

volumes_distances = convex_hull_volume(solutions_distances, alternative_solutions + 1)
volumes_HSJ = convex_hull_volume(solutions_HSJ, alternative_solutions + 1)
volumes_Min_Max = convex_hull_volume(solutions_Min_Max, alternative_solutions + 1)
volumes_Rand_Vec = convex_hull_volume(solutions_Rand_Vec, alternative_solutions + 1)
volumes_SPORES = convex_hull_volume(solutions_SPORES, alternative_solutions + 1)

println(volumes_distances)
println(volumes_HSJ)
println(volumes_Min_Max)
println(volumes_Rand_Vec)
println(volumes_SPORES)

# println(volume(VPolygon(convex_hull([[2, 2], [6, 0], [1.67, 3], [1.8, 3.4], [7.2, 1.6], [6.67, 0]]))))

# plot(VPolygon(CH), title="Convex Hull of Solutions", xlabel="x", ylabel="y")