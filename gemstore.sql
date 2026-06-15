-- GEMSTORE - Mobile Legends Diamond Top-Up Platform
-- Database Schema

CREATE DATABASE IF NOT EXISTS gemstore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gemstore;

-- Users (Customer, Reseller, Admin)
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role ENUM('customer', 'reseller', 'admin') DEFAULT 'customer',
  status ENUM('active', 'pending', 'blocked') DEFAULT 'active',
  wallet_balance DECIMAL(12, 2) DEFAULT 0.00,
  mlbb_user_id VARCHAR(50),
  mlbb_server_id VARCHAR(50),
  referral_code VARCHAR(20) UNIQUE,
  referred_by INT,
  reseller_discount DECIMAL(5, 2) DEFAULT 10.00,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (referred_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_role (role),
  INDEX idx_status (status),
  INDEX idx_referral (referral_code)
);

-- Diamond Packages
CREATE TABLE packages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  diamonds VARCHAR(50) NOT NULL,
  type ENUM('diamonds', 'weekly_pass', 'twilight_pass') DEFAULT 'diamonds',
  price DECIMAL(10, 2) NOT NULL,
  reseller_price DECIMAL(10, 2),
  product_image VARCHAR(255),
  product_option VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Orders
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(30) NOT NULL UNIQUE,
  user_id INT NOT NULL,
  package_id INT NOT NULL,
  mlbb_user_id VARCHAR(50) NOT NULL,
  mlbb_server_id VARCHAR(50) NOT NULL,
  quantity INT DEFAULT 1,
  unit_price DECIMAL(10, 2) NOT NULL,
  discount_amount DECIMAL(10, 2) DEFAULT 0.00,
  total_amount DECIMAL(10, 2) NOT NULL,
  coupon_id INT,
  payment_method ENUM('wallet', 'upi', 'phonepe', 'gpay', 'paytm', 'razorpay', 'cashfree') DEFAULT 'wallet',
  payment_status ENUM('pending', 'paid', 'failed', 'refunded') DEFAULT 'pending',
  status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
  placed_by_reseller INT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (package_id) REFERENCES packages(id),
  INDEX idx_user (user_id),
  INDEX idx_status (status),
  INDEX idx_created (created_at)
);

-- Wallet Transactions
CREATE TABLE transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  type ENUM('deposit', 'withdrawal', 'purchase', 'refund', 'referral_bonus', 'commission', 'admin_credit', 'admin_debit') NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  balance_after DECIMAL(12, 2) NOT NULL,
  description VARCHAR(255),
  reference_id VARCHAR(100),
  order_id INT,
  status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'completed',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL,
  INDEX idx_user_type (user_id, type)
);

-- Wallet Deposit/Withdrawal Requests
CREATE TABLE wallet_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  type ENUM('deposit', 'withdrawal') NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  payment_method VARCHAR(50),
  payment_proof VARCHAR(255),
  upi_id VARCHAR(100),
  bank_details TEXT,
  status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  admin_note TEXT,
  processed_by INT,
  processed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (processed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Coupons
CREATE TABLE coupons (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  discount_type ENUM('percentage', 'fixed') DEFAULT 'percentage',
  discount_value DECIMAL(10, 2) NOT NULL,
  min_order_amount DECIMAL(10, 2) DEFAULT 0.00,
  max_uses INT DEFAULT NULL,
  used_count INT DEFAULT 0,
  expires_at TIMESTAMP NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Coupon Usage Tracking
CREATE TABLE coupon_usages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  coupon_id INT NOT NULL,
  user_id INT NOT NULL,
  order_id INT NOT NULL,
  discount_amount DECIMAL(10, 2) NOT NULL,
  used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (coupon_id) REFERENCES coupons(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (order_id) REFERENCES orders(id)
);

-- Referral Rewards
CREATE TABLE referral_rewards (
  id INT AUTO_INCREMENT PRIMARY KEY,
  referrer_id INT NOT NULL,
  referred_id INT NOT NULL,
  order_id INT,
  reward_amount DECIMAL(10, 2) NOT NULL,
  status ENUM('pending', 'credited') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (referrer_id) REFERENCES users(id),
  FOREIGN KEY (referred_id) REFERENCES users(id)
);

-- Reseller Commissions
CREATE TABLE reseller_commissions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  reseller_id INT NOT NULL,
  order_id INT NOT NULL,
  order_amount DECIMAL(10, 2) NOT NULL,
  commission_rate DECIMAL(5, 2) NOT NULL,
  commission_amount DECIMAL(10, 2) NOT NULL,
  status ENUM('pending', 'credited') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reseller_id) REFERENCES users(id),
  FOREIGN KEY (order_id) REFERENCES orders(id)
);

-- Support Tickets
CREATE TABLE support_tickets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ticket_number VARCHAR(20) NOT NULL UNIQUE,
  user_id INT NOT NULL,
  subject VARCHAR(200) NOT NULL,
  category ENUM('order', 'payment', 'account', 'technical', 'other') DEFAULT 'other',
  priority ENUM('low', 'medium', 'high') DEFAULT 'medium',
  status ENUM('open', 'in_progress', 'resolved', 'closed') DEFAULT 'open',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Ticket Replies
CREATE TABLE ticket_replies (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ticket_id INT NOT NULL,
  user_id INT NOT NULL,
  message TEXT NOT NULL,
  is_admin BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ticket_id) REFERENCES support_tickets(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Notifications
CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  type ENUM('order', 'wallet', 'promo', 'support', 'system') DEFAULT 'system',
  is_read BOOLEAN DEFAULT FALSE,
  link VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_user_read (user_id, is_read)
);

-- Banners
CREATE TABLE banners (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(150),
  image_url VARCHAR(500),
  link_url VARCHAR(500),
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Announcements
CREATE TABLE announcements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FAQs
CREATE TABLE faqs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  question VARCHAR(500) NOT NULL,
  answer TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Site Settings
CREATE TABLE site_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(100) NOT NULL UNIQUE,
  setting_value TEXT,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Activity Logs
CREATE TABLE activity_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  action VARCHAR(100) NOT NULL,
  details TEXT,
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_created (created_at)
);

-- Reseller API Keys (Optional)
CREATE TABLE api_keys (
  id INT AUTO_INCREMENT PRIMARY KEY,
  reseller_id INT NOT NULL,
  api_key VARCHAR(64) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT TRUE,
  last_used_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reseller_id) REFERENCES users(id)
);

-- Seed Admin User: run `npm run seed` in backend/ after import (admin@gemstore.com / Admin@123)

-- Seed MLBB Packages
INSERT INTO packages (name, diamonds, type, price, reseller_price, sort_order) VALUES
('86 Diamonds', '86', 'diamonds', 149.00, 134.00, 1),
('172 Diamonds', '172', 'diamonds', 299.00, 269.00, 2),
('257 Diamonds', '257', 'diamonds', 449.00, 404.00, 3),
('344 Diamonds', '344', 'diamonds', 599.00, 539.00, 4),
('429 Diamonds', '429', 'diamonds', 749.00, 674.00, 5),
('514 Diamonds', '514', 'diamonds', 899.00, 809.00, 6),
('706 Diamonds', '706', 'diamonds', 1199.00, 1079.00, 7),
('878 Diamonds', '878', 'diamonds', 1499.00, 1349.00, 8),
('963 Diamonds', '963', 'diamonds', 1649.00, 1484.00, 9),
('1412 Diamonds', '1412', 'diamonds', 2399.00, 2159.00, 10),
('Weekly Diamond Pass', 'Weekly', 'weekly_pass', 159.00, 143.00, 11),
('Twilight Pass', 'Twilight', 'twilight_pass', 499.00, 449.00, 12);

-- Seed Site Settings
INSERT INTO site_settings (setting_key, setting_value) VALUES
('site_name', 'GEMSTORE'),
('tagline', 'Fast, Secure & Affordable MLBB Diamond Top-Ups'),
('whatsapp_support', '+91 8900387026'),
('support_email', 'gemstore25@gmail.com'),
('referral_bonus_percent', '5'),
('reseller_commission_percent', '8'),
('min_wallet_deposit', '100'),
('min_wallet_withdrawal', '500');

-- Seed Sample Coupon
INSERT INTO coupons (code, discount_type, discount_value, min_order_amount, max_uses, expires_at) VALUES
('WELCOME10', 'percentage', 10.00, 100.00, 1000, DATE_ADD(NOW(), INTERVAL 1 YEAR));

-- Seed FAQs
INSERT INTO faqs (question, answer, sort_order) VALUES
('How long does diamond delivery take?', 'Most orders are delivered within 5-15 minutes after payment confirmation.', 1),
('What payment methods do you accept?', 'We accept UPI, PhonePe, Google Pay, Paytm, Razorpay, Cashfree, and Wallet balance.', 2),
('How do I find my MLBB User ID and Server ID?', 'Open Mobile Legends, go to your Profile. User ID is shown at the top. Server ID is the number in parentheses next to your name.', 3),
('Can I get a refund?', 'Refunds are available for failed orders. Contact support via WhatsApp or ticket system.', 4);

<!-- WHATSAPP FAB -->
<a class="wa-fab" href="https://wa.me/91918900287026" target="_blank" title="WhatsApp Support">
  <svg width="28" height="28" viewBox="0 0 32 32" fill="none"><circle cx="16" cy="16" r="16" fill="transparent"/><path d="M16 4C9.373 4 4 9.373 4 16c0 2.385.658 4.617 1.8 6.525L4 28l5.65-1.775A11.94 11.94 0 0016 28c6.627 0 12-5.373 12-12S22.627 4 16 4z" fill="white"/><path d="M21.75 19.15c-.3-.15-1.77-.87-2.04-.97-.27-.1-.47-.15-.67.15-.2.3-.77.97-.94 1.17-.17.2-.35.22-.65.07-.3-.15-1.26-.46-2.4-1.47-.89-.79-1.49-1.77-1.66-2.07-.17-.3-.02-.46.13-.61.13-.13.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.07-.15-.67-1.62-.92-2.22-.24-.58-.49-.5-.67-.51-.17-.01-.37-.01-.57-.01-.2 0-.52.07-.79.37-.27.3-1.04 1.02-1.04 2.49s1.07 2.89 1.22 3.09c.15.2 2.1 3.2 5.08 4.49.71.31 1.26.49 1.69.62.71.23 1.36.2 1.87.12.57-.09 1.77-.72 2.02-1.42.25-.7.25-1.3.17-1.42-.08-.12-.27-.19-.57-.34z" fill="#25d366"/></svg>
</a>
<div class="wa-tooltip">💬 Chat with Support on WhatsApp</div>

 <!-- FOOTER -->
  <footer class="admin-footer">
    © 2026 GEM STORE. All rights reserved. · <a href="https://wa.me/919189002870260" target="_blank">WhatsApp Support</a>
  </footer>
</div>
