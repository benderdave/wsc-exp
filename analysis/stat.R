#Read in the data
datain = read.csv("results.csv")

#Recode into factors
fPerson = factor(datain$Person)
logRt = log10(datain$Rt)

#Load package
library(lmerTest)

#Fit models
fit = lmer(logRt ~ Hit + (1|fPerson), data=datain) #Random Intercept
fit.f = lmer(logRt ~ Hit + (1+Hit|fPerson), data=datain) #Random Slope & Intercept
summary(fit)
summary(fit.f)
anova(fit)

AIC(fit,fit.f) #Compare models (smaller is better)

plot(fit) #Check out residuals

#Examine the data
table(datain$Hit)
plot(table(fPerson))
range(table(fPerson))
summary(datain$Rt)

#Plot the data
hist(datain$Rt)
hist(logRt)
boxplot(logRt~Hit,data=datain)

#Remove one large outlier
data2 = subset(datain,datain$Rt < 260000)

#Refit model
fPerson2 = factor(data2$Person)
logRt2 = log10(data2$Rt)
fit2 = lmer(logRt2 ~ Hit + (1|fPerson2), data=data2)
summary(fit2)

#Plot residuals
plot(fit2)
plot(fitted(fit2),resid(fit2))

#Identify large outliers (very fast response)
out = data.frame(fPerson,fitted(fit))
colnames(out)[2] = "fitted"
colnames(out)
subset(out,out$fitted<3)
