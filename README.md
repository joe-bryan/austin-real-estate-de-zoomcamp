## Austin For Sale Listings - Project Overview
---
### Can I get some analysis with those new listings? 
Sure, we can go to the apps and see what is newly being listed. A 3 bed / 2 bath on the eastside for $650,000? That sounds good! With maybe one other listing in that zip code, you could know if the property you like is at a good price. But what if there are 20? Making that comparison is so much harder then. This data engineering project aims to make the shopping experience a bit easier by providing visualizations such as what is the average price of listings in that zip code, how much more or less is a specific listing from the average of the zip code, and other lesser-known statistics.

This would not be possible without [HomeHarvest](https://github.com/Bunsly/HomeHarvest/tree/master), a real estate scraping tool that grabs listings from [Realtor.com](https://realtor.com). **HomeHarvest** provides two ways to get listings: a Python library or their site **tryhomeharvest.com**. In this project, we'll use the Python library as a way to document our steps with code.

The logistics of this project take some twists and turns, especially since there will be an initial batch along with continuous batches of data. but careful documentation and description of each step will help you follow along.

### 1. Tech Stack
This is a quick snapshot of the technologies used to make this data engineering pipeline possible.




### 2. Project Configuration

To reproduce this project, a [Google Cloud](https://www.cloud.google.com) account is needed. The steps below highlight what is needed. Side note, this project can also be run locally, but I have not fully tested it. 

* If you don't have an account, create an account with your Google email.
* Create a project with an appropriate name, e.g., "austin-real-estate", and save the Project ID as it will be used later in various resources.
* Follow the instructions in this article called, ["Setting up the development environment on Google Virtual Machine"](https://itsadityagupta.hashnode.dev/setting-up-the-development-environment-on-google-virtual-machine) by Aditya Gupta to get a virtual machine ready. You can skip the sections: ```Installing Pgcli```, ```Installiing Pyspark```, and ```Cloning the course repo```.

#### A. Clone the Repo

Finally, we can clone this repository with this line of code

```
git clone https://github.com/joe-bryan/austin-real-estate-de-zoomcamp.git
```

After the command runs, you can run ```ls``` to see the repository in your directory. Run ```cd austin-real-estate-de-zoomcamp``` to move into the git repo directory.

#### B. Terraform

[Terraform](https://www.terraform.io/) is Infrastructure-as-Code, and it is used to automate cloud resources configuration. Two Terraform files are used to build the cloud resources, ```main.tf``` and ```variables.tf```.

```main.tf```

```
terraform {
  required_version = ">= 1.0"
  backend "local" {}  # Can change from "local" to "gcs" (for google) or "s3" (for aws), if you would like to preserve your tf-state online
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project
  region = var.region
  // credentials = file(var.credentials)  # Use this if you do not want to set env-var GOOGLE_APPLICATION_CREDENTIALS
}

# Data Lake Bucket
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "data-lake-bucket" {
  name          = var.gcs_bucket_name
  location      = var.region
  force_destroy = true

  # Optional, but recommended settings:
  storage_class = var.storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled     = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30  // days
    }
  }
}

# DWH
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset
resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = var.bq_dataset_name
  project    = var.project
  location   = var.region
}
```

```variables.tf```

```
variable "project" {
  description = "austin-real-estate-de-project"
  default = "austin-real-estate-de-project"
}

variable "region" {
  description = "Region for GCP resources. Choose as per your location: https://cloud.google.com/about/locations"
  default = "us-east1"
  type = string
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  #Update the below to a unique bucket name
  default     = "aus_listings"
}

variable "storage_class" {
  description = "Storage class type for your bucket. Check official docs for more info."
  default = "STANDARD"
}

variable "bq_dataset_name" {
  description = "BigQuery Dataset that raw data (from GCS) will be written to"
  type = string
  default = "austin_new_listings"
}
```

Run ```cd terraform``` to move into the terraform directory that has the main and variable files. To make sure we have the proper permissions in GCP, run these two commands

```
export GOOGLE_APPLICATION_CREDENTIALS="<path/to/your/service-account-authkeys>.json"

# Refresh token/session, and verify authentication
gcloud auth application-default login
```

The following prompts can be run from the command line of the virtual machine once the files above are configured. 

Initialize and configure the backend
```
terraform init
```

Propose an execution plan. 
```
terraform plan
```

Ask for approval of plan, and apply changes.
```
terraform apply
```

Destroy stack of resources once you are done with the project
```
terraform destroy
```



### 3. Workflow Orchestration

[Mage](https://www.mage.ai/) serves as the data pipeline tool that will bring the real estate listings over to Google Cloud Storage. After it lands in GCS, another script will move the data to BigQuery. To start up Mage, run these pieces of code:
```
cp dev.env .env 
```

```
docker compose up -d
```
To check that the container is up and running, ```docker ps``` displays what containers are running along with other details.


The first command will the project name for Mage, and the second will run the Docker container in a detached manner that holds Mage. Next, we will forward the port that Mage has. 

* Open Visual Studio Code and install the ```Remote - SSH``` extension. 
* VS Code has a button on the bottom left corner named ```Open a Remote Window```. Select the button and choose ```Connect to Host...``` on the menu at the top. You should see the name of the ssh alias for the virtual machine you created and select it. VS Code now has access to the virtual machine. 
* Open up a terminal window in VS Code and select ```PORTS``` on the menu.
* Select ```Forward a Port```
* In the Port section, type in ```6789```. That is the port for Mage.
* Go to Mage by typing in ```localhost:6789``` on your browser.

Now that Mage is up and running, we have to copy our Google service account key from the ```.gcp``` directory over to the git repo directory for Mage to have access. Here's what to do:

* ```cd``` to get to the home directory
* ```cd .gcp``` to be in the directory of the service key
* ```cp service_account_key_name.json ~/austin-real-estate-de-zoomcamp``` to copy the key to the repo
* Go back to Mage, select Files on the left menu, and open ***io_config.yaml***. Scroll down to GOOGLE_SERVICE_ACC_KEY_FILEPATH. There you can put the path of the key ```/home/src/service_account_key_name.json```. You also comment out the rest of the GOOGLE_SERVICE_ACC_KEY lines as they are not needed. Save the file.

We ensure that Mage has the HomeHarvest library needed to get the listings. On the left sided menu, select the Terminal and run this code ```pip install homeharvest```. Later on, if running the script gives an error about updating dask, copy the pip install code and open up the Mage terminal and paste it there.

In the repository, the folders ```data_loaders``` ```data_exporters``` and ```transformers``` hold the scripts to the pipelines in Mage. Data loader scripts load data, transformers clean up the data, and data exporters push the data out.

You can copy the scripts over to the project folders within Mage by:

* Go to the terminal in Mage
* run ```cp data_loaders/script_name aus-new-listings/data_loaders/script_name``` for the data_loader files
* run ```cp transformers/script_name aus-new-listings/transformers/script_name``` for the transformers files
* run ```cp data_exporters/script_name aus-new-listings/data_exporters/script_name``` for the data_exporters files

Now the files are within Mage and can be used in pipelines

There are two pipelines that are run in Mage:

* hourly_listings
* hourly_pendings

The hourly_listings pipeline runs every hour and brings in the all the for sale listings. It saves the listings to ***all_listings.parquet*** to have a file that has the latest data, and also saves to GCS in this manner: ```%Y-%m-%d/%H:%M/for_sale_listings.parquet``` to keep a record of the listings each hour. The listings that hour are also pushed to the BigQuery table ```listings```. Here is the tree diagram to organize files and connect them correctly.



The hourly_pendings pipeline runs every hour and brings in the all the pending listings. It saves the pending listings to ***all_pending.parquet*** to have a file that has the latest data, and also saves to GCS in this manner: ```%Y-%m-%d/%H:%M/pending_listings.parquet``` to keep a record of the pending listings each hour. The pending listings that hour are also pushed to the BigQuery table ```pending```. Here is the tree diagram to organize files and connect them correctly.

What makes an orchestrator special is its ability to schedule scripts. In our case, these two pipelines will be on a schedule to run every hour. To check if a pipeline has a schedule, click on Pipelines on the left sided menu. On the screen, the first column says Status and next to it is the name of the pipeline. If it says ```active``` in the Status column, that means the schedule is turned on. If it doesn't you can click on a pipeline. Then on the left sided menu, click Triggers. If a schedule doensn't show, select the ```+ New trigger``` button to create one. There are two choices if you want to run this hourly. On the Frequency selection, you can pick hourly or custom. I selected custom to set it using Cron. My Cron schedule is ```55 * * * *``` so that is runs at 55 minutes past the hour every hour. Make sure both pipelines have schedules and are running every hour.


### 4. Data Transformation

#### A. Google Cloud dbt setup

A service account within Big Query needs to be created to enable communication with dbt cloud. Open the [BigQuery Credentials Wizard](https://console.cloud.google.com/apis/credentials/wizard) in Google Cloud. 
* Choose ```BigQuery API``` for Select an API * and
* ```Application Data``` for What data will you be accessing?
* For the service account, give it a name relating to dbt. I chose ```dbt-service-account```
* You can choose the encompassing ```BigQuery Admin``` role, or more specific roles if you want. I chose ```BigQuery Admin```.
* Select Done at the bottom.
* Go to IAM & Admin, Service Accounts, and click on the new service account.
* Select Keys at the top, then ADD KEY, Create new key, and in JSON format. This downloads the key to your computer.

#### B. dbt Cloud Project Setup

* Create a [dbt Cloud](https://www.getdbt.com/pricing/) account
* After logging in, it prompts you to Complete project setup. Choose BigQuery as your connection.
* Upload the Service Account key for dbt, which will fill out many fields below.
* In Development Credentials, select a relevant Dataset name. Then click on Test Connection on the bottom right hand side. If it is successful, click Next.

#### C. Setup GitHub & dbt Cloud

* In Setup a repository, click on Git Clone. You will need a GitHub repo that you have Admin access, or select Managed Repository. If using Managed Repository, the steps below can be skipped.
* Go the main page of repository you are going to use press Code, SSH, and copy the url.
* Paste the url back in dbt Cloud, and press Import.
* A deploy key is generated, go to your repository and go to the settings tab. Under security you'll find the menu deploy keys. Click on add key and paste the deploy key provided by dbt cloud. Make sure to tick "write access". 
* By going to the next page, select Start developing in the IDE.
* After it loads, dbt is ready to be used.
* Press Initialize dbt project as that will create the folder structure.
* Make an initial commit by clicking Commit and sync. It will prompt you to create a new branch. You can use the commit message "initial commit" and click Commit.

Now we can get to work on a crucial dbt file: ```dbt_project.yml``` 

```dbt_project.yml``` has some basic information about the dbt project plus some options that can be made. We will stick to the defaults, but make sure that name matches what goes under models.

```

# Name your project! Project names should contain only lowercase characters
# and underscores. A good package name should reflect your organization's
# name or the intended use of these models
name: 'dbt_austin_real_estate' # name of dataset in bigquery
version: '1.0.0'
config-version: 2

# This setting configures which "profile" dbt uses for this project.
profile: 'default'

# These configurations specify where dbt should look for different types of files.
# The `model-paths` config, for example, states that models in this project can be
# found in the "models/" directory. You probably won't need to change these!
model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

target-path: "target"  # directory which will store compiled SQL files
clean-targets:         # directories to be removed by `dbt clean`
  - "target"
  - "dbt_packages"


# Configuring models
# Full documentation: https://docs.getdbt.com/docs/configuring-models

# In dbt, the default materialization for a model is a view. This means, when you run 
# dbt run or dbt build, all of your models will be built as a view in your data platform. 
# The configuration below will override this setting for models in the example folder to 
# instead be materialized as tables. Any models you add to the root of the models folder will 
# continue to be built as views. These settings can be overridden in the individual model files
# using the `{{ config(...) }}` macro.

models:
  dbt_austin_real_estate:
    # Applies to all files under models/example/
    # example:
    # +materialized: view

```

#### D. Sources

We now bring in sources of data to dbt. That means we will bring the listings and pending tables in BigQuery.

* Create a folder within the models folder and name it sources. 
* On the middle of your screen, click ```+ Create new file```. We create a ```schema.yml``` file that defines the name that we refer to when bringing in source data, the project id from Google, the schema in BigQuery, the tables, and column information. This file gets saved in the sources folder.
* Create a file named ```listings_view.sql``` in the sources folder. This brings in the listings table and makes it a view.
* Create a file named ```pending_view.sql``` in the sources folder. This brings in the pending table and makes it a view.

```schema.yml```

```

version: 2

sources:
  - name: sources
    database: austin-real-estate-de-project
    schema: austin_new_listings
    description: >
      "Data from HomeHarvest that is batched in hourly"
    tables:

      - name: listings
        columns:
          - name: mls_id
            description: "The primary key for this table"

      - name: pending
        columns:
          - name: mls_id
            description: "The primary key for this table"

models:
    - name: listings_view
      description: >
        HomeHarvest is a real estate scraper that gets listings data from Realtor.com. The data 
        is of listings for sale in the Austin, TX area. If its for sale in the area, the data is here.
        The listing can come from multiple MLS groups.
      columns:
        - name: property_url
          description: The url of the listing on Realtor.com.
        - name: mls
          description: The multiple listing network that is listing the home.
        - name: mls_id
          description: The id in the mls group the listings belongs to.
        - name: status
          description: Whether the home is for sale, pending, or sold.
        - name: style
          description: The style of the listing. For example, single-family, condo, etc.                                   
        - name: street
          description: The street of where the listing is.
        - name: unit
          description: The unit information if the listing has one.
        - name: city
          description: The city of the listing.
        - name: state
          description: The state of the listing.
        - name: zip_code
          description: The zipcode of the listing.
        - name: beds
          description: How many beds the listing has.
        - name: full_baths
          description: The number of full baths the listing has.
        - name: half_baths
          description: The number of half baths the listing has
        - name: sqft
          description: The square feet of the listing.
        - name: year_built
          description: When the home was built.
        - name: days_on_mls
          description: The number of days the listing has been on Realtor.com
        - name: list_price
          description: The listed price.
        - name: list_date
          description: The date of when it was listed.          
        - name: property_url
          description: The url of the listing on Realtor.com
        - name: sold_price
          description: The price of when it was sold. Since these two tables do not have sold listings, this column will be removed in staging.
        - name: last_sold_date
          description: The date of the last time the home was sold. Sometimes this is provided.
        - name: lot_sqft
          description: The lot square feet of the listing.
        - name: price_per_sqft
          description: The price divided by the square feet of the listing.
        - name: latitude
          description: The latitude coordinate of the listing.
        - name: longitude
          description: The longitude coordinate of the listing.
        - name: stories
          description: The number of stories if provided.
        - name: hoa_fee
          description: The HOA fee if it has one.    
        - name: parking_garage
          description: The number of parking spots provided.
        - name: primary_photo
          description: The url of the primary photo for the listing on Realtor.com.
        - name: alt_photos
          description: Urls of other photos of the listing on Realtor.com.
        - name: timestamp
          description: A timestamp of when the listing was captured.

                           
    - name: pending_view
      description: >
        HomeHarvest is a real estate scraper that gets listings data from Realtor.com. The data 
        is of pending listings in the Austin, TX area. The listing can come from multiple MLS groups.
      columns:
        - name: property_url
          description: The url of the listing on Realtor.com.
        - name: mls
          description: The multiple listing network that is listing the home.
        - name: mls_id
          description: The id in the mls group the listings belongs to.
        - name: status
          description: Whether the home is for sale, pending, or sold.
        - name: style
          description: The style of the listing. For example, single-family, condo, etc.                                   
        - name: street
          description: The street of where the listing is.
        - name: unit
          description: The unit information if the listing has one.
        - name: city
          description: The city of the listing.
        - name: state
          description: The state of the listing.
        - name: zip_code
          description: The zipcode of the listing.
        - name: beds
          description: How many beds the listing has.
        - name: full_baths
          description: The number of full baths the listing has.
        - name: half_baths
          description: The number of half baths the listing has
        - name: sqft
          description: The square feet of the listing.
        - name: year_built
          description: When the home was built.
        - name: days_on_mls
          description: The number of days the listing has been on Realtor.com
        - name: list_price
          description: The listed price.
        - name: list_date
          description: The date of when it was listed.          
        - name: property_url
          description: The url of the listing on Realtor.com
        - name: sold_price
          description: The price of when it was sold. Since these two tables do not have sold listings, this column will be removed in staging.
        - name: last_sold_date
          description: The date of the last time the home was sold. Sometimes this is provided.
        - name: lot_sqft
          description: The lot square feet of the listing.
        - name: price_per_sqft
          description: The price divided by the square feet of the listing.
        - name: latitude
          description: The latitude coordinate of the listing.
        - name: longitude
          description: The longitude coordinate of the listing.
        - name: stories
          description: The number of stories if provided.
        - name: hoa_fee
          description: The HOA fee if it has one.    
        - name: parking_garage
          description: The number of parking spots provided.
        - name: primary_photo
          description: The url of the primary photo for the listing on Realtor.com.
        - name: alt_photos
          description: Urls of other photos of the listing on Realtor.com.
        - name: timestamp
          description: A timestamp of when the listing was captured.
```

```listings_view.sql```

```
{{ config(materialized='view')}}

with forsaledata as (

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

    from {{ source('sources', 'listings')}}

)

select *
from forsaledata
```

```pending_view.sql```

```
{{ config(materialized='view')}}

with pendingdata as (
    
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
    
    from {{ source('sources', 'pending')}}

)

select *
from pendingdata
```

Staging is where we make transformations to the data. This goes back to our problem statement where we wanted to make the shopping experience easier for homes in the Austin area. We'll create some columns that will provide more information about each listing.

* Create a staging folder in the models folder. 
* Create a file named ```schema.yml```. Here we define the models we will create in staging, along with information about some columns and some tests.

This area differs as well as we will create numerous smaller files that are transformations and can be brought in as common table expressions in the main staging files. Here an example of a file that gets the avg price of for sale listings grouped by zip code and style.

```staging_avg_price.sql```

```
{{ config(materialized='view')}}

with cte as (

    select
        ROUND(AVG(list_price), 0) AS avg_price_by_zipcode_by_style
        , zip_code
        , CAST(style AS STRING) as style
    from {{ source('sources', 'listings')}}
    GROUP BY 
        zip_code
        , style

)

select
    *
from cte
```

Another thing to note is that all of these models are being developed as views with the line

```
{{ config(materialized='view') }}
```

```staging_listings.sql```

```
{{ config(materialized='view')}}

with source as (
    
    select *
    from {{ source('sources', 'listings')}}

),

decade as (
    
    select *
    from {{ ref('staging_decade')}}

),

avg_price_all as (
    
    select *
    from {{ ref('staging_avg_price')}}

),

avg_price_decade as (
    
    select *
    from {{ ref('staging_avg_price_decade')}}

),

avg_price_decade_zipcode as (
    
    select *
    from {{ ref('staging_avg_price_decade_zipcode')}}

),

listings_zipcode as (
    
    select *
    from {{ ref('staging_listings_zipcode')}}

),

listings_zipcode_style as (
    select *
    from {{ ref('staging_listings_zipcode_style')}}
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
    LEFT JOIN decade
    ON source.year_built=decade.year_built
    AND source.style=decade.style
    AND source.zip_code=decade.zip_code
    LEFT JOIN avg_price_all
    ON source.zip_code=avg_price_all.zip_code
    AND source.style=avg_price_all.style
    LEFT JOIN listings_zipcode
    ON source.zip_code=listings_zipcode.zip_code
    LEFT JOIN listings_zipcode_style
    ON source.zip_code=listings_zipcode_style.zip_code
    AND source.style=listings_zipcode_style.style
    LEFT JOIN avg_price_decade
    ON decade.decade_built=avg_price_decade.decade_built
    AND decade.style=avg_price_decade.style
    LEFT JOIN avg_price_decade_zipcode
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
```

```staging_pending.sql``` mirrors the listings table except its references cte's that have pending data.

A marts folder is created as it is used for requests for datasets from data analysts, data scientists, ml engineers, etc. For our case, we will create a dataset that can be used for visualization on a dashboard. The dataset will combine listings for sale and pending into one big table.

* Create a marts folder in models.
* Create a schema.yml file in the marts folder. The file describes the model that is going to be created and along with some tests.
* Create a austin_for_sale_and_pending.sql file in the marts folder. Our model will be defined there.

```austin_for_sale_and_pending.sql```

```
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
```

All models are created, which means the dbt build command can be run. You can type that in at the bottom the dbt page. It is successful, the models are created in BigQuery. You can commit your changes to the main branch if you wish. A common error I had initially was that dbt could not find by BigQuery table that was located in ```us-east1```. The error said that the table, schema, and project id were not in that region. To problem solve, I went to Account settings, Projects, and edited the BigQuery connection. There is a setting for location, and I set it to region I wanted Google Cloud to work in. I also deleted the schema in BigQuery that dbt created, and created another one. Its called Create dataset in BigQuery. For location type, I selected Multi-region.

If we want the dbt models to receive the latest data, we have to deploy the models and put them on a schedule.

* Select Deploy, then Environments in top bar menu of dbt.
* Click on ```+ Create environment```
* Give the environment a name and a description if you would like. In Deployment credentials, put the name of the dataset that dbt is writing to in BigQuery. Click ```Save``` at the top.
* Next go to Deploy, then select Jobs. Click ```+ Create job``` and choose Deploy job. Give the job a name and a description. When you scroll down to schedule, you can set it to run minutes after the data is updated in BigQuery. In my case, BigQuery is updated at 55 minutes past the hour so I will put dbt to run 59 minutes past the hour ```59 * * * *```. Click ```Save``` at the top when done.

### 5. Visualizations and Dashboard

I chose Tableau for the visualizations since its maps are top of the line. In a production environment, we would use a live connection to the BigQuery table so that the dashboard updates automatically. However, since this is on Tableau Public, a direct connection to BigQuery is not possible. Instead, we have to download a csv file from the BigQuery table. To do so:

* Run a ```SELECT *``` query on the table
* Download the a csv file to Google Drive. Downloading locally would not get all the rows since the file size limit would be reached.
* A new tab is open. Press the download button to download to your computer.

The csv file is used to make the dashboard in Tableau Public. Additionally, since the csv file is being used, a new csv file needs to be added manually every time to update the data. 

The dashboard brings a live-like experience of the listings currently in the Austin, TX market. All for sale and pending listings can be viewed. Through the gathering and transformation of the data, we are able to answer these questions that make the shopping experience easier for the user.

* How many listings are there currently?
* What is the average price of a listing?
* How many listings are there by zipcode?
* What is the median price by zipcode?
* Is the price of a listing more, less, or equal to the average price of listing in that zipcode in that style?
* What is the difference in price compared to the average price of listing in that zipcode in that style?
* What is the average price of a listing in the same zipcode and style?
* What is the average price of a listing from the same decade and style?
* What is the average price of a listing from the same decade and style and zipcode?
* How many listings are in a zipcode and in the style?
* Being able to search listings by decade built
* Being able to search by how long the listing has been on the market?
* Being able to search by whether a listing is more or less than the average price in the same zipcode and style

Link to the dashboard: [Austin Real Estate Listings](https://public.tableau.com/app/profile/joe.alanis/viz/AustinRealEstate_17130461839520/Listings?publish=yes)