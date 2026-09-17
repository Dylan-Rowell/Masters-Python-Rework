library(mgcv)
library(tweedie)

get.TW.posterior.dbn <- function(TW_model, test_data, n_reps = 10000, ranefs = NA){
  
  
  #Parameter draws
  br <- rmvn(n_reps, coef(TW_model), vcov(TW_model))
  
  # build the Lp matrix
  Xp <- predict(TW_model, 
                newdata=test_data, 
                type="lpmatrix", 
                exclude = ranefs)
  
  #ranef draws
  if(!is.na(ranefs)){
    
    devs <- gam.vcomp(mod_TW)
    devs_index <- grepl(paste0(ranefs, collapse = '|'), rownames(devs))
    ranef_dev <- devs[devs_index, "std.dev"]
    ranef_draws <- rmvn(n_reps, rep(0, length(ranefs)), diag(ranef_dev))
    
    br_index <- which(grepl(paste0(ranefs, collapse = '|'), colnames(br)))
    br <- cbind(br[,-br_index], ranef_draws)
    
    Xp_index <- which(grepl(paste0(ranefs, collapse = '|'), colnames(Xp)))
    Xp <- cbind(Xp[,-Xp_index], 1, 1)
  }
  
  
  # this is now a matrix with n.rep replicate smooths over length(xp)
  # locations. Exponentiate to put on the response scale.
  fv <- exp(Xp%*%t(br))
  
  # now simulate from Tweedie deviates with mean exp(fv) (log link!),
  # scale and power parameter from the model
  test_posteriors <- matrix(rTweedie(fv, phi=TW_model$scale, p=TW_model$family$getTheta(TRUE)),
                            nrow(fv), ncol(fv))
  
  return(test_posteriors)
}