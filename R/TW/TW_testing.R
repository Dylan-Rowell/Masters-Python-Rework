
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(mgcv)


# #-----------------#
# 6) Testing
# #-----------------#

#-------------------------
# Initialising
#-------------------------
num_iter <- length(date_index)

coverage_TW_95 <- rep(NA, num_iter)
width_TW_95 <- rep(NA, num_iter)

coverage_TW_60 <- rep(NA, num_iter)
width_TW_60 <- rep(NA, num_iter)

quantile_score_TW <- rep(NA, num_iter)

R_squared_TW <- rep(NA, num_iter)
RMSE_TW <- rep(NA, num_iter)
model_info_TW <- NULL

#-------------------------
# Monthly Iteration
#-------------------------

for(i in 1:num_iter){
  
  #-------------------------
  # Data Split
  #-------------------------
  input_date <- date_index[i]
  tmp_name <- input_date
  
  ##################
  ### Data Split ###
  ##################
  
  ####--------------------------####
  # Scalar Response Variables
  ####--------------------------####
  
  ## Catch Test
  Y_response_test <- (
    cbind(Full_Data_LONG_test[which(Full_Data_LONG_test$prediction_date_md == input_date), 
                              response_string]))
  
  
  ####--------------------------####
  # Scalar Predictor Variable
  ####--------------------------####
  
  ## Test
  X_predict_test <- (
    cbind(Full_Data_LONG_test[which(Full_Data_LONG_test$prediction_date_md == input_date), 
                              c(TW_explanatory_variables)]))
  X_predict_test["vessel_year"] <- paste(X_predict_test[,"vessel_number"], X_predict_test[,"docking_date_year"], sep = "_")
  
  #-------------------------
  # Fitting
  #-------------------------
  
  
  TW_data_test <- data.frame(X_predict_test, Y_response_test)
  
  TW_data_test$vessel_number <- as.factor(data.frame(X_predict_test)$vessel_number)
  TW_data_test$vessel_year <- as.factor(data.frame(X_predict_test)$vessel_year)
  TW_data_test$docking_date_year <- as.numeric(data.frame(X_predict_test)$docking_date_year)
  
  #-------------------------
  # Testing
  #-------------------------
  
  par(mfrow = c(3,2))
  par(mar = c(4,5,3,2))
  
  TW_post_preds <- get.TW.posterior.dbn(TW_model = mod_TW,
                                        test_data = TW_data_test,
                                        n_reps = 10000,
                                        ranefs = c("vessel_year", "vessel_number"))
  
  TW_post_preds <- as.matrix(TW_post_preds + X_predict_test[,chosen_species])
  Y_hat_quantiles <- t(apply(TW_post_preds, 1, quantile, 
                             prob = c(0.025,0.975,quant_probs)))
  
  Y_test <- as.matrix(Y_response_test + X_predict_test[,chosen_species])
  Y_hat  <- (apply(TW_post_preds, 1, median))
  
  coverage_95 <- interval.coverage(Y_test, 
                                   lower = Y_hat_quantiles[,"2.5%"], 
                                   upper = Y_hat_quantiles[,"97.5%"])
  width_95 <- interval.width(lower = Y_hat_quantiles[,"2.5%"], 
                             upper = Y_hat_quantiles[,"97.5%"])
  
  coverage_60 <- interval.coverage(Y_test, 
                                   lower = Y_hat_quantiles[,"20%"], 
                                   upper = Y_hat_quantiles[,"80%"])
  width_60 <- interval.width(lower = Y_hat_quantiles[,"20%"], 
                             upper = Y_hat_quantiles[,"80%"])
  
  quants <- matrix(Y_hat_quantiles[,-c(1,2)], nrow = N_test, 
                   ncol = length(quant_probs), 
                   byrow = FALSE)
  
  quantile_scores_mtx <- quantile_probs_scoring(as.vector(Y_test), 
                                                quants, 
                                                quant_probs)
  
  quant_score <- mean(abs(quantile_scores_mtx))
  
  catch_results <- diagnostics.plot(YZ_hat = Y_hat, 
                                    YZ_test = Y_test,
                                    method = "TW",
                                    species = chosen_species)
  
  catch_results$coverage_95 <- coverage_95
  catch_results$width_95 <- width_95
  
  catch_results$coverage_60 <- coverage_60
  catch_results$width_60 <- width_60
  
  catch_results$quant_score <- quant_score
  catch_results$quantile_scores_mtx <- quantile_scores_mtx
  
  
  #Saving to a list to be passed to the forecasting function
  model_info_TW[[tmp_name]]$catch_results <- catch_results
  
  
  coverage_TW_95[i] <- catch_results$coverage_95
  width_TW_95[i] <- catch_results$width_95
  
  coverage_TW_60[i] <- catch_results$coverage_60
  width_TW_60[i] <- catch_results$width_60
  
  R_squared_TW[i] <- catch_results$R_squared
  RMSE_TW[i] <- catch_results$RMSE
  quantile_score_TW[i] <- catch_results$quant_score
  
  save.last.plot.pdf(species = chosen_species,
                     method = "TW_Full",
                     type = "diagnostics",
                     iteration = i)
  
  save.plots.for.GIF(species = chosen_species,
                     method = "TW_Full",
                     type = "diagnostics",
                     iteration = i)
  
}

combine.pngs.to.gif(species = chosen_species,
                    method = "TW_Full",
                    type = "diagnostics",
                    delay = 1000)

final_model_results[[chosen_species]][["TW_Full"]]$routine <- model_info_TW



plot(coverage_TW_95, type = "l", ylim = c(0,1))
plot(R_squared_TW ~ seq(0.5, 12, length.out = 23), type = "l", ylim = c(0,1))
abline(h = 0.8, lty = 2)
```