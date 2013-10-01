################################## GENERIC FUNCTIONS ############################
# find matrix of densities at y, for each component of the mixture
# INPUT y is an n-vector
# OUTPUT k by n matrix of densities
compdens = function(x,y,log=FALSE){
  UseMethod("compdens")
}
compdens.default = function(x,y,log=FALSE){
  stop("No such class")
}

#find cdf at y, a generic function
mixcdf = function(x,y,lower.tail=TRUE){
  UseMethod("mixcdf")
}
mixcdf.default = function(x,y,lower.tail=TRUE){
  stop("No such class")
}

#find density at y, a generic function
dens = function(x,y){
  UseMethod("dens")
}
dens.default = function(x,y){
  return (x$pi %*% compdens(x, y))
}

#find log likelihood of data in y
LogLik = function(x,y){
  UseMethod("LogLik")
}
LogLik.default = function(x,y){
  sum(dens(x,y))
}

#compute the density of the components of the mixture m
#when convoluted with a normal with standard deviation s
#the density is evaluated at x
#x and s are n-vectors
#m is a mixture with k components
#output is a k by n matrix of densities
compdens_conv = function(m, x, s){
  UseMethod("compdens_conv")
}
compdens_conv.default = function(m,x, s){
  stop("No such class")
}

#compute density of mixture m convoluted with normal of sd (s)
#at locations x
#m is a mixture
#x is an n vector
#s is an n vector or integer
dens_conv = function(m,x,s){
  UseMethod("dens_conv")
}
dens_conv.default = function(m,x,s){
  colSums(m$pi * compdens_conv(m,x,s))
}

#compute the posterior prob that each observation
#came from each component of the mixture m
#output a k by n vector of probabilities
#computed by weighting the component densities by pi
#and then normalizing
comppostprob=function(m,x,s){
 UseMethod("comppostprob") 
}
comppostprob.default = function(m,x,s){
  t(t(m$pi * compdens_conv(m,x,s))/dens_conv(m,x,s))
}
# evaluate cdf of posterior distribution of beta at c
# m is the prior on beta, a mixture
# c is location of evaluation
# assumption is betahat | beta \sim N(beta,sebetahat)
# m is a mixture with k components
# c a scalar
# betahat, sebetahat are n vectors 
# output is a k by n matrix
compcdf_post=function(m,c,betahat,sebetahat){
  UseMethod("compcdf_post")
}
compcdf_post.default=function(m,c,betahat,sebetahat){
  stop("method compcdf_post not written for this class")
}


cdf_post = function(m,c,betahat,sebetahat){
  UseMethod("cdf_post")
}
cdf_post.default=function(m,c,betahat,sebetahat){
  colSums(comppostprob(m,betahat,sebetahat)*compcdf_post(m,c,betahat,sebetahat))
}

#output posterior mean for beta for prior mixture m,
#given observations betahat, sebetahat
postmean = function(m, betahat,sebetahat){
  UseMethod("postmean")
}
postmean.default = function(m,betahat,sebetahat){
   colSums(comppostprob(m,betahat,sebetahat) * comp_postmean(m,betahat,sebetahat))
}



#output posterior mean for beta for each component of prior mixture m,
#given observations betahat, sebetahat
comp_postmean = function(m, betahat,sebetahat){
  UseMethod("comp_postmean")
}
comp_postmean.default = function(m,betahat,sebetahat){
  stop("method comp_postmean not written for this class")
}


#find nice limits of mixture m for plotting
min_lim = function(m){
  UseMethod("min_lim")
}
min_lim.default=function(m){
  -5
}

max_lim = function(m){
  UseMethod("max_lim")
}
max_lim.default=function(m){
  5
}


#plot density of mixture
plot_dens = function(m,npoints=100,...){
  UseMethod("plot_dens")
}
plot_dens.default = function(m,npoints=100,...){
  x = seq(min_lim(m),max_lim(m),length=npoints)
  plot(x,dens(m,x),type="l",xlab="density",ylab="x",...)
}

plot_post_cdf = function(m,betahat,sebetahat,npoints=100,...){
  UseMethod("plot_post_cdf")
}
plot_post_cdf.default = function(m,betahat,sebetahat,npoints=100,...){
  x = seq(min_lim(m),max_lim(m),length=npoints)
  x_cdf = vapply(x,cdf_post,FUN.VALUE=betahat,m=m,betahat=betahat,sebetahat=sebetahat)
  plot(x,x_cdf,type="l",xlab="x",ylab="cdf",...)
 # for(i in 2:nrow(x_cdf)){
 #   lines(x,x_cdf[i,],col=i)
 # }
}

############################### METHODS FOR normalmix class ###########################

# constructor
normalmix = function(pi,mean,sd){
  structure(data.frame(pi,mean,sd),class="normalmix")
}


compdens.normalmix = function(x,y,log=FALSE){
  k=length(x$mean)
  n=length(y)
  d = matrix(rep(y,rep(k,n)),nrow=k)
  return(matrix(dnorm(d, x$mean, x$sd, log),nrow=k))  
}

#density of convolution of each component of a normal mixture with N(0,s^2) at x
# x an n-vector at which density is to be evaluated
#return a k by n matrix
#Note that convolution of two normals is normal, so it works that way
compdens_conv.normalmix = function(m, x, s){
  if(length(s)==1){s=rep(s,length(x))}
  sdmat = sqrt(outer(s^2,m$sd^2,FUN="+")) #n by k matrix of standard deviations of convolutions
  return(t(dnorm(outer(x,m$mean,FUN="-")/sdmat)/sdmat))
}


mixcdf.normalmix = function(x,y,lower.tail=TRUE){
  x$pi %*%  vapply(y,pnorm,x$mean,x$mean,x$sd,lower.tail)
}

#c is a scalar
#m a mixture with k components
#betahat a vector of n observations
#sebetahat an n vector of standard errors
#return a k by n matrix of the posterior cdf
compcdf_post.normalmix=function(m,c,betahat,sebetahat){
  k = length(m$pi)
  n=length(betahat)
  #compute posterior standard deviation (s1) and posterior mean (m1)
  s1 = sqrt(outer(sebetahat^2,m$sd^2,FUN="*")/outer(sebetahat^2,m$sd^2,FUN="+"))
  m1 = t(comp_postmean(m,betahat,sebetahat))
  t(pnorm(c,mean=m1,sd=s1))
}

#return posterior mean for each component of prior m, given observations betahat and sebetahat
#input, m is a mixture with k components
#betahat, sebetahat are n vectors
#output is a k by n matrix
comp_postmean.normalmix = function(m,betahat,sebetahat){
  t((outer(sebetahat^2,m$mean, FUN="*") + outer(betahat,m$sd^2, FUN="*"))/outer(sebetahat^2,m$sd^2,FUN="+"))
}



############################### METHODS FOR unimix class ###########################

#constructor
#here the uniform is parameterized in terms of min=mean-sd and min=mean+sd
#(so obviously sd is a misnomer!)
unimix = function(pi,a,b){
  structure(data.frame(pi,a,b),class="unimix")
}

compdens.unimix = function(x,y,log=FALSE){
  k=length(x$a)
  n=length(y)
  d = matrix(rep(y,rep(k,n)),nrow=k)
  return(matrix(dunif(d, x$a, x$b, log),nrow=k))  
}

#density of convolution of each component of a unif mixture with N(0,s) at x
# x an n-vector
#return a k by n matrix
compdens_conv.unimix = function(m, x, s){
  return(t(pnorm(outer(x,m$a,FUN="-")/s)
          -pnorm(outer(x,m$b,FUN="-")/s))/(m$b-m$a))
}


#c is a scalar
#m a mixture with k components
#betahat a vector of n observations
#sebetahat an n vector of standard errors
#return a k by n matrix of the posterior cdf
compcdf_post.unimix=function(m,c,betahat,sebetahat){
  k = length(m$pi)
  n=length(betahat)
  tmp = matrix(1,nrow=k,ncol=n)
  tmp[m$a >= c,] = 0
  subset = m$a<c & m$b>c # subset of components (1..k) with nontrivial cdf
  if(sum(subset)>0){
    pna = pnorm(outer(betahat,m$a[subset],FUN="-")/sebetahat)
    pnc = pnorm(outer(betahat,c,FUN="-")/sebetahat)
    pnb = pnorm(outer(betahat,m$b[subset],FUN="-")/sebetahat)
    tmp[subset,] = t((pnc-pna)/(pnb-pna))
  }
  tmp
}

