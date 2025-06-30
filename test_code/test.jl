import MultiObjectiveAlgorithms as MOA
using Ipopt
using Plots
using Gurobi
using Heuristics
using JuMP


model  = JuMP.Model(Gurobi.Optimizer)

@variable(model, 0 <= x)
@variable(model, 0 <= y)

@constraint(model, -x -3y <= -1)
@constraint(model, -3x -y <= -1)

@objective(model, Min, x + y)

JuMP.optimize!(model)

println("Objective function value: ", JuMP.objective_value(model))
println("Variable values: ", JuMP.value(x)," and " , JuMP.value(y))

# function get_model_slack(; N=2)
#     optimizer = Gurobi.Optimizer
#     # optimizer = () -> MOA.Optimizer(Gurobi.Optimizer)
#     model = Model(optimizer)

#     @variable(model, 0.0 <= x[1:N] <= 1.0)
#     @variable(model, 0.0 <= s <= 10.0)
#     @constraint(model, sum(x[1:N]) >= 1.0 - s)

#     @constraint(model, x[1] == 0.5)

#     # @variable(model, 0.0 <= slack_pos[1:N-1, 2:N] <= 10.0)
#     # @variable(model, 0.0 <= slack_neg[1:N-1, 2:N] <= 10.0)

#     # for i in 1:N-1
#     #     for j in i+1:N
#     #         @constraint(model, x[i] - slack_pos[i, j] <= 1.00001 * x[j])
#     #         @constraint(model, x[i] + slack_neg[i, j] >= 0.99999 * x[j])
#     #     end
#     # end

#     @objective(model, Min, sum(x[1:N]) +  N * s) #+ sum(3 * slack_pos[i, j] for i in 1:N-1 for j in i+1:N) + sum(3* slack_neg[i, j] for i in 1:N-1 for j in i+1:N))



#     JuMP.optimize!(model)

#     @info "Objective function:" objective_function(model)
#     @info "Variable values: " value.(all_variables(model))[1], value.(all_variables(model))[2], value.(all_variables(model))[3]
#     return model
# end

# function f(x)
#     fx1 = x[1]
#     fx2 = x[2]
#     fx = [fx1, fx2] #objective functions
#     gx = [0.0] #inequality constraints
#     hx = [x[1] - sum(x[i] for i in 3:(18 * 8 + 2))] #equality constraints
    
#     return fx, gx, hx
# end
# lb = zeros(18 * 8 + 2)
# ub = ones(18 * 8 + 2)
# ub[1] = 18*8
# bounds = boxconstraints(lb, ub)


# optimized = Metaheuristics.optimize(f, bounds, Metaheuristics.NSGA3(; N= 1000, p_cr = 0.95, η_cr = 10, η_m = 40, p_m = 0.001, partitions = 3, reference_points = []))

# @info "Optimal" optimized

# for i in 1:2
#     @info "Minimal" minimizer(optimized)[i]
# end

# # for i in 1:100
# #     println(positions(optimized)[i, :])
# # end


# # for solution in optimized.population
# #     @info "solution" (solution)
# # end
# # @info "equality constraints" gval(optimized)



# # N = 2
# # model = get_model_slack(; N = N)

# # information = Information(f_optimum = objective_value(model))


# # result = multi_objective_generate_alternatives(model, Heuristics.NSGA2(model; N=100, information = information))

# # @info "State: " result
# # X = positions(result)
# # # println(X)

# # scatter(X[:,1], X[:,2], X[:,3],  title="Minimizing with x1 + x2 + s >= 1", xlabel="Value of x1", ylabel="value of x2", zlabel="value of s", label="Pareto front", legend=:topright, ylims=(-0.01,1.01), xlims=(-0.01,1.01))

# # savefig("./plots/Test.png")


# # function get_model_lagrangian(; N=2)
# #     optimizer = Gurobi.Optimizer
# #     model = Model(optimizer)

# #     @variable(model, 0.0 <= x[1:N] <= 1.0)
# #     # @variable(model, 0.0 <= μ)  # Lagrange multiplier for the constraint
# #     @variable(model, 0.0 <= s <= 10) # slack variable for the sum constraint

# #     @constraint(model, sum(x[1:N]) - s == 1.0)
# #     λ = 2.0 #penalty parameter

# #     @objective(model, Min, sum(x[1:N]) + λ * s)

# #     JuMP.optimize!(model)
# #     @info "Objective function:" objective_function(model)
# #     @info "Objective function value: " objective_value(model)
# #     @info "Variable values: " value.(all_variables(model))[1], value.(all_variables(model))[2], value.(all_variables(model))[3]
# #     return model
# # end

# # N = 2
# # model_lagrangian = get_model_lagrangian(; N = N)

# # # information_lagrangian = Information(f_optimum = objective_value(model_lagrangian))

# # # result_lagrangian = multi_objective_generate_alternatives(model_lagrangian, Metaheuristics.NSGA3(; N=100, information = information_lagrangian))

# # # @info "State: " result_lagrangian
# # # X_lagrangian = positions(result_lagrangian)

# # # scatter(X_lagrangian[:,1], X_lagrangian[:,2], title="Minimizing with x1 + x2 >= 1 using Lagrangian", xlabel="Value of x1", ylabel="value of x2", label="Pareto front", legend=:topright, ylims=(-0.01,1.01), xlims=(-0.01,1.01))

# # # savefig("./plots/Test_Lagrangian.png")




# #OLD random code

# # solution_values = collect(Float64, value.(all_variables(model); result = 1))
# # println(solution_values)
# # solution_values = collect(Float64, value.(all_variables(model); result = 2))
# # println(solution_values)
# # println(initial_solution)

# # println(objective_value(model; result = 1))
# # println(objective_value(model; result = 2))


# # for i in 1:100
# #     for j in 1:N-1
# #         for k in j+1:N
# #             if !(X[i,j] <= 1.00001 * X[i,k] && X[i,j] >= 0.99999 * X[i,k])
# #                 println("Violation at $i: $j, $k")
# #                 println("Values: $(X[i,j]), $(X[i,k])")
# #                 println("Absolute value: ", abs(X[i,j] - X[i,k]))
# #             end
# #         end
# #     end
# # end
