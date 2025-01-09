using Literate: Literate
using DerivableInterfaces: DerivableInterfaces

Literate.markdown(
  joinpath(pkgdir(DerivableInterfaces), "examples", "README.jl"),
  joinpath(pkgdir(DerivableInterfaces), "docs", "src");
  flavor=Literate.DocumenterFlavor(),
  name="index",
)
