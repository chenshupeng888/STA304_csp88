#  Chen,shupeng



## Step 1. Dealing with missing values

library(tidyverse)
diabetes = read.csv("diabetes.csv",header = TRUE,stringsAsFactors = FALSE)[,-1]

colSums(is.na(diabetes))[colSums(is.na(diabetes))>0] #Find those variables with missing values


# we will remove `weight` and `payer_code` because miss too many values. (table1)
# we remove `weight,payer_code`. But we keep `medical specialty` and `race`, adding the value "missing" in order to account for missing value.
#We also remove `encounter_id`, `admission_source_id` and `encounter_num` because they are not considered relevant to the outcome.


diabetes.new <- diabetes %>% select(-weight,-payer_code,-encounter_id,-admission_source_id,-encounter_num) %>%
  replace_na(list(race = "missing", medical_specialty = "missing")) 


#The preliminary dataset contained multiple inpatient visits for some patients and the observations could not be 
#considered as statistically independent an assumption of the logistic regression model.
#We thus used only one encounter per patient; in particular, 
#we considered only the first encounter for each patient as the
#primary admission and determined whether or not they were readmitted within 30 days. 


#Additionally,we removed all encounters that resulted in either discharge to
#a hospice or patient death, to avoid biasing our analysis. (reference from mapping csv)


diabetes.new <- diabetes.new[!duplicated(diabetes.new$patient_nbr),]
diabetes.new <- diabetes.new %>% filter(!discharge_disposition_id %in% c(11,13,14,19,20,21)) 

#In the following analysis, groups that covered less than 10% of encounters were grouped into "other" category.

#Readmission
diabetes.new$readmitted = ifelse(diabetes.new$readmitted == "<30", "readmitted","otherwise")

#Race
diabetes.new$race[! diabetes.new$race %in% c("AfricanAmerican","Caucasian","missing")]="Other"


#Gender
diabetes.new <- diabetes.new %>% filter(gender !="Unknown/Invalid")

#Age
diabetes.new %>% group_by(age) %>% summarise(proportion = mean(readmitted =="readmitted")) %>%
  ggplot(aes(age,proportion,group=1))+geom_line()+geom_point() %>%
  labs(x="Age",y="Propotion of Readmitted",title="Relationship of age and the Readmission rate")
diabetes.new$age[diabetes.new$age %in% c("[0-10)","[10-20)","[20-30)")]="<30"
diabetes.new$age[diabetes.new$age %in% c("[30-40)","[40-50)","[50-60)")]="[30,60)"
diabetes.new$age[diabetes.new$age %in% c("[60-70)","[70-80)","[80-90)","[90-100)")]="[60,100)"

# Admission type
diabetes.new$admission_type_id[diabetes.new$admission_type_id>3]="Other"
diabetes.new$admission_type_id[diabetes.new$admission_type_id==1]="Emergency"
diabetes.new$admission_type_id[diabetes.new$admission_type_id==2]="Urgent"
diabetes.new$admission_type_id[diabetes.new$admission_type_id==3]="Elective"

# Discharge_disposition
diabetes.new$discharge_disposition_id[diabetes.new$discharge_disposition_id>1]="Other"
diabetes.new$discharge_disposition_id[diabetes.new$discharge_disposition_id==1]="Home"

# Medical Specialty: medical specialty categories are grouped based on wikipedia

diabetes.new$medical_specialty[diabetes.new$medical_specialty == "Family/GeneralPractice"] ="General"
diabetes.new$medical_specialty[diabetes.new$medical_specialty %in% c("Cardiology", "Cardiology-Pediatric", "Gastroenterology", "Endocrinology", "Endocrinology-Metabolism", "Hematology", "Hematology/Oncology", "InternalMedicine", "Nephrology", "InfectiousDiseases", "Oncology", "Proctology", "Pulmonology", "Rheumatology", "SportsMedicine", "Urology")] ="Internal medicine"
diabetes.new$medical_specialty[diabetes.new$medical_specialty %in% c("Emergency/Trauma","Anesthesiology", "Anesthesiology-Pediatric", "AllergyandImmunology", "Dentistry", "Dermatology", "Neurology", "Neurophysiology", "Ophthalmology", "Pathology", "Pediatrics", "Pediatrics-AllergyandImmunology", "Pediatrics-CriticalCare", "Pediatrics-EmergencyMedicine", "Pediatrics-Endocrinology", "Pediatrics-Hematology-Oncology", "Pediatrics-InfectiousDiseases", "Pediatrics-Neurology", "Pediatrics-Pulmonology", "Perinatology", "PhysicalMedicineandRehabilitation", "PhysicianNotFound", "Podiatry", "Psychiatry", "Psychiatry-Addictive", "Psychiatry-Child/Adolescent", "Psychology", "Radiologist", "Radiology", "Resident", "Speech", "Gynecology", "Obsterics&Gynecology-GynecologicOnco", "Obstetrics", "ObstetricsandGynecology", "OutreachServices", "DCPTEAM", "Hospitalist")] ="Other"
diabetes.new$medical_specialty[diabetes.new$medical_specialty%in%c("Orthopedics", "Orthopedics-Reconstructive", "Osteopath", "Otolaryngology", "Surgeon", "Surgery-Cardiovascular", "Surgery-Cardiovascular/Thoracic", "Surgery-Colon&Rectal", "Surgery-General", "Surgery-Maxillofacial", "Surgery-Neuro", "Surgery-Pediatric", "Surgery-Plastic", "Surgery-PlasticwithinHeadandNeck", "Surgery-Thoracic", "Surgery-Vascular", "SurgicalSpecialty")]="Surgery"


# Number of services during the encounter
diabetes.new = diabetes.new %>% mutate(num_services = num_lab_procedures+num_procedures+num_medications)%>%
  select(-num_lab_procedures,-num_procedures,-num_medications)


# Number of visits in the year preceding the encounter
diabetes.new = diabetes.new %>% mutate(num_visits = number_outpatient+number_inpatient+number_emergency)%>%
  select(-number_outpatient,-number_inpatient,-number_emergency)

# Glucose serum test and A1c test result are usually highly correlated, so we just pick one of them. In our dataset, A1c test has more taken, 
#so we keep A1c test and remove glucose serum test.

diabetes.new = diabetes.new %>% select(-max_glu_serum)


#This preliminary plot was the motivation to divide the age variable into three categories, <30,[30,60) and 60+.




#In this dataset, we have a lot of features for different medications. However, what we only care is the impact of medication change on A1c test result.
#We will not look into those individual medications. Instead, we will form 4 different groups (reference https://doi.org/10.1155/2014/781670 ).

#1. no HbA1c test performed
#2. HbA1c performed and in normal range
#3. HbA1c performed and the result is greater than 8% with no change in diabetic medications, 
#4. HbA1c performed, result is greater than 8%, and diabetic medication was changed.    (table2)

diabetes.new = diabetes.new %>% mutate(HbA1c = ifelse(A1Cresult=="None","Not measured",ifelse(A1Cresult==">8"&change=="Ch","High, changed",ifelse(A1Cresult==">8"&change=="No","High, not changed","Normal")))) %>%
  select(-A1Cresult,-change)

diabetes.new %>% group_by(HbA1c) %>% summarise(proportion = mean(readmitted =="readmitted")) %>%
  ggplot(aes(HbA1c,proportion,group=1))+geom_line()+geom_point() %>%
  labs(x="HbA1c result",y="Propotion of Readmitted",title="Relationship of HbA1c and the Readmission rate")

diabetes.new = diabetes.new[,-c(10:33)]

#Next, we are going to provides the distribution of variable values and readmissions.(table3)

# These are categorical variables
diabetes.new %>%group_by(HbA1c) %>%
  summarise(Number_of_encounters = n(),
            percentage_in_population = n()/nrow(diabetes.new),
            Readmitted_number_of_encounter=sum(readmitted=="readmitted"),
            percentage_in_group=mean(readmitted=="readmitted"))

diabetes.new %>%group_by(gender) %>%
  summarise(Number_of_encounters = n(),
            percentage_in_population = n()/nrow(diabetes.new),
            Readmitted_number_of_encounter=sum(readmitted=="readmitted"),
            percentage_in_group=mean(readmitted=="readmitted"))

diabetes.new %>%group_by(discharge_disposition_id) %>%
  summarise(Number_of_encounters = n(),
            percentage_in_population = n()/nrow(diabetes.new),
            Readmitted_number_of_encounter=sum(readmitted=="readmitted"),
            percentage_in_group=mean(readmitted=="readmitted"))

diabetes.new %>%group_by(admission_type_id) %>%
  summarise(Number_of_encounters = n(),
            percentage_in_population = n()/nrow(diabetes.new),
            Readmitted_number_of_encounter=sum(readmitted=="readmitted"),
            percentage_in_group=mean(readmitted=="readmitted"))

diabetes.new %>%group_by(medical_specialty) %>%
  summarise(Number_of_encounters = n(),
            percentage_in_population = n()/nrow(diabetes.new),
            Readmitted_number_of_encounter=sum(readmitted=="readmitted"),
            percentage_in_group=mean(readmitted=="readmitted"))

diabetes.new %>%group_by(race) %>%
  summarise(Number_of_encounters = n(),
            percentage_in_population = n()/nrow(diabetes.new),
            Readmitted_number_of_encounter=sum(readmitted=="readmitted"),
            percentage_in_group=mean(readmitted=="readmitted"))

diabetes.new %>%group_by(age) %>%
  summarise(Number_of_encounters = n(),
            percentage_in_population = n()/nrow(diabetes.new),
            Readmitted_number_of_encounter=sum(readmitted=="readmitted"),
            percentage_in_group=mean(readmitted=="readmitted"))

# The following are numerical data
summary(diabetes.new$Length.of.Stay)
summary(diabetes.new$number_diagnoses)
summary(diabetes.new$num_services)
summary(diabetes.new$num_visits)

#Remove gender from the dataset
diabetes.new = diabetes.new %>% select(-gender)


#We can see, `gender` is actually not that significant. So in our further analysis, we will not include `gender`. 


## Step 3. Model Fit
#The 10 variables we will consider are `race`, `age`, `admission_type_id`, `discharge_dispoistion_id`, `Length.of.Stay`, `medical_specialty`, `number_diagnoses`, `num_services`, `num_visits`, `HbA1c`.

#We first divide the data into two parts, one is training set and the other is test set.


set.seed(1004465321)  #Student ID
testid = sample(diabetes.new$patient_nbr,20000)
train = diabetes.new[!diabetes.new$patient_nbr %in% testid,]
test = diabetes.new[diabetes.new$patient_nbr %in% testid,]

#Remove the covariate, patient_nbr. We will not include it in the regression model
train = train %>% select(-patient_nbr)
test = test %>% select(-patient_nbr)

mod1 = glm(factor(readmitted)~.,family = binomial,data=train)
mod.red = step(mod1)
summary(mod.red)

## Step 4. Model Diagnostics
linpred <- predict(mod.red) # predicted value based on linear predictor 
predprob <- predict(mod.red, type='response') # predicted probabilities
rawres <- (train$readmitted=="readmitted") - predprob
plot(rawres ~ linpred, xlab='linear predictor',ylab='residuals')

#Unfortunately the plot above is not particularly useful! We will now construct a binned residual plot as described in the lecture slides.
#First, we add the residuals and linear predictor to the data frame.
train <- mutate(train,residuals=residuals(mod.red), linpred=predict(mod.red),predprob=predict(mod.red,type='response'))
#We now create the bins, compute the mean of the residuals and linear predictors in each bin.
gdf <- group_by(train, ntile(linpred,100)) 
diagdf<-summarise(gdf,residuals=mean(residuals),
                  linpred=mean(linpred),
                  predprob=mean(predprob)) 
plot(residuals~linpred,diagdf,
     xlab='Linear Predictor',ylab='Deviance Residuals',pch=20)

plot(residuals~predprob,diagdf,
     xlab='Fitted Values',ylab='Deviance Residuals',pch=20)

#The deviance residuals are not constrained to have mean zero, 
#so the mean level of the plot is not of interest.
#We observe an even variation as the linear predictor and fitted values vary - 
#thus the plots do not detect any inadequacies in the model, except some outliers at the right tail.

#We can also plot the binned residuals against the predictors. For example, we can group by Length of stay.
gdf <- group_by(train, Length.of.Stay)
diagdf <- summarise(gdf, residuals = mean(residuals)) 
ggplot(diagdf, aes(x=Length.of.Stay, y=residuals)) + geom_point()
#Nothing remarkable except perhaps a large residual for a stay of 11,13,14 days. Let's take a closer look.
filter(train, Length.of.Stay %in% c(11,13,14)) %>% select(Length.of.Stay,readmitted,residuals)

#We conclude that if lengh of stay is not too large, e.g., less than 10 days, the longer stay,
#the higher readmission probability. However, this is not always the case.
#Especially, when the length of stay is close to 2 weeks,
#we assume those patients are well treated in their current encounter, 
#then they are less likely to have an early readmission in the next 30 days.


#We can display a QQ plot of the residuals, just like we would for linear models.
qqnorm(residuals(mod.red))
qqline(residuals(mod.red))

#However, there is no reason to expect these residuals to be normally distributed, 
#so this is fine. We can detect unusual observations by examining the leverages;
#we can use a half-normal plot for this.

library(faraway) 
halfnorm(hatvalues(mod.red))
#We can identify those two outlying points:
filter(train,hatvalues(mod.red)>0.017)
#These two individuals have relatively higher number of services and number of visits, 
#and both of them don't have HbA1c test measured - 
#given the relatively large size of the dataset and the fact that these points are not particularly extreme, 
#there is no need to be concerned.


## Step 5. Goodness of fit

#We first divide the observations up into $J$ bins based on the linear predictor.
#We then take the mean response and mean predicted probability within each bin.

#We then plot the observed proportions against the predicted probabilities. 
#For a well-calibrated prediction model, the observed proportions and predicted probabilities should be close.
gdf <- group_by(train, ntile(linpred,100))
hldf<-summarise(gdf,y=sum(readmitted=="readmitted"), ppred=mean(predprob),count=n())
hldf<-mutate(hldf,se.fit=sqrt(ppred*(1-ppred)/count)) 
ggplot(hldf,aes(x=ppred,y=y/count, ymin=y/count-2*se.fit,ymax=y/count+2*se.fit))+
geom_point()+geom_linerange(color=grey(0.75))+ geom_abline(intercept=0,slope=1)+xlab("Predicted Probability")+ylab("Observed Proportion
")

#Although there is some variation, 
#there is no consistent deviation from what is expected.
#We have computed approximate 95% confidence intervals using the binomial variance.
#The line passes through most of these intervals confirming that the variation from the expected is not excessive.

#We will now compute the test statistic and p-value for the Hosmer-Lemeshow test. This test formalizes the procedure above.
hlstat <- with(hldf, sum((y-count*ppred)^2/(count*ppred*(1-ppred)))) 
c(hlstat, nrow(hldf))
#
#The p-value is given by
1-pchisq(hlstat,100-2)

#Since the p-value is greater than 0.05,
#we detect no lack of fit. 
#For relatively small (but non-significant) p-values,
#it might be worth experimenting with different numbers of bins
#in order to see if the test ever becomes significant.
#Now let's move on to sensitivity and specificity. 
#The ROC curve perhaps the best way to assess goodness of fit for binary response models. 
library(pROC)
p1 <- predict(mod.red, type = "response")
roc_logit <- roc(train$readmitted ~ p1)
## The True Positive Rate ##
TPR <- roc_logit$sensitivities
## The False Positive Rate ##
FPR <- 1 - roc_logit$specificities
plot(FPR, TPR, xlim = c(0,1), ylim = c(0,1), type = 'l', lty = 1, lwd = 2,col = 'red')
abline(a = 0, b = 1, lty = 2, col = 'blue')
text(0.7,0.4,label = paste("AUC = ", round(auc(roc_logit),2)))

## Step 6. Prediction Power
test <- mutate(test,linpred=predict(mod.red,newdata = test),predprob=predict(mod.red,newdata=test,type='response'))
gdf <- group_by(test, ntile(linpred,100))
hldf<-summarise(gdf,y=sum(readmitted=="readmitted"), ppred=mean(predprob),count=n())
hldf<-mutate(hldf,se.fit=sqrt(ppred*(1-ppred)/count)) 
ggplot(hldf,aes(x=ppred,y=y/count, ymin=y/count-2*se.fit,ymax=y/count+2*se.fit))+
geom_point()+geom_linerange(color=grey(0.75))+ geom_abline(intercept=0,slope=1)+xlab("Predicted Probability")+ylab("Observed Proportion
")

library(pROC)
p1 <- predict(mod.red, newdata=test,type = "response")
roc_logit <- roc(test$readmitted ~ p1)
## The True Positive Rate ##
TPR <- roc_logit$sensitivities
## The False Positive Rate ##
FPR <- 1 - roc_logit$specificities
plot(FPR, TPR, xlim = c(0,1), ylim = c(0,1), type = 'l', lty = 1, lwd = 2,col = 'red')
abline(a = 0, b = 1, lty = 2, col = 'blue')
text(0.7,0.4,label = paste("AUC = ", round(auc(roc_logit),2)))
```


