import cart_analysis_package.df_transforms as dft
import pytest
import pandas as pd

@pytest.fixture
def retrieve_df():
    df = pd.read_csv('./data/1Q26_orders.csv')
    return df

@pytest.fixture
def process_df(retrieve_df):
    df = retrieve_df
    df = dft.clean_df2(df)
    df = dft.remove_negative(df)
    df = dft.subset_shopping2(df)
    return df


def test_setup(retrieve_df):
    df = dft.clean_df2(retrieve_df)
    #print(sorted(df.columns))
    """expects: order_id,sales,discount_and_rewards"""
    df = dft.remove_negative(df)
    print(sorted(df.columns))
    df = dft.subset_shopping2(df)
    assert isinstance(df, pd.DataFrame)
    assert df.shape[0] > 0

def test_encoding(retrieve_df):
    df = dft.clean_df2(retrieve_df)
    df = dft.remove_negative(df)
    df = dft.subset_shopping2(df)
    df2 = dft.encoding(df,'dept_list')
    assert isinstance(df2, pd.DataFrame)
    print(df2.dtypes)
    assert df2.shape[0] > 0