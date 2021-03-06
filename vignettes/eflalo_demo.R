## ---- echo = T, warning = F, message = F, eval = T-----------------------
library(discaRd)
data(eflalo, package = 'discaRd')

## ----make_obs_flag, echo = T, warning = F, message = F, eval = T---------
dm = make.obs.flag.dat(eflalo, obs_level = .1)
str(dm)

## ----setup_data, echo = T, warning = F, message = F, eval = T------------
bspec = 'LE_KG_BSS' # European seabass (FAO code BSS)

# Observed subset
bdat = ddply(dm[dm$OBSFLAG==1,], 'STRATA' ,function(x) get.bydat(x, aggfact = 'DOCID',load = F, bspec = bspec, catch_disp = 1))

# All trips
ddat = dm[,c('FY','STRATA','DOCID','DATE_TRIP','fday','yday','NESPP3','LIVE_POUNDS')]

## ----run_cochran, echo = T, warning = F, message = F---------------------
# setup the unique strata in full dataset
strata_complete =  unique(c(bdat$STRATA, ddat$STRATA))

# set a year of interest
focal_year = 1801

bydat_focal = subset(bdat, FY == focal_year)
bydat_prev = subset(bdat, FY == focal_year - 1)
trips_focal = subset(ddat, FY == focal_year)
trips_prev = subset(ddat, FY == focal_year - 1)

# first day of the fishing year with a commerical trip
minday = min(c(unique(subset(bdat, FY==focal_year)$fday)), unique(subset(ddat, FY==focal_year)$fday))

dest_y1 <- get.cochran.ss.by.strat(bydat_focal, trips_focal, targCV =.3, strata_name = "STRATA", strata_complete = strata_complete)

# previous year
dest_y0 <- get.cochran.ss.by.strat(bydat_prev, trips_prev, targCV =.3, strata_name = "STRATA", strata_complete = strata_complete)

# compare the two years total discard rate
data.frame(r = c(dest_y0$rTOT, dest_y1$rTOT)
, CVTOT = c(dest_y0$CVTOT, dest_y1$CVTOT)
, row.names = c('y0','y1')
)


## ----use_trans_rate, echo = T, results='asis', warning = F, message = F, eval = T----
# Use the Cochran Trans function
	dest <- cochran.trans.calc(bydat_focal = bydat_focal, trips_focal = trips_focal, bydat_prev = bydat_prev, trips_prev = trips_prev, CV_target =.3, strata_name = "STRATA", strata_complete = strata_complete, time_span = c(minday, 365))

str(dest$D)

## ----plot_discard, echo = F, eval = T, message = F, warning = F----------
	# get cumulative discard at each day...
	cdest = colSums(dest[[1]], na.rm=T)
	cdest[is.nan(cdest)] = 0
	cdest[is.na(cdest)] = 0
	
# add catch cap number here.. arbitrary 10% more than the discard estimate.. 
cc =  max(cdest)*1.1  

# dates of the fishing year
fdates = seq(mdy(paste0('01-01-', focal_year)), mdy(paste0('12-31-',focal_year)), 'day')

plot(fdates[as.numeric(names(cdest))], cdest, lwd =2 , col = 4, typ='l', xlab='Fishing Day', ylab='Discard', ylim = c(0, cc*1.2))

abline(h = cc, lwd = 2, lty=2, col = 2)
grid()

## ----boot, echo = T, eval = F, message = F, warning = F------------------
#  	nboot = 100
#  	ncores = detectCores()
#  	cl = makeCluster(ncores)
#  	registerDoParallel(cl, cores = ncores)
#  	
#  	(t1 =Sys.time())
#  	print(paste0('Bootstrapping ', nboot, ' times using ', ncores, ' cores'))
#  	bout.list = foreach(1:nboot) %dopar% {
#  	library(discaRd)
#  	discaRd::bootr.strat(bdat = bdat, ddat = ddat, focal_year = focal_year, strata_name = 'STRATA', strata_complete = strata_complete, time_inter = 7, trans_method = "ntrips", time_span = c(minday, 365))
#  	}
#  	(t2 = Sys.time()-t1)
#  	
#  	# Stop cluster
#  	stopCluster(cl)

## ----plot_boot, eval = F, echo=F, fig.height=7, fig.width=8, message=F, warning=F----
#  # dates of the fishing year
#  	fdates = seq(mdy(paste0('01-01-', focal_year)), mdy(paste0('12-31-',focal_year+1)), 'day')
#  
#  # use subset columns
#  idx = as.numeric(colnames(bout.list[[1]]$D))
#  
#  #------------------------------------------#
#  # plot by quantile
#  #------------------------------------------#
#  
#  bdf = ldply(bout.list, function(x) colSums(x$D, na.rm = T))
#  
#  bdf = t(apply(bdf, 2, function(x) quantile(x,  probs = c(0.025, 0.25, 0.5, 0.75, 0.975), na.rm=T)))
#  
#  
#  plot(fdates[as.numeric(names(cdest))], cdest, lwd =2 , col = 4, typ='l', xlab='Fishing Day', ylab='Discard', ylim = c(0, cc*1.2))
#  
#  matplot(fdates[idx], bdf, typ='l', col = c(1,2,3,2,1), lty = c(3,2,1,2,3), ylab = 'Discard', xlab = 'Fishing Day', ylim = c(0, max(bdf)*1.05), add=T)
#  # lines(fdates[1:365], cdest, lwd =2 , col = 4, add=T)
#  
#  grid()
#  
#  legend('bottomright', c('Current estimate','Median','50%','95%'), lty = c(1,1,2,3), col = c(4,3,2,1), lwd = c(2,1,1,1), bg = 'white')
#  
#  # catch cap
#  abline(h = cc, lwd = 2, lty=2, col = 2)
#  text(fdates[100], cc*1.05, paste0(focal_year, ' Catch Cap'))    # adjust the annotation location
#  
#  title(paste0('European seabass', '\n', 'FY ', focal_year, ': 5 trip based Transition Rate'))
#  

