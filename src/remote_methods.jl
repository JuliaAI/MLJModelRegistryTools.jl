# Remote methods are methods called on remote processes for the purpose of when extacting
# model metadata for a package


# # HELPERS

function finaltypes(T::Type)
    s = InteractiveUtils.subtypes(T)
    if isempty(s)
        return [T, ]
    else
        return reduce(vcat, [finaltypes(S) for S in s])
    end
end

"""
    model_type_given_constructor(modeltypes)

**Private method.**

Return a dictionary of `modeltypes`, keyed on constructor. Where multiple types share a
single constructor, there can only be one value (and which value appears is not
predictable).

Typically a model type and it's constructor have the same name, but for wrappers, such as
`TunedModel`, several types share the same constructor (e.g., `DeterministicTunedModel`,
`ProbabilisticTunedModel` are model types sharing constructor `TunedModel`).

"""
function modeltype_given_constructor(modeltypes)

    # Note that wrappers are required to overload `MLJModelInterface.constructor` and the
    # fallback is `nothing`.

    return Dict(
        map(modeltypes) do M
            C =  MLJModelInterface.constructor(M)
            Pair(isnothing(C) ? M : C, M)
        end...,
    )
end

"""
    encode_dic(d)

Convert an arbitrary nested dictionary `d` into a nested dictionary whose leaf values are
all strings, suitable for writing to a TOML file (a poor man's serialization). The rules
for converting leaves are:

1. If it's a `Symbol`, preserve the colon, as in :x -> ":x".

2. If it's an `AbstractString`, apply `string` function (e.g, to remove `SubString`s).

3. In all other cases, except `AbstractArray`s, first wrap in single quotes, as in sum -> "\`sum\`".

4. Replace any `#` character in the application of Rule 3 with `_` (to handle `gensym` names)

5. For an `AbstractVector`, broadcast the preceding Rules over its elements.

"""
function encode_dic(s)
    prestring = string("`", s, "`")
    # hack for objects with gensyms in their string representation:
    str = replace(prestring, '#'=>'_')
    return str
end
encode_dic(s::Symbol) = string(":", s)
encode_dic(s::AbstractString) = string(s)
encode_dic(v::AbstractVector) = encode_dic.(v)
function encode_dic(d::AbstractDict)
    ret = LittleDict{}()
    for (k, v) in d
        ret[encode_dic(k)] = encode_dic(v)
    end
    return ret
end

api_pkg(M) = split(MLJModelInterface.load_path(M), '.') |> first


# # REMOTE METHODS

"""
    MLJModelRegistryTools.traits_given_constructor_name(pkg; check_traits=true)

Build and return a dictionary of model metadata as follows: The keys consist of the names
of constructors of any `model` object subtyping `MLJModelInterface.Model` wherever the
package providing the model implementation (assumed to be imported) is `pkg`. This is the
package appearing as the root of `MLJModelInterface.load_path(model)`. The values are
corresponding dictionaries of traits, keyed on trait name.

Poor man's serialization, as provided by [`MLJRegistry.encode_dic`)(@ref), is applied to
the dictionary, to make it suitable for writing to TOML files.

Also, apply smoke tests to the associated trait definitions, assuming `check_traits=true`.

"""
function traits_given_constructor_name(pkg; check_traits=true)

    # Some explanation for the gymnamstics going on here: The model registry is actually
    # keyed on constructor names, not model type names, a change from the way the registry
    # was initially set up. These are usually the same, but wrappers frequently provide
    # exceptions; e.g., "TunedModel" is a constructor for two model types
    # "ProbabilisticTunedModel" and "DeterministicTunedModel". Unfortunately, what is easy
    # to grab are the model type names (we look for subtypes of `Model`) and we get the
    # constructors after, through the `constructor` trait. Only one

    modeltypes = filter(finaltypes(MLJModelInterface.Model)) do M
        !(isabstracttype(M)) && api_pkg(M) == pkg
    end
    modeltype_given_constructor = MLJModelRegistryTools.modeltype_given_constructor(modeltypes)
    constructors = keys(modeltype_given_constructor) |> collect
    sort!(constructors, by=string)
    traits_given_constructor_name = Dict{String,Any}()

    for C in constructors
        M = modeltype_given_constructor[C]
        check_traits && MLJModelRegistryTools.check_traits(M)
        constructor_name = split(string(C), '.') |> last
        traits = LittleDict{Symbol,Any}(trait => eval(:(MLJModelInterface.$trait))(M)
                                        for trait in MLJModelInterface.MODEL_TRAITS)
        traits[:name] = constructor_name
        traits_given_constructor_name[constructor_name] = traits
    end

    return encode_dic(traits_given_constructor_name)
end
