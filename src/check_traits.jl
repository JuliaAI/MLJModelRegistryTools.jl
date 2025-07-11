# # LOGGING

err_bad_trait(M) = ErrorException("$M has a bad trait declaration. ")
function err_bad_trait(M, message)
    @error message
    throw(err_bad_trait(M))
end

# # HELPERS

ismissing_or_isa(x, T) = ismissing(x) || x isa T


# # METHOD TO CHECK TRAITS

function check_traits(M)
    if !ismissing_or_isa(MLJModelInterface.is_pure_julia(M), Bool)
        err_bad_trait(M, "`is_pure_julia` must return true or false")
    end
    if !ismissing_or_isa(MLJModelInterface.supports_weights(M), Bool)
        err_bad_trait(M, "`supports_weights` must return `true`, "*
            "`false` or `missing`. ")
    end
    if !ismissing_or_isa(MLJModelInterface.supports_class_weights(M), Bool)
        err_bad_trait(M, "`supports_class_weights` must return `true`, "*
            "`false` or `missing`. ")
    end
    if !(MLJModelInterface.is_wrapper(M) isa Bool)
        err_bad_trait(M, "`is_wrapper` must return `true` or `false`. ")
    end
    load_path = MLJModelInterface.load_path(M)
    load_path isa String ||
        err_bad_trait(M, "`load_path` must return a `String`. ")
    contains(load_path, "unknown") &&
        err_bad_trait(M, "`load_path` return value contains string \"unknown\". ")
    pkg = MLJModelInterface.package_name(M)
    pkg isa String || err_bad_trait(M, "`package_name` must return a `String`. ")
    api_pkg = split(load_path, '.') |> first
    pkg == "unknown" && err_bad_trait(M, "`package_name` returns \"unknown\". ")
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
        err_bad_trait(M, "Cannot import value of `load_path` (parsed as expression). ")
        rethrow(excptn)
    end
end
