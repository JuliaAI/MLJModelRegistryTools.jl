using Test

test_files = [
    "setpath.jl",
    "GenericRegistry.jl",
    "remote_methods.jl",
    "methods.jl",
]

files = isempty(ARGS) ? test_files : ARGS

for file in files
    quote
        @testset $file begin
            include($file)
        end
    end |> eval
end
