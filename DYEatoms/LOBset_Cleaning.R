### LOBset cleaning
### Cleans up the .csv file output by LOBSTAHS, puts it in long format

# Step 0: Load useful libraries ----
library(dplyr)
library(reshape2)





# Step 1: Import the data ----

#Tell R where you are and where the data is
  #You may have to change this depending on where the .csv file is found
setwd("~/Desktop/Elab/GitHub Things/SavioBridge/DYEatoms")

#Read the data in and save it as the variable "LOBset"
LOBset <- read.csv("LOBset_Pos.csv")

#Check that it loaded properly by looking at the first 6 rows
head(LOBset)





#Step 2: Do some data cleaning ----

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






# Step 4: Add treatment conditions to it
    #Metadata from https://www2.whoi.edu/staff/bvanmooy/gordon-and-betty-moore-foundation-project-data/
    # and the Excel spreadsheet

#Make a new column called "treatment"
treatments <- c("Control", "+NP", "+NPSi")
num_compounds <- dim(LOBset)[1]
treatment_col <- c(rep(treatments[1], num_compounds*2), 
                   rep(treatments[2], num_compounds*3),
                   rep(treatments[3], num_compounds*3))
complete_LOBset <- mutate(long_LOBset, treatment_col)


# Final step: Write out the data as a new csv file "Clean_LOBset_Pos.csv" ----
write.csv(complete_LOBset, file = "Clean_LOBset_Pos.csv")