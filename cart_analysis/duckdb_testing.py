# %%
import duckdb as ddb
import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import datetime
import seaborn as sns
import cart_analysis_package.df_transforms as df_transforms

"""
sample code for duckdb:
pandas_df = pd.DataFrame({"a": [42]})
duckdb.sql("SELECT * FROM pandas_df")
"""

# %%
#df = pd.read_csv('./Items with cost(2).csv')
df = pd.read_csv('./1Q26_orders.csv')
display(df.shape)
df = df_transforms.clean_df2(df)
df = df_transforms.remove_negative(df)
display(df.shape)
df = df_transforms.subset_shopping2(df)
#sorted(df.columns)

# %%
con = ddb.connect()
con.register("df", df)
#con.execute("CREATE TABLE test_df_table AS SELECT * FROM df")


# %%
print(con.table("df").dtypes)

print(con.execute("DESCRIBE TABLE df").df())

# %%
# order metadata along with a list of unique departments (as an array)
con.execute(
"""
SELECT order_id, order_date_str, array_agg(DISTINCT department) dept_array, 
SUM(sales) AS order_sales, SUM(quantity) AS order_quantity
FROM df
GROUP BY 1,2
LIMIT 3
""").df()

# %%
# requires a subquery: order metadata along with ea component deparment and # of items in order
con.execute(
"""
SELECT
    order_id, order_date_str, 
    SUM(dept_sales) AS order_sales_all, SUM(dept_qty) AS order_quantity_all,
    list(DISTINCT department) AS dept_array,
    map_from_entries(list(struct_pack(k := department, v := dept_qty))) AS dept_data
FROM (
    SELECT order_id, order_date_str, department, 
    SUM(quantity) AS dept_qty, SUM(sales) AS dept_sales
    FROM df
    GROUP BY 1,2,3
)
GROUP BY 1,2
LIMIT 3;
""").df()


# %%
# in order to facilitate the average cart value by deparment, I need order metadata alongside each deparment; this can simply be done by broadcasting the list of unique deparments along the order metadata
#store the resulset as a df
df2 = con.execute(
"""
SELECT order_id, order_date_str, unnest(dept_array) dept, order_sales, order_quantity
FROM (
    SELECT order_id, order_date_str, array_agg(DISTINCT department) dept_array, 
    SUM(sales) AS order_sales, SUM(quantity) AS order_quantity
    FROM df
    GROUP BY 1,2
    LIMIT 3
) as t
""").df()

# %%
#look at a monthly avg of cart value by department (ie if the department appears in the cart, what is the average cart sales value)
con.register("df2", df2)

con.execute("""
select date_trunc('month',order_date_str) as month, dept, avg(order_sales) as avg_cart_sales, avg(order_quantity) as avg_cart_quantity
from df2
group by 1,2
order by 1,2
""").df()
# %%
