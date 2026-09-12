# %%

import numpy as np
import pandas as pd

trawlers_df = pd.read_csv("Data/trawlers_daily.csv")
trawlers_df["docking_date"] = pd.to_datetime(trawlers_df["docking_date"])
trawlers_df["docking_date_month"] = trawlers_df["docking_date"].dt.month

fish_columns = [
    "CHOK",
    "CYNZAN",
    "GURN",
    "HAKE",
    "HMKC",
    "KKLP",
    "PANG",
    "RAJIDE",
    "SJSH",
    "ECSOLE",
    "KOB",
    "MONK",
    "RDFS",
    "OCTOP",
    "WSTM",
    "CRPN",
    "GLBK",
    "RSTM",
    "WHST",
    "SFSH",
    "BRDMAN",
    "BTSN",
    "JDRY",
    "MCKR",
    "SNOK",
    "HNSH",
    "DGSH",
    "SEPIA",
    "WRFS",
    "OMMAST",
    "BLHT",
    "APMF",
    "JCPV",
    "WBRBL",
    "MLLT",
    "ELF",
    "BNST",
    "STNT",
    "ROMN",
    "PGGY",
    "SGRN",
    "SNTR",
    "SWFS",
    "TUNA",
]
fish_columns.sort()

effort_columns = [
    "trip_length_dd",
    "number_of_trawls",
    "trawl_length_hh",
    "number_of_drags",
]

# %%
numeric_columns = fish_columns + effort_columns

trawlers_identifiers = trawlers_df.drop(columns=numeric_columns)

trawlers_annual_df = (
    trawlers_df.drop(columns=["docking_date", "season", "Record", "docking_date_month"])
    .groupby(["docking_date_yy", "vessel_number"], as_index=False)
    .agg("sum")
)

trawlers_monthly_df = (
    trawlers_df.drop(columns=["docking_date", "season"])
    .groupby(["docking_date_yy", "vessel_number", "docking_date_month"], as_index=False)
    .agg("sum")
)

# %%
cumsum_values = trawlers_df.groupby(
    ["docking_date_yy", "vessel_number"], as_index=False
)[numeric_columns].transform("cumsum")


end_total_df = pd.merge(
    trawlers_identifiers,
    trawlers_annual_df,
    how="left",
    on=["docking_date_yy", "vessel_number"],
)[numeric_columns]

response_values = end_total_df - cumsum_values
response_values = response_values.add_suffix("_response")
cumsum_values = cumsum_values.add_suffix("_cumsum")

exp_1 = response_values.head(25)
exp_2 = cumsum_values.head(25)
exp_3 = end_total_df.head(25)

trawlers_complete_df = pd.concat(
    [trawlers_identifiers, cumsum_values, response_values], axis=1
)

# %%
months = trawlers_complete_df["docking_date_month"]

conditions = [
    months.isin([1, 2, 3]),
    months.isin([4, 5, 6]),
    months.isin([7, 8, 9]),
    months.isin([10, 11, 12]),
]
choices = ["summer", "autumn", "winter", "spring"]

trawlers_complete_df["season"] = np.select(conditions, choices, default="unknown")

trawlers_annual_df.to_csv("Data/trawlers_annual.csv", index=False)
trawlers_monthly_df.to_csv("Data/trawlers_monthly.csv", index=False)
trawlers_complete_df.to_csv("Data/trawlers_feature_response.csv", index=False)
