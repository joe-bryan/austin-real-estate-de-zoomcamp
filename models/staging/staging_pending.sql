{{ config(materialized='view') }}

with source as (
    
    select *
    from {{ source('austin_listings', 'pending') }}

),

source_decade as (

    select
       CONCAT(SUBSTRING(CAST(source.year_built AS STRING), 1, 3), "0s") AS decade_built
       , CAST(style AS STRING) as style
       , zip_code
       , year_built
    from source

),

avg_price_all as (

    select
        ROUND(AVG(list_price), 0) AS avg_price_by_zipcode_by_style
        , zip_code
        , CAST(style AS STRING) as style
    from {{ source('austin_listings', 'pending') }}
    GROUP BY 
        zip_code
        , style

),

avg_price_decade as (

    select
        ROUND(AVG(list_price), 0) AS avg_price_by_decade_by_style
        , CAST(style AS STRING) as style
        , CONCAT(SUBSTRING(CAST(year_built AS STRING), 1, 3), "0s") AS decade_built
    from {{ source('austin_listings', 'pending') }}
    GROUP BY 
        decade_built
        , style

),

avg_price_decade_by_zipcode as (

    select
        ROUND(AVG(list_price), 0) AS avg_price_by_decade_by_style_by_zipcode
        , CAST(style AS STRING) as style
        , CONCAT(SUBSTRING(CAST(year_built AS STRING), 1, 3), "0s") AS decade_built
        , zip_code
    from {{ source('austin_listings', 'pending') }}
    GROUP BY 
        decade_built
        , style
        , zip_code

),

listings_zipcode as (
    
    select
        zip_code
        , COUNT(zip_code) as listings_per_zipcode
    from {{ source('austin_listings', 'pending') }}
    GROUP BY 
        zip_code

),

listings_zipcode_by_style as (
    
    select
        zip_code
        , CAST(style AS STRING) as style
        , COUNT(zip_code) as listings_by_zipcode_by_style
        
    from {{ source('austin_listings', 'pending') }}
    GROUP BY 
        zip_code
        , style

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
        , listings_zipcode_by_style.listings_by_zipcode_by_style
        , source.beds
        , source.full_baths
        , source.half_baths
        , source.sqft
        , CAST(source.year_built AS STRING) as year_built
        , source_decade.decade_built
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
        , avg_price_decade_by_zipcode.avg_price_by_decade_by_style_by_zipcode
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
    JOIN source_decade
    ON source.year_built=source_decade.year_built
    AND source.style=source_decade.style
    AND source.zip_code=source_decade.zip_code
    JOIN avg_price_all
    ON source.zip_code=avg_price_all.zip_code
    AND source.style=avg_price_all.style
    JOIN listings_zipcode
    ON source.zip_code=listings_zipcode.zip_code
    JOIN listings_zipcode_by_style
    ON source.zip_code=listings_zipcode_by_style.zip_code
    AND source.style=listings_zipcode_by_style.style
    JOIN avg_price_decade
    ON source_decade.decade_built=avg_price_decade.decade_built
    AND source_decade.style=avg_price_decade.style
    JOIN avg_price_decade_by_zipcode
    ON source_decade.decade_built=avg_price_decade_by_zipcode.decade_built
    AND source_decade.style=avg_price_decade_by_zipcode.style
    AND source_decade.zip_code=avg_price_decade_by_zipcode.zip_code
)

select 
    *
from 
    cte
