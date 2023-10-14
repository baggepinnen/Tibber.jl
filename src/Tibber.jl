"""
Initialize using
```julia
using Tibber
Tibber.account!(TIBBER_TOKEN::String)
Tibber.home!()
```
You can get your Tibber API token from https://developer.tibber.com/settings/access-token
"""
module Tibber

using PythonCall
using Comonicon
using Dates
using Printf
using RecipesBase

const tibber = Ref(Py(nothing))
const account = Ref(Py(nothing))
const home = Ref(Py(nothing))

function __init__()
    tibber[] = pyimport("tibber")
end


"""
    account!(token; tibber)

Set your Tibber API token. You can get it from https://developer.tibber.com/settings/access-token
"""
function account!(token; tibber=tibber[])
    account[] = tibber.Account(token)
end

"""
    home!(ind::Int = 0; account)

Set the default home to the `ind`th home in the account. Defaults to the first home (python-style zero-based indexing).
"""
function home!(ind::Int = 0; account = account[])
    home[] = account.homes[ind]
end


function get_id(; home = home[])
    pyconvert(Any, home.id)
end
function get_time_zone(; home = home[])
    pyconvert(Any, home.time_zone)
end
function get_app_nickname(; home = home[])
    pyconvert(Any, home.app_nickname)
end
function get_app_avatar(; home = home[])
    pyconvert(Any, home.app_avatar)
end
function get_size(; home = home[])
    pyconvert(Any, home.size)
end
function get_type(; home = home[])
    pyconvert(Any, home.type)
end
function get_number_of_residents(; home = home[])
    pyconvert(Any, home.number_of_residents)
end
function get_primary_heating_source(; home = home[])
    pyconvert(Any, home.primary_heating_source)
end
function get_has_ventilation_system(; home = home[])
    pyconvert(Any, home.has_ventilation_system)
end
function get_main_fuse_size(; home = home[])
    pyconvert(Any, home.main_fuse_size)
end



# ==============================================================================
## Consumption
# ==============================================================================


"""
    ConsumptionData2

A struct containing consumption data.

# Fields:
- `from_time::DateTime`
- `to_time::DateTime`
- `unit_price::Float64`
- `currency::String`
- `consumption::Float64`
- `cost::Float64`
"""
struct ConsumptionData2
    from_time::DateTime
    to_time::DateTime
    unit_price
    currency::String
    consumption
    cost
end

function Base.show(io::IO, d::ConsumptionData2)
    println(io, "ConsumptionData2(")
    @printf(io, "  %-15s= %-20s\n", "from_time", d.from_time)
    @printf(io, "  %-15s= %-20s\n", "to_time", d.to_time)
    @printf(io, "  %-15s= %-20s\n", "unit_price", d.unit_price)
    @printf(io, "  %-15s= %-20s\n", "currency", d.currency)
    @printf(io, "  %-15s= %-20s\n", "consumption", d.consumption)
    @printf(io, "  %-15s= %-20s\n", "cost", d.cost)
    print(io, ")")
end



"""
    fetch_consumption(when = "HOURLY"; first = nothing, last = nothing, home)

Fetch historical consumption data. Returns an array of `ConsumptionData2` objects.

# Arguments:
- `when`: Options include `"HOURLY"`, `"DAILY"`, `"MONTHLY"`, `"YEARLY"`
- `first`: A number of periods to fetch, e.g. `first=3` will fetch the first 3 periods available
- `last`: A number of periods to fetch, e.g. `last=3` will fetch the last 3 periods available
- `home`: Optionally override the default home.
"""
function fetch_consumption(when = "HOURLY"; first = nothing, last = nothing, home = home[])
    data = home.fetch_consumption(when; first, last)
    map(data) do d
        from_time = pyconvert(String, d.from_time)
        to_time = pyconvert(String, d.to_time)
        unit_price = pyconvert(Union{Nothing, Float64}, d.unit_price)
        currency = pyconvert(String, d.currency)
        consumption = pyconvert(Union{Nothing, Float64}, d.consumption)
        cost = pyconvert(Union{Nothing, Float64}, d.cost)
        from_time = DateTime(from_time[1:19], dateformat"Y-m-dTH:M:S")
        to_time = DateTime(to_time[1:19], dateformat"Y-m-dTH:M:S")
        ConsumptionData2(from_time, to_time, unit_price, currency, consumption, cost)
    end
end

function _prep(x)
    y = replace(x, nothing => missing)
    repeat(y, inner=2)
end

@recipe function plot(data::Vector{ConsumptionData2})
    starttimes = getproperty.(data, :from_time)
    endtimes = getproperty.(data, :to_time)
    xrotation --> 45
    # seriestype --> :steppost
    layout --> (3,1)
    legend --> false
    size --> (800,800)
    # link --> :x
    xdata = [permutedims(starttimes); permutedims(endtimes)][:]
    hover --> xdata
    @series begin
        xticks --> false
        ylabel --> "Consumption"
        xdata, _prep(getproperty.(data, :consumption))
    end
    @series begin
        xticks --> false
        ylabel --> "Cost ($(data[1].currency))"
        xdata, _prep(getproperty.(data, :cost))
    end
    @series begin
        ylabel --> "Unit price ($(data[1].currency))"
        xticks --> round(xdata[1], Hour):Hour(2):xdata[end]
        xdata, _prep(getproperty.(data, :unit_price))
    end
end



# ==============================================================================
## Price info
# ==============================================================================

struct PriceInfo
    start_time::DateTime
    total::Float64
    energy::Float64
    tax::Float64
    currency::String
    level::String
end

function PriceInfo(t)
    start_time = pyconvert(String, t["startsAt"])
    total = pyconvert(Float64, t["total"])
    energy = pyconvert(Float64, t["energy"])
    tax = pyconvert(Float64, t["tax"])
    currency = pyconvert(String, t["currency"])
    level = pyconvert(String, t["level"])
    start_time = DateTime(start_time[1:19], dateformat"Y-m-dTH:M:S")
    PriceInfo(start_time, total, energy, tax, currency, level)
end

function fetch_priceinfo(; home = home[])
    i = pyconvert(Dict, home.cache)
    today = i["currentSubscription"]["priceInfo"]["today"]
    tomorrow = i["currentSubscription"]["priceInfo"]["tomorrow"]

    today = map(PriceInfo, today)
    tomorrow = map(PriceInfo, tomorrow)
    [today; tomorrow]
end

@recipe function plot(data::Vector{PriceInfo})
    starttimes = getproperty.(data, :start_time)
    endtimes = starttimes + Hour(1)
    xrotation --> 45

    legend --> false
    size --> (800,800)
    # link --> :x
    xdata = [permutedims(starttimes); permutedims(endtimes)][:]
    hover --> xdata
    @series begin
        xticks --> round(xdata[1], Hour):Hour(2):xdata[end]
        ylabel --> "Total price ($(data[1].currency))"
        xdata, _prep(getproperty.(data, :total))
    end
end

end

