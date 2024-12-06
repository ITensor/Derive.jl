using Derive: Derive
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(Derive, :DocTestSetup, :(using Derive); recursive=true)

include("make_index.jl")

makedocs(;
  modules=[Derive],
  authors="ITensor developers <support@itensor.org> and contributors",
  sitename="Derive.jl",
  format=Documenter.HTML(;
    canonical="https://ITensor.github.io/Derive.jl", edit_link="main", assets=String[]
  ),
  pages=["Home" => "index.md"],
)

deploydocs(; repo="github.com/ITensor/Derive.jl", devbranch="main", push_preview=true)
