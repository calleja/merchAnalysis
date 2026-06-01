import pandas as pd

# %%
def clean_df(df):
    """ order_date, test"""
    df.columns = [i.replace(' ', '_').lower() for i in df.columns]
    df['order_date'] = pd.to_datetime(df['order_date'], errors='coerce')
    df = df.assign(order_date_str = df['order_date'].dt.date)
    return df


# %%

#check columns names with this decorator
def check_columns(func):
    def wrapper(df):
    #only works for functions where the only parameter is a dataframe
        required = [c.strip() for c in func.__doc__.split(',')]
        if all(col in df.columns for col in required):
            return func(df)
        else:
            print(f"Error: {func.__doc__} not found in columns")
            return None
    return wrapper

@check_columns
def remove_negative(df):
    #remove order IDs having total sales < 0
    #function helper comments
    """order_id,sales,discount_and_reward"""
    #expected = a df with columns: order_id, sales_sum, discount_sum
    neg_sales = df.groupby(['order_id']).agg(sales_sum=('sales','sum'),discount_sum=('discount_and_reward','sum')).query('sales_sum <0').reset_index()
    non_neg = df[~df['order_id'].isin(neg_sales['order_id'])]
    return non_neg


def subset_shopping(df):
    cols = ['barcode','brand','department','items_total','order_date',
'product_id','quantity','sub-department','order_id','sales','order_date_str']
    df2 = df.loc[:,cols]
    return df2

#help me handle odd column names; created by AI
import re

def to_underscored(text: str) -> str:
    """
    Convert a string to underscore-separated words with these rules:
    1) Replace ' - ' (dash with spaces on both sides) with a single '_'
    2) Replace '-' between non-space chars (e.g., 'sub-department') with '_'
    3) Replace remaining spaces with '_'
    4) Collapse multiple underscores into one and trim edge underscores
    """
    s = text.strip()

    # Rule 1: " - " -> "_"
    s = re.sub(r"\s-\s", "_", s)

    # Rule 2: dash between two non-space chars -> "_"
    s = re.sub(r"(?<=\S)-(?=\S)", "_", s)

    # Rule 3: one or more spaces -> "_"
    s = re.sub(r"\s+", "_", s)

    # Cleanup: collapse "__" and trim leading/trailing "_"
    s = re.sub(r"_+", "_", s).strip("_")

    return s

#this version of the function is for Vori's newer reporting format (ao 5/26/2026)
def clean_df2(df):
    #replace dashes with underscores
    df.columns = [to_underscored(i).lower() for i in df.columns]
    df['order_date'] = pd.to_datetime(df['order_date'], errors='coerce')
    df = df.assign(order_date_str = df['order_date'].dt.date)
    return df

@check_columns
def subset_shopping2(df):
    """ barcode, brand, department, items_amount, order_date, product_name_id, quantity, sub_department, order_id, sales, order_date_str """
    cols = ['barcode','brand','department','items_amount','order_date',
'product_name_id','quantity','sub_department','order_id','sales','order_date_str']
    df2 = df.loc[:,cols]
    return df2