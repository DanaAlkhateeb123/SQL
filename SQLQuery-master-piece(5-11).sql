CREATE DATABASE NostalgiaDB;
GO

USE NostalgiaDB;
GO

-- Accounts, login identity, and profile information.
CREATE TABLE Users
(
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Email VARCHAR(255) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    PasswordSalt VARCHAR(100) NOT NULL,
    Role VARCHAR(20) NOT NULL DEFAULT 'USER',
    FirstName VARCHAR(80) NOT NULL,
    LastName VARCHAR(80) NOT NULL,
    PhoneNumber VARCHAR(30),
    Gender VARCHAR(30),
    City VARCHAR(100),
    ProfilePhoto VARCHAR(MAX),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
);

-- The application has one set of notification switches per member.
CREATE TABLE UserSettings
(
    UserSettingsID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL UNIQUE,
    OrderUpdates BIT NOT NULL DEFAULT 1,
    ListingUpdates BIT NOT NULL DEFAULT 1,
    AuctionUpdates BIT NOT NULL DEFAULT 1,
    MessageUpdates BIT NOT NULL DEFAULT 1,
    NewsUpdates BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- The pickup form can remember one reusable pickup address for each member.
CREATE TABLE UserPickupAddresses
(
    UserPickupAddressID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL UNIQUE,
    ContactName VARCHAR(160) NOT NULL,
    PhoneNumber VARCHAR(30) NOT NULL,
    Governorate VARCHAR(80) NOT NULL,
    City VARCHAR(100) NOT NULL,
    Street VARCHAR(200) NOT NULL,
    Building VARCHAR(80) NOT NULL,
    Unit VARCHAR(80),
    Notes VARCHAR(500),
    Latitude DECIMAL(9,6) NOT NULL,
    Longitude DECIMAL(9,6) NOT NULL,
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- These values match the category choices in the Selling form.
CREATE TABLE Categories
(
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryKey VARCHAR(40) NOT NULL UNIQUE,
    CategoryName VARCHAR(80) NOT NULL UNIQUE,
    IsActive BIT NOT NULL DEFAULT 1
);

-- A member can create many listings. Admin approval and block feedback live here.
CREATE TABLE Listings
(
    ListingID INT PRIMARY KEY IDENTITY(1,1),
    SellerID INT NOT NULL,
    CategoryID INT NOT NULL,
    Title VARCHAR(200) NOT NULL,
    Description VARCHAR(MAX),
    ItemCondition VARCHAR(30) NOT NULL,
    Material VARCHAR(150) NOT NULL,
    ItemLocation VARCHAR(200) NOT NULL,
    ListingType VARCHAR(40) NOT NULL,
    Price DECIMAL(10,2),
    CurrencyCode VARCHAR(3) NOT NULL DEFAULT 'USD',
    Status VARCHAR(20) NOT NULL DEFAULT 'pending',
    ReviewReason VARCHAR(MAX),
    PreviousReviewReason VARCHAR(MAX),
    SubmittedAt DATETIME NOT NULL DEFAULT GETDATE(),
    ReviewedAt DATETIME,
    ReviewedByUserID INT,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (SellerID) REFERENCES Users(UserID),
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    FOREIGN KEY (ReviewedByUserID) REFERENCES Users(UserID),
    CHECK (Price IS NULL OR Price >= 0)
);

-- Selling accepts up to ten photos for one listing.
CREATE TABLE ListingImages
(
    ListingImageID INT PRIMARY KEY IDENTITY(1,1),
    ListingID INT NOT NULL,
    ImageSource VARCHAR(MAX) NOT NULL,
    AltText VARCHAR(200),
    SortOrder INT NOT NULL DEFAULT 1,
    FOREIGN KEY (ListingID) REFERENCES Listings(ListingID)
);

-- Junction table: users can save many listings, and each listing can be saved by many users.
CREATE TABLE Favorites
(
    UserID INT NOT NULL,
    ListingID INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (UserID, ListingID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (ListingID) REFERENCES Listings(ListingID)
);

-- One auction belongs to one listing. CurrentBid is updated when a valid bid is accepted.
CREATE TABLE Auctions
(
    AuctionID INT PRIMARY KEY IDENTITY(1,1),
    ListingID INT NOT NULL UNIQUE,
    StartingPrice DECIMAL(10,2) NOT NULL,
    CurrentBid DECIMAL(10,2) NOT NULL,
    CurrencyCode VARCHAR(3) NOT NULL DEFAULT 'JOD',
    StartsAt DATETIME NOT NULL,
    EndsAt DATETIME NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'pending_approval',
    WinnerUserID INT,
    ClosedAt DATETIME,
    FOREIGN KEY (ListingID) REFERENCES Listings(ListingID),
    FOREIGN KEY (WinnerUserID) REFERENCES Users(UserID),
    CHECK (StartingPrice >= 0),
    CHECK (CurrentBid >= StartingPrice),
    CHECK (EndsAt > StartsAt)
);

-- An auction and a user can each have many bids.
CREATE TABLE Bids
(
    BidID INT PRIMARY KEY IDENTITY(1,1),
    AuctionID INT NOT NULL,
    BidderID INT NOT NULL,
    BidAmount DECIMAL(10,2) NOT NULL,
    BidTime DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID),
    FOREIGN KEY (BidderID) REFERENCES Users(UserID),
    CHECK (BidAmount > 0)
);

-- Users can set one reminder per auction.
CREATE TABLE AuctionReminders
(
    UserID INT NOT NULL,
    AuctionID INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (UserID, AuctionID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID)
);

-- The current checkout supports one listing per order, so ListingID is stored directly.
CREATE TABLE Orders
(
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    OrderNumber VARCHAR(30) NOT NULL UNIQUE,
    BuyerID INT NOT NULL,
    SellerID INT NOT NULL,
    ListingID INT NOT NULL,
    AuctionID INT,
    Status VARCHAR(30) NOT NULL DEFAULT 'Paid',
    ItemPrice DECIMAL(10,2) NOT NULL,
    DeliveryFee DECIMAL(10,2) NOT NULL DEFAULT 0,
    TotalAmount DECIMAL(10,2) NOT NULL,
    CurrencyCode VARCHAR(3) NOT NULL DEFAULT 'USD',
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (BuyerID) REFERENCES Users(UserID),
    FOREIGN KEY (SellerID) REFERENCES Users(UserID),
    FOREIGN KEY (ListingID) REFERENCES Listings(ListingID),
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID),
    CHECK (ItemPrice >= 0),
    CHECK (DeliveryFee >= 0),
    CHECK (TotalAmount >= 0)
);

-- One payment record per order. Never store full card numbers or security codes here.
CREATE TABLE Payments
(
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL UNIQUE,
    PaymentMethod VARCHAR(30) NOT NULL,
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT 'Pending',
    Amount DECIMAL(10,2) NOT NULL,
    CurrencyCode VARCHAR(3) NOT NULL,
    ProviderReference VARCHAR(200),
    PaidAt DATETIME,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    CHECK (Amount >= 0)
);

-- Checkout recipient address and map point; one delivery record per order.
CREATE TABLE Deliveries
(
    DeliveryID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL UNIQUE,
    RecipientName VARCHAR(160) NOT NULL,
    PhoneNumber VARCHAR(30) NOT NULL,
    Governorate VARCHAR(80) NOT NULL,
    City VARCHAR(100) NOT NULL,
    Street VARCHAR(200) NOT NULL,
    Building VARCHAR(80) NOT NULL,
    Unit VARCHAR(80),
    DeliveryNotes VARCHAR(500),
    Latitude DECIMAL(9,6),
    Longitude DECIMAL(9,6),
    Status VARCHAR(30) NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Seller pickup/contact details entered from the order notification.
CREATE TABLE PickupDetails
(
    PickupDetailsID INT PRIMARY KEY IDENTITY(1,1),
    DeliveryID INT NOT NULL UNIQUE,
    ContactName VARCHAR(160) NOT NULL,
    PhoneNumber VARCHAR(30) NOT NULL,
    Governorate VARCHAR(80) NOT NULL,
    City VARCHAR(100) NOT NULL,
    Street VARCHAR(200) NOT NULL,
    Building VARCHAR(80) NOT NULL,
    Unit VARCHAR(80),
    PickupNotes VARCHAR(500),
    PreferredPickupAt DATETIME,
    Latitude DECIMAL(9,6) NOT NULL,
    Longitude DECIMAL(9,6) NOT NULL,
    Status VARCHAR(30) NOT NULL DEFAULT 'scheduled',
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (DeliveryID) REFERENCES Deliveries(DeliveryID)
);

-- Tracking page shows a sequence of order status updates.
CREATE TABLE OrderTrackingEvents
(
    TrackingEventID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    Status VARCHAR(30) NOT NULL,
    Description VARCHAR(500),
    Location VARCHAR(200),
    EventAt DATETIME NOT NULL DEFAULT GETDATE(),
    RecordedByUserID INT,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (RecordedByUserID) REFERENCES Users(UserID)
);

-- A conversation is between the buyer and seller, optionally about one listing.
CREATE TABLE Conversations
(
    ConversationID INT PRIMARY KEY IDENTITY(1,1),
    BuyerID INT NOT NULL,
    SellerID INT NOT NULL,
    ListingID INT,
    Status VARCHAR(20) NOT NULL DEFAULT 'open',
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (BuyerID) REFERENCES Users(UserID),
    FOREIGN KEY (SellerID) REFERENCES Users(UserID),
    FOREIGN KEY (ListingID) REFERENCES Listings(ListingID),
    CHECK (BuyerID <> SellerID)
);

CREATE TABLE Messages
(
    MessageID INT PRIMARY KEY IDENTITY(1,1),
    ConversationID INT NOT NULL,
    SenderID INT NOT NULL,
    MessageText VARCHAR(MAX) NOT NULL,
    SentAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsRead BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (ConversationID) REFERENCES Conversations(ConversationID),
    FOREIGN KEY (SenderID) REFERENCES Users(UserID)
);

-- Notification links are optional because a notification can refer to an order, listing, or auction.
CREATE TABLE Notifications
(
    NotificationID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    Category VARCHAR(30) NOT NULL,
    NotificationType VARCHAR(50),
    Title VARCHAR(200) NOT NULL,
    Body VARCHAR(MAX) NOT NULL,
    ActionText VARCHAR(100),
    Href VARCHAR(500),
    IsRead BIT NOT NULL DEFAULT 0,
    OrderID INT,
    ListingID INT,
    AuctionID INT,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ListingID) REFERENCES Listings(ListingID),
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID)
);

-- Feedback form includes overall satisfaction and a separate seller star rating.
CREATE TABLE Reviews
(
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL UNIQUE,
    ReviewerID INT NOT NULL,
    SellerID INT NOT NULL,
    SatisfactionRating INT NOT NULL,
    SellerRating INT NOT NULL,
    ReviewText VARCHAR(MAX) NOT NULL,
    FollowUpEmail VARCHAR(255),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ReviewerID) REFERENCES Users(UserID),
    FOREIGN KEY (SellerID) REFERENCES Users(UserID),
    CHECK (SatisfactionRating BETWEEN 1 AND 5),
    CHECK (SellerRating BETWEEN 1 AND 5)
);

-- Contact Us and admin feedback queue submissions.
CREATE TABLE Feedback
(
    FeedbackID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    Name VARCHAR(160) NOT NULL,
    Email VARCHAR(255) NOT NULL,
    Topic VARCHAR(80) NOT NULL,
    MessageText VARCHAR(MAX) NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'New',
    AdminNote VARCHAR(MAX),
    ReviewedByUserID INT,
    SubmittedAt DATETIME NOT NULL DEFAULT GETDATE(),
    ReviewedAt DATETIME,
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (ReviewedByUserID) REFERENCES Users(UserID)
);

-- The admin settings page stores these workspace-wide values.
CREATE TABLE AdminSettings
(
    AdminSettingsID INT PRIMARY KEY IDENTITY(1,1),
    AdminUserID INT NOT NULL UNIQUE,
    MarketplaceName VARCHAR(100) NOT NULL DEFAULT 'Nostalgia',
    DisplayCurrency VARCHAR(3) NOT NULL DEFAULT 'USD',
    SupportEmail VARCHAR(255),
    Announcement VARCHAR(MAX),
    ListingAlerts BIT NOT NULL DEFAULT 1,
    OrderAlerts BIT NOT NULL DEFAULT 1,
    AuctionAlerts BIT NOT NULL DEFAULT 1,
    WeeklySummary BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (AdminUserID) REFERENCES Users(UserID)
);

-- ------------------------------------------------------------
-- Small sample data. The password values below are placeholders;
-- real accounts must receive secure hashes from the application.
-- ------------------------------------------------------------
INSERT INTO Users (Email, PasswordHash, PasswordSalt, Role, FirstName, LastName, PhoneNumber, City)
VALUES
('admin@nostalgia.com', 'SAMPLE_HASH_ONLY', 'SAMPLE_SALT_ONLY', 'ADMIN', 'Nostalgia', 'Admin', NULL, 'Amman'),
('aya.seller@example.com', 'SAMPLE_HASH_ONLY', 'SAMPLE_SALT_ONLY', 'USER', 'Aya', 'Fares', '+962791111111', 'Amman'),
('omar.buyer@example.com', 'SAMPLE_HASH_ONLY', 'SAMPLE_SALT_ONLY', 'USER', 'Omar', 'Ali', '+962792222222', 'Irbid'),
('layth.bidder@example.com', 'SAMPLE_HASH_ONLY', 'SAMPLE_SALT_ONLY', 'USER', 'Layth', 'Saleh', '+962793333333', 'Zarqa');

INSERT INTO UserSettings (UserID)
SELECT UserID FROM Users WHERE Email IN ('aya.seller@example.com', 'omar.buyer@example.com', 'layth.bidder@example.com');

INSERT INTO UserPickupAddresses (UserID, ContactName, PhoneNumber, Governorate, City, Street, Building, Unit, Notes, Latitude, Longitude)
VALUES
((SELECT UserID FROM Users WHERE Email = 'aya.seller@example.com'), 'Aya Fares', '+962791111111', 'Amman', 'Amman', 'Garden Street', '8', 'Ground floor', 'Front entrance', 31.980000, 35.880000);

INSERT INTO Categories (CategoryKey, CategoryName)
VALUES
('electronics', 'Electronics'), ('clothes', 'Clothes'), ('furniture', 'Furniture'),
('books', 'Books'), ('games', 'Games'), ('antiques', 'Antiques'),
('accessories', 'Accessories'), ('bags', 'Bags'), ('shoes', 'Shoes'), ('other', 'Other');

INSERT INTO Listings (SellerID, CategoryID, Title, Description, ItemCondition, Material, ItemLocation, ListingType, Price, CurrencyCode, Status)
VALUES
((SELECT UserID FROM Users WHERE Email = 'aya.seller@example.com'), (SELECT CategoryID FROM Categories WHERE CategoryKey = 'electronics'), 'Retro Film Camera', 'A tested vintage camera in working condition.', 'good', 'Metal and leather', 'Amman, Jordan', 'Fixed Price (Direct Buy)', 95.00, 'USD', 'published'),
((SELECT UserID FROM Users WHERE Email = 'aya.seller@example.com'), (SELECT CategoryID FROM Categories WHERE CategoryKey = 'antiques'), 'Vintage Brass Coffee Set', 'A brass coffee set with light signs of age.', 'very-good', 'Brass', 'Amman, Jordan', 'Auction', NULL, 'JOD', 'published');

INSERT INTO ListingImages (ListingID, ImageSource, AltText, SortOrder)
VALUES
((SELECT ListingID FROM Listings WHERE Title = 'Retro Film Camera'), '../assets/images/auction-camera.jpg', 'Retro film camera', 1),
((SELECT ListingID FROM Listings WHERE Title = 'Vintage Brass Coffee Set'), '../assets/images/auction-tea-set.jpg', 'Brass coffee set', 1);

INSERT INTO Favorites (UserID, ListingID)
VALUES
((SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com'), (SELECT ListingID FROM Listings WHERE Title = 'Retro Film Camera'));

INSERT INTO Auctions (ListingID, StartingPrice, CurrentBid, CurrencyCode, StartsAt, EndsAt, Status)
VALUES
((SELECT ListingID FROM Listings WHERE Title = 'Vintage Brass Coffee Set'), 120.00, 175.00, 'JOD', '2026-11-01 09:00:00', '2026-11-08 18:00:00', 'live');

INSERT INTO Bids (AuctionID, BidderID, BidAmount, BidTime)
VALUES
((SELECT AuctionID FROM Auctions WHERE ListingID = (SELECT ListingID FROM Listings WHERE Title = 'Vintage Brass Coffee Set')), (SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com'), 160.00, '2026-11-05 10:15:00'),
((SELECT AuctionID FROM Auctions WHERE ListingID = (SELECT ListingID FROM Listings WHERE Title = 'Vintage Brass Coffee Set')), (SELECT UserID FROM Users WHERE Email = 'layth.bidder@example.com'), 175.00, '2026-11-05 11:20:00');

INSERT INTO AuctionReminders (UserID, AuctionID)
VALUES
((SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com'), (SELECT AuctionID FROM Auctions WHERE ListingID = (SELECT ListingID FROM Listings WHERE Title = 'Vintage Brass Coffee Set')));

INSERT INTO Orders (OrderNumber, BuyerID, SellerID, ListingID, Status, ItemPrice, DeliveryFee, TotalAmount, CurrencyCode)
VALUES
('NOST-0001', (SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com'), (SELECT UserID FROM Users WHERE Email = 'aya.seller@example.com'), (SELECT ListingID FROM Listings WHERE Title = 'Retro Film Camera'), 'Delivered', 95.00, 5.00, 100.00, 'USD');

INSERT INTO Payments (OrderID, PaymentMethod, PaymentStatus, Amount, CurrencyCode, ProviderReference, PaidAt)
VALUES
((SELECT OrderID FROM Orders WHERE OrderNumber = 'NOST-0001'), 'Card', 'Paid', 100.00, 'USD', 'DEMO-PAYMENT-REF-001', GETDATE());

INSERT INTO Deliveries (OrderID, RecipientName, PhoneNumber, Governorate, City, Street, Building, Unit, DeliveryNotes, Latitude, Longitude, Status)
VALUES
((SELECT OrderID FROM Orders WHERE OrderNumber = 'NOST-0001'), 'Omar Ali', '+962792222222', 'Amman', 'Amman', 'Rainbow Street', '12', '2nd floor', 'Call on arrival', 31.953900, 35.910600, 'Delivered');

INSERT INTO PickupDetails (DeliveryID, ContactName, PhoneNumber, Governorate, City, Street, Building, PickupNotes, PreferredPickupAt, Latitude, Longitude, Status)
VALUES
((SELECT DeliveryID FROM Deliveries WHERE OrderID = (SELECT OrderID FROM Orders WHERE OrderNumber = 'NOST-0001')), 'Aya Fares', '+962791111111', 'Amman', 'Amman', 'Garden Street', '8', 'Front entrance', '2026-11-06 14:00:00', 31.980000, 35.880000, 'scheduled');

INSERT INTO OrderTrackingEvents (OrderID, Status, Description, Location)
VALUES
((SELECT OrderID FROM Orders WHERE OrderNumber = 'NOST-0001'), 'Paid', 'Payment received.', 'Nostalgia'),
((SELECT OrderID FROM Orders WHERE OrderNumber = 'NOST-0001'), 'Preparing', 'Seller is preparing the item.', 'Amman'),
((SELECT OrderID FROM Orders WHERE OrderNumber = 'NOST-0001'), 'On the way', 'The item is with the delivery service.', 'Amman'),
((SELECT OrderID FROM Orders WHERE OrderNumber = 'NOST-0001'), 'Delivered', 'The buyer received the item.', 'Amman');

INSERT INTO Conversations (BuyerID, SellerID, ListingID)
VALUES
((SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com'), (SELECT UserID FROM Users WHERE Email = 'aya.seller@example.com'), (SELECT ListingID FROM Listings WHERE Title = 'Retro Film Camera'));

INSERT INTO Messages (ConversationID, SenderID, MessageText)
VALUES
((SELECT ConversationID FROM Conversations WHERE ListingID = (SELECT ListingID FROM Listings WHERE Title = 'Retro Film Camera')), (SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com'), 'Is the camera still available?'),
((SELECT ConversationID FROM Conversations WHERE ListingID = (SELECT ListingID FROM Listings WHERE Title = 'Retro Film Camera')), (SELECT UserID FROM Users WHERE Email = 'aya.seller@example.com'), 'Yes, it is available and tested.');

INSERT INTO Notifications (UserID, Category, NotificationType, Title, Body, ActionText, Href, OrderID)
VALUES
((SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com'), 'orders', 'order_delivered', 'Your order is complete', 'Your Retro Film Camera has been delivered.', 'My orders', '../user-orders/user-orders.html', (SELECT OrderID FROM Orders WHERE OrderNumber = 'NOST-0001'));

INSERT INTO Reviews (OrderID, ReviewerID, SellerID, SatisfactionRating, SellerRating, ReviewText)
VALUES
((SELECT OrderID FROM Orders WHERE OrderNumber = 'NOST-0001'), (SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com'), (SELECT UserID FROM Users WHERE Email = 'aya.seller@example.com'), 5, 5, 'The camera arrived in good condition.');

INSERT INTO Feedback (UserID, Name, Email, Topic, MessageText, Status)
VALUES
((SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com'), 'Omar Ali', 'omar.buyer@example.com', 'General Question', 'How can I update a saved delivery address?', 'New');

INSERT INTO AdminSettings (AdminUserID, MarketplaceName, DisplayCurrency, SupportEmail)
VALUES
((SELECT UserID FROM Users WHERE Email = 'admin@nostalgia.com'), 'Nostalgia', 'USD', 'support@nostalgia.example');

-- Simple table checks.
SELECT * FROM Users;
SELECT * FROM UserSettings;
SELECT * FROM UserPickupAddresses;
SELECT * FROM Categories;
SELECT * FROM Listings;
SELECT * FROM ListingImages;
SELECT * FROM Favorites;
SELECT * FROM Auctions;
SELECT * FROM Bids;
SELECT * FROM AuctionReminders;
SELECT * FROM Orders;
SELECT * FROM Payments;
SELECT * FROM Deliveries;
SELECT * FROM PickupDetails;
SELECT * FROM OrderTrackingEvents;
SELECT * FROM Conversations;
SELECT * FROM Messages;
SELECT * FROM Notifications;
SELECT * FROM Reviews;
SELECT * FROM Feedback;
SELECT * FROM AdminSettings;

-- Simple relationship checks.
SELECT * FROM Listings WHERE CategoryID = (SELECT CategoryID FROM Categories WHERE CategoryKey = 'antiques');
SELECT * FROM Orders WHERE BuyerID = (SELECT UserID FROM Users WHERE Email = 'omar.buyer@example.com');
