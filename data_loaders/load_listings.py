from homeharvest import scrape_property
from datetime import datetime
from pandas import DataFrame

if "data_loader" not in globals():
    from mage_ai.data_preparation.decorators import data_loader
if "test" not in globals():
    from mage_ai.data_preparation.decorators import test


@data_loader
def load_listings_data(*args, **kwargs) -> DataFrame:
    """
    Template code for loading data from any source.

    Returns:
        Anything (e.g. data frame, dictionary, array, int, str, etc.)
    """
    # Generate filename based on current timestamp
    current_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    listings = scrape_property(
        location="Austin, TX",
        listing_type="for_sale",  # or (for_sale, for_rent, pending)
    )
    listings["style"] = listings["style"].astype("str")
    listings["timestamp"] = current_timestamp

    print(f"Number of properties: {len(listings)}")

    return listings


@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, "The output is undefined"


@test
def assert_columns(df):
    expected_columns = [
        "property_url",
        "mls",
        "mls_id",
        "status",
        "style",
        "street",
        "unit",
        "city",
        "state",
        "zip_code",
        "beds",
        "full_baths",
        "half_baths",
        "sqft",
        "year_built",
        "days_on_mls",
        "list_price",
        "list_date",
        "sold_price",
        "last_sold_date",
        "lot_sqft",
        "price_per_sqft",
        "latitude",
        "longitude",
        "stories",
        "hoa_fee",
        "parking_garage",
        "primary_photo",
        "alt_photos",
        "timestamp",
    ]
    assert set(df.columns) == set(
        expected_columns
    ), "Columns of the dataframe are not correct"


@test
def assert_style_column(df):
    assert df["style"].dtype == "object", "The 'style' column is not of type string"
