using Test
using Distributed
using Suppressor
import Pkg.TOML as TOML

# The following ENVIRONMENT directory contains a Project.toml file with the following
# dependencies: "Example", and that is all.
const ENVIRONMENT  = joinpath(@__DIR__, "_dummy_environment")

# Anthony's local alternative for debugging:
# const ENVIRONMENT =
#    "/Users/anthony/GoogleDrive/Julia/MLJ/MLJModelRegistry/test/_dummy_environment"

import MLJModelRegistry.GenericRegistry as R

@testset "`GenericRegistry.run` and `GenericRegistry.close`" begin
    n = nprocs()
    @suppress begin

        # bunch of runs:
        # works because no env is specified, so Tables will be added to a temp env:
        future1 = R.run(["Tables",], :(names(Tables)))
        # works because Examples is in the specified env:
        future2 = R.run("Example", :(Example.hello("Julia")); environment=ENVIRONMENT)
        # fails because Example is not listed in specified packages:
        future3 = R.run("Tables", :(using Example))
        # fails because Tables is not in the specified env:
        future4 = R.run(["Tables",], :(names(Tables)), environment=ENVIRONMENT)
        # works because `setup` statement manually adds Tables to the specified env:
        future5 = R.run(
            quote # `setup`
                using Pkg
                Pkg.add("Tables")
            end,
            "Tables",
            quote # main `program`
                outcome = names(Tables)
                Pkg.rm("Tables")
                outcome
            end,
            environment=ENVIRONMENT,
        )

        # fetch and test the outcomes:
        @test issubset([:Tables, :columntable, :rowtable], fetch(future1))
        @test fetch(future2) == "Hello, Julia"
        @test_throws(RemoteException, fetch(future3))
        @test_throws(RemoteException, fetch(future4))
        @test issubset([:Tables, :columntable, :rowtable], fetch(future5))

        # shutdown the `run` processes:
        R.close.([future1, future2, future3, future4, future5])
    end
    @test nprocs() == n
end

@testset "`GenericRegistry.put` and `GenericRegistry.get`" begin
    rm(R.corresponding_metadata(ENVIRONMENT))
    @test isnothing(R.get("Example", ENVIRONMENT))
    @test isnothing(R.get("RoguePkg", ENVIRONMENT))
    @test_throws R.err_invalid_package("RoguePkg") R.put("RoguePkg", "flop", ENVIRONMENT)
    R.put("Example", "popular", ENVIRONMENT)
    @test R.get("Example", ENVIRONMENT) == "popular"
    R.put("Example", "spaghetti", ENVIRONMENT)
    @test R.get("Example", ENVIRONMENT) == "spaghetti"
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
