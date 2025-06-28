using Test
using Distributed
using Suppressor
import Pkg.TOML as TOML

# The following ENVIRONMENT directory contains a Project.toml file with the following
# dependencies: "Tables", "Example", and "Pkg", and that is all.
const ENVIRONMENT  = joinpath(@__DIR__, "_dummy_environment")

# Anthony's local alternative for debugging:
# const ENVIRONMENT =
#    "/Users/anthony/GoogleDrive/Julia/MLJ/MLJModelRegistry/test/_dummy_environment"

import MLJModelRegistry.GenericRegistry as R

@testset "`GenericRegistry.run` and `GenericRegistry.close`" begin
    n = nprocs()
    @suppress begin

        # invalid list of packages:
        @test_throws(
            R.err_missing_packages(["RoguePkg", "Tables"]),
            R.run(:(nothing), ["RoguePkg", "Tables"], ENVIRONMENT),
        )

        # bunch of runs:
        future1 = R.run(:(names(Tables)), ["Tables",], ENVIRONMENT)
        future2 = R.run(
            :(using Example; hello("Julia")),
            ["Tables", "Pkg"],
            ENVIRONMENT,
        )
        future3 = R.run(:(names(Tables)), ["Tables",])
        future4 = R.run(
            :(using Example; hello("Julia")),
            ["Tables", "Pkg"],
        )

        # fetch and test the outcomes
        @test issubset([:Tables, :columntable, :rowtable], fetch(future1))
        @test fetch(future2) == "Hello, Julia"
        @test issubset([:Tables, :columntable, :rowtable], fetch(future3))
        @test_throws(RemoteException, fetch(future4))

        # shutdown the `run` processes:
        R.close(future1)
        R.close(future2)
        R.close(future3)
        R.close(future4)
    end
    @test nprocs() == n
end

@testset "`GenericRegistry.put` and `GenericRegistry.get`" begin
    rm(R.corresponding_metadata(ENVIRONMENT))
    @test isnothing(R.get("Tables", ENVIRONMENT))
    @test isnothing(R.get("RoguePkg", ENVIRONMENT))
    @test_throws R.err_invalid_package("RoguePkg") R.put("RoguePkg", "flop", ENVIRONMENT)
    R.put("Tables", "popular", ENVIRONMENT)
    @test R.get("Tables", ENVIRONMENT) == "popular"
    R.put("Tables", "spaghetti", ENVIRONMENT)
    @test R.get("Tables", ENVIRONMENT) == "spaghetti"
end

@testset "GenericRegistry.gc" begin
    # manually add a key-value pair to the metadata dictionary for a package not in the
    # project:
    metadata = R.corresponding_metadata(ENVIRONMENT)
    d = TOML.parsefile(metadata)
    d["RoguePkg"] = "flip"
    open(metadata, "w") do file
        TOML.print(file, d)
    end

    # check it's really there:
    d = TOML.parsefile(metadata)
    @assert d["RoguePkg"] == "flip"

    # collect garbage and check it is gone:
    R.gc(ENVIRONMENT)
    d = TOML.parsefile(metadata)
    @test !("RoguePkg" in keys(d))
end

rm(R.corresponding_metadata(ENVIRONMENT))

true
