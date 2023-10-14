ENV["JULIA_CONDAPKG_BACKEND"] = "Null"
ENV["JULIA_PYTHONCALL_EXE"] = "python3"

using Tibber
using ConfigEnv
cd(@__DIR__)
dotenv()
TOKEN = ENV["TIBBER_TOKEN"]
# using Tibber.PythonCall
# using Tibber: home



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

Tibber.fetch_consumption("HOURLY", first=10)