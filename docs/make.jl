using DerivableInterfaces: DerivableInterfaces
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(
  DerivableInterfaces, :DocTestSetup, :(using DerivableInterfaces); recursive=true
)

include("make_index.jl")

makedocs(;
  modules=[DerivableInterfaces],
  authors="ITensor developers <support@itensor.org> and contributors",
  sitename="DerivableInterfaces.jl",
  format=Documenter.HTML(;
    canonical="https://ITensor.github.io/DerivableInterfaces.jl",
    edit_link="main",
    assets=String[],
  ),
  pages=["Home" => "index.md"],
)

deploydocs(;
  repo="github.com/ITensor/DerivableInterfaces.jl", devbranch="main", push_preview=true
)
