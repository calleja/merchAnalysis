library(dplyr)
library(lubridate)
library(ggplot2)
library(stringr)
library(readxl)
###########################################################
##     Merch analysis
##     ascertain the extent of null values of key fields
##     this informs the purpose of the SBERT model or xgboost
##     the response variables are department_name, vendor, and category (both are needed)
############################################################

setwd('/home/candela/pCloudDrive/pCloud Backup/mofongo-HP-EliteBook-840-G8-Notebook-PC/Documents/ghfc/merch/merch_analysis_git')

#key fields: category, store_vendor_products, department_name, active_vendor_configuration, vendors
catalog <- readxl::read_excel('greeneHillFoodCoOp_catalog_1754767583990.xlsx',sheet='greeneHillFoodCoOp_catalog_1754')

catalog |>
  select('category', 'store_vendor_products', 'department_name', 'active_vendor_configuration', 'vendors', 'active_vendor_name') |>
  summarize(across(everything(), ~sum(is.na(.))))

#explore prospective input factors to a knn or xgboost model
catalog |>
  select('active_vendor_name','vendors','case_size','cost','brand_string','department_name','created_at','sold_by_weight','pack_size','category') |>
  summarize(across(everything(), ~sum(is.na(.))))

#all barcodes have a department
catalog |>
  group_by(department_name) |>
  summarize(size = n()) |>
  arrange(desc(size))

  
catalog |>
  select(name,active_vendor_name,category,department_name) |>
  arrange(name) |>
  tail(10)
