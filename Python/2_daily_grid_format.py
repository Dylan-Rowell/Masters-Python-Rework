import pandas as pd

trawlers_df = pd.read_csv("Data/trawlers_basic.csv")

trawlers_df["docking_date"] = pd.to_datetime(
    trawlers_df["docking_date"], format="%Y-%m-%d", exact=False
)

vessel_no_series = pd.Series(trawlers_df["vessel_number"].unique())
vessel_no_series.name = "vessel_number"

date_series = pd.Series(pd.date_range(start="1990-01-01", end="2019-12-31", freq="D"))
date_series.name = "docking_date"

date_vessel_number = pd.merge(date_series, vessel_no_series, how="cross")
date_vessel_number["docking_date_yy"] = date_vessel_number["docking_date"].dt.year

trawlers_daily_df = (
    pd.merge(
        date_vessel_number,
        trawlers_df,
        how="left",
        on=["docking_date", "vessel_number", "docking_date_yy"],
    )
    .sort_values(by=["vessel_number", "docking_date"])
    .fillna(0)
    .drop(columns=["land_ID", "sailing_date", "company_number"])
)

print(trawlers_daily_df.duplicated().sum())

print(len(trawlers_daily_df))
print(trawlers_daily_df["docking_date"].nunique())
print(22 * trawlers_daily_df["docking_date"].nunique())

print(trawlers_daily_df[["docking_date", "vessel_number"]].duplicated().sum())

print(
    trawlers_daily_df[
        trawlers_daily_df[["docking_date", "vessel_number"]].duplicated(keep=False)
    ]
)

trawlers_daily_df = trawlers_daily_df.groupby(
    ["docking_date", "vessel_number"], as_index=False
).agg("max")

trawlers_daily_df.to_csv("Data/trawlers_daily.csv", index=False)
