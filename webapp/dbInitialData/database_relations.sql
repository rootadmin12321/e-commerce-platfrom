/* ---------------------------------------------
   TABLE KEYS (Primary + Foreign Keys)
----------------------------------------------*/

/* ===== CATEGORY TABLE ===== */
ALTER TABLE Category
ADD CONSTRAINT pk_category_id
PRIMARY KEY (category_id);

ALTER TABLE Category
ADD CONSTRAINT fk_category
FOREIGN KEY (parent_category_id)
REFERENCES Category(category_id);

/* ===== PRODUCT TABLE ===== */
ALTER TABLE Product
ADD CONSTRAINT pk_product_id
PRIMARY KEY (product_id);

ALTER TABLE Product
ADD CONSTRAINT fk_product
FOREIGN KEY (category_id)
REFERENCES Category(category_id);

/* ===== VARIANT TABLE ===== */
ALTER TABLE Variant
ADD CONSTRAINT pk_variant_id
PRIMARY KEY (variant_id);

ALTER TABLE Variant
ADD CONSTRAINT fk_variant
FOREIGN KEY (product_id)
REFERENCES Product(product_id);

/* ===== INVENTORY TABLE ===== */
/* Uncomment if you want a primary key on inventory_id */
/*
ALTER TABLE Inventory
ADD CONSTRAINT pk_inventory_id PRIMARY KEY (inventory_id);
*/

ALTER TABLE Inventory
ADD CONSTRAINT fk_inventory
FOREIGN KEY (variant_id)
REFERENCES Variant(variant_id);

/* ===== REGISTERED_USER TABLE ===== */
ALTER TABLE Registered_User
ADD CONSTRAINT pk_user_id
PRIMARY KEY (user_id);

/* ===== CART_ITEM TABLE ===== */
ALTER TABLE Cart_Item
ADD CONSTRAINT pk_cart_item
PRIMARY KEY (user_id, variant_id);

ALTER TABLE Cart_Item
ADD CONSTRAINT fk_cart_item0
FOREIGN KEY (user_id)
REFERENCES Registered_User(user_id);

ALTER TABLE Cart_Item
ADD CONSTRAINT fk_cart_item1
FOREIGN KEY (variant_id)
REFERENCES Variant(variant_id);

/* ===== ORDERS TABLE ===== */
ALTER TABLE Orders
ADD CONSTRAINT pk_order_id
PRIMARY KEY (order_id);

ALTER TABLE Orders
ADD CONSTRAINT fk_order
FOREIGN KEY (user_id)
REFERENCES Registered_User(user_id);

/* ===== ORDER_ITEM TABLE ===== */
ALTER TABLE Order_Item
ADD CONSTRAINT pk_order_item_id
PRIMARY KEY (order_item_id);

ALTER TABLE Order_Item
ADD CONSTRAINT fk_order_item0
FOREIGN KEY (order_id)
REFERENCES Orders(order_id);

ALTER TABLE Order_Item
ADD CONSTRAINT fk_order_item1
FOREIGN KEY (variant_id)
REFERENCES Variant(variant_id);

/* ===== DELIVERY_MODULE TABLE ===== */
ALTER TABLE Delivery_Module
ADD CONSTRAINT pk_delivery_module_id
PRIMARY KEY (delivery_module_id);

ALTER TABLE Delivery_Module
ADD CONSTRAINT fk_delivery_module
FOREIGN KEY (order_item_id)
REFERENCES Order_Item(order_item_id);

/* ---------------------------------------------
   STORED PROCEDURES
----------------------------------------------*/

DELIMITER $$

/* ===== Add a New User ===== */
CREATE PROCEDURE AddUser(
  IN p_email VARCHAR(255),
  IN p_password VARCHAR(255),
  IN p_username VARCHAR(255)
)
BEGIN
  INSERT INTO Registered_User (email, password, username)
  VALUES (p_email, p_password, p_username);
END$$

/* ===== Get Cart for Registered User ===== */
CREATE PROCEDURE get_cart(IN user_id INT)
BEGIN
    SELECT
        ci.quantity AS quantity,
        v.name AS name,
        v.price AS price,
        v.variant_image AS variant_image,
        p.title AS title,
        v.variant_id AS variant_id
    FROM
        Cart_Item AS ci
    JOIN
        Variant AS v ON ci.variant_id = v.variant_id
    JOIN
        Product AS p ON v.product_id = p.product_id
    WHERE
        ci.user_id = user_id;
END$$

/* ===== Get Subcategories by Parent Name ===== */
CREATE PROCEDURE get_categories(IN parent_category_name VARCHAR(255))
BEGIN
    SELECT category_name, category_image, category_id
    FROM Category
    WHERE parent_category_id = (
        SELECT category_id FROM Category WHERE category_name = parent_category_name
    );
END$$

/* ===== Get Guest Cart (No User Login) ===== */
CREATE PROCEDURE get_guest_cart(IN variant_id INT)
BEGIN
    SELECT p.title, v.name, v.price, v.variant_image, v.variant_id
    FROM Product AS p
    JOIN Variant AS v ON p.product_id = v.product_id
    WHERE v.variant_id = variant_id;
END$$

/* ===== Get Variant Name by Order Item ID ===== */
CREATE PROCEDURE get_variant_name(IN order_item_id INT)
BEGIN
    SELECT variant.name AS variant_name, delivery_module.estimated_days AS estimated_days
    FROM Order_Item
    INNER JOIN Variant ON Order_Item.variant_id = Variant.variant_id
    LEFT JOIN Delivery_Module ON Order_Item.order_item_id = Delivery_Module.order_item_id
    WHERE Order_Item.order_item_id = order_item_id;
END$$

/* ===== Duplicate: Get Variant Name (Safe Alternate) ===== */
CREATE PROCEDURE GetOrderItemDetails(IN order_item_id INT)
BEGIN
    SELECT Variant.name, Delivery_Module.estimated_days
    FROM Order_Item
    INNER JOIN Variant ON Order_Item.variant_id = Variant.variant_id
    LEFT JOIN Delivery_Module ON Order_Item.order_item_id = Delivery_Module.order_item_id
    WHERE Order_Item.order_item_id = order_item_id;
END$$

/* ===== Fix Negative Stock Values ===== */
CREATE PROCEDURE set_stock_count_NULL(IN variant_id INT)
BEGIN
    UPDATE Inventory
    SET stock_count = 0
    WHERE variant_id = variant_id AND stock_count < 0;
END$$

DELIMITER ;
