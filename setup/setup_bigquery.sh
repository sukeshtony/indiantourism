#!/bin/bash

PROJECT_ID=$(gcloud config get-value project)
DATASET_NAME="india_tourism"
LOCATION="US"

# Generate bucket name
if [ -z "$1" ]; then
    BUCKET_NAME="gs://india-tourism-data-$PROJECT_ID"
    echo "No bucket provided. Using default: $BUCKET_NAME"
else
    BUCKET_NAME=$1
fi

echo "------------------------------------------------------------"
echo "India Tourism AI Agent Setup"
echo "Project: $PROJECT_ID"
echo "Dataset: $DATASET_NAME"
echo "Bucket:  $BUCKET_NAME"
echo "------------------------------------------------------------"

# 1️⃣ Create Bucket
echo "[1/6] Checking bucket..."
if gcloud storage buckets describe $BUCKET_NAME >/dev/null 2>&1; then
    echo "Bucket already exists."
else
    echo "Creating bucket..."
    gcloud storage buckets create $BUCKET_NAME --location=$LOCATION
fi

# 2️⃣ Upload CSV data
echo "[2/6] Uploading data..."
gcloud storage cp data/*.csv $BUCKET_NAME

# 3️⃣ Create Dataset
echo "[3/6] Creating dataset..."
if bq show "$PROJECT_ID:$DATASET_NAME" >/dev/null 2>&1; then
    echo "Dataset exists."
else
    bq mk --location=$LOCATION "$PROJECT_ID:$DATASET_NAME"
fi

# 4️⃣ Tourist Places Table
echo "[4/6] Creating tourist_places table..."

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.tourist_places\` (
    zone STRING,
    state STRING,
    city STRING,
    name STRING,
    type STRING,
    establishment_year INT64,
    visit_time_hours FLOAT64,
    google_rating FLOAT64,
    entrance_fee_inr INT64,
    airport_nearby STRING,
    weekly_off STRING,
    significance STRING,
    dslr_allowed STRING,
    review_count_lakhs FLOAT64,
    best_time_to_visit STRING
)
OPTIONS(description='Top tourist attractions in India');
"

bq load --source_format=CSV --skip_leading_rows=1 --replace \
"$PROJECT_ID:$DATASET_NAME.tourist_places" \
"$BUCKET_NAME/tourist_places.csv"

# 5️⃣ Hotels Table
echo "[5/6] Creating hotels table..."

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.hotels\` (
    serial_no INT64,
    state STRING,
    city STRING,
    category STRING,
    alcohol STRING,
    hotel_name STRING,
    address STRING,
    start_date DATE,
    expiry_date DATE,
    total_rooms INT64
)
OPTIONS(description='Hotels available across India');
"

bq load --source_format=CSV --skip_leading_rows=1 --replace \
"$PROJECT_ID:$DATASET_NAME.hotels" \
"$BUCKET_NAME/hotels_india.csv"

# 6️⃣ Indian Restaurants Table
echo "[6/6] Creating indian_restaurants table..."

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.indian_restaurants\` (
    restaurant_name STRING,
    rating FLOAT64,
    average_price INT64,
    avg_delivery_time INT64,
    south_indian BOOL,
    north_indian BOOL,
    fast_food BOOL,
    street_food BOOL,
    biryani BOOL,
    bakery BOOL,
    location STRING
)
OPTIONS(description='Indian restaurant dataset');
"

bq load --source_format=CSV --skip_leading_rows=1 --replace \
"$PROJECT_ID:$DATASET_NAME.indian_restaurants" \
"$BUCKET_NAME/indian_restaurants.csv"


# 7️⃣ Zomato Restaurants Table
echo "[7/7] Creating zomato_restaurants table..."

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`$PROJECT_ID.$DATASET_NAME.zomato_restaurants\` (
    res_id INT64,
    name STRING,
    establishment STRING,
    url STRING,
    address STRING,
    city STRING,
    city_id INT64,
    locality STRING,
    latitude FLOAT64,
    longitude FLOAT64
)
OPTIONS(description='Zomato restaurant dataset for India');
"

bq load --source_format=CSV --skip_leading_rows=1 --replace \
"$PROJECT_ID:$DATASET_NAME.zomato_restaurants" \
"$BUCKET_NAME/zomato_restaurants.csv"


echo "------------------------------------------------------------"
echo "Tourism Dataset Setup Complete!"
echo "------------------------------------------------------------"
