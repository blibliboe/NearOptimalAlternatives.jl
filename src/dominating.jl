export fast_nondominated_sort_dict, get_dataframes, fast_nondominated_sort, approximately_unique_solutions


# Convert Dicts to vectors of objective values for comparison
function extract_values(d::Dict{JuMP.VariableRef, Float64}, variables::AbstractArray{T,N}) where {T<:Union{VariableRef,AffExpr},N}
    [d[v] for v in variables]
end


function fast_nondominated_sort_dict(variables::AbstractArray{T,N}, population::Vector{Dict{JuMP.VariableRef, Float64}}) where {T<:Union{VariableRef,AffExpr},N}
    # Ensure variables are flattened into a single vector for consistent indexing
    solutions = [extract_values(ind, variables) for ind in population]

    fast_nondominated_sort(solutions)
end

function dominates(p::Vector{Float64}, q::Vector{Float64})
    all(p .<= q) && any(p .< q)
end


function fast_nondominated_sort(solutions)
    num_individuals = length(solutions)
    S = [Int[] for _ in 1:num_individuals]
    n = zeros(Int, num_individuals)
    rank = zeros(Int, num_individuals)
    fronts = Vector{Vector{Int}}()


    front = Int[]

    for p in 1:num_individuals
        for q in 1:num_individuals
            if dominates(solutions[p], solutions[q])
                push!(S[p], q)
            elseif dominates(solutions[q], solutions[p])
                n[p] += 1
            end
        end
        if n[p] == 0
            rank[p] = 1
            push!(front, p)
        end
    end

    push!(fronts, front)

    i = 1
    while !isempty(fronts[i])
        next_front = Int[]
        for p in fronts[i]
            for q in S[p]
                n[q] -= 1
                if n[q] == 0
                    rank[q] = i + 1
                    push!(next_front, q)
                end
            end
        end
        push!(fronts, next_front)
        i += 1
    end

    return fronts[1:end-1], rank
end

function get_dataframes(fronts, ranks, classes, instances)
    rank = maximum(ranks)
    class_counts = Dict((r, Dict(class => 0 for class in classes)) for r in 1:rank)

    classification = []

    for (i, instance) in enumerate(instances)
        for _ in 1:instance
            push!(classification, classes[i])
        end
    end

    for (r, f) in enumerate(fronts)
        for i in f
            class_of_point = classification[i]
            class_counts[r][class_of_point] += 1
        end
    end


    data = []
    for r in 1:rank
        for class in classes
            push!(data, (r, class, class_counts[r][class]))
        end
    end

    df = DataFrame(data, [:Rank, :Class, :Count])
    

    return df

end


function approximately_unique_solutions(solutions; threshold::Float64 = 0.1)::Vector{Vector{Float64}}
    unique_solutions = []
    for i in 1:length(solutions)
        is_unique = true
        for j in 1:length(unique_solutions)
            diff_count = sum(abs.(solutions[i] .- unique_solutions[j]) .> threshold)
            if diff_count < ceil(Int, 0.1)
                is_unique = false
                break
            end
        end
        if is_unique
            push!(unique_solutions, solutions[i])
        end
    end
    return unique_solutions
end