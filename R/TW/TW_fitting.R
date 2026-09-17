
load("_RData/final_model_results.RData")
set.seed(500)

chosen_species <- "KOB"

source("R/shared_functions.R") # Fetch the other functions
source("R/TW/TW_functions.R")

trawlers_df <- read.csv("Data/trawlers_feature_response.csv")
trawlers_df["vessel_year"] <- paste(trawlers_df[,"vessel_number"], trawlers_df[,"docking_date_yy"], sep = "_")

# #-----------------#
# 1) Formula Definition
# #-----------------#
TW_explanatory_variables <- c("ECSOLE_cumsum", "HAKE_cumsum", "trip_length_dd_response", "docking_date_month", "docking_date_yy", "vessel_number")
chosen_species_expl_str <- paste0(chosen_species, "_cumsum")

if(any(TW_explanatory_variables == chosen_species_expl_str)){
  TW_explanatory_variables <- TW_explanatory_variables[!TW_explanatory_variables %in% chosen_species_expl_str]
}

TW_explanatory_variables <- c(chosen_species, TW_explanatory_variables)

response_string <- paste0(chosen_species, "_response")
explanatory_string <- paste0(TW_explanatory_variables, collapse = "+")

gam_form <- as.formula(paste0(response_string, "~", explanatory_string,
                              '+ s(vessel_year, bs = "re")',
                              '+ s(vessel_number, bs = "re")'))



## Train
X_predict_train <- (
  cbind(catch_train_sample[,c(chosen_species, 
                              TW_explanatory_variables)]))

## Catch Train
Y_response_train <- (
  cbind(catch_train_sample[,response_string]))

TW_data_train <- data.frame(X_predict_train, Y_response_train)
TW_data_train$vessel_number <- as.factor(data.frame(X_predict_train)$vessel_number)
TW_data_train$vessel_year <- as.factor(data.frame(X_predict_train)$vessel_year)
TW_data_train$docking_date_year <- as.numeric(data.frame(X_predict_train)$docking_date_year)


# #-----------------#
# 4) EDA
# #-----------------#



names(catch_train_sample)

plot(unlist(log(catch_train_sample[,response_string]+0.001)) ~ unlist(catch_train_sample[,"days_remaining"]), 
     xlab = "days_remaining",
     ylab = response_string,
     col = catch_train_sample$prediction_date_month,
     pch = as.numeric(catch_train_sample$season))

plot(unlist(log(catch_train_sample[,response_string]+0.001)) ~ unlist(catch_train_sample[,chosen_species]), 
     xlab = chosen_species,
     ylab = response_string,
     col = catch_train_sample$prediction_date_month,
     pch = as.numeric(catch_train_sample$season))

plot(unlist(log(catch_train_sample[,response_string]+0.001)) ~ unlist(catch_train_sample[,"trip_length_dd_response"]), 
     xlab = "trip_length_dd_response",
     ylab = response_string,
     col = catch_train_sample$prediction_date_month,
     pch = as.numeric(catch_train_sample$season))

plot(unlist(log(catch_train_sample[,response_string]+0.001)) ~ unlist(catch_train_sample[,"docking_date_year"]), 
     xlab = "docking_date_year",
     ylab = response_string,
     col = catch_train_sample$prediction_date_month,
     pch = as.numeric(catch_train_sample$season))

# #-----------------#
# 5) Training
# #-----------------#


species_string <- paste0("s(",chosen_species,",bs='cr', k = 3)")

explanatory_string <- paste(species_string, "ECSOLE", "HAKE", 
                            "trip_length_dd_response", "docking_date_year",
                            "s(days_remaining,bs='cr', k = 3)",
                            's(vessel_year, bs = "re")',
                            's(vessel_number, bs = "re")', sep = "+")

gam_form <- as.formula(paste0(response_string, "~", explanatory_string))

mod_TW <- gam(gam_form,
              data = TW_data_train,
              family = tw(link = "log"))

TW_model_name_for_save = paste0("_RData/TW_Full_", chosen_species, ".RData")
save(mod_TW, file = TW_model_name_for_save)

mod_TW_information <- summary(mod_TW)

par(mfrow = c(3,2))
gam.check(mod_TW)
plot(mod_TW)

main_heading = paste0("TW - ", chosen_species, " GAM Diagnostics: ", date_index[i])
mtext(main_heading, 
      side = 3, 
      line = -2, outer = T, 
      font = 2)

