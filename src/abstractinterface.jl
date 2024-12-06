# Get the interface of an object.
interface(x) = interface(typeof(x))
# TODO: Define as `DefaultInterface()`.
interface(::Type) = error("Interface unknown.")

# Adapted from `Base.Broadcast.combine_styles`.
# Get the combined interfaces of the input objects.
function combine_interfaces(x1, x2, x_rest...)
  return combine_interfaces(combine_interfaces(x1, x2), x_rest...)
end
combine_interfaces(x1, x2) = combine_interface_rule(interface(x1), interface(x2))
combine_interfaces(x) = interface(x)

# Rules for combining interfaces.
function combine_interface_rule(
  interface1::Interface, interface2::Interface
) where {Interface}
  return interface1
end
# TODO: Define as `UnknownInterface()`.
combine_interface_rule(interface1, interface2) = error("No rule for combining interfaces.")

abstract type AbstractInterface end

(interface::AbstractInterface)(f) = InterfaceFunction(interface, f)
