ENV["JULIA_CONDAPKG_BACKEND"] = "Null"   # To handle the pthon installation manually
ENV["JULIA_PYTHONCALL_EXE"] = "python3"  # Configure your python call python binary

using Tibber
using ConfigEnv
cd(@__DIR__)
dotenv()

# TOKEN = ENV["TIBBER_TOKEN"] # Store your token in the environment variable TIBBER_TOKEN, for example, using ConfigEnv.jl and a .env file
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
Tibber.get_primary_heating_source()
Tibber.get_has_ventilation_system()
Tibber.get_main_fuse_size()

using Plots
c = Tibber.fetch_consumption("HOURLY", first=10)
plot(c)

p = Tibber.fetch_priceinfo()
plot(p)