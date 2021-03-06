### LOBset cleaning
### Cleans up the .csv file output by LOBSTAHS, puts it in long format

# Step 0: Load useful libraries ----
library(dplyr)
library(reshape2)




# Step 1: Import the data ----

#Tell R where you are and where the data is
  #You may have to change this depending on where the .csv file is found
#setwd("~/Desktop/Elab/GitHub Things/SavioBridge/DYEatoms")

#Read the data in and save it as the variable "LOBset"
LOBset <- read.csv("CollinsDYE_Pos.csv")

#Check that it loaded properly by looking at the first 6 rows
head(LOBset)

#Grab some data that will be useful later
DNPPEs <- filter(LOBset, compound_name=="DNPPE"&peakgroup_rt>800)
max_DNPPE <- max(DNPPEs[,10:17])
norm_factor <- as.numeric(max_DNPPE/DNPPEs[,10:17])

biomass <- filter(LOBset, compound_name=="Chl_a")
max_chl <- max(biomass[,10:17])
bio_factor <- as.numeric(max_chl/biomass[,10:17])




#Step 2: Do some data cleaning ----

#Throw out all the low-confidence compound assignments

LOBset <- LOBset %>% mutate(questionable=C3c+C3f+C3r+C4+C5+C6a+C6b) %>%
  filter(questionable==0) %>% filter(!grepl("^L", species))


num_compounds <- dim(LOBset)[1]
norm_factor <- rep(norm_factor, each=num_compounds)
bio_factor <- rep(bio_factor, each=num_compounds)

#Grab only the columns we want: RT, m/z, compound name, lipid species, lipid class, sample number
  #And save it as a new variable "simple_LOBset"

#Grab all the column names that have "Orbi" in them
col_names <- names(LOBset)
sample_cols <- grep("Orbi", col_names, value = T)

#Make a vector with all the column names in it
cols_to_keep <- c(
  "peakgroup_mz",
  "peakgroup_rt",
  "compound_name",
  "species",
  "lipid_class",
  sample_cols
)

#And grab them
simple_LOBset <- select(LOBset, cols_to_keep)

#Make sure we got what we expected
head(simple_LOBset)

#Rename the first 5 columns to something more descriptive
names(simple_LOBset)[1:5] <- c("m/z", "RT", "compound_name", "lipid_species", "lipid_class")
head(simple_LOBset)
#Yay!





# Step 3: Put the data in long format ----
long_LOBset <- melt(simple_LOBset, id=c("m/z", "RT", "compound_name", "lipid_species", "lipid_class"),
                    value.name = "intensity", variable.name = "sample")
#Check that we got what we wanted
head(long_LOBset)





# Step 3.5: Normalize to DNPPE
norm_LOBset <- long_LOBset %>%
  mutate("intensity"=intensity*norm_factor)


# Step 3.6: Normalize to chlorophyll
norm_LOBset <- norm_LOBset %>%
  mutate("intensity"=intensity*bio_factor)



# Step 4: Add treatment conditions to it ----
    #Metadata from https://www2.whoi.edu/staff/bvanmooy/gordon-and-betty-moore-foundation-project-data/
    # and the Excel spreadsheet

#Make a new column called "treatment"
  #The first two samples are controls (1129 and 1130), the next 3 are +NP, 
treatments <- c("Control", "Control", "+NP", "+NP", "+NP", "+NPSi", "+NPSi", "+NPSi")
treatment_col <- rep(treatments, each=num_compounds)
full_LOBset <- mutate(norm_LOBset, "treatment"=treatment_col)





# Step 5: Append a column denoting the polarity ----
complete_LOBset_pos <- mutate(full_LOBset, polarity="positive")




# Step 6: Do everything again, but for the other polarity ----
LOBset <- read.csv("CollinsDYE_Neg.csv")
DNPPEs <- filter(LOBset, compound_name=="DNPPE"&peakgroup_rt>800)
max_DNPPE <- max(DNPPEs[,10:17])
norm_factor <- as.numeric(max_DNPPE/DNPPEs[,10:17])
LOBset <- LOBset %>% mutate(questionable=C3c+C3f+C3r+C4+C5+C6a+C6b) %>%
  filter(questionable==0) %>% filter(!grepl("^L", species))
num_compounds <- dim(LOBset)[1]
norm_factor <- rep(norm_factor, each=num_compounds)
col_names <- names(LOBset)
sample_cols <- grep("Orbi", col_names, value = T)
cols_to_keep <- c("peakgroup_mz","peakgroup_rt","compound_name",
                  "species","lipid_class",sample_cols)
simple_LOBset <- select(LOBset, cols_to_keep)
names(simple_LOBset)[1:5] <- c("m/z", "RT", "compound_name", "lipid_species", "lipid_class")
head(simple_LOBset)
long_LOBset <- melt(simple_LOBset, id=c("m/z", "RT", "compound_name", "lipid_species", "lipid_class"),
                    value.name = "intensity", variable.name = "sample")
norm_LOBset <- long_LOBset %>%
  mutate("intensity"=intensity*norm_factor)
treatments <- c("Control", "Control", "+NP", "+NP", "+NP", "+NPSi", "+NPSi", "+NPSi")
treatment_col <- rep(treatments, each=num_compounds)
full_LOBset <- mutate(norm_LOBset, "treatment"=treatment_col)
complete_LOBset_neg <- mutate(full_LOBset, polarity="negative")


# Step 7: Append the two data frames by stacking them on top of each other ----
complete_LOBset <- rbind(complete_LOBset_pos, complete_LOBset_neg)



# Final step: Write out the data as a new csv file "Clean_LOBset_Pos.csv" ----
write.csv(complete_LOBset, file = "Clean_LOBset.csv")
