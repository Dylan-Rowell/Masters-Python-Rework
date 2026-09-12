# %%

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

trawlers_annual_df = pd.read_csv("Data/trawlers_annual.csv")
trawlers_monthly_df = pd.read_csv("Data/trawlers_monthly.csv")
trawlers_complete_df = pd.read_csv("Data/trawlers_feature_response.csv")
explorer = trawlers_complete_df.head(25)

trawlers_complete_df["vessel_year"] = (
    trawlers_complete_df["vessel_number"]
    .astype(str)
    .str.cat(trawlers_complete_df["docking_date_yy"].astype(str), sep="_")
)
trawlers_monthly_df["vessel_year"] = (
    trawlers_monthly_df["vessel_number"]
    .astype(str)
    .str.cat(trawlers_monthly_df["docking_date_yy"].astype(str), sep="_")
)
trawlers_annual_df["vessel_year"] = (
    trawlers_annual_df["vessel_number"]
    .astype(str)
    .str.cat(trawlers_annual_df["docking_date_yy"].astype(str), sep="_")
)


# %%
sns.histplot(data=trawlers_annual_df, x="trip_length_dd")
plt.show()

viable_obs = trawlers_annual_df.loc[
    trawlers_annual_df["trip_length_dd"] >= 50,
    ["vessel_year", "trip_length_dd"],
]
sns.histplot(data=viable_obs, x="trip_length_dd")
plt.show()


# %%
trawlers_complete_df = trawlers_complete_df[
    trawlers_complete_df["vessel_year"].isin(viable_obs["vessel_year"])
]
trawlers_monthly_df = trawlers_monthly_df[
    trawlers_monthly_df["vessel_year"].isin(viable_obs["vessel_year"])
]
trawlers_annual_df = trawlers_annual_df[
    trawlers_annual_df["vessel_year"].isin(viable_obs["vessel_year"])
]

# %%
sns.displot(
    data=trawlers_complete_df, x="KOB_response", kind="hist", col="season", col_wrap=2
)
sns.displot(
    data=trawlers_complete_df,
    x="ECSOLE_response",
    kind="hist",
    col="season",
    col_wrap=2,
)

# %%
sns.lineplot(
    x="docking_date_month",
    y="KOB_cumsum",
    data=trawlers_complete_df,
    hue="vessel_number",
)

# %%
sns.lineplot(
    x="docking_date_month",
    y="KOB_cumsum",
    data=trawlers_complete_df,
    hue="docking_date_yy",
)

# %%
