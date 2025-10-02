CREATE DATABASE IF NOT EXISTS crm_device_management
CHARACTER SET utf8mb4user
COLLATE utf8mb4_unicode_ci;
USE crm_device_management;

CREATE TABLE Role (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    is_active TINYINT(1) DEFAULT 1
);

CREATE TABLE User (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (role_id) REFERENCES Role(id) ON DELETE RESTRICT
);

CREATE TABLE Permission (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE Role_Permission (
    role_id INT,
    permission_id INT,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES Role(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES Permission(id) ON DELETE CASCADE
);

CREATE TABLE Category (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active TINYINT(1) DEFAULT 1
);

CREATE TABLE Brand (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active TINYINT(1) DEFAULT 1
);

CREATE TABLE Product (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    brand_id INT,
    image_url VARCHAR(255),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    purchase_price DECIMAL(15,2),
    selling_price DECIMAL(15,2),
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (category_id) REFERENCES Category(id) ON DELETE RESTRICT,
    FOREIGN KEY (brand_id) REFERENCES Brand(id) ON DELETE SET NULL
);

CREATE TABLE Inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity >= 0),
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE RESTRICT
);

CREATE TABLE DevicePurchase (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
	total_amount DECIMAL(15,2),
    purchase_date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES User(id)
);

CREATE TABLE DevicePurchaseDetail (
    id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(15,2) NOT NULL,
    FOREIGN KEY (purchase_id) REFERENCES DevicePurchase(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE RESTRICT
);

CREATE TABLE Device (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
	UNIQUE (user_id, product_id),
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE RESTRICT
);

CREATE TABLE DeviceDetail (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    purchase_detail_id INT NOT NULL,
    serial_number VARCHAR(100) UNIQUE,
    warranty_expiration DATE NOT NULL,
    status ENUM('ACTIVE','EXPIRED','REPLACED') DEFAULT 'ACTIVE',
    FOREIGN KEY (device_id) REFERENCES Device(id),
    FOREIGN KEY (purchase_detail_id) REFERENCES DevicePurchaseDetail(id)
);

CREATE TABLE Request (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    device_id INT NOT NULL,
    device_detail_id INT NULL,
    description TEXT NOT NULL,
    status ENUM('PENDING', 'IN_PROGRESS', 'WAITING_CONFIRM', 'AWAITING_PAYMENT', 'COMPLETED', 'CLOSED') DEFAULT 'PENDING',
    response_by_cskh TEXT,
    forwarded_to_tech TINYINT(1) DEFAULT 0,
    comment TEXT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    attachment TEXT,
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE RESTRICT,
    FOREIGN KEY (device_id) REFERENCES Device(id) ON DELETE RESTRICT,
    FOREIGN KEY (device_detail_id) REFERENCES DeviceDetail(id) ON DELETE SET NULL
);

CREATE TABLE InventoryRequest (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (request_id) REFERENCES Request(id) ON DELETE CASCADE
);

CREATE TABLE InventoryRequestDetail (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inventory_request_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
	action ENUM('TAKEN','RETURNED') NOT NULL DEFAULT 'TAKEN',
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (inventory_request_id) REFERENCES InventoryRequest(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE RESTRICT
);

CREATE TABLE Transaction (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    type ENUM('IMPORT_SUPPLIER','EXPORT_REQUEST','RETURN_REQUEST') NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    inventory_request_detail_id INT NULL,
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE RESTRICT,
    FOREIGN KEY (inventory_request_detail_id) REFERENCES InventoryRequestDetail(id)
);

CREATE TABLE Invoice (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    status ENUM('PENDING', 'PAID', 'CANCELLED') DEFAULT 'PENDING',
    issue_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (request_id) REFERENCES Request(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE RESTRICT
);

CREATE TABLE InvoiceItem (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
	product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(15,2) NOT NULL,
    subtotal DECIMAL(15,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    description TEXT,
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (invoice_id) REFERENCES Invoice(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE RESTRICT
);

CREATE TABLE Payment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    status ENUM('PENDING', 'COMPLETED', 'FAILED') DEFAULT 'PENDING',
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active TINYINT(1) DEFAULT 1,
    FOREIGN KEY (invoice_id) REFERENCES Invoice(id) ON DELETE CASCADE
);
-- 1. Tạo Role
INSERT INTO Role (name, description, is_active)
VALUES 
('ADMIN', 'Quản trị viên có toàn quyền', 1),
('USER', 'Người dùng bình thường', 1);

-- 2. Tạo User admin
INSERT INTO User (role_id, username, password, full_name, email, phone, is_active)
VALUES 
((SELECT id FROM Role WHERE name='ADMIN'), 
 'admin', 
 -- Mật khẩu hash MD5 ví dụ, bạn nên hash theo bcrypt trong thực tế
 MD5('admin123'), 
 'Admin System', 
 'admin@example.com', 
 '0123456789', 
 1);

-- 3. Tạo Permission (ví dụ quyền CRUD cơ bản)
INSERT INTO Permission (name, description)
VALUES 
('VIEW_USER', 'Xem danh sách người dùng'),
('VIEW_USER_DETAIL', 'Xem chi tiết người dùng'),
('MANAGE_USER', 'Tạo, sửa, xóa người dùng'),
('VIEW_DEVICE', 'Xem thiết bị'),
('MANAGE_DEVICE', 'Quản lý thiết bị'),
('VIEW_REQUEST', 'Xem yêu cầu'),
('MANAGE_REQUEST', 'Quản lý yêu cầu');

-- 4. Gán tất cả quyền cho role ADMIN
INSERT INTO Role_Permission (role_id, permission_id)
SELECT r.id, p.id 
FROM Role r, Permission p
WHERE r.name='ADMIN';

-- 5. Tạo một vài user mẫu
INSERT INTO User (role_id, username, password, full_name, email, phone, is_active)
VALUES 
((SELECT id FROM Role WHERE name='USER'), 'user1', MD5('user123'), 'Nguyen Van A', 'user1@example.com', '0901234567', 1),
((SELECT id FROM Role WHERE name='USER'), 'user2', MD5('user123'), 'Tran Thi B', 'user2@example.com', '0902345678', 1);

-- 6. Tạo dữ liệu mẫu Category và Brand
INSERT INTO Category (name, description) VALUES ('Laptop','Máy tính xách tay'), ('Smartphone','Điện thoại thông minh');
INSERT INTO Brand (name, description) VALUES ('Dell','Hãng Dell'), ('Apple','Hãng Apple');

-- 7. Tạo dữ liệu Product mẫu
INSERT INTO Product (category_id, brand_id, name, purchase_price, selling_price)
VALUES 
((SELECT id FROM Category WHERE name='Laptop'), (SELECT id FROM Brand WHERE name='Dell'), 'Dell XPS 13', 2000, 2500),
((SELECT id FROM Category WHERE name='Smartphone'), (SELECT id FROM Brand WHERE name='Apple'), 'iPhone 15', 1000, 1200);
UPDATE User
SET password = '123'
WHERE id > 0;