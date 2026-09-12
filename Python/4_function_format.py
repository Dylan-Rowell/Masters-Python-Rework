import pandas as pd

trawlers_daily_df = pd.read_csv("Data/trawlers_feature_response.csv")
trawlers_annual_df = pd.read_csv("Data/trawlers_annual.csv")
trawlers_daily_df["docking_date"] = pd.to_datetime(trawlers_daily_df["docking_date"])


effort_columns = [
    "trip_length_dd",
    "number_of_trawls",
    "trawl_length_hh",
    "number_of_drags",
]

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

trawlers_daily_df = trawlers_daily_df.loc[
    :, ~trawlers_daily_df.columns.str.endswith("_response")
].drop(columns=["docking_date_month", "season", "Record"])

trawlers_daily_df.columns = trawlers_daily_df.columns.str.removesuffix("_cumsum")

effort_pattern = "|".join(effort_columns)
fish_pattern = "|".join(fish_columns)

trawlers_fish_df = trawlers_daily_df.loc[
    :, ~trawlers_daily_df.columns.str.contains(effort_pattern)
]
trawlers_effort_df = trawlers_daily_df.loc[
    :, ~trawlers_daily_df.columns.str.contains(fish_pattern)
]

trawlers_fish_long_df = pd.melt(
    trawlers_fish_df,
    id_vars=["docking_date", "docking_date_yy", "vessel_number"],
    var_name="code",
    value_name="cumsum_mass",
)

trawlers_effort_long_df = pd.melt(
    trawlers_effort_df,
    id_vars=["docking_date", "docking_date_yy", "vessel_number"],
    var_name="code",
    value_name="cumsum_total",
)

fish_months = trawlers_fish_long_df["docking_date"].dt.strftime("%m").astype(str)
fish_days = trawlers_fish_long_df["docking_date"].dt.strftime("%d").astype(str)

effort_months = trawlers_effort_long_df["docking_date"].dt.strftime("%m").astype(str)
effort_days = trawlers_effort_long_df["docking_date"].dt.strftime("%d").astype(str)

trawlers_fish_long_df["month_day"] = fish_months.str.cat(fish_days, sep="-")
trawlers_effort_long_df["month_day"] = effort_months.str.cat(effort_days, sep="-")

trawlers_fish_wide = trawlers_fish_long_df.pivot_table(
    index=["docking_date_yy", "vessel_number", "code"],
    columns="month_day",
    values="cumsum_mass",
).reset_index()

trawlers_effort_wide = trawlers_effort_long_df.pivot_table(
    index=["docking_date_yy", "vessel_number", "code"],
    columns="month_day",
    values="cumsum_total",
).reset_index()

trawlers_wide_df = pd.concat([trawlers_fish_wide, trawlers_effort_wide], axis=0)

trawlers_wide_df = trawlers_wide_df.ffill(axis=1)

trawlers_wide_df.to_csv("Data/trawlers_wide.csv", index=False)
