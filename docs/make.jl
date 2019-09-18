using Documenter, EconometricsLH

makedocs(
    modules = [EconometricsLH],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    checkdocs = :exports,
    sitename = "EconometricsLH",
    pages = Any["index.md"]
)

# deploydocs(
#     repo = "github.com/hendri54/EconometricsLH.git",
# )
