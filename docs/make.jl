Pkg.activate("./docs");

using Documenter, EconometricsLH, FilesLH

makedocs(
    modules = [EconometricsLH],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    checkdocs = :exports,
    sitename = "EconometricsLH",
    pages = Any["index.md"]
)

pkgDir = rstrip(normpath(@__DIR__, ".."), '/');
@assert endswith(pkgDir, "EconometricsLH")
deploy_docs(pkgDir);

Pkg.activate(".");

# deploydocs(
#     repo = "github.com/hendri54/EconometricsLH.git",
# )
