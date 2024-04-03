## Austin For Sale Listings - Project Overview
---
### Can I get some analysis with those new listings? 
Sure, we can go to the apps and see what is newly being listed. A 3 bed / 2 bath on the eastside for $650,000? That sounds good! With maybe one other listing in that zip code, you could know if the property you like is at a good price. But what if there are 20? Making that comparison is so much harder then. This data engineering project aims to make the shopping experience a bit easier by providing visualizations such as what is the average price of listings in that zip code, how much more or less is a specific listing from the average of the zip code, and other lesser-known statistics.

This would not be possible without [HomeHarvest](https://github.com/Bunsly/HomeHarvest/tree/master), a real estate scraping tool that grabs listings from [Realtor.com](https://realtor.com). **HomeHarvest** provides two ways to get listings: a Python library or their site **tryhomeharvest.com**. In this project, we'll use the Python library as a way to document our steps with code.

The logistics of this project take some twists and turns, especially since there will be an initial batch along with continuous batches of data. but careful documentation and description of each step will help you follow along.

### 1. Tech Stack
This is a quick snapshot of the technologies used to make this data engineering pipeline possible.

### 2. Project Configuration

To reproduce this project, a Google Cloud account is needed. 

* If you don't have an account, create an account with your Google email.
* Setup a project with an appropriate name. E.g., "austin-real-estate" and save the Project ID as it will be used later on in various resources.
* 
