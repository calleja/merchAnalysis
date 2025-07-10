library(tidyverse)
library(fpp3)
library(ggplot2)
library(lubridate)

#based on reports in Vori: https://dash.vori.com/retail/reporting/sales/items-sales -> apply date parameters; compile report; hover on screen until the option to "show underlying data" -> export this
#set to your local working directory
setwd('/home/candela/pCloudDrive/pCloud Backup/mofongo-HP-EliteBook-840-G8-Notebook-PC/Documents/ghfc/merch/merch_analysis_git')

dir()
getwd()
items <- read.csv('./Itemswithcost.csv')

sapply(items,class)

#cols of interest
cols.tgt <- c('Order.Date','Department','Barcode','Product.Cost.Status','Each.Cost','Active.Vendor',
'Retail.Price','Quantity','Weight','Items.Total','Sales','Cost.Of.Goods.Sold','Product.Name','Brand','Sold.By.Weight','Discount.And.Rewards')

items |>
  select(all_of(cols.tgt)) -> items.2

#Invoice reporting: Barcode could = Item Code
items.2 |>
  mutate(order.dt = as.Date(Order.Date, format = "%a, %b %d, %Y, %H:%M %p")) -> items.2

#study to look at the price fluctuation over time; rank those with higher variance

#weekly sales by barcode
week(items.2$order.dt)[1:4]
isoweek(items.2$order.dt)[1:4]

#weekly sales by Barcode of non-weighted items
items.2 |>
  filter(Sold.By.Weight == "false") |>
  group_by(Barcode,year(order.dt),isoweek(order.dt)) |>
  summarize(total.qty.sold = sum(Quantity)) |>
  rename(year = 'year(order.dt)',week_num = 'isoweek(order.dt)') |>
  arrange(Barcode,year,week_num)-> item.summary

#create a tsibble object: a powerful time-series dataframe compatible with many operatoins in the 'fpp' library
#tsibble requires a unique key; making one on date, barcode, department, vendor
#this tsibble focuses on Quantity only... you can expand it to other measures
items.2 |>
  group_by(order.dt,Department,Barcode,Active.Vendor) |>
  summarize(Quantity = sum(Quantity)) |>
  as_tsibble(key = c('Department','Barcode','Active.Vendor'), index = 'order.dt') -> item.ts

#check interval to ensure it's daily
interval(item.ts)

head(item.ts)

#inspect keys
key_data(item.ts)
key_rows(item.ts) # row numbers by key index
key_vars(item.ts)

#fill gaps (days where there are no sales for the Barcode
# handle missigness: https://tsibble.tidyverts.org/articles/implicit-na.html
has_gaps(item.ts,.full=TRUE)

item.ts |>
  fill_gaps(Quantity = 0L, .full=TRUE) -> item.ts.ng

class(item.ts.ng)
is_tsibble(item.ts.ng)

class(item.ts)

has_gaps(item.ts.ng,.full=TRUE)

#doing this will wipe out the tsibble and make this is a grouped_df  
item.ts.ng[is.na(item.ts.ng$Quantity),'Quantity'] <- 0

item.ts.ng |>
as_tsibble(key = c('Department','Barcode','Active.Vendor'), index = 'order.dt') -> item.ts.ng

#plot a key
item.ts |>
  filter(Barcode == '632726047900' & Active.Vendor == 'Union Beer Distributors') |>
  autoplot()

item.ts.ng |>
  filter(Barcode == '632726047900' & Active.Vendor == 'Union Beer Distributors') |>
  autoplot()



#study to count the number of weeks and range for sales data by Barcode; NOTE the date range of the dataset is limited
item.summary |>
  group_by(Barcode) |>
  summarize(cnt = n(), first = min(year), last = max(year)) -> item.cnt

item.cnt |>
  arrange(desc(cnt),desc(first)) |>
  head()
head()

#abstract away from vendor and count units sold across time
items.2 |>
  group_by(order.dt, Barcode,Department) |>
  summarize(total.sold = sum(Quantity), total.weight = sum(Weight)) -> agg.totals

#any comprehensive study of sales pattern is limited by the duration of sales logs; Vori was only adopted in 09/2023
#identify the distribution of tenure by Barcode
items.2 |>
  group_by(Barcode) |>
  summarize(min=min(order.dt)) -> first.date.barcode

#plot distribution by age
first.date.barcode |>
  group_by(min) |>
  summarize(size=n()) |>
  ggplot(aes(x=min,y=size)) +
  geom_bar(stat="identity")

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
