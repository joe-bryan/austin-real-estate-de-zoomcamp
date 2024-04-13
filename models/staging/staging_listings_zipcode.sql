{{ config(materialized='view')}}

with cte as (
    
    select
        zip_code
        , COUNT(zip_code) as listings_per_zipcode
    from {{ source('sources', 'listings')}}
    GROUP BY 
        zip_code

)

select *
from cte