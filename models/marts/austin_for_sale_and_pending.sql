{{ config(materialized='view')}}

with for_sale as (

    select *
    from {{ ref('staging_listings')}}

),

pending as (

    select *
    from {{ ref('staging_pending')}}

)

select *
from for_sale
UNION DISTINCT
select * 
from pending
ORDER BY list_date DESC