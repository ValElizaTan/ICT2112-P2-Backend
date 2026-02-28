-- Order Rental Processing System Schema
-- Version 1.0
-- Created: 28 Feb 2026

CREATE DATABASE DatabaseDB;
GO

USE DatabaseDB;
GO

--TEAM 1 PRIMARY KEY TABLES

-- ============================================================
-- ENUM Types
-- ============================================================
CREATE TYPE transport_mode AS ENUM (
    'TRUCK', 'SHIP', 'PLANE', 'TRAIN'
);

CREATE TYPE transport_mode_combination AS ENUM (
    'TRUCK_ONLY', 'SHIP_TRUCK', 'AIR_TRUCK', 'RAIL_TRUCK', 'MULTIMODAL'
);

CREATE TYPE preference_type AS ENUM (
    'SPEED', 'COST', 'GREEN'
);

CREATE TYPE batch_status AS ENUM (
    'PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
);

CREATE TYPE carbon_stage_type AS ENUM (
    'DAMAGE_INSPECTION', 'REPAIRING', 'SERVICING', 'CLEANING', 'RETURN'
);

CREATE TYPE hub_type AS ENUM (
    'WAREHOUSE', 'SHIPPING_PORT', 'AIRPORT'
);


-- ============================================================
-- TransportationHub (Parent — Table-Per-Subtype Inheritance)
-- ============================================================
CREATE TABLE transportation_hub (
    hub_id             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hub_type           hub_type         NOT NULL,
    longitude          DOUBLE PRECISION NOT NULL,
    latitude           DOUBLE PRECISION NOT NULL,
    country_code       VARCHAR(10)      NOT NULL,
    address            VARCHAR(255)     NOT NULL,
    operational_status VARCHAR(50),
    operation_time     VARCHAR(50)
);

CREATE TABLE warehouse (
    hub_id                        INT PRIMARY KEY,
    warehouse_code                VARCHAR(100) NOT NULL,
    total_warehouse_volume        FLOAT,
    climate_control_emission_rate FLOAT,
    lighting_emission_rate        FLOAT,
    security_system_emission_rate FLOAT,
    CONSTRAINT fk_warehouse_hub FOREIGN KEY (hub_id)
        REFERENCES transportation_hub(hub_id) ON DELETE CASCADE
);

CREATE TABLE shipping_port (
    hub_id      INT PRIMARY KEY,
    port_code   VARCHAR(20)  NOT NULL,
    port_name   VARCHAR(255) NOT NULL,
    port_type   VARCHAR(50),
    vessel_size VARCHAR(50),
    CONSTRAINT fk_shipping_port_hub FOREIGN KEY (hub_id)
        REFERENCES transportation_hub(hub_id) ON DELETE CASCADE
);

CREATE TABLE airport (
    hub_id       INT PRIMARY KEY,
    airport_code VARCHAR(10)  NOT NULL,
    airport_name VARCHAR(255) NOT NULL,
    terminal     INT,
    CONSTRAINT fk_airport_hub FOREIGN KEY (hub_id)
        REFERENCES transportation_hub(hub_id) ON DELETE CASCADE
);


-- ============================================================
-- Transport (Parent — Table-Per-Subtype Inheritance)
-- ============================================================
CREATE TABLE transport (
    transport_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transport_mode  transport_mode   NOT NULL,
    max_load_kg     DOUBLE PRECISION,
    vehicle_size_m2 FLOAT,
    is_available    BOOLEAN          DEFAULT TRUE
);

CREATE TABLE truck (
    transport_id  INT PRIMARY KEY,
    truck_id      INT         NOT NULL,
    truck_type    VARCHAR(50),
    license_plate VARCHAR(50),
    CONSTRAINT fk_truck_transport FOREIGN KEY (transport_id)
        REFERENCES transport(transport_id) ON DELETE CASCADE
);

CREATE TABLE ship (
    transport_id    INT PRIMARY KEY,
    ship_id         INT         NOT NULL,
    vessel_type     VARCHAR(50),
    vessel_number   VARCHAR(50),
    max_vessel_size VARCHAR(50),
    CONSTRAINT fk_ship_transport FOREIGN KEY (transport_id)
        REFERENCES transport(transport_id) ON DELETE CASCADE
);

CREATE TABLE plane (
    transport_id   INT PRIMARY KEY,
    plane_id       INT         NOT NULL,
    plane_type     VARCHAR(50),
    plane_callsign VARCHAR(50),
    CONSTRAINT fk_plane_transport FOREIGN KEY (transport_id)
        REFERENCES transport(transport_id) ON DELETE CASCADE
);

CREATE TABLE train (
    transport_id  INT PRIMARY KEY,
    train_id      INT         NOT NULL,
    train_type    VARCHAR(50),
    license_plate VARCHAR(50),
    CONSTRAINT fk_train_transport FOREIGN KEY (transport_id)
        REFERENCES transport(transport_id) ON DELETE CASCADE
);


-- ============================================================
-- Route & Route Legs
-- ============================================================
CREATE TABLE route (
    route_id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    origin_address      VARCHAR(255)               NOT NULL,
    destination_address VARCHAR(255)               NOT NULL,
    total_distance_km   DOUBLE PRECISION,
    is_valid            BOOLEAN                    DEFAULT TRUE,
    mode_combination    transport_mode_combination,
    origin_hub_id       INT,
    destination_hub_id  INT,
    CONSTRAINT fk_route_origin_hub      FOREIGN KEY (origin_hub_id)
        REFERENCES transportation_hub(hub_id),
    CONSTRAINT fk_route_destination_hub FOREIGN KEY (destination_hub_id)
        REFERENCES transportation_hub(hub_id)
);

CREATE TABLE route_leg (
    leg_id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    route_id       INT            NOT NULL,
    sequence       INT,
    transport_mode transport_mode,
    start_point    VARCHAR(255),
    end_point      VARCHAR(255),
    distance_km    DOUBLE PRECISION,
    is_first_mile  BOOLEAN        DEFAULT FALSE,
    is_last_mile   BOOLEAN        DEFAULT FALSE,
    transport_id   INT,
    CONSTRAINT fk_route_leg_route     FOREIGN KEY (route_id)
        REFERENCES route(route_id),
    CONSTRAINT fk_route_leg_transport FOREIGN KEY (transport_id)
        REFERENCES transport(transport_id)
);


-- ============================================================
-- Carbon Results & Leg Carbon
-- ============================================================
CREATE TABLE carbon_result (
    carbon_result_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    total_carbon_kg   DOUBLE PRECISION,
    created_at        TIMESTAMP DEFAULT NOW(),
    validation_passed BOOLEAN   DEFAULT FALSE
);

CREATE TABLE leg_carbon (
    leg_id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transport_mode   transport_mode,
    distance_km      DOUBLE PRECISION,
    weight_kg        DOUBLE PRECISION,
    carbon_kg        DOUBLE PRECISION,
    carbon_rate      DOUBLE PRECISION,
    carbon_result_id INT,
    route_leg_id     INT,
    CONSTRAINT fk_leg_carbon_result FOREIGN KEY (carbon_result_id)
        REFERENCES carbon_result(carbon_result_id),
    CONSTRAINT fk_leg_carbon_leg    FOREIGN KEY (route_leg_id)
        REFERENCES route_leg(leg_id)
);


-- ============================================================
-- Shipping Options & Pricing Rules
-- ============================================================
CREATE TABLE shipping_option (
    option_id        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    display_name     VARCHAR(255),
    cost             NUMERIC(10, 2),
    carbon_footprint DOUBLE PRECISION,
    delivery_days    INT,
    is_green_option  BOOLEAN DEFAULT FALSE,
    route_id         INT,
    CONSTRAINT fk_shipping_option_route FOREIGN KEY (route_id)
        REFERENCES route(route_id)
);

CREATE TABLE pricing_rule (
    rule_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transport_mode   transport_mode,
    base_rate_per_km NUMERIC(10, 4),
    is_active        BOOLEAN        DEFAULT TRUE,
    -- NOTE: ERD typed carbon_surcharge as DateTime — corrected to NUMERIC(10,4)
    carbon_surcharge NUMERIC(10, 4)
);


-- ============================================================
-- Customer Choice (Composite PK)
-- NOTE: customer_id and order_id reference external Customer/Order
--       tables not defined in this ERD — FK constraints omitted.
-- ============================================================
CREATE TABLE customer_choice (
    customer_id     INT             NOT NULL,
    order_id        INT             NOT NULL,
    preference_type preference_type,
    created_at      TIMESTAMP       DEFAULT NOW(),
    PRIMARY KEY (customer_id, order_id)
);


-- ============================================================
-- Delivery Batch & Batch Orders
-- NOTE: batch_order.order_id references an external Order table
--       not defined in this ERD — FK constraint omitted.
-- ============================================================
CREATE TABLE delivery_batch (
    delivery_batch_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_hub            VARCHAR(255),
    destination_address   VARCHAR(255),
    delivery_batch_status batch_status DEFAULT 'PENDING',
    total_orders          INT          DEFAULT 0,
    carbon_savings        FLOAT,
    source_hub_id         INT,
    CONSTRAINT fk_delivery_batch_hub FOREIGN KEY (source_hub_id)
        REFERENCES transportation_hub(hub_id)
);


-- ============================================================
-- Product Return & Return Stages
-- ============================================================
CREATE TABLE product_return (
    return_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    return_status VARCHAR(50),
    total_carbon  FLOAT,
    date_in       DATE,
    date_on       DATE
);

CREATE TABLE return_stage (
    stage_id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    return_id             INT              NOT NULL,
    stage_type            VARCHAR(50),
    energy_kwh            DOUBLE PRECISION,
    labour_hours          DOUBLE PRECISION,
    materials_kg          DOUBLE PRECISION,
    cleaning_supplies_qty DOUBLE PRECISION,
    water_litres          DOUBLE PRECISION,
    packaging_kg          DOUBLE PRECISION,
    storage_hours         DOUBLE PRECISION,
    CONSTRAINT fk_return_stage_return FOREIGN KEY (return_id)
        REFERENCES product_return(return_id)
);

CREATE TABLE carbon_emission (
    emission_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stage_id    INT               NOT NULL,
    carbon_kg   FLOAT,
    stage_type  carbon_stage_type,
    CONSTRAINT fk_carbon_emission_stage FOREIGN KEY (stage_id)
        REFERENCES return_stage(stage_id)
);


-- TEAM 1 CROSS TEAM FK TABLES
CREATE TABLE batch_order (
    batch_id        INT       NOT NULL,
    order_id        INT       NOT NULL, -- FK to external Order table (omitted)
    added_timestamp TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (batch_id, order_id),
    CONSTRAINT fk_batch_order_batch FOREIGN KEY (batch_id)
        REFERENCES delivery_batch(delivery_batch_id)
);


-- TEAM 1 END

--TEAM 2 PRIMARY KEY TABLES
-- PURCHASE ORDER & STOCK --
CREATE TABLE IF NOT EXISTS PurchaseOrder (
    poID INT PRIMARY KEY,
    supplierID INT,
    poDate DATE,
    status ENUM('COMPLETED','CONFIRMED','SUBMITTED','APPROVED','REJECTED','CANCELLED'),
    expectedDeliveryDate DATE,
    totalAmount DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS POLineItem (
    poLineID INT AUTO_INCREMENT PRIMARY KEY,
    poID INT,
    productID INT,
    qty INT,
    unitPrice DECIMAL(10,2),
    lineTotal DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS StockItem (
    productID INT PRIMARY KEY,
    sku VARCHAR(100),
    name VARCHAR(255),
    uom VARCHAR(50)
);

-- SUPPLIER & VETTING --
CREATE TABLE IF NOT EXISTS Supplier (
    SupplierID INT PRIMARY KEY,
    Name VARCHAR(255),
    Details VARCHAR(500),
    CreditPeriod INT,
    AvgTurnaroundTime FLOAT,
    SupplierCategory ENUM('A','B','C','D'), -- need update
    IsVerified BOOLEAN,
    VettingResult ENUM('APPROVED','REJECTED','PENDING') -- need update
);

CREATE TABLE IF NOT EXISTS SupplierCategoryChangeLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    SupplierID INT,
    PreviousCategory ENUM('A','B','C','D'), -- need update
    NewCategory ENUM('A','B','C','D'), -- need update
    ChangeReason VARCHAR(255),
    ChangedAt DATETIME
);

CREATE TABLE IF NOT EXISTS VettingRecord (
    VettingID INT AUTO_INCREMENT PRIMARY KEY,
    RatingID INT,
    SupplierID VARCHAR(255),
    VettedByUserID VARCHAR(255),
    VettedAt DATETIME,
    Decision ENUM('APPROVED','REJECTED'),
    Notes TEXT
);

CREATE TABLE IF NOT EXISTS ReliabilityRating (
    RatingID INT AUTO_INCREMENT PRIMARY KEY,
    SupplierID VARCHAR(255),
    Score DECIMAL(5,2),
    Rationale TEXT,
    RatingBand ENUM('HIGH','MEDIUM','LOW','UNRATED'),
    CalculatedByUserID VARCHAR(255),
    CalculatedAt DATETIME
);

-- REPLENISHMENT --
CREATE TABLE IF NOT EXISTS ReplenishmentRequest (
    RequestId INT AUTO_INCREMENT PRIMARY KEY,
    RequestedBy VARCHAR(100),
    Status ENUM('DRAFT','SUBMITTED','CANCELLED','COMPLETED'),
    CreatedAt DATETIME,
    Remarks TEXT,
    CompletedAt DATETIME,
    CompletedBy DATETIME
);

CREATE TABLE IF NOT EXISTS LineItem (
    LineItemId INT AUTO_INCREMENT PRIMARY KEY,
    RequestId INT,
    ProductId INT,
    QuantityRequest INT,
    ReasonCode ENUM('LOWSTOCK','DEMANDSPIKE','REPLACEMENT','NEWITEM','OTHERS'),
    Remarks TEXT
);

-- TRANSACTIONS --
CREATE TABLE IF NOT EXISTS RentalOrderLog (
    RentalOrderId INT AUTO_INCREMENT PRIMARY KEY,
    OrderId VARCHAR(50),
    CustomerId VARCHAR(50),
    OrderDate DATETIME,
    TotalAmount DECIMAL(10,2),
    Status ENUM('PENDING','CONFIRMED','CANCELLED','COMPLETED'),
    DetailsJSON TEXT
);

CREATE TABLE IF NOT EXISTS LoanLog (
    LoanListId INT AUTO_INCREMENT PRIMARY KEY,
    OrderId VARCHAR(50),
    Status ENUM('ONGOING','RETURNED','OVERDUE','CANCELLED'),
    LoanDate DATETIME,
    ReturnDate DATETIME,
    DueDate DATETIME,
    DetailsJSON TEXT
);

CREATE TABLE IF NOT EXISTS ReturnLog (
    ReturnId INT AUTO_INCREMENT PRIMARY KEY,
    CustomerId VARCHAR(50),
    ReturnRequestId INT,
    ReturnItemId INT,
    RefundAmount DECIMAL(10,2),
    RequestDate DATETIME,
    CompletionDate DATETIME,
    Status ENUM('PENDING','APPROVED','REJECTED','COMPLETED'),
    ImageURL VARCHAR(500),
    DetailsJSON TEXT
);

CREATE TABLE IF NOT EXISTS PurchaseOrderLog (
    PurchaseOrderId INT AUTO_INCREMENT PRIMARY KEY,
    SupplierId VARCHAR(50),
    Status ENUM('PENDING','APPROVED','REJECTED','DELIVERED','CANCELLED'),
    ExpectedDeliveryDate DATETIME,
    TotalAmount DECIMAL(10,2),
    DetailsJSON TEXT
);

CREATE TABLE IF NOT EXISTS ClearenceLog (
    ClearenceBatchId INT AUTO_INCREMENT PRIMARY KEY,
    BatchName VARCHAR(255),
    ClearenceItemId INT,
    ClearenceDate DATETIME,
    FinalPrice DECIMAL(10,2),
    RecommendedPrice DECIMAL(10,2),
    SaleDate DATETIME,
    Status ENUM('ONGOING','COMPLETED','CANCELLED'),
    DetailsJSON TEXT
);

-- ANALYTICS TABLES --
CREATE TABLE IF NOT EXISTS ReportExport (
    ReportID INT AUTO_INCREMENT PRIMARY KEY,
    RefAnalyticsID INT,
    Title VARCHAR(255),
    VisualType ENUM('TABLE', 'BAR', 'COLUMN', 'LINE', 'PIE', 'AREA'),
    FileFormat ENUM('CSV', 'XLSX', 'PDF', 'PNG'),
    URL VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS Analytics (
    AnalyticsID INT AUTO_INCREMENT PRIMARY KEY,
    StartDate DATETIME,
    EndDate DATETIME,
    loanAmt INT,
    returnAmt INT,
    PrimarySupplierID INT,
    PrimaryItemID INT,
    SupplierReliability DECIMAL(10,2),
    TurnoverRate DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS AnalysisList (
    AnalyticsID INT,
    TransactionLogID INT
);


--TEAM 3 PRIMARY KEY TABLES
CREATE TYPE product_status AS ENUM ('AVAILABLE', 'UNAVAILABLE', 'RETIRED');

CREATE TYPE inventory_status AS ENUM 
('AVAILABLE', 'RETIRED', 'CLEARANCE', 'SOLD', 
 'MAINTENANCE', 'RESERVED', 'ON_LOAN', 'BROKEN');

CREATE TYPE clearance_status AS ENUM ('CLEARANCE', 'SOLD');

CREATE TYPE clearance_batch_status AS ENUM ('SCHEDULED', 'ACTIVE', 'CLOSED');

CREATE TABLE Category (
    CategoryId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Product (
    ProductId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CategoryId INT NOT NULL,
    Sku VARCHAR(255) NOT NULL,
    Status product_status NOT NULL DEFAULT 'AVAILABLE',
    CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_product_category
        FOREIGN KEY (CategoryId)
        REFERENCES Category(CategoryId)
        ON DELETE RESTRICT
);

CREATE TABLE ProductDetails (
    DetailsId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ProductId INT NOT NULL UNIQUE,
    TotalQuantity INT NOT NULL DEFAULT 0,
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    Weight DECIMAL(10,2),
    Image VARCHAR(255),
    Price DECIMAL(10,2) NOT NULL,
    DepositRate DECIMAL(10,2) DEFAULT 0,

    CONSTRAINT fk_productdetails_product
        FOREIGN KEY (ProductId)
        REFERENCES Product(ProductId)
        ON DELETE CASCADE
);

CREATE TABLE InventoryItem (
    InventoryId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ProductId INT NOT NULL,
    SerialNumber VARCHAR(255) NOT NULL UNIQUE,
    Status inventory_status NOT NULL DEFAULT 'AVAILABLE',
    CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ExpiryDate TIMESTAMP,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (ProductId)
        REFERENCES Product(ProductId)
        ON DELETE CASCADE
);

CREATE TABLE ClearanceBatch (
    ClearanceBatchId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    BatchName VARCHAR(255) NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ClearanceDate TIMESTAMP,
    Status clearance_batch_status NOT NULL DEFAULT 'SCHEDULED'
);

CREATE TABLE ClearanceItem (
    ClearanceItemId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ClearanceBatchId INT NOT NULL,
    InventoryItemId INT NOT NULL UNIQUE,
    FinalPrice DECIMAL(10,2),
    RecommendedPrice DECIMAL(10,2),
    SaleDate TIMESTAMP,
    Status clearance_status NOT NULL DEFAULT 'CLEARANCE',

    CONSTRAINT fk_clearance_batch
        FOREIGN KEY (ClearanceBatchId)
        REFERENCES ClearanceBatch(ClearanceBatchId)
        ON DELETE CASCADE,

    CONSTRAINT fk_clearance_inventory
        FOREIGN KEY (InventoryItemId)
        REFERENCES InventoryItem(InventoryId)
        ON DELETE CASCADE
);

--TEAM 4 PRIMARY KEY TABLES
CREATE TABLE
  IF NOT EXISTS User (
    userId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    passwordHash VARCHAR(255) NOT NULL,
    phoneCountry INT,
    phoneNumber VARCHAR(20)
  );

CREATE TABLE
  IF NOT EXISTS Customer (
    customerId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    userId INT NOT NULL,
    address VARCHAR(255) NOT NULL,
    customerType INT NOT NULL,
    CONSTRAINT fk_customer_user FOREIGN KEY (userId) REFERENCES User (userId) ON UPDATE CASCADE ON DELETE CASCADE
  );

CREATE TABLE
  IF NOT EXISTS Staff (
    staffId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    userId INT NOT NULL,
    department VARCHAR(50) NOT NULL,
    CONSTRAINT fk_staff_user FOREIGN KEY (userId) REFERENCES User (userId) ON UPDATE CASCADE ON DELETE CASCADE
  );

CREATE TABLE
  IF NOT EXISTS Notification (
    notificationId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    userId INT NOT NULL,
    message VARCHAR(255) NOT NULL,
    dateSent DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    isRead BOOL NOT NULL DEFAULT FALSE,
    type ENUM ('ORDER_UPDATE', 'PROMOTION', 'SYSTEM', 'PRODUCT') NOT NULL,
    CONSTRAINT fk_notification_user FOREIGN KEY (userId) REFERENCES Users (userId) ON UPDATE CASCADE ON DELETE CASCADE
  );

CREATE TABLE
  IF NOT EXISTS NotificationPreference (
    preferenceId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    userId INT NOT NULL,
    emailEnabled BOOL NOT NULL DEFAULT TRUE,
    smsEnabled BOOL NOT NULL DEFAULT FALSE,
    frequency ENUM ('INSTANT', 'DAILY', 'WEEKLY') NOT NULL,
    granularity ENUM ('ALL', 'IMPORTANT_ONLY', 'NONE') NOT NULL,
    CONSTRAINT fk_notificationpref_user FOREIGN KEY (userId) REFERENCES Users (userId) ON UPDATE CASCADE ON DELETE CASCADE
  );

--TEAM 5 PRIMARY KEY TABLES
--001_building_footprint
CREATE TABLE IF NOT EXISTS BuildingFootprint (
  buildingCarbonFootprintID INT AUTO_INCREMENT PRIMARY KEY,
  timeHourly DATETIME NOT NULL,
  zone VARCHAR(50),
  block VARCHAR(50),
  floor VARCHAR(50),
  room VARCHAR(50),
  totalRoomCo2 DOUBLE NOT NULL
);

--002_EcoBadge
CREATE TABLE IF NOT EXISTS EcoBadge (
  badgeId INT AUTO_INCREMENT PRIMARY KEY,
  maxCarbonG DOUBLE NOT NULL,
  criteriaDescription VARCHAR(255),
  badgeName VARCHAR(100) NOT NULL
);

--003_ProductFootprint
CREATE TABLE IF NOT EXISTS ProductFootprint (
  productCarbonFootprintID INT AUTO_INCREMENT PRIMARY KEY,
  productID INT NOT NULL,
  badgeId INT NOT NULL,
  productToxicPercentage DOUBLE,
  totalCo2 DOUBLE NOT NULL,
  calculatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--004_StaffAccessLog
CREATE TABLE IF NOT EXISTS StaffAccessLog (
  accessId INT AUTO_INCREMENT PRIMARY KEY,
  staffId INT NOT NULL,
  eventTime DATETIME NOT NULL,
  eventType ENUM('IN','OUT') NOT NULL
);

--005_StaffFootprint
CREATE TABLE IF NOT EXISTS StaffFootprint (
  staffCarbonFootprintID INT AUTO_INCREMENT PRIMARY KEY,
  staffId INT NOT NULL,
  time DATETIME NOT NULL,
  hoursWorked DOUBLE NOT NULL,
  totalStaffCo2 DOUBLE NOT NULL
);

--006_CustomerRewards
CREATE TABLE IF NOT EXISTS CustomerRewards (
  customerRewardsID INT AUTO_INCREMENT PRIMARY KEY,
  customerId INT NOT NULL,
  discount DOUBLE NOT NULL,
  totalCarbon DOUBLE NOT NULL
);

--007_PackagingProfile
CREATE TABLE IF NOT EXISTS PackagingProfile (
  profileId INT AUTO_INCREMENT PRIMARY KEY,
  orderId INT NOT NULL,
  volume DOUBLE NOT NULL,
  fragilityLevel VARCHAR(50)
);

--008_PackagingConfiguration
CREATE TABLE IF NOT EXISTS PackagingConfiguration (
  configurationId INT AUTO_INCREMENT PRIMARY KEY,
  profileId INT NOT NULL
);

--009_PackagingMaterial
CREATE TABLE IF NOT EXISTS PackagingMaterial (
  materialId INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(50),
  recyclable BOOLEAN NOT NULL DEFAULT FALSE,
  reusable BOOLEAN NOT NULL DEFAULT FALSE
);

--010_PackagingConfigMaterials
CREATE TABLE IF NOT EXISTS PackagingConfigMaterials (
PRIMARY KEY (configurationId, materialId)
  configurationId INT NOT NULL,
  materialId INT NOT NULL,
  category VARCHAR(50),
  quantity INT NOT NULL,
);

--TEAM 6 PRIMARY KEY TABLES
-- SESSION
CREATE TABLE IF NOT EXISTS Session (
    sessionId INT AUTO_INCREMENT PRIMARY KEY,
    userId INT,
    role VARCHAR(50),
    createdAt DATETIME,
    expiresAt DATETIME
);

-- CART
CREATE TABLE IF NOT EXISTS Cart (
    cartId INT AUTO_INCREMENT PRIMARY KEY,
    customerId INT NULL,
    sessionId INT NULL,
    rentalStart DATETIME,
    rentalEnd DATETIME,
    status ENUM('ACTIVE','CHECKED_OUT','EXPIRED') DEFAULT 'ACTIVE'
);

-- CART ITEM
CREATE TABLE IF NOT EXISTS CartItem (
    cartItemId INT AUTO_INCREMENT PRIMARY KEY,
    cartId INT,
    productId INT,
    quantity INT,
    isSelected BOOLEAN DEFAULT TRUE
);

-- CHECKOUT
CREATE TABLE IF NOT EXISTS Checkout (
    checkoutId INT AUTO_INCREMENT PRIMARY KEY,
    customerId INT,
    cartId INT,
    deliveryMethodId VARCHAR(50),
    paymentMethodType ENUM('CREDIT_CARD'),
    status ENUM('IN_PROGRESS','CONFIRMED','CANCELLED') DEFAULT 'IN_PROGRESS',
    notifyOptIn BOOLEAN DEFAULT FALSE,
    createdAt DATETIME
);

-- ORDER
CREATE TABLE IF NOT EXISTS `Order` (
    orderId INT AUTO_INCREMENT PRIMARY KEY,
    customerId INT,
    checkoutId INT,
    orderDate DATETIME,
    status ENUM(
        'PENDING',
        'CONFIRMED',
        'PROCESSING',
        'READY_FOR_DISPATCH',
        'DISPATCHED',
        'DELIVERED',
        'CANCELLED'
    ) DEFAULT 'PENDING',
    deliveryType ENUM('NextDay','ThreeDays','OneWeek'),
    totalAmount DECIMAL(10,2)
);

-- ORDER ITEM
CREATE TABLE IF NOT EXISTS OrderItem (
    orderItemId INT AUTO_INCREMENT PRIMARY KEY,
    orderId INT,
    productId INT,
    quantity INT,
    unitPrice DECIMAL(10,2),
    rentalStartDate DATETIME,
    rentalEndDate DATETIME
);

-- TRANSACTION (Core Financial Record)
CREATE TABLE IF NOT EXISTS Transaction (
    transactionId INT AUTO_INCREMENT PRIMARY KEY,
    orderId INT,
    amount DECIMAL(10,2),
    type ENUM('PAYMENT','REFUND'),
    purpose ENUM('ORDER','PENALTY','REFUND_DEPOSIT'),
    status ENUM('PENDING','COMPLETED','FAILED','CANCELLED') DEFAULT 'PENDING',
    providerTransactionId VARCHAR(100),
    createdAt DATETIME
);

-- PAYMENT (Business Payment Record)
CREATE TABLE IF NOT EXISTS Payment (
    paymentId INT AUTO_INCREMENT PRIMARY KEY,
    orderId INT,
    transactionId INT,
    amount DECIMAL(10,2),
    purpose ENUM('RENTAL_FEE_DEPOSIT','PENALTY_FEE'),
    status ENUM('PENDING','COMPLETED','FAILED','CANCELLED') DEFAULT 'PENDING',
    createdAt DATETIME
);

-- DEPOSIT (Deposit Tracking)
CREATE TABLE IF NOT EXISTS Deposit (
    depositId INT AUTO_INCREMENT PRIMARY KEY,
    orderId INT,
    transactionId INT,
    originalAmount DECIMAL(10,2),
    heldAmount DECIMAL(10,2),
    refundedAmount DECIMAL(10,2),
    forfeitedAmount DECIMAL(10,2),
    createdAt DATETIME
);

--TEAM 1 CROSS TEAM FK TABLES

--TEAM 2 CROSS TEAM FK TABLES

--TEAM 3 CROSS TEAM FK TABLES

--TEAM 4 CROSS TEAM FK TABLES
CREATE TABLE
  IF NOT EXISTS OrderStatusHistory (
    historyId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    orderId INT NOT NULL,
    status ENUM (
      'PENDING',
      'PROCESSING',
      'SHIPPED',
      'DELIVERED',
      'CANCELLED'
    ) NOT NULL,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedBy VARCHAR(50) NOT NULL,
    remark VARCHAR(255),
    CONSTRAINT fk_order_status_history_order FOREIGN KEY (orderId) REFERENCES Orders (orderId) ON UPDATE CASCADE ON DELETE CASCADE
  );

CREATE TABLE
  IF NOT EXISTS Refund (
    refundId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    orderId INT NOT NULL,
    customerId INT NOT NULL,
    depositRefundAmount DECIMAL(10, 2) NOT NULL,
    returnDate DATETIME NOT NULL,
    penaltyAmount DECIMAL(10, 2) DEFAULT 0.00,
    returnMethod VARCHAR(50) NOT NULL,
    CONSTRAINT fk_refund_order FOREIGN KEY (orderId) REFERENCES Orders (orderId) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_refund_customer FOREIGN KEY (customerId) REFERENCES Customers (customerId) ON UPDATE CASCADE ON DELETE RESTRICT
  );

CREATE TABLE
  IF NOT EXISTS Shipment (
    trackingId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    orderId INT NOT NULL,
    batchId INT NOT NULL,
    status ENUM ('PENDING', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED') NOT NULL,
    weight DOUBLE NOT NULL,
    destination VARCHAR(255) NOT NULL,
    CONSTRAINT fk_shipment_order FOREIGN KEY (orderId) REFERENCES Orders (orderId) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_shipment_batch FOREIGN KEY (batchId) REFERENCES Batches (batchId) ON UPDATE CASCADE ON DELETE RESTRICT
  );

CREATE TABLE
  IF NOT EXISTS DeliveryMethod (
    deliveryId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    orderId INT NOT NULL,
    durationDays INT NOT NULL,
    deliveryCost DECIMAL(10, 2) NOT NULL,
    carrierId VARCHAR(50) NOT NULL,
    CONSTRAINT fk_deliverymethod_order FOREIGN KEY (orderId) REFERENCES Orders (orderId) ON UPDATE CASCADE ON DELETE RESTRICT
  );

--TEAM 5 CROSS TEAM FK TABLES

--TEAM 6 CROSS TEAM FK TABLES
