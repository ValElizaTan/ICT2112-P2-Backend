-- Order Rental Processing System Schema
-- Version 1.0
-- Created: 28 Feb 2026

CREATE DATABASE DatabaseDB;
GO

USE DatabaseDB;
GO

--TEAM 1 PRIMARY KEY TABLES

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

--TEAM 4 PRIMARY KEY TABLES
CREATE TABLE IF NOT EXISTS OrderStatusHistory (
  historyId INT AUTO_INCREMENT PRIMARY KEY,
  orderId INT NOT NULL,
  status ENUM('PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED') NOT NULL,
  timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedBy VARCHAR(50) NOT NULL,
  remark VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS Refund (
  refundId INT AUTO_INCREMENT PRIMARY KEY,
  orderId INT NOT NULL,
  customerId INT NOT NULL,
  depositRefundAmount DECIMAL(10,2) NOT NULL,
  returnDate DATETIME NOT NULL,
  penaltyAmount DECIMAL(10,2) DEFAULT 0.00,
  returnMethod VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Shipment (
  trackingId INT AUTO_INCREMENT PRIMARY KEY,
  orderId INT NOT NULL,
  batchId INT NOT NULL,
  status ENUM('PENDING', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED') NOT NULL,
  weight DOUBLE NOT NULL,
  destination VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS DeliveryMethod (
  deliveryId INT AUTO_INCREMENT PRIMARY KEY,
  orderId INT NOT NULL,
  durationDays INT NOT NULL,
  deliveryCost DECIMAL(10,2) NOT NULL,
  carrierId VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS Notification (
  notificationId INT AUTO_INCREMENT PRIMARY KEY,
  userId INT NOT NULL,
  message VARCHAR(255) NOT NULL,
  dateSent DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  isRead BOOL NOT NULL DEFAULT FALSE,
  type ENUM('ORDER_UPDATE', 'PROMOTION', 'SYSTEM', 'PRODUCT') NOT NULL
);

CREATE TABLE IF NOT EXISTS NotificationPreference (
  preferenceId INT AUTO_INCREMENT PRIMARY KEY,
  userId INT NOT NULL,
  emailEnabled BOOL NOT NULL DEFAULT TRUE,
  smsEnabled BOOL NOT NULL DEFAULT FALSE,
  frequency ENUM('INSTANT', 'DAILY', 'WEEKLY') NOT NULL,
  granularity ENUM('ALL', 'IMPORTANT_ONLY', 'NONE') NOT NULL
);

CREATE TABLE IF NOT EXISTS User (
  userId INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  passwordHash VARCHAR(255) NOT NULL,
  phoneCountry INT,
  phoneNumber VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Customer (
  customerId INT AUTO_INCREMENT PRIMARY KEY,
  userId INT NOT NULL,
  address VARCHAR(255) NOT NULL,
  customerType INT NOT NULL
);

CREATE TABLE IF NOT EXISTS Staff (
  staffId INT AUTO_INCREMENT PRIMARY KEY,
  userId INT NOT NULL,
  department VARCHAR(50) NOT NULL
);

--TEAM 5 PRIMARY KEY TABLES
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
    paymentId VARCHAR(50) PRIMARY KEY,
    orderId INT,
    transactionId INT,
    amount DECIMAL(10,2),
    purpose ENUM('RENTAL_FEE_DEPOSIT','PENALTY_FEE'),
    status ENUM('PENDING','COMPLETED','FAILED','CANCELLED') DEFAULT 'PENDING',
    createdAt DATETIME
);

-- DEPOSIT (Deposit Tracking)
CREATE TABLE IF NOT EXISTS Deposit (
    depositId VARCHAR(50) PRIMARY KEY,
    orderId INT,
    transactionId INT,
    originalAmount DECIMAL(10,2),
    heldAmount DECIMAL(10,2),
    refundedAmount DECIMAL(10,2),
    forfeitedAmount DECIMAL(10,2),
    createdAt DATETIME
);