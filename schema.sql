--TEAM 5 001_building_footprint table
CREATE TABLE IF NOT EXISTS BuildingFootprint (
  buildingCarbonFootprintID SERIAL PRIMARY KEY,
  timeHourly TIMESTAMP NOT NULL,
  zone VARCHAR(50),
  block VARCHAR(50),
  floor VARCHAR(50),
  room VARCHAR(50),
  totalRoomCo2 DOUBLE PRECISION NOT NULL
);