module NearOptimalAlternatives

# Packages

using JuMP
using Distances
using MathOptInterface
using Metaheuristics
using Heuristics
using DataStructures


include("results.jl")
include("generate-alternatives.jl")
include("alternative-metaheuristics.jl")
include("metaheuristic-helper-functions.jl")
include("mo-alternative-metaheuristics.jl")


# algortihm to include
include("MGA/Distances.jl")
include("MGA/HSJ.jl")
include("MGA/Spores.jl")
include("MGA/random-vector.jl")
include("MGA/MinMax.jl")

include("experiments.jl")

# include("test.jl")

end
