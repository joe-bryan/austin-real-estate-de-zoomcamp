{{ config(materialized='view')}}

with source as (
    
    select *
    from {{ source('sources', 'pending')}}

),

decade as (
    
    select *
    from {{ ref('staging_decade_pending')}}

),

avg_price_all as (
    
    select *
    from {{ ref('staging_avg_price_pending')}}

),

avg_price_decade as (
    
    select *
    from {{ ref('staging_avg_price_decade_pending')}}

),

avg_price_decade_zipcode as (
    
    select *
    from {{ ref('staging_avg_price_decade_zipcode_pending')}}

),

listings_zipcode as (
    
    select *
    from {{ ref('staging_listings_zipcode_pending')}}

),

listings_zipcode_style as (
    select *
    from {{ ref('staging_listings_zipcode_style_pending')}}
),

cte as (

    select
        source.property_url
        , source.mls
        , source.mls_id
        , source.status
        , CAST(source.style AS STRING) AS style
        , source.street
        , source.unit
        , source.city
        , source.state
        , source.zip_code
        , listings_zipcode.listings_per_zipcode
        , listings_zipcode_style.listings_by_zipcode_by_style
        , source.beds
        , source.full_baths
        , source.half_baths
        , source.sqft
        , CAST(source.year_built AS STRING) as year_built
        , decade.decade_built
        , source.days_on_mls
        , CASE
            WHEN source.days_on_mls <= 7 THEN 'new'
            WHEN source.days_on_mls > 7 AND source.days_on_mls <= 30 THEN 'less than a month'
            ELSE 'more than a month'
          END AS time_on_market
        , source.list_price
        , avg_price_all.avg_price_by_zipcode_by_style
        , (
            ROUND(source.list_price - avg_price_all.avg_price_by_zipcode_by_style, 0)
          ) AS difference_from_avg
        , CASE
            WHEN ROUND(source.list_price - avg_price_all.avg_price_by_zipcode_by_style, 0) > 0 THEN 'more'
            WHEN ROUND(source.list_price - avg_price_all.avg_price_by_zipcode_by_style, 0) < 0 THEN 'less'
            ELSE 'equal'
          END AS more_or_less_than_avg
        , avg_price_decade.avg_price_by_decade_by_style
        , avg_price_decade_zipcode.avg_price_by_decade_by_style_by_zipcode
        , CAST(source.list_date AS DATE) AS list_date
        , CAST(source.last_sold_date AS DATE) AS last_sold_date
        , source.lot_sqft
        , source.price_per_sqft
        , source.latitude
        , source.longitude
        , source.stories
        , source.hoa_fee
        , source.parking_garage
        , source.primary_photo
        , source.alt_photos
        , CAST(source.timestamp AS TIMESTAMP) AS timestamp

    from source
    JOIN decade
    ON source.year_built=decade.year_built
    AND source.style=decade.style
    AND source.zip_code=decade.zip_code
    JOIN avg_price_all
    ON source.zip_code=avg_price_all.zip_code
    AND source.style=avg_price_all.style
    JOIN listings_zipcode
    ON source.zip_code=listings_zipcode.zip_code
    JOIN listings_zipcode_style
    ON source.zip_code=listings_zipcode_style.zip_code
    AND source.style=listings_zipcode_style.style
    JOIN avg_price_decade
    ON decade.decade_built=avg_price_decade.decade_built
    AND decade.style=avg_price_decade.style
    JOIN avg_price_decade_zipcode
    ON decade.decade_built=avg_price_decade_zipcode.decade_built
    AND decade.style=avg_price_decade_zipcode.style
    AND decade.zip_code=avg_price_decade_zipcode.zip_code
),

unique_cte as (

    select DISTINCT *
    from cte
)

select *
from unique_cte
