module MGA

# Packages

using JuMP
using Distances
using MathOptInterface

include("results.jl")
include("alternative-optimisation.jl")
include("generate-alternatives.jl")

end
