using Test
using MLJModelRegistry
using MLJModels
using MLJModels.MLJModelInterface
using Random
import Pkg.TOML as TOML

import MLJModelRegistry.encode_dic

@testset "finaltypes" begin
    types = MLJModelRegistry.finaltypes(Integer)
    @test UInt8 in types
    @test !(Signed in types)
end

scratch_space = joinpath(tempdir(), randstring(20))
mkdir(scratch_space)
toml = joinpath(scratch_space, "dictionary.toml")

@testset "`encode_dic` is compatible with `MLJModels.decode_dic" begin
    d = Dict()
    d[:test] = Tuple{Union{Continuous,Missing},Finite}
    d["junk"] = Dict{Any,Any}("H" => Missing, :cross => "lemon",
                              :t => :w, "r" => "r",
                              "tuple" =>(nothing, Float64),
                              "vector" =>[1, 2, Int])
    d["a"] = "b"
    d[:f] = true
    d["j"] = :post
    open(toml, "w") do file
        TOML.print(file, encode_dic(d))
    end
    d2 = TOML.parsefile(toml)
    @test MLJModels.decode_dic(d2) == d
end

struct Dummy <: MLJModelInterface.Unsupervised end
pkg = parentmodule(Dummy) |> string
MLJModelInterface.load_path(::Type{<:Dummy}) = "$pkg.Dummy"

@testset "traits_given_constructor_name" begin
    d = MLJModelRegistry.traits_given_constructor_name(pkg; check_traits=false)
    traits = d["Dummy"]
    @test traits[":human_name"] == "dummy"
    # check that `check_traits=true` works:
    @test_logs(
        (:error, ),
        @test_throws(
            MLJModelRegistry.err_bad_trait(Dummy),
            MLJModelRegistry.traits_given_constructor_name(pkg)
        ),
    )
end

true
