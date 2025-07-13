using Test
using MLJModelRegistry

@testset "setters and getters for registry path" begin
    @test_throws(
        MLJModelRegistry.ERR_REGISTRY_PATH,
        MLJModelRegistry.registry_path(),
    )
    setpath("google boogle")
    @test MLJModelRegistry.registry_path() == "google boogle"
    setpath("")
end
