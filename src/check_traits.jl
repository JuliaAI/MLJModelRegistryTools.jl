# TODO: This method should live at MLJModelInterface !

ismissing_or_isa(x, T) = ismissing(x) || x isa T

function check_traits(M)
    message = "$M has a bad trait declaration.\n"
    ismissing_or_isa(MLJModelInterface.is_pure_julia(M), Bool) ||
        error(message*"`is_pure_julia` must return true or false")
    ismissing_or_isa(MLJModelInterface.supports_weights(M), Bool) ||
        error(message*"`supports_weights` must return `true`, "*
        "`false` or `missing`. ")
    ismissing_or_isa(MLJModelInterface.supports_class_weights(M), Bool) ||
        error(message*"`supports_class_weights` must return `true`, "*
            "`false` or `missing`. ")
    MLJModelInterface.is_wrapper(M) isa Bool ||
        error(message*"`is_wrapper` must return `true` or `false`. ")
    load_path = MLJModelInterface.load_path(M)
    load_path isa String ||
        error(message*"`load_path` must return a `String`. ")
    contains(load_path, "unknown") &&
        error(message*"`load_path` return value contains string \"unknown\". ")
    pkg = MLJModelInterface.package_name(M)
    pkg isa String || error(message*"`package_name` must return a `String`. ")
    api_pkg = split(load_path, '.') |> first
    pkg == "unknown" && error(message*"`package_name` returns \"unknown\". ")
    load_path_ex = Meta.parse(load_path)
    api_pkg_ex = Symbol(api_pkg)
    import_ex = :(import $api_pkg_ex)
    program_to_test_load_path = quote
        $import_ex
        $load_path_ex
    end
    try
        Main.eval(program_to_test_load_path)
    catch excptn
        error(message*"Cannot import value of `load_path` (parsed as expression). ")
        rethrow(excptn)
    end
end
