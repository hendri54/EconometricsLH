using Documenter, EconometricsLH

makedocs(
    modules = [EconometricsLH],
    format = :html,
    checkdocs = :exports,
    sitename = "EconometricsLH.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/hendri54/EconometricsLH.jl.git",
)
