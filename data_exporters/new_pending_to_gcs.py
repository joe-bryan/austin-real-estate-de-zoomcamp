from mage_ai.settings.repo import get_repo_path
from mage_ai.io.config import ConfigFileLoader
from mage_ai.io.google_cloud_storage import GoogleCloudStorage
from pandas import DataFrame
from os import path

if "data_exporter" not in globals():
    from mage_ai.data_preparation.decorators import data_exporter


@data_exporter
def export_data(data: DataFrame, **kwargs) -> None:
    """
    Exports data to some source.

    Args:
        data: The output from the upstream parent block
        args: The output from any additional upstream blocks (if applicable)

    Output (optional):
        Optionally return any object and it'll be logged and
        displayed when inspecting the block run.
    """
    now = kwargs.get("execution_date")

    now_file_path = now.strftime("%Y-%m-%d")

    hour_file_path = now.strftime("%H:%M")

    config_path = path.join(get_repo_path(), "io_config.yaml")
    config_profile = "default"

    bucket_name = "aus_listings"
    object_key = f"{now_file_path}/{hour_file_path}/pending_listings.parquet"

    GoogleCloudStorage.with_config(
        ConfigFileLoader(config_path, config_profile)
    ).export(
        data,
        bucket_name,
        object_key,
    )
