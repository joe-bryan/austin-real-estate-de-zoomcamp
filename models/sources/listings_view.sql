{{ config(materialized='view') }}

with source_listings as (

    select
        property_url
        , mls
        , mls_id
        , status
        , style
        , street
        , unit
        , city
        , state
        , zip_code
        , beds
        , full_baths
        , half_baths
        , sqft
        , year_built
        , days_on_mls
        , list_price
        , list_date
        , sold_price
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
        , timestamp

    from {{ source('austin_listings', 'listings') }}
)

select 
    *
from 
    source_listings