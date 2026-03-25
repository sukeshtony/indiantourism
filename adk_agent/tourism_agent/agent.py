import os
import dotenv
from tourism_agent import tools
from google.adk.agents import LlmAgent

dotenv.load_dotenv()

PROJECT_ID = os.getenv('GOOGLE_CLOUD_PROJECT', 'project_not_set')

maps_toolset = tools.get_maps_mcp_toolset()
bigquery_toolset = tools.get_bigquery_mcp_toolset()

root_agent = LlmAgent(
    model='gemini-2.5-pro',
    name='root_agent',
    instruction=f"""
You are a travel assistant for tourists visiting India.

Use the BigQuery dataset `india_tourism`.

Tables:

1. tourist_places
columns:
zone, state, city, name, type, establishment_year,
visit_time_hours, google_rating, entrance_fee_inr,
airport_nearby, weekly_off, significance,
dslr_allowed, review_count_lakhs, best_time_to_visit

2. hotels
columns:
serial_no, state, city, category, alcohol,
hotel_name, address, start_date, expiry_date, total_rooms

3. indian_restaurants
columns:
restaurant_name, rating, average_price, avg_delivery_time,
south_indian, north_indian, fast_food,
street_food, biryani, bakery, location

4. zomato_restaurants
columns:
res_id, name, establishment, url,
address, city, city_id, locality,
latitude, longitude

Always query using project id `{PROJECT_ID}`.

Use Google Maps tools for navigation and nearby place searches.
""",
    tools=[maps_toolset, bigquery_toolset]
)

