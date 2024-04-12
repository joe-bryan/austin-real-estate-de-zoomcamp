{{ config(materialized='view') }}

with source as (
    
    select *
    from {{ ref('listings_view') }}

), 

cte as (

    select
        property_url
        , mls
        , mls_id::INT
        , status
        , style
        , street
        , unit
        , city
        , state::VARCHAR(2)
        , zip_code
        , beds
        , full_baths
        , half_baths
        , sqft
        , year_built
        , days_on_mls
        , list_price
        , list_date
        , last_sold_date
        , lot_sqft
        , price_per_sqft
        , latitude
        , longitude
        , stories
        , hoa_fee
        , parking_garage
        , primary_photo
        , alt_photos
        , timestamp::TIMESTAMP

    from source
)

select *
from cte