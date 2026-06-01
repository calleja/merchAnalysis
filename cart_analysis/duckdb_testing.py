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
con.execute(
"""
SELECT order_id, order_date_str, array_agg(DISTINCT department) dept_array, 
SUM(sales) AS order_sales, SUM(quantity) AS order_quantity,
struct_pack(k:=department, v:=sum(quantity)) AS dept_quant
FROM df
GROUP BY 1,2
LIMIT 3
""").df()

# %%
# map() takes parallel key/value arrays, not scalar pairs — build entries then aggregate:
#   dept_data['GROCERY']  or  map_extract_value(dept_data, 'GROCERY')
con.execute(
"""
SELECT
    order_id, order_date_str, 
    SUM(dept_sales) AS order_sales, SUM(dept_qty) AS order_quantity,
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
# Query dept_data: bracket access, map_extract_value, or unnest via map_entries
con.execute(
"""
WITH per_order AS (
    SELECT
        order_id,
        order_date_str,
        map_from_entries(list(struct_pack(k := department, v := sum_qty))) AS dept_data
    FROM (
        SELECT order_id, order_date_str, department, SUM(quantity) AS sum_qty
        FROM df
        GROUP BY ALL
    )
    GROUP BY ALL
)
SELECT
    order_id,
    order_date_str,
    dept_data,
    dept_data['GROCERY'] AS grocery_qty,
    map_extract_value(dept_data, 'PRODUCE') AS produce_qty
FROM per_order
LIMIT 3;
""").df()

# %%
