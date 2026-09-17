# Packages

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(tibble)
library(car)
library(magick)

#++++++++++++++++++++++++++++++++++++++++++++
# Accuracy Calculator
#++++++++++++++++++++++++++++++++++++++++++++

## Reporter
measure.accuracy <- function(pred_dat, test_dat){
  
  rmse = sqrt(mean((test_dat-pred_dat)^2))
  mae  = mean(abs(test_dat-pred_dat))
  
  
  SSR <- sum((test_dat-pred_dat)^2)
  SST <- sum((test_dat - mean(test_dat))^2)
  
  R_squared = 1 - SSR/SST
  

  return(list(R_squared = R_squared, 
              RMSE = rmse,
              MAE = mae))
  
}


#++++++++++++++++++++++++++++++++++++++++++++
# Interval metrics
#++++++++++++++++++++++++++++++++++++++++++++

# coverage
interval.coverage <- function(test, lower, upper) {
  
  coverage <- (test >= lower) & (test <= upper)
  return(mean(coverage))
}


## Width


interval.width <-function(lower, upper) {
  width <- upper-lower
  return(mean(width))
}



#++++++++++++++++++++++++++++++++++++++++++++
# Quantile scores
#++++++++++++++++++++++++++++++++++++++++++++
quantile_score_custom <- function(y, q, tau) {
  # y   = vector of observed values
  # q   = vector of quantile predictions
  # tau = quantile level (0-1)
  
  if (length(tau) != 1) stop("tau must be a single numeric value")
  
  score <- ifelse(y <= q,
                  2 * (1 - tau) * (q - y),
                  2 * tau * abs(q - y))
  return(score)
}


quantile_probs_scoring <- function(test_obs, quantiles, probabilities){
  mean_scores <- sapply(seq_along(quant_probs), function(i) {
    tau <- quant_probs[i]
    q_tau <- quantiles[, i]
    mean(quantile_score_custom(test_obs, q_tau, tau))
  })
  return(mean_scores)
}

#++++++++++++++++++++++++++++++++++++++++++++
# Test Diagnostics
#++++++++++++++++++++++++++++++++++++++++++++
test.diagnostics.plot <- function(YZ_hat, YZ_test, colour = "purple", method = "", species = ""){
    
    main_heading = paste0(method, " - ", species, " Catch Diagnostics: ", date_index[i])
    
    scalar_data_Y_hat = YZ_hat
    scalar_data_Y_test = YZ_test
    
    residuals = scalar_data_Y_test - scalar_data_Y_hat
    
    #Diagnostics
    hist(scale(residuals), breaks = 20, 
         main = "", xlab = "Std. Residuals", col = colour)
    plot(scale(residuals), 
         main = "", ylab = "Std. Residuals", col = colour)
    abline(h = c(0, 2, -2), lty = c(1,2,2))
    
    
    if(method != "LM"){
      qqplot(x = scalar_data_Y_test, y = scalar_data_Y_hat, ylab = "Pred Quantiles", xlab = "Obs Quantiles")
      abline(b = 1, a = 0)
    }else{
      qqnorm(scale(residuals), main = "")
      abline(a = 0, b = 1)
    }
    
    
    #Test Results
    test_results = measure.accuracy(scalar_data_Y_hat,
                                    scalar_data_Y_test)
    
    RMSE = test_results$RMSE
    R_squared <- test_results$R_squared
    
    XYlims <- c(0, max(c(scalar_data_Y_test, scalar_data_Y_hat)))
    
    plot(scalar_data_Y_test ~ scalar_data_Y_hat, 
         ylab = "Actual Values", 
         xlab = "Predicted Values", 
         xlim = XYlims,
         ylim = XYlims,
         lty = 2, col = "red")
    abline(a = 0, b = 1)
    legend("topleft", legend = c(paste0("Test RMSE = ", round(RMSE, 3)), 
                                 paste0("Rsq = ", round(R_squared, 3))), bty = "n")
    if(effort == FALSE){
      abline(a = min_catch_threshold, b = -1, lty = 2)
      abline(h = min_catch_threshold, lty = 2)
      abline(v = min_catch_threshold, lty = 2)
      
      
      abline(a = max_catch_threshold, b = -1, lty = 2)
      abline(h = max_catch_threshold, lty = 2)
      abline(v = max_catch_threshold, lty = 2)
      
      
    }
    
    mtext(main_heading, 
          side = 3, line = -2, outer = T, font = 2)
  
  print(test_results)
  return(test_results)
  
}


#++++++++++++++++++++++++++++++++++++++++++++
# Plotting
#++++++++++++++++++++++++++++++++++++++++++++
## PNGs For Gif

save.plots.for.GIF <- function(species = "", type = "", method = "", folder_path = NULL, iteration = 1, width = 500, height = 500) {
  
  main <- "_figures"
  
  if (is.null(folder_path)){
    folder <- paste0(main, "/", species, "/", type, "/", method, "_PNGS")
  } else{
    folder <- paste0(main, "/", folder_path)
  }
  
  filename <- sprintf(paste0(species, "_", type, "_", method, "_%03d"), iteration)
  
  if (dir.exists(folder) == F) {
    dir.create(folder, showWarnings = T, recursive = T)
  }
  
  if (!grepl("\\.png$", filename)) {
    filename <- paste0(folder, "/", filename, ".png")
  }
  
  # Record the current plot (must be base graphics)
  last_plot <- recordPlot()
  
  # Create SVG device
  png(filename, width = width, height = height)
  on.exit(dev.off())
  
  # Replay the captured plot to SVG device
  replayPlot(last_plot)
}

combine.pngs.to.gif <- function(species = "", type = "", method = "", input_dir_path = NULL,  delay = 100) {
  
  main <- "_figures"
  
  if (is.null(input_dir_path)){
    input_dir <- paste0(main, "/", species, "/", type, "/", method, "_PNGS")
  } else{
    input_dir <- paste0(main, "/", input_dir_path)
  }
  
  filename <- paste0(species, "_", type, "_", method, "_GIF")
  
  #Check in folder
  files <- list.files(input_dir, pattern = "\\.png$", full.names = TRUE)
  
  imgs <- image_read(files)
  
  animation <- image_animate(image_join(imgs), delay = delay / 10)
  
  image_write(animation, paste0("_gifs/", filename, ".gif"))
}


## SVGs

{}
save.last.plot.svg <- function(species = "", type = "", method = "", folder_path = NULL, filename = NULL, iteration = 1, width = 8, height = 8) {
  
  main <- "_figures"
  
  if (is.null(folder_path)){
    folder <- paste0(main, "/", species, "/", type, "/", method, "_SVGS")
    filename <- sprintf(paste0(species, "_", type, "_", method, "_%03d"), iteration)
  } else{
    folder <- paste0(main, "/", folder_path)
    filename <- filename
  }
  
  if (dir.exists(folder) == F) {
    dir.create(folder, showWarnings = T, recursive = T)
  }
  
  if (!grepl("\\.svg$", filename)) {
    filename <- paste0(folder, "/", filename, ".svg")
  }
  
  # Record the current plot (must be base graphics)
  last_plot <- recordPlot()
  
  # Create SVG device
  svg(filename, width = width, height = height)
  on.exit(dev.off())
  
  # Replay the captured plot to SVG device
  replayPlot(last_plot)
}

save.ggplot.svg <- function(plot, filename, folder = "_figures", width = 6, height = 4) {
  if (!grepl("\\.svg$", filename)) {
    filename <- paste0(folder, "/", filename, ".svg")
  }
  else{
    filename <- paste0(folder, "/", filename)
  }  
  ggsave(filename, plot = plot, width = width, height = height, device = "svg")
}



## PDFs


# These are also really useful!

save.last.plot.pdf <- function(species = "", type = "", method = "", folder_path = NULL, filename = NULL, iteration = 1, width = 8, height = 8) {
  
  main <- "_figures"
  
  if (is.null(folder_path)){
    folder <- paste0(main, "/", species, "/", type, "/", method, "_PDFs")
    filename <- sprintf(paste0(species, "_", type, "_", method, "_%03d"), iteration)
  } else{
    folder <- paste0(main, "/", folder_path)
    filename <- filename
  }
  
  if (dir.exists(folder) == F) {
    dir.create(folder, showWarnings = T, recursive = T)
  }
  
  if (!grepl("\\.pdf$", filename)) {
    filename <- paste0(folder, "/", filename, ".pdf")
  }
  
  # Record the current plot (must be base graphics)
  last_plot <- recordPlot()
  
  # Create PDF device
  pdf(filename, width = width, height = height)
  on.exit(dev.off())
  
  # Replay the captured plot to pdf device
  replayPlot(last_plot)
}

save.ggplot.pdf <- function(plot, filename, folder = "_figures", width = 6, height = 4) {
  
  
  if (!grepl("\\.pdf$", filename)) {
    filename <- paste0(folder, "/", filename, ".pdf")
  }
  else{
    filename <- paste0(folder, "/", filename)
  }  
  ggsave(filename, plot = plot, width = width, height = height, device = "pdf")
}
