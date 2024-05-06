using MGA
using Test
using SCIP
using JuMP

for file in readdir(@__DIR__)
  if !startswith("test-")(file)
    continue
  end
  include(file)
end
