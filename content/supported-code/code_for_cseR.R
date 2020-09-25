## packages we using 
library(tidyverse)
library(usethis)
library(devtools)
library(cesR)
# data is getting from ces2019_web
cesR::get_ces(srvy = "ces2019_web")

## plots of education level 
# show it by geom bar
ces2019_web%>%
  ggplot(aes(x=cps19_education))+geom_bar(colour="blue")+scale_x_binned(name="Education Level")+
  labs(y="Number of people",title="Grap1: Education level among respondents",
       caption= "Source:Stephenson, Laura B; Harell, Allison; Rubenson, Daniel; 
       Loewen, Peter John, 2020, '2019 Canadian Election Study")+theme_bw()


#### plot of satisfaction with government
#show it by histogram
ces2019_web%>%
  ggplot(aes(x=cps19_fed_gov_sat))+geom_histogram(stat="count")+scale_x_binned(name= "Satisfaction to Federal Government")+
  labs(y="Number of people",title="Graph2: Respondents'Satisfaction with Federal Government",
       caption= "Source:Stephenson, Laura B; Harell, Allison; Rubenson, Daniel; Loewen, Peter John, 2020,
       '2019 Canadian Election Study")+theme_linedraw()

#### group people whose educatiion level below high scool together with their satisfaction with government.
## and show it by geom count.
ces2019_web_1<-
  ces2019_web%>%
  filter(cps19_education<4)
ces2019_web_1<-
  ces2019_web_1%>%
  select(cps19_education,cps19_fed_gov_sat)
ces2019_web_1%>%
  ggplot(aes(x=cps19_education,y=cps19_fed_gov_sat))+geom_count()+
  labs(y="Satisfaction with Federal Government",x="Education Level",
       title="Graph3:Relationship between Satisfaction with Government and high Education",
       caption= "Source:Stephenson, Laura; Harell, Allison; Rubenson, Daniel; Loewen, Peter, 2020, '2019 CES")+
  theme_linedraw()


### group people whose educatiion level above high scool together with their satisfaction with government.
## and show it by geom count
ces2019_web_2<-
  ces2019_web%>%
  filter(cps19_education>=4)
ces2019_web_2<-
  ces2019_web_2%>%
  select(cps19_education,cps19_fed_gov_sat)
ces2019_web_2%>%
  ggplot(aes(x=cps19_education,y=cps19_fed_gov_sat))+
  geom_count(colour="blue")+labs(y="Satisfaction with Federal Government",x="Education Level",
                                 title="Graph4:Relationship between Satisfaction with Government and low Education",
                                 caption= "Source: Stephenson, Laura; Harell,
                                 Allison; Rubenson, Daniel; Loewen, Peter, 2020, '2019 CES")+theme_classic()

#####################