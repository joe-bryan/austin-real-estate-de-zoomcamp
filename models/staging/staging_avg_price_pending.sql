{{ config(materialized='view')}}

with cte as (

    select
        ROUND(AVG(list_price), 0) AS avg_price_by_zipcode_by_style
        , zip_code
        , CAST(style AS STRING) as style
    from {{ source('sources', 'pending')}}
    GROUP BY 
        zip_code
        , style

)

select
    *
from cte