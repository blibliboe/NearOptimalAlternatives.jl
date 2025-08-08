module NearOptimalAlternatives

# Packages

using JuMP
using Distances
using MathOptInterface
using Metaheuristics
using Heuristics
using StatsPlots
using DataStructures
using DataFrames
using CategoricalArrays

include("results.jl")
include("generate-alternatives.jl")
include("alternative-metaheuristics.jl")
include("metaheuristic-helper-functions.jl")
include("mo-alternative-metaheuristics.jl")

# the dominating algorithm
include("dominating.jl")


# algortihm to include
include("MGA/Distances.jl")
include("MGA/HSJ.jl")
include("MGA/Spores.jl")
include("MGA/random-vector.jl")
include("MGA/MinMax.jl")
include("MGA/DomVec.jl")
include("MGA/ExpVec.jl")
include("MGA/MGA.jl")

# include("experiments.jl")

end
