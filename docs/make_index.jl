using Literate: Literate
using Derive: Derive

Literate.markdown(
  joinpath(pkgdir(Derive), "examples", "README.jl"),
  joinpath(pkgdir(Derive), "docs", "src");
  flavor=Literate.DocumenterFlavor(),
  name="index",
)
