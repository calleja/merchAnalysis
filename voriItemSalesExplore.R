library(tidyverse)
library(randomForest)
library(fpp3)
library(ggplot2)
library(zoo)
library(lubridate)

setwd('/home/candela/pCloudDrive/pCloud Backup/mofongo-HP-EliteBook-840-G8-Notebook-PC/Documents/ghfc/merch')

dir()
getwd()
items <- read.csv('./Itemswithcost.csv')

sapply(items.2,class)

cols.tgt <- c('Order.Date','Department','Barcode','Product.Cost.Status','Each.Cost','Active.Vendor',
'Retail.Price','Quantity','Weight','Items.Total','Sales','Cost.Of.Goods.Sold','Product.Name','Brand','Sold.By.Weight')

items |>
  select(all_of(cols.tgt)) -> items.2

#Invoice reporting: Barcode could = Item Code
items.2 |>
  mutate(order.dt = as.Date(Order.Date, format = "%a, %b %d, %Y, %H:%M %p")) -> items.2

#study to look at the price fluctuation over time; rank those with higher variance

#weekly sales by barcode
week(items.2$order.dt)[1:4]
isoweek(items.2$order.dt)[1:4]

items.2 |>
  filter(Sold.By.Weight == "false") |>
  group_by(Barcode,year(order.dt),isoweek(order.dt)) |>
  summarize(total.qty.sold = sum(Quantity)) |>
  rename(year = 'year(order.dt)',week_num = 'isoweek(order.dt)') |>
  arrange(Barcode,year,week_num)-> item.summary

head(item.summary)

#study to look at those barcodes with multiple vendors