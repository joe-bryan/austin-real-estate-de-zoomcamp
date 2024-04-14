import pandas as pd
from datetime import datetime

if "transformer" not in globals():
    from mage_ai.data_preparation.decorators import transformer
if "test" not in globals():
    from mage_ai.data_preparation.decorators import test


@transformer
def transform(data, data2, *args, **kwargs):
    """
    Template code for a transformer block.

    Add more parameters to this function if this block has multiple parent blocks.
    There should be one parameter for each output variable from each parent block.

    Args:
        data: The output from the upstream parent block
        args: The output from any additional upstream blocks (if applicable)

    Returns:
        Anything (e.g. data frame, dictionary, array, int, str, etc.)
    """
    # Specify your transformation logic here
    current_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    date = datetime.strptime(current_timestamp, "%Y-%m-%d %H:%M:%S").date()

    date_str = date.strftime("%Y-%m-%d")

    print(f"Number of previously listed properties: {len(data2)}")

    print(f"Number of newly listed properties: {len(data)}")

    join_listings = pd.concat([data2, data])

    print((f"Number of joined listed properties: {len(join_listings)}"))

    print((f"Difference in listed properties: {len(data) - len(data2)}"))

    new_listings_noduplicates = join_listings.drop_duplicates(
        subset="mls_id", keep=False
    )

    print((f"New listings in last hour: {len(new_listings_noduplicates)}"))

    print(new_listings_noduplicates["list_date"].value_counts())

    return new_listings_noduplicates


@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, "The output is undefined"
