{{ config(materialized='view')}}

with cte as (

    select
        ROUND(AVG(list_price), 0) AS avg_price_by_decade_by_style_by_zipcode
        , CAST(style AS STRING) as style
        , CONCAT(SUBSTRING(CAST(year_built AS STRING), 1, 3), "0s") AS decade_built
        , zip_code
    from {{ source('sources', 'listings') }}
    GROUP BY 
        decade_built
        , style
        , zip_code

)

select *
from cte