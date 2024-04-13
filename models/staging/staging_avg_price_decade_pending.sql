{{ config(materialized='view')}}

with cte as (

    select
        ROUND(AVG(list_price), 0) AS avg_price_by_decade_by_style
        , CAST(style AS STRING) as style
        , CONCAT(SUBSTRING(CAST(year_built AS STRING), 1, 3), "0s") AS decade_built
    from {{ source('sources', 'pending') }}
    GROUP BY 
        decade_built
        , style

)

select
    *
from cte