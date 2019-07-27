library('openxlsx')
library('mice')
library('ssfa')
library('ggplot2')
library('frontier')
library('reshape2')

df_2017_geo <- read.xlsx(xlsxFile = '2017_for_sfa_geo.xlsx', skipEmptyCols = TRUE)

for (i in 4:11) 
  df_2017_geo[,i] <- as.numeric(df_2017_geo[,i])

for (i in 4:9) 
  df_2017_geo[,i] <- outlier(df_2017_geo[,i])

X_spatial <- with(df_2017_geo, 
                cbind(mean_EGE = `Средний.балл.ЕГЭ.студентов..принятых.по.результатам.ЕГЭ.на.обучение.по.очной.форме.по.программам.бакалавриата.и.специалитета.за.счет.средств.соответствующих.бюджетов.бюджетной.системы.РФ` / Доходы.вуза.из.всех.источников,
                      nums_of_NPR = Общая.численность.НПР / Доходы.вуза.из.всех.источников,
                      Income_of_univ = Доходы.вуза.из.всех.источников,
                      Nums_of_publications = Общее.количество.публикаций,
                      Priv_cont = Приведенный.контингент,
                      NIOKR = `Общий.объем.научно.исследовательских.и.опытно.конструкторских.работ..далее...НИОКР`,
                      longitude = `Широта`,
                      latitude = `Долгота`))



impute_X.spatial <- mice(X_spatial)
X_spatial <- complete(impute_X.spatial,1)


for (i in 1:6) 
  X_spatial[,i] <- replace_zero(X_spatial[,i])

W <- constructW(cbind(X_spatial$longitude, X_spatial$latitude), df_2017_geo$id)
W <- rowStdrt(W)



ssfa <- ssfa(-log(Income_of_univ) ~ log(mean_EGE) + log(nums_of_NPR) + log(Nums_of_publications) + 
                                                    log(Priv_cont) + log(NIOKR), 
                                    data = X_spatial, 
                                    data_w = W, 
                                    form = "production", 
                                    par_rho=TRUE)

summary(ssfa)
ggplot(as.data.frame(eff.ssfa(ssfa)), fill = "grey", color = "black") + 
  geom_density(aes(x = eff.ssfa(ssfa))) + ggtitle('Distribution of effectiency`s estimations')


sfa.ef <- efficiencies(sfa) # efficiency estimators of classic sfa
sfa.ef[497] <- NA
df_sfa <- data.frame(cbind(sfa = sfa.ef, ssfa = as.vector(eff.ssfa(ssfa)) ))
sd(eff.ssfa(ssfa))
data <- melt(df_sfa)
ggplot(data, aes(x=value, fill=variable)) + geom_density(alpha=0.25) + theme(legend.position = c(0.3, 0.75)) + 
  xlab('efficiency')



mean(eff.ssfa(ssfa)[-497] - efficiencies(sfa))

dif <- eff.ssfa(ssfa)[-497] - efficiencies(sfa)
dif[497] <- NA

df_sfa <- data.frame(cbind(df_sfa, dif ))
df_sfa <- data.frame(cbind(df_sfa, id = df_2017_geo$id))
df_sfa <- data.frame(cbind(df_sfa, name = df_2017_geo$name))
df_sfa <- data.frame(cbind(df_sfa, region = df_2017_geo$region))

write.xlsx(df_sfa, file = 'df_sfa_dif.xlsx')


data <- melt(df_sfa$dif)
ggplot(data, aes(x=value)) + geom_density(alpha=0.25) + theme(legend.position = c(0.3, 0.75)) + 
  xlab('dif of eff')

hist(df_sfa$dif)
boxplot(df_sfa$dif)

ggplot(df_sfa, aes(x = '', y = dif )) +
  geom_boxplot() + 
  geom_text(aes(label = id), na.rm = TRUE, hjust = -0.3, check_overlap = TRUE)


