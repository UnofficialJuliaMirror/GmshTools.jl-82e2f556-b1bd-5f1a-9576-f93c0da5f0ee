using BinaryProvider

const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))

products = Product[
    LibraryProduct(prefix, "libgmsh", :libgmsh),
]

bin_prefix = "http://gmsh.info/bin"
version = "4.4.1"

download_info = Dict(
    Linux(:x86_64, :glibc) => ("$bin_prefix/Linux/gmsh-4.2.2-Linux64-sdk.tgz", "ea6a6d36da41b9e777111e055c416ffe994d57c7e3debf174b98e4c09b3b33d7"),
    Windows(:x86_64) => ("$bin_prefix/Windows/gmsh-$version-Windows64-sdk.zip", "094207b56e23e462f2e11ffc2d7006f88c641b62fa9d01522f731dcf00e321a9"),
    MacOS(:x86_64) => ("$bin_prefix/MacOSX/gmsh-$version-MacOSX-sdk.tgz", "40c13c22f0bff840fc827e5f4530668b2818c1472593370ebf302555df498f9e"),
)

if haskey(ENV, "GMSH_LIB_PATH")
    products = Product[
        LibraryProduct(ENV["GMSH_LIB_PATH"], "libgmsh", :libgmsh),
    ]
    write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
else
    if any(!satisfied(p; verbose=verbose) for p in products)
        # `satisfied` will cause segment fault on linux if `libgmsh` is pre-existing
        try
            # Download and install binaries
            url, tarball_hash = choose_download(download_info)
            try
                install(url, tarball_hash; prefix=prefix, force=true, verbose=true)
            catch e
                # cannot list content of .zip, manually unzip
                tarball_path = joinpath(prefix, "downloads", basename(url))
                run(pipeline(`unzip $(tarball_path) -d $(prefix.path)`))
            end

            # strip the top directory
            content_path = joinpath(prefix, splitext(basename(url))[1])
            foreach(
                (x) -> mv(joinpath(content_path, x), joinpath(prefix, x); force=true),
                readdir(content_path)
                )
            rm(content_path; force=true, recursive=true)
        catch e
            if typeof(e) <: ArgumentError
                error("Your platform $(Sys.MACHINE) is not supported by this package!")
            else
                rethrow(e)
            end
        end
    end
    write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
end
