using MGA
using Documenter

DocMeta.setdocmeta!(MGA, :DocTestSetup, :(using MGA); recursive = true)

makedocs(;
  modules = [MGA],
  doctest = true,
  linkcheck = true,
  authors = "Matthijs Arnoldus <m.arnoldus-1@tudelft.nl> and contributors",
  repo = "https://github.com/TulipaEnergy/MGA.jl/blob/{commit}{path}#{line}",
  sitename = "MGA.jl",
  format = Documenter.HTML(;
    prettyurls = get(ENV, "CI", "false") == "true",
    canonical = "https://TulipaEnergy.github.io/MGA.jl",
    assets = ["assets/style.css"],
  ),
  pages = [
    "Home" => "index.md",
    "Contributing" => "contributing.md",
    "Dev setup" => "developer.md",
    "Reference" => "reference.md",
  ],
)

deploydocs(; repo = "github.com/TulipaEnergy/MGA.jl", push_preview = true)
