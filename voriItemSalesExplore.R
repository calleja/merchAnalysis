library(tidyverse)
library(randomForest)
library(fpp3)
library(ggplot2)
library(lubridate)

setwd('/home/candela/pCloudDrive/pCloud Backup/mofongo-HP-EliteBook-840-G8-Notebook-PC/Documents/ghfc/merch/merch_analysis_git')

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

#weekly sales by Barcode
items.2 |>
  filter(Sold.By.Weight == "false") |>
  group_by(Barcode,year(order.dt),isoweek(order.dt)) |>
  summarize(total.qty.sold = sum(Quantity)) |>
  rename(year = 'year(order.dt)',week_num = 'isoweek(order.dt)') |>
  arrange(Barcode,year,week_num)-> item.summary

head(item.summary)

#study to count the number of weeks and range for sales data by Barcode; NOTE the date range of the dataset is limited
item.summary |>
  group_by(Barcode) |>
  summarize(cnt = n(), first = min(year), last = max(year)) -> item.cnt

item.cnt |>
  arrange(desc(cnt),desc(first)) |>
  head()
head()

#verify no NA
sapply(items.2, function(x) sum(is.na(x)))

#study to look at those barcodes with multiple vendors
items.2 |>
  group_by(Department,Barcode) |>
  summarize(vendor.cnt = length(unique(Active.Vendor))) |>
  #count # of Barcodes having > 1 vendor
  filter(vendor.cnt>1) |>
  group_by(Department) |>
  summarize(cnt = n()) -> multi.vendor.cnt

#some steps to impute the count of barcodes w/multiple vendors to the "proportion" barchart
zero.vec <- vendor.prop$Department[!vendor.prop$Department %in% multi.vendor.cnt$Department]
step.df <- data.frame(zero.vec,rep(0,length(zero.vec)))
names(step.df) <- names(multi.vendor.cnt)
df.2.merge <- rbind(step.df,multi.vendor.cnt)

#proportion of Barcodes having > 1 vendor
items.2 |>
  group_by(Department,Barcode) |>
  summarize(vendor.cnt = length(unique(Active.Vendor))) |>
  #count # of Barcodes having > 1 vendor
  group_by(Department) |>
  summarize(cnt = sum(vendor.cnt>1)/n()) -> vendor.prop
  
#sort the barcode count dataframe to match the order of Department of vendor.prop
df.2.merge<- df.2.merge[match(vendor.prop$Department, df.2.merge$Department),]

random_colors <- sample(colors(), length(vendor.prop$Department))

vendor.prop |>
  ggplot(aes(x=Department,y=cnt, fill=random_colors)) +
  geom_bar(stat="identity") +
  theme(axis.text.x = element_text(angle = 45, vjust=0.5)) +
  labs(title = "Proportion of barcodes with multiple vendors", y="num of barcodes") +
  geom_text(aes(label = df.2.merge$cnt), vjust = -0.5, position = position_dodge(0.9)) +
  scale_fill_identity()
