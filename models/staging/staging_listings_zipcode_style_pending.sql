{{ config(materialized='view')}}

with cte as (
    
    select
        zip_code
        , CAST(style AS STRING) as style
        , COUNT(zip_code) as listings_by_zipcode_by_style
        
    from {{ source('sources', 'pending')}}
    GROUP BY 
        zip_code
        , style

)

select *
from cte