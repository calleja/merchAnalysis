import pandas as pd

def clean_df(df):
    df.columns = [i.replace(' ', '_').lower() for i in df.columns]
    df['order_date'] = pd.to_datetime(df['order_date'], errors='coerce')
    return df

def subset_shopping(df):
    cols = ['barcode','brand','department','items_total','order_date',
'product_id','quantity','sub-department','order_id','sales']
    df2 = df.loc[:,cols]
    return df2