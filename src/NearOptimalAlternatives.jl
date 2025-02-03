module NearOptimalAlternatives

# Packages

using JuMP
using Distances
using MathOptInterface
using Metaheuristics
using DataStructures


include("results.jl")
include("alternative-optimisation.jl")
include("generate-alternatives.jl")
include("alternative-metaheuristics.jl")
include("metaheuristic-helper-functions.jl")
include("mo-alternative-metaheuristics.jl")
include("test.jl")

end
