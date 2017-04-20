library('foreign')
library('lfe')
library('stargazer')
setwd("~/Desktop/NYC Food Inspection/Data/DTA")

df <- read.dta('nyc_inspect_shift.dta')
df$INSPDATE <- as.Date(df$INSPDATE)

df_post <- df[df$INSPDATE > "2010-10-01",]

est <- felm(next_score ~ SCORE|CAMIS + INSPDATE|0|
              InspectorID,data = df_post[df_post$INSPTYPE == "A",])

est2 <- felm(next_score ~ SCORE|CAMIS |open ~ Average_Score,data = df_post[df_post$INSPTYPE == "B",])

stargazer(est)