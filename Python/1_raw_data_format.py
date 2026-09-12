import pandas as pd

landings_df = pd.read_excel("Data/InshoreTrawlLandingsReduced.xlsx", sheet_name=2)

effort_df = pd.read_excel("Data/InshoreTrawlLandingsReduced.xlsx", sheet_name=3)

landings_wide_df = landings_df.pivot_table(
    index="land_ID", columns="species_code", values="nominal_mass", fill_value=0
).reset_index()

trawlers_full = pd.merge(landings_wide_df, effort_df, how="inner", on="land_ID")

trawlers_full.to_csv("Data/trawlers_basic.csv", index=False)
