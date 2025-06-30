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
    # corner point (1.67, 3)

    #When slack is 1 there are some new corner points with this slack constraint is the line y = -1/3x + 4
    # slack added points (1.8,3.4) (7.2, 1.6) 


    @objective(model, Min, x + 3*y)


    # objective function should be (6.0, 0.0) with value 6.0
    JuMP.optimize!(model)

    @info "Objective function:" objective_function(model)
    @info "Objective function value: " objective_value(model)
    @info "Variable values: " value.(all_variables(model))[1], value.(all_variables(model))[2]
    return model, [x, y]
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


# Function to select the method and return the corresponding solutions and volumes
function select_method(method::Symbol, slack, alternative_solutions)
    model, variables = ddmodel()
    result = nothing
    solutions = zeros((alternative_solutions + 1, 2))

    solvetime = @elapsed begin

        result = MGA!(model, slack, alternative_solutions, variables; method = method)


    end

    for (k, v) in enumerate(all_variables(model))
        for i in 1:alternative_solutions + 1
            setindex!(solutions, result.solutions[i][v], i + (k - 1) * (alternative_solutions + 1))
        end
    end



    volumes = convex_hull_volume(solutions, alternative_solutions + 1)
    return solutions, volumes, solvetime
end

alternative_solutions = 20
slack = 1.3

methods = [:Dist, :HSJ, :Min_Max, :Rand_Vec, :Spores]
method_names = [:Distances, :HSJ, :Min_Max, :Random_Vector, :Spores]
# methods = [:SPORES]
# methods = [:Min_Max]
results = Dict{Symbol, Tuple{Array{Float64, 2}, Array{Float64, 1}}}()
runtimes = Dict{Symbol, Float64}()
for (i, method) in enumerate(methods)
    solutions, volumes, solvetime = select_method(method, slack, alternative_solutions)
    
    results[method_names[i]] = (solutions, volumes)
    runtimes[method] = solvetime
end

for (name, (sol, vol)) in results
    println("Method: $name")
    println("Solutions: $sol")
    println("Volumes: $vol")
end


function plotting(results)
    # Plotting the solutions in different plots
    for (name, (sol, _))in results

    
        scatter(sol[:, 1], sol[:, 2], xlabel="x", ylabel="y", title="Alternatives found by $name", xaxis=[0, 8], yaxis=[0, 4], label=false)
        plot!(VPolygon(convex_hull([sol[i, :] for i in 1:alternative_solutions + 1])), xlabel="x", ylabel="y")
        # for i in 1:size(sol, 1)
        #     annotate!(sol[i, 1], sol[i, 2], text(string(i - 1), :left))
        # end
        savefig("./plots/Solutions for $name.png")
    end

    plot()
    for (name, (sol, _)) in results
        
        plot!(VPolygon(convex_hull([sol[i, :] for i in 1:alternative_solutions + 1])), title="Convex Hull of Solutions", xlabel="x", ylabel="y", label="$name")
        # for i in 1:size(sol, 1)
        #     annotate!(sol[i, 1], sol[i, 2], text(string(i - 1), :left))
        # end
        savefig("./plots/All hull shapes.png")
    end

    # Plotting the volumes in the same plot
    plot()
    for (name, (_, vol)) in results
        plot!(vol[2:end], label="Volumes for $name", xlabel="Iteration", ylabel="Volume", title="Volumes over Iterations")
    end
    plot!(fill(7.7465, 20), label="Maximal Convex Hull", xlabel="Iteration", ylabel="Volume", title="Volumes over Iterations")

    savefig("./plots/Volumes for all methods.png")


    plot()
    # actual convex hull (2.5,1),(2, 1.5),(5.92, 1.86),(5.3, 0),(5, 0),(1.67, 3),(1.75, 3.25), (1.8,2.2) 
    actual = zeros((8, 2))
    actual[1, :] = [2.5, 1]
    actual[2, :] = [2, 1.5]
    actual[3, :] = [5.92, 1.86]
    actual[4, :] = [5.3, 0]
    actual[5, :] = [5, 0]
    actual[6, :] = [1.67, 3]
    actual[7, :] = [1.75, 3.25]
    actual[8, :] = [1.8, 2.2]
    println("Actual solutions: ", actual)
    scatter(actual[:, 1], actual[:, 2], label="True solutions", xlabel="x", ylabel="y", xaxis=[0, 8], yaxis=[0, 4])
    plot!(VPolygon(convex_hull([actual[i,:] for i in 1:8])), title="Near-optimal solutions space", xlabel="x", ylabel="y")


    savefig("./plots/True solution.png")
    println("Actual volume: ", volume(VPolygon(convex_hull([actual[i,:] for i in 1:8]))))
    plot()

    dominance = zeros((5, 2))
    dominance[1, :] = [2.5, 1]
    dominance[2, :] = [2, 1.5]
    # actual[3, :] = [5.92, 1.86]
    # actual[4, :] = [5.3, 0]
    dominance[3, :] = [5, 0]
    dominance[4, :] = [1.67, 3]
    # actual[7, :] = [1.75, 3.25]
    dominance[5, :] = [1.8, 2.2]
    println("Actual solutions: ", dominance)
    scatter(dominance[:, 1], dominance[:, 2], label="Non-dominated alternatives", xlabel="x", ylabel="y", title="Structurally different solutions", xaxis=[0, 8], yaxis=[0, 4])
    plot!(VPolygon(convex_hull([dominance[i,:] for i in 1:5])), xlabel="x", ylabel="y")


    savefig("./plots/dominance.png")
    println("Actual volume: ", volume(VPolygon(convex_hull([dominance[i,:] for i in 1:5]))))
end

println("Runtimes: ", runtimes)
plotting(results)

# println(volume(VPolygon(convex_hull([[2, 2], [6, 0], [1.67, 3], [1.8, 3.4], [7.2, 1.6], [6.67, 0]]))))

# plot(VPolygon(CH), title="Convex Hull of Solutions", xlabel="x", ylabel="y")