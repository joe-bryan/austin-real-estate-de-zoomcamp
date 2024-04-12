{{ config(materialized='view') }}

with cte as (

    select
       CONCAT(SUBSTRING(CAST(year_built AS STRING), 1, 3), "0s") AS decade_built
       , CAST(style AS STRING) as style
       , zip_code
       , year_built
    from {{ source('austin_listings', 'listings') }}

)

select
    *
from cte