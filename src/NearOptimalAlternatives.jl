module NearOptimalAlternatives

# Packages

using JuMP
using Distances
using MathOptInterface
using Metaheuristics
using DataStructures

include("MGA-Methods/Max-Distance.jl")
include("MGA-Methods/HSJ.jl")
include("MGA-Methods/Spores.jl")

include("results.jl")
include("alternative-optimisation.jl")
include("generate-alternatives.jl")
include("alternative-metaheuristics.jl")



end
