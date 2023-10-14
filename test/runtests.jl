@show get(ENV, "CI", false)

if get(ENV, "CI", false) == "true"
    using CondaPkg
    CondaPkg.add("tibber.py")
else
    ENV["JULIA_CONDAPKG_BACKEND"] = "Null"   # To handle the python installation manually
    ENV["JULIA_PYTHONCALL_EXE"] = "python3"  # Configure your python call python binary
end


using Tibber
using Test
using Plots

@testset "Tibber.jl" begin

    TOKEN = Tibber.tibber[].DEMO_TOKEN # We use a demo token here for demonstration purposes
    Tibber.account!(TOKEN)
    Tibber.home!()

    Tibber.get_id()
    Tibber.get_time_zone()
    Tibber.get_app_nickname()
    Tibber.get_app_avatar()
    Tibber.get_size()
    Tibber.get_type()
    Tibber.get_number_of_residents()
    @test Tibber.get_primary_heating_source() == "GROUND"
    @test !Tibber.get_has_ventilation_system()
    @test Tibber.get_main_fuse_size() == 25

    
    c = Tibber.fetch_consumption("HOURLY", first=10)
    plot(c)

    p = Tibber.fetch_priceinfo()
    plot(p)
end
