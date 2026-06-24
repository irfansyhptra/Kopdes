# Implementation Plan: KOPDES Smart Cooperative Intelligence System

## Overview

This implementation plan breaks down the KOPDES system into actionable coding tasks organized by functional epics. The system is a comprehensive digital cooperative platform integrating e-commerce, UMKM marketplace, delivery management, and AI-powered business intelligence. 

The implementation uses:
- **Frontend**: Flutter (Dart) for multi-platform support (Android, iOS, Windows, Linux, macOS)
- **Backend**: NestJS (TypeScript) with modular architecture
- **Database**: PostgreSQL with Prisma ORM
- **Caching**: Redis
- **Storage**: MinIO for object storage, Isar for local mobile storage
- **AI Layer**: LangChain/LangGraph, Gemini/GPT, XGBoost, IndoBERT, Qdrant

## Tasks

### Epic 1: Core System Setup

- [ ] 1.1 Initialize NestJS backend project with modular architecture
  - Set up NestJS project with recommended folder structure
  - Configure TypeScript with strict mode
  - Set up ESLint and Prettier for code quality
  - Create base module structure (auth, product, order, delivery, umkm, ai, inventory, admin, community)
  - Configure environment variables management (.env with validation)
  - _Requirements: 36.1, 36.7_
  - _Priority: Critical_
  - _Estimated Effort: 4 hours_

- [ ] 1.2 Set up PostgreSQL database with Prisma ORM
  - Install and configure Prisma
  - Define complete Prisma schema for all entities (User, Product, Order, UMKM, Delivery, etc.)
  - Create initial database migration
  - Set up database connection pooling
  - Configure Prisma Client generation
  - _Requirements: 17.5, 19.6_
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 1.1_


- [ ] 1.3 Configure Redis caching layer
  - Install Redis and configure connection
  - Create Redis module in NestJS
  - Implement cache service with get/set/delete operations
  - Set up session storage configuration
  - _Requirements: 3.4, 15.1_
  - _Priority: High_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 1.1_

- [ ] 1.4 Set up MinIO object storage for images
  - Install and configure MinIO server
  - Create MinIO storage module in NestJS
  - Implement image upload service with bucket management
  - Configure image compression and optimization
  - Set up public URL generation for images
  - _Requirements: 18.6, 11.3_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 1.1_

- [ ] 1.5 Initialize Flutter frontend project with clean architecture
  - Create Flutter project with multi-platform support
  - Set up feature-first folder structure (core, features)
  - Configure Riverpod for state management
  - Set up Dio for HTTP client with interceptors
  - Configure Go Router for navigation
  - Set up dependency injection
  - _Requirements: 36.1, 36.2, 36.3, 36.4, 36.5, 36.6_
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_

- [ ] 1.6 Configure Isar local database for Flutter
  - Install and configure Isar
  - Define Isar schemas (ProductCache, OrderCache, UserProfileCache)
  - Implement local storage service with CRUD operations
  - Set up data synchronization strategy
  - _Requirements: 3.1, 3.4_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 1.5_

- [ ] 1.7 Set up Docker containerization
  - Create Dockerfile for NestJS backend
  - Create docker-compose.yml with services (PostgreSQL, Redis, MinIO)
  - Configure environment variables for containers
  - Set up health checks for all services
  - Create development and production configurations
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 1.1, 1.2, 1.3, 1.4_


- [ ] 1.8 Configure CI/CD pipeline
  - Set up GitHub Actions or GitLab CI
  - Create build pipeline for backend (linting, testing, build)
  - Create build pipeline for Flutter (Android, iOS, Desktop)
  - Configure automated testing execution
  - Set up deployment workflows
  - _Priority: Medium_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 1.1, 1.5, 1.7_

- [ ] 1.9 Checkpoint - Verify core infrastructure
  - Ensure all services start successfully via Docker Compose
  - Verify database connections and migrations
  - Verify Redis caching functionality
  - Verify MinIO storage accessibility
  - Test Flutter app runs on at least one platform
  - Ask the user if questions arise.

### Epic 2: Authentication & Authorization

- [ ] 2.1 Implement JWT authentication service in NestJS
  - Create Auth module with controller and service
  - Implement JWT strategy with access and refresh tokens
  - Create DTOs for login, register, and token refresh
  - Implement password hashing with bcrypt
  - Set up token expiration handling (15 min access, 7 days refresh)
  - Store refresh tokens in database with user association
  - _Requirements: 1.1, 1.3, 1.6_
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 1.2_

- [ ] 2.2 Implement role-based access control (RBAC)
  - Create RolesGuard for role validation
  - Implement @Roles decorator for endpoint protection
  - Define five roles: SUPER_ADMIN, ADMIN_KOPDES, CUSTOMER, UMKM, COURIER
  - Create role hierarchy and permission matrix
  - Implement role checking middleware
  - _Requirements: 1.4, 1.5_
  - _Priority: Critical_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 2.1_


- [ ] 2.3 Implement password reset flow
  - Create password reset request endpoint
  - Generate secure reset tokens with expiration
  - Store reset tokens in database
  - Implement email service integration for reset links
  - Create password reset confirmation endpoint
  - Validate reset token before allowing password change
  - _Requirements: 1.6 (implied from password reset functionality)_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 2.1_

- [ ] 2.4 Implement user registration endpoints
  - Create registration controller with validation
  - Implement customer registration (role: CUSTOMER)
  - Implement UMKM registration (role: UMKM, status: PENDING_VERIFICATION)
  - Implement courier registration by admin
  - Validate unique email and phone constraints
  - Return JWT tokens upon successful registration
  - _Requirements: 1.1, 2.1, 11.1_
  - _Priority: Critical_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 2.1, 2.2_

- [ ] 2.5 Create authentication UI in Flutter
  - Design login screen with email and password fields
  - Design registration screen with role-specific forms
  - Implement password reset request UI
  - Create password reset confirmation screen
  - Implement form validation with proper error messages
  - Add loading states and error handling
  - _Requirements: 1.1, 2.1_
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 1.5, 2.1_

- [ ] 2.6 Implement authentication state management in Flutter
  - Create AuthStateNotifier with Riverpod
  - Implement login, logout, and token refresh logic
  - Store tokens securely using flutter_secure_storage
  - Implement auto-login on app start
  - Create authentication interceptor for Dio
  - Handle token expiration with automatic refresh
  - _Requirements: 1.1, 1.3, 1.6_
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 2.1, 2.5_


- [ ] 2.7 Implement route guards and role-based navigation
  - Create authentication guard in Go Router
  - Redirect unauthenticated users to login
  - Implement role-based route restrictions
  - Create different home screens for each role
  - Handle unauthorized access attempts gracefully
  - _Requirements: 1.5, 1.4_
  - _Priority: High_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 2.6_

- [ ]* 2.8 Write unit tests for authentication service
  - Test JWT token generation and validation
  - Test password hashing and verification
  - Test refresh token flow
  - Test authentication failures with invalid credentials
  - Test role-based access control
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 2.1, 2.2, 2.3, 2.4_

- [ ] 2.9 Checkpoint - Verify authentication system
  - Test user registration for all roles
  - Test login and token generation
  - Test token refresh mechanism
  - Test role-based access control
  - Test password reset flow
  - Verify secure token storage on Flutter
  - Ask the user if questions arise.

### Epic 3: Product Management

- [ ] 3.1 Create Product and Category entities with Prisma
  - Define Product schema with fields (name, description, price, stock, categoryId, imageUrls, isActive)
  - Define Category schema
  - Create database migration
  - Set up relations between Product and Category
  - Add indexes for performance (categoryId, isActive)
  - _Requirements: 3.1, 18.2_
  - _Priority: Critical_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 1.2_


- [ ] 3.2 Implement Product service with CRUD operations
  - Create Product module with controller and service
  - Implement createProduct with admin authorization
  - Implement updateProduct with admin authorization
  - Implement getProduct by ID with caching
  - Implement getProducts with pagination and filtering
  - Implement deleteProduct (soft delete by setting isActive=false)
  - Implement checkStockAvailability method
  - _Requirements: 18.2, 18.3, 18.4, 3.4_
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 3.1, 2.2_

- [ ] 3.3 Implement Category management service
  - Create Category service with CRUD operations
  - Implement createCategory with admin authorization
  - Implement getCategories endpoint
  - Implement updateCategory with admin authorization
  - Implement deleteCategory with cascade handling
  - _Requirements: 18.1, 3.2_
  - _Priority: High_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 3.1, 2.2_

- [ ] 3.4 Implement product image upload with MinIO
  - Create image upload endpoint
  - Implement image validation (size, format)
  - Implement image compression before storage
  - Store images in MinIO with organized bucket structure
  - Generate and return public URLs for images
  - Support multiple image uploads per product
  - _Requirements: 18.6, 11.3_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 1.4, 3.2_

- [ ] 3.5 Implement product search and filtering
  - Create search endpoint with query parameter
  - Implement full-text search on product name and description
  - Implement filter by category
  - Implement filter by price range (minPrice, maxPrice)
  - Implement filter by stock availability (inStock boolean)
  - Return paginated results with metadata
  - Cache search results in Redis
  - _Requirements: 3.3, 3.2_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 3.2, 1.3_


- [ ] 3.6 Create product catalog UI in Flutter
  - Design product list screen with grid/list view toggle
  - Implement product card widget with image, name, price, stock
  - Create category filter chips
  - Implement search bar with debounced search
  - Add pagination with infinite scroll
  - Implement pull-to-refresh
  - Show stock availability indicators
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 1.5, 3.2, 3.5_

- [ ] 3.7 Create product detail UI in Flutter
  - Design product detail screen with image carousel
  - Display product information (name, description, price, stock, category)
  - Show real-time stock availability
  - Implement "Add to Cart" button with quantity selector
  - Handle out-of-stock state with pre-order option
  - Show loading and error states
  - _Requirements: 3.1, 3.4, 3.5, 4.1, 5.1_
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 3.6_

- [ ] 3.8 Implement product caching in Isar
  - Create ProductCache schema in Isar
  - Implement sync service to fetch and cache products
  - Cache products on first load and periodic refresh
  - Serve cached data when offline
  - Implement cache invalidation strategy
  - _Requirements: 3.1, 3.4_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 1.6, 3.2_

- [ ] 3.9 Create admin product management UI
  - Design admin product list with edit/delete actions
  - Create product form for add/edit with validation
  - Implement image upload UI with preview
  - Create category management UI
  - Add confirmation dialogs for delete actions
  - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5, 18.6_
  - _Priority: High_
  - _Estimated Effort: 7 hours_
  - _Dependencies: 3.2, 3.3, 3.4, 2.7_


- [ ]* 3.10 Write unit tests for product service
  - Test product CRUD operations
  - Test stock availability validation
  - Test search and filtering logic
  - Test image upload handling
  - Test caching behavior
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 18.1, 18.2, 18.3, 18.4, 18.5, 18.6_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 3.2, 3.3, 3.4, 3.5_

- [ ] 3.11 Checkpoint - Verify product management
  - Test product creation and updates by admin
  - Test product search and filtering
  - Test image upload and display
  - Test product catalog on Flutter app
  - Test offline product caching
  - Ask the user if questions arise.

### Epic 4: Order Management

- [ ] 4.1 Create Order entities with Prisma
  - Define Order schema (customerId, totalAmount, status, paymentMethod, paymentStatus, deliveryAddressId)
  - Define OrderItem schema (orderId, productId, quantity, price)
  - Define Cart schema for temporary cart storage
  - Define PreOrder schema
  - Create database migrations
  - Set up relations between Order, OrderItem, Product, User
  - Add indexes for performance (customerId, status, createdAt)
  - _Requirements: 4.1, 4.5, 5.1_
  - _Priority: Critical_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 1.2, 3.1_

- [ ] 4.2 Implement shopping cart service
  - Create Cart service with add/update/remove operations
  - Implement addToCart with stock validation
  - Implement getCart for current user
  - Implement updateCartItem quantity
  - Implement removeFromCart
  - Store cart data in database for persistence
  - Cache cart in Redis for performance
  - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 4.1, 3.2_


- [ ] 4.3 Implement checkout service
  - Create checkout endpoint with transaction handling
  - Validate stock availability for all cart items before checkout
  - Create Order and OrderItem records
  - Clear cart after successful order creation
  - Handle stock validation failures gracefully
  - Return order details with payment instructions
  - _Requirements: 4.5, 4.6_
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 4.2_

- [ ] 4.4 Implement pre-order system
  - Create pre-order service
  - Allow pre-order creation for out-of-stock products
  - Store pre-order with status PENDING
  - Implement notification when pre-ordered product is back in stock
  - Create getPreOrders endpoint for user
  - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 4.1, 3.2_

- [ ] 4.5 Implement order status management
  - Create updateOrderStatus endpoint (admin only)
  - Define status flow: PENDING → PAID → PROCESSING → READY_FOR_DELIVERY → OUT_FOR_DELIVERY → DELIVERED → COMPLETED
  - Validate status transitions
  - Trigger notifications on status changes
  - Log status change history
  - _Requirements: 8.4, 19.1_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 4.3_

- [ ] 4.6 Implement invoice generation service
  - Create invoice generation using PDF library (pdfmake or similar)
  - Include order details, items, prices, payment info, timestamps
  - Store invoice PDF in MinIO
  - Generate public URL for invoice access
  - Create downloadInvoice endpoint
  - _Requirements: 7.1, 7.2, 7.3_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 4.3, 1.4_


- [ ] 4.7 Create shopping cart UI in Flutter
  - Design cart screen showing cart items
  - Display product details, quantity, price per item
  - Implement quantity adjustment controls
  - Implement remove from cart action
  - Show total amount calculation
  - Display "Proceed to Checkout" button
  - Handle empty cart state
  - _Requirements: 4.1, 4.3, 4.4_
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 4.2, 3.7_

- [ ] 4.8 Create checkout UI in Flutter
  - Design checkout screen with order summary
  - Display delivery address selection/creation
  - Show payment method options (QRIS, COD)
  - Display order total and breakdown
  - Implement place order button
  - Handle checkout errors (stock unavailable)
  - Navigate to order confirmation after success
  - _Requirements: 4.5, 4.6, 6.1, 6.2_
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 4.3, 4.7_

- [ ] 4.9 Create order history UI in Flutter
  - Design order list screen with status indicators
  - Display order cards with key information
  - Implement filter by status
  - Create order detail screen showing full order info
  - Display invoice download button
  - Show order timeline with status history
  - _Requirements: 7.3, 19.1_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 4.3, 4.5_

- [ ] 4.10 Implement pre-order UI in Flutter
  - Add pre-order button on out-of-stock products
  - Create pre-order confirmation dialog
  - Display pre-order list screen
  - Show notification when pre-ordered items are available
  - _Requirements: 5.1, 5.2, 5.3, 5.4_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 4.4, 3.7_


- [ ]* 4.11 Write unit tests for order service
  - Test cart operations (add, update, remove)
  - Test checkout flow with stock validation
  - Test order status transitions
  - Test pre-order creation
  - Test invoice generation
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.1, 5.2, 5.3, 5.4, 7.1, 7.2, 7.3_
  - _Priority: Medium_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 4.2, 4.3, 4.4, 4.5, 4.6_

- [ ] 4.12 Checkpoint - Verify order management
  - Test adding products to cart
  - Test checkout with stock validation
  - Test order creation and status updates
  - Test pre-order functionality
  - Test invoice generation and download
  - Ask the user if questions arise.

### Epic 5: Payment System

- [ ] 5.1 Integrate QRIS payment gateway
  - Research and select QRIS payment provider (e.g., Midtrans, Xendit)
  - Install payment gateway SDK
  - Create Payment module with service
  - Implement QRIS code generation endpoint
  - Implement payment webhook handler for status updates
  - Update order payment status on successful payment
  - _Requirements: 6.2, 6.3_
  - _Priority: Critical_
  - _Estimated Effort: 8 hours_
  - _Dependencies: 4.3_

- [ ] 5.2 Implement COD payment handling
  - Create COD payment selection logic
  - Mark order as PENDING_PAYMENT with COD method
  - Create admin endpoint to confirm COD payment after delivery
  - Update order payment status to PAID on admin confirmation
  - _Requirements: 6.4, 6.5_
  - _Priority: High_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 4.3_


- [ ] 5.3 Create payment UI in Flutter
  - Design QRIS payment screen with QR code display
  - Implement QR code scanning functionality
  - Show payment countdown timer
  - Display payment status updates
  - Create payment success/failure screens
  - Handle payment cancellation
  - _Requirements: 6.1, 6.2, 6.3_
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 5.1, 4.8_

- [ ] 5.4 Implement payment status polling/webhook
  - Create payment status polling mechanism in Flutter
  - Implement WebSocket listener for real-time payment updates
  - Update UI automatically on payment confirmation
  - Handle timeout scenarios
  - _Requirements: 6.3, 6.5_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 5.1, 5.3_

- [ ]* 5.5 Write unit tests for payment service
  - Test QRIS code generation
  - Test payment webhook handling
  - Test COD payment confirmation
  - Test payment status updates
  - _Requirements: 6.2, 6.3, 6.4, 6.5_
  - _Priority: Medium_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 5.1, 5.2_

- [ ] 5.6 Checkpoint - Verify payment system
  - Test QRIS payment flow end-to-end
  - Test COD payment selection and confirmation
  - Test payment webhook processing
  - Test payment UI and status updates
  - Ask the user if questions arise.

### Epic 6: Delivery System

- [ ] 6.1 Create Delivery entities with Prisma
  - Define Delivery schema (orderId, courierId, status, courierMarkedDeliveredAt, customerConfirmedAt, estimatedDeliveryTime, actualDeliveryTime)
  - Define DeliveryLocation schema for real-time tracking
  - Create database migrations
  - Set up relations between Delivery, Order, User (courier)
  - Add indexes for performance (courierId, status, orderId)
  - _Requirements: 8.1, 8.5, 8.6, 9.1_
  - _Priority: Critical_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 1.2, 4.1_


- [ ] 6.2 Implement delivery assignment service
  - Create Delivery service
  - Implement assignDelivery endpoint (admin only)
  - Create delivery record linked to order and courier
  - Set initial status to ASSIGNED
  - Send notification to courier on assignment
  - _Requirements: 10.1, 10.2_
  - _Priority: Critical_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 6.1, 4.5_

- [ ] 6.3 Implement dual validation delivery workflow
  - Create courierMarkDelivered endpoint
  - Record courierMarkedDeliveredAt timestamp
  - Update delivery status to COURIER_DELIVERED
  - Send notification to customer
  - Create customerConfirmDelivery endpoint
  - Record customerConfirmedAt timestamp
  - Update delivery status to CUSTOMER_CONFIRMED then COMPLETED
  - Update order status to COMPLETED
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 6.2_

- [ ] 6.4 Implement delivery status management
  - Create updateDeliveryStatus endpoint (courier and admin)
  - Support status transitions: ASSIGNED → ACCEPTED → PICKED_UP → IN_TRANSIT → COURIER_DELIVERED → CUSTOMER_CONFIRMED → COMPLETED
  - Validate status transitions
  - Log all status changes with timestamps
  - Send notifications on each status change
  - _Requirements: 9.2, 9.3, 10.4_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 6.3_

- [ ] 6.5 Set up WebSocket server for real-time tracking
  - Install and configure Socket.IO in NestJS
  - Create WebSocket gateway for delivery tracking
  - Implement connection authentication
  - Create room-based tracking per delivery
  - Implement courier location broadcast
  - _Requirements: 9.1, 9.2, 9.3_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 6.1_


- [ ] 6.6 Implement courier location tracking
  - Create updateCourierLocation endpoint
  - Store location updates in Redis with TTL
  - Broadcast location updates via WebSocket
  - Calculate estimated arrival time based on distance
  - Store location history in database
  - _Requirements: 9.1, 9.2, 9.3_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 6.5_

- [ ] 6.7 Create courier task management UI in Flutter
  - Design courier dashboard showing assigned deliveries
  - Display delivery list with order details and customer info
  - Implement accept/reject delivery actions
  - Create delivery detail screen with customer address and contact
  - Add map integration (OpenStreetMap) showing delivery location
  - Implement status update buttons
  - Add "Mark as Delivered" button
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_
  - _Priority: Critical_
  - _Estimated Effort: 7 hours_
  - _Dependencies: 6.2, 6.4_

- [ ] 6.8 Implement real-time delivery tracking UI in Flutter
  - Install and configure Socket.IO client
  - Create delivery tracking screen with live map
  - Display courier location marker with real-time updates
  - Display customer location marker
  - Show delivery status timeline
  - Display estimated arrival time
  - Show delivery status updates with timestamps
  - Implement customer confirmation button
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 8.3_
  - _Priority: High_
  - _Estimated Effort: 8 hours_
  - _Dependencies: 6.5, 6.6_

- [ ] 6.9 Implement background location tracking for couriers
  - Configure background location service in Flutter
  - Send location updates to backend periodically
  - Handle location permissions
  - Optimize battery usage
  - _Requirements: 9.1, 9.2_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 6.6, 6.7_


- [ ]* 6.10 Write unit tests for delivery service
  - Test delivery assignment
  - Test dual validation workflow
  - Test status transitions
  - Test location tracking
  - Test WebSocket connections
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 9.1, 9.2, 9.3, 9.4, 10.1, 10.2, 10.3, 10.4, 10.5_
  - _Priority: Medium_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 6.11 Checkpoint - Verify delivery system
  - Test delivery assignment by admin
  - Test courier accepting and managing deliveries
  - Test real-time location tracking
  - Test dual validation workflow
  - Test WebSocket connection and updates
  - Ask the user if questions arise.

### Epic 7: UMKM Marketplace

- [ ] 7.1 Create UMKM entities with Prisma
  - Define UMKM schema (userId, businessName, description, address, phone, status, verifiedAt)
  - Define UMKMProduct schema (umkmId, name, description, price, stock, categoryId, imageUrls, isApproved)
  - Define Review schema (productId, umkmProductId, userId, rating, comment)
  - Create database migrations
  - Set up relations between UMKM, UMKMProduct, User, Review
  - Add indexes for performance
  - _Requirements: 11.1, 11.3, 12.4_
  - _Priority: Critical_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 1.2, 3.1_

- [ ] 7.2 Implement UMKM registration and approval service
  - Create UMKM service with registration endpoint
  - Set initial status to PENDING_VERIFICATION
  - Create admin endpoints: approveUMKM and rejectUMKM
  - Update user role to UMKM on approval
  - Send notification to UMKM actor on approval/rejection
  - Store rejection reason in database
  - _Requirements: 11.1, 11.2, 20.1, 20.2_
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 7.1, 2.2_


- [ ] 7.3 Implement UMKM product management service
  - Create UMKM product CRUD endpoints
  - Restrict product creation to verified UMKM actors
  - Implement createUMKMProduct with image upload
  - Implement updateUMKMProduct
  - Implement deactivate product functionality
  - Create admin approval workflow for UMKM products
  - _Requirements: 11.3, 11.4, 11.5, 11.6, 20.3, 20.4_
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 7.2, 1.4_

- [ ] 7.4 Implement UMKM marketplace browsing
  - Create getUMKMProducts endpoint with filtering and pagination
  - Implement filter by UMKM business
  - Implement search functionality for UMKM products
  - Display only approved products to customers
  - Include UMKM business information in product responses
  - _Requirements: 12.1, 12.2_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 7.3_

- [ ] 7.5 Implement product reviews and ratings
  - Create Review service
  - Implement addReview endpoint (authenticated customers only)
  - Validate that customer purchased the product before reviewing
  - Implement getReviews endpoint with pagination
  - Calculate and display average rating for products
  - Update product rating on new reviews
  - _Requirements: 12.4, 12.5_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 7.3, 4.3_

- [ ] 7.6 Implement UMKM sales analytics service
  - Create analytics service for UMKM actors
  - Calculate total revenue, number of orders
  - Identify best-selling products by quantity
  - Calculate sales trends over time periods
  - Calculate product views and conversion rates
  - Create getSalesAnalytics endpoint
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 7.3, 4.3_


- [ ] 7.7 Create UMKM registration UI in Flutter
  - Design UMKM registration form
  - Collect business name, description, address, phone
  - Implement form validation
  - Show pending verification status after submission
  - Display approval/rejection notifications
  - _Requirements: 11.1, 11.2, 11.6_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 7.2, 2.5_

- [ ] 7.8 Create UMKM product management UI in Flutter
  - Design UMKM dashboard showing product list
  - Create product form for adding/editing products
  - Implement image upload for UMKM products
  - Show product approval status
  - Display rejection feedback from admin
  - Implement product activation/deactivation toggle
  - _Requirements: 11.3, 11.4, 11.5, 11.6_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 7.3, 7.7_

- [ ] 7.9 Create UMKM marketplace browsing UI in Flutter
  - Design UMKM marketplace screen separate from regular products
  - Display UMKM products with business information
  - Implement filter by UMKM business
  - Create UMKM product detail screen
  - Display reviews and ratings
  - Implement add to cart for UMKM products
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 7.4, 7.5_

- [ ] 7.10 Create product review UI in Flutter
  - Design review submission form with rating and comment
  - Display review list on product detail screen
  - Show average rating with star display
  - Implement review sorting and filtering
  - _Requirements: 12.4, 12.5_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 7.5, 7.9_


- [ ] 7.11 Create UMKM analytics dashboard UI in Flutter
  - Design analytics dashboard for UMKM actors
  - Display total revenue and order count
  - Show best-selling products chart
  - Display sales trend graph over time
  - Show product performance metrics (views, conversion)
  - Implement time period selector (week, month, year)
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 7.6, 7.8_

- [ ] 7.12 Create admin UMKM management UI
  - Design admin screen for pending UMKM registrations
  - Display UMKM details with approve/reject buttons
  - Create rejection reason input dialog
  - Design admin screen for pending UMKM products
  - Display product details with approve/reject actions
  - Show list of all active UMKM businesses with metrics
  - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 20.6_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 7.2, 7.3, 2.7_

- [ ]* 7.13 Write unit tests for UMKM service
  - Test UMKM registration and approval workflow
  - Test UMKM product CRUD operations
  - Test product reviews and ratings
  - Test sales analytics calculations
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 12.1, 12.2, 12.3, 12.4, 12.5, 13.1, 13.2, 13.3, 13.4, 13.5_
  - _Priority: Medium_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 7.2, 7.3, 7.5, 7.6_

- [ ] 7.14 Checkpoint - Verify UMKM marketplace
  - Test UMKM registration and approval flow
  - Test UMKM product creation and management
  - Test marketplace browsing and filtering
  - Test reviews and ratings
  - Test sales analytics display
  - Ask the user if questions arise.


### Epic 8: Inventory Management

- [ ] 8.1 Create Inventory entities with Prisma
  - Define InventoryMovement schema (productId, type, quantity, reason, beforeStock, afterStock, performedBy, timestamp)
  - Define StockAlert schema (productId, threshold, isActive)
  - Create database migrations
  - Set up relations with Product and User
  - Add indexes for reporting queries
  - _Requirements: 17.5_
  - _Priority: High_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 1.2, 3.1_

- [ ] 8.2 Implement inventory management service
  - Create Inventory service
  - Implement addStock endpoint (admin only)
  - Implement adjustStock endpoint with reason notes
  - Automatically reduce stock on order completion
  - Record all inventory movements in InventoryMovement table
  - Calculate beforeStock and afterStock for audit trail
  - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 8.1, 3.2_

- [ ] 8.3 Implement critical stock alerts
  - Create StockAlert configuration per product
  - Check stock levels after each movement
  - Flag products below threshold as critical
  - Create getCriticalStockProducts endpoint
  - Send notifications to admin when stock is critical
  - _Requirements: 17.6, 22.8_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 8.2_

- [ ] 8.4 Implement inventory movement history
  - Create getInventoryMovements endpoint with filtering
  - Support filter by product, date range, movement type
  - Display complete audit log with user who performed action
  - Implement pagination for large datasets
  - _Requirements: 17.5_
  - _Priority: Medium_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 8.2_


- [ ] 8.5 Create admin inventory management UI in Flutter
  - Design inventory list screen showing all products with stock levels
  - Highlight critical stock products in red
  - Implement stock adjustment dialog with reason input
  - Create add stock dialog
  - Display inventory movement history per product
  - Show audit trail with timestamps and user info
  - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.6_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 8.2, 8.3, 8.4, 2.7_

- [ ]* 8.6 Write unit tests for inventory service
  - Test stock addition and adjustment
  - Test automatic stock reduction on orders
  - Test critical stock detection
  - Test inventory movement logging
  - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.6_
  - _Priority: Medium_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 8.2, 8.3, 8.4_

- [ ] 8.7 Checkpoint - Verify inventory management
  - Test stock additions and adjustments
  - Test automatic stock reduction on orders
  - Test critical stock alerts
  - Test inventory movement history
  - Ask the user if questions arise.

### Epic 9: AI Cooperative Assistant

- [ ] 9.1 Set up LangChain/LangGraph infrastructure
  - Install LangChain and LangGraph libraries
  - Configure LLM provider (Gemini or GPT) with API keys
  - Create AI module in NestJS
  - Set up prompt templates and chains
  - Configure conversation memory management
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7_
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 1.1_


- [ ] 9.2 Implement AI Cooperative Assistant with database integration
  - Create CooperativeAssistant service using LangGraph
  - Implement tools for querying product catalog (stock, availability)
  - Implement tools for querying order status and tracking
  - Implement tools for querying UMKM marketplace products
  - Implement tools for querying promotions and services
  - Configure agent to respond in natural Indonesian language
  - Handle out-of-scope queries with helpful fallback messages
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7_
  - _Priority: Critical_
  - _Estimated Effort: 10 hours_
  - _Dependencies: 9.1, 3.2, 4.3, 7.4_

- [ ] 9.3 Create chat API endpoint for Cooperative Assistant
  - Create POST /ai/chat/cooperative endpoint
  - Accept user message and conversation history
  - Return AI response with context
  - Implement rate limiting to prevent abuse
  - Store conversation history in Redis with TTL
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 9.2_

- [ ] 9.4 Create AI chat UI in Flutter
  - Design chat interface with message bubbles
  - Implement message input with send button
  - Display AI responses with typing indicator
  - Show suggested actions as quick reply buttons
  - Implement conversation history scrolling
  - Add chat bubble with AI branding/avatar
  - Handle loading and error states
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 9.3, 1.5_

- [ ]* 9.5 Write integration tests for AI Cooperative Assistant
  - Test product availability queries
  - Test order status queries
  - Test UMKM product queries
  - Test out-of-scope query handling
  - Test Indonesian language responses
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 9.2, 9.3_


- [ ] 9.6 Checkpoint - Verify AI Cooperative Assistant
  - Test AI assistant responses to various queries
  - Test database integration for product and order queries
  - Test Indonesian language responses
  - Test chat UI functionality
  - Ask the user if questions arise.

### Epic 10: AI UMKM Assistant

- [ ] 10.1 Implement AI UMKM Business Assistant
  - Create UMKMAssistant service using LangChain
  - Implement sales data analysis tools
  - Implement best-selling product identification
  - Implement slow-moving product detection
  - Generate actionable business recommendations
  - Provide pricing optimization suggestions
  - Analyze market trends for product categories
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6_
  - _Priority: High_
  - _Estimated Effort: 8 hours_
  - _Dependencies: 9.1, 7.6_

- [ ] 10.2 Create chat API endpoint for UMKM Assistant
  - Create POST /ai/chat/umkm endpoint
  - Restrict access to UMKM role only
  - Accept UMKM-specific queries
  - Return AI insights and recommendations
  - Store conversation history
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6_
  - _Priority: High_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 10.1_

- [ ] 10.3 Create UMKM AI assistant UI in Flutter
  - Add AI assistant tab in UMKM dashboard
  - Design business insights chat interface
  - Display AI-generated charts and visualizations
  - Show recommended actions as actionable cards
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 10.2, 7.8_


- [ ]* 10.4 Write integration tests for AI UMKM Assistant
  - Test sales analysis functionality
  - Test product recommendations
  - Test business insights generation
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6_
  - _Priority: Medium_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 10.1, 10.2_

- [ ] 10.5 Checkpoint - Verify AI UMKM Assistant
  - Test UMKM assistant with sample sales data
  - Test business recommendations
  - Test UI integration
  - Ask the user if questions arise.

### Epic 11: AI Inventory Intelligence

- [ ] 11.1 Set up XGBoost for demand forecasting
  - Install XGBoost and data science libraries (pandas, scikit-learn)
  - Create InventoryIntelligence service
  - Prepare historical sales data for training
  - Design feature engineering (date features, trends, seasonality)
  - Train initial XGBoost model
  - _Requirements: 23.1, 23.2, 23.3, 23.4, 25.1, 25.2_
  - _Priority: High_
  - _Estimated Effort: 8 hours_
  - _Dependencies: 9.1, 4.3, 8.2_

- [ ] 11.2 Implement fast-moving product analysis
  - Calculate sales velocity per product
  - Rank products by sales velocity
  - Calculate average time to sell out
  - Identify demand trends (increasing, stable, decreasing)
  - Create getFastMovingProducts endpoint
  - _Requirements: 23.1, 23.2, 23.3, 23.4, 23.5_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 11.1_

- [ ] 11.3 Implement slow-moving and dead stock analysis
  - Identify products with low sales velocity
  - Calculate days without sales
  - Identify dead stock (zero sales in configurable period)
  - Calculate inventory holding costs
  - Suggest actions (promotions, discontinue)
  - Create getSlowMovingProducts endpoint
  - _Requirements: 24.1, 24.2, 24.3, 24.4, 24.5, 24.6_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 11.1_


- [ ] 11.4 Implement smart restock recommendations
  - Use XGBoost model to forecast future demand
  - Calculate optimal reorder quantity based on sales velocity
  - Prioritize recommendations based on stock urgency
  - Factor in lead time for procurement
  - Consider seasonal patterns in recommendations
  - Create getRestockRecommendations endpoint
  - _Requirements: 25.1, 25.2, 25.3, 25.4, 25.5, 25.6_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 11.1, 11.2_

- [ ]* 11.5 Write unit tests for inventory intelligence
  - Test fast-moving product calculations
  - Test slow-moving product detection
  - Test restock recommendation algorithm
  - Test XGBoost model predictions
  - _Requirements: 23.1, 23.2, 23.3, 23.4, 23.5, 24.1, 24.2, 24.3, 24.4, 24.5, 24.6, 25.1, 25.2, 25.3, 25.4, 25.5, 25.6_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 11.2, 11.3, 11.4_

- [ ] 11.6 Checkpoint - Verify AI Inventory Intelligence
  - Test fast-moving product analysis with sample data
  - Test slow-moving product detection
  - Test restock recommendations
  - Ask the user if questions arise.

### Epic 12: AI Anomaly Detection

- [ ] 12.1 Implement inventory anomaly detection
  - Create AnomalyDetection service
  - Calculate Expected_Stock = (Stock_Awal + Stock_Masuk - Stock_Terjual)
  - Compare Expected_Stock with Actual_Stock
  - Flag discrepancies exceeding threshold
  - Calculate anomaly severity (low, medium, high, critical)
  - Categorize anomalies by potential cause (recording error, loss, theft, damage)
  - Create detectAnomalies endpoint
  - _Requirements: 26.1, 26.2, 26.3, 26.4, 26.5, 26.6_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 8.2, 9.1_


- [ ] 12.2 Implement inventory risk scoring
  - Calculate risk scores based on anomaly history
  - Factor in anomaly frequency, magnitude, and recency
  - Classify products into risk categories (low, medium, high, critical)
  - Prioritize high-risk products for review
  - Create getRiskScores endpoint
  - _Requirements: 27.1, 27.2, 27.3, 27.4, 27.5_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 12.1_

- [ ] 12.3 Implement automated audit report generation
  - Create AuditReport service
  - Generate periodic inventory audit reports
  - Include summary of detected anomalies
  - List high-risk products
  - Provide recommended actions for each issue
  - Include statistical analysis of inventory accuracy trends
  - Create getAuditReport endpoint with date range
  - Generate PDF audit reports using pdfmake
  - _Requirements: 28.1, 28.2, 28.3, 28.4, 28.5, 28.6_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 12.1, 12.2, 1.4_

- [ ]* 12.4 Write unit tests for anomaly detection
  - Test anomaly detection algorithm
  - Test risk score calculation
  - Test audit report generation
  - _Requirements: 26.1, 26.2, 26.3, 26.4, 26.5, 26.6, 27.1, 27.2, 27.3, 27.4, 27.5, 28.1, 28.2, 28.3, 28.4, 28.5, 28.6_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 12.1, 12.2, 12.3_

- [ ] 12.5 Checkpoint - Verify AI Anomaly Detection
  - Test anomaly detection with sample discrepancies
  - Test risk scoring
  - Test audit report generation
  - Ask the user if questions arise.


### Epic 13: AI Demand Intelligence

- [ ] 13.1 Set up IndoBERT NLP and Qdrant vector database
  - Install IndoBERT model and transformers library
  - Install and configure Qdrant vector database
  - Create DemandIntelligence service
  - Implement text embedding generation using IndoBERT
  - Set up Qdrant collections for community suggestions
  - _Requirements: 29.1, 29.2, 29.3, 29.4, 29.5, 29.6_
  - _Priority: High_
  - _Estimated Effort: 7 hours_
  - _Dependencies: 9.1, 1.7_

- [ ] 13.2 Implement community need analysis with NLP
  - Process community suggestions with IndoBERT
  - Extract key product needs from suggestion text
  - Group similar suggestions using vector similarity
  - Categorize suggestions into product categories
  - Identify emerging needs not in current catalog
  - Quantify community interest by supporter count
  - Create analyzeCommunityNeeds endpoint
  - _Requirements: 29.1, 29.2, 29.3, 29.4, 29.5, 29.6_
  - _Priority: High_
  - _Estimated Effort: 8 hours_
  - _Dependencies: 13.1, 14.1_

- [ ] 13.3 Implement demand trend analysis
  - Analyze historical sales patterns for trends
  - Identify seasonal demand variations
  - Correlate demand spikes with external factors
  - Identify products with increasing/decreasing trajectories
  - Create getDemandTrends endpoint
  - Generate trend visualizations
  - _Requirements: 30.1, 30.2, 30.3, 30.4, 30.5_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 11.1, 4.3_

- [ ] 13.4 Implement community demand ranking
  - Rank suggested products by supporter count
  - Factor in suggestion frequency and recency
  - Identify top requested product categories
  - Highlight frequently requested but unstocked products
  - Create getRankedDemands endpoint
  - _Requirements: 31.1, 31.2, 31.3, 31.4, 31.5_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 13.2_


- [ ] 13.5 Implement AI procurement recommendations
  - Generate procurement recommendations based on community analysis
  - Prioritize products with highest community demand
  - Estimate potential demand volume for new products
  - Consider feasibility factors (supplier availability)
  - Provide justification for each recommendation
  - Create getProcurementRecommendations endpoint
  - _Requirements: 32.1, 32.2, 32.3, 32.4, 32.5, 32.6_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 13.4_

- [ ] 13.6 Implement demand forecasting
  - Forecast product demand for next month using XGBoost
  - Incorporate community suggestion data into forecasts
  - Adjust for seasonal patterns
  - Account for holidays and significant dates
  - Provide confidence intervals for predictions
  - Create getDemandForecast endpoint
  - _Requirements: 33.1, 33.2, 33.3, 33.4, 33.5, 33.6_
  - _Priority: High_
  - _Estimated Effort: 7 hours_
  - _Dependencies: 11.1, 13.2_

- [ ]* 13.7 Write integration tests for demand intelligence
  - Test NLP processing of community suggestions
  - Test demand ranking algorithm
  - Test procurement recommendations
  - Test demand forecasting
  - _Requirements: 29.1-29.6, 30.1-30.5, 31.1-31.5, 32.1-32.6, 33.1-33.6_
  - _Priority: Medium_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 13.2, 13.4, 13.5, 13.6_

- [ ] 13.8 Checkpoint - Verify AI Demand Intelligence
  - Test community need analysis with sample suggestions
  - Test demand ranking and forecasting
  - Test procurement recommendations
  - Ask the user if questions arise.


### Epic 14: Community Features

- [ ] 14.1 Create CommunitySuggestion entities with Prisma
  - Define CommunitySuggestion schema (userId, productName, category, description, supportCount)
  - Define SuggestionSupport schema (suggestionId, userId, createdAt)
  - Create database migrations
  - Set up relations with User
  - Add indexes for performance
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_
  - _Priority: High_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 1.2_

- [ ] 14.2 Implement community suggestion service
  - Create CommunitySuggestion service
  - Implement submitSuggestion endpoint (authenticated users)
  - Implement getSuggestions endpoint with pagination
  - Implement supportSuggestion endpoint to add support
  - Prevent duplicate support from same user
  - Increment supportCount on each support
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 14.1_

- [ ] 14.3 Create community suggestion UI in Flutter
  - Design suggestion submission form (product name, category, description)
  - Create suggestion list screen showing all community suggestions
  - Display support count with "Support" button
  - Implement visual feedback for already-supported suggestions
  - Add sorting options (most supported, recent)
  - _Requirements: 14.1, 14.2, 14.3, 14.4_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 14.2, 1.5_

- [ ] 14.4 Create admin view for community suggestions
  - Add suggestions tab in admin dashboard
  - Display all suggestions with support counts
  - Show AI-analyzed insights from Demand Intelligence
  - Implement filter by category
  - Link to procurement recommendations
  - _Requirements: 14.5, 29.6, 31.5, 32.6_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 14.2, 13.2, 2.7_


- [ ]* 14.5 Write unit tests for community features
  - Test suggestion submission
  - Test suggestion support mechanism
  - Test duplicate support prevention
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_
  - _Priority: Medium_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 14.2_

- [ ] 14.6 Checkpoint - Verify community features
  - Test suggestion submission and display
  - Test support functionality
  - Test admin view of suggestions
  - Ask the user if questions arise.

### Epic 15: Executive Dashboard

- [ ] 15.1 Implement executive dashboard aggregation service
  - Create ExecutiveDashboard service
  - Aggregate insights from AI_Inventory_Intelligence
  - Aggregate insights from AI_Anomaly_Detection
  - Aggregate insights from AI_Demand_Intelligence
  - Calculate real-time operational metrics
  - Create getDashboardInsights endpoint
  - _Requirements: 34.1, 34.2, 34.3, 34.4, 34.5, 34.6, 34.7, 34.8, 34.9, 34.10, 34.11, 34.12_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 11.2, 11.3, 11.4, 12.1, 12.2, 13.4, 13.6_

- [ ] 15.2 Implement admin dashboard metrics
  - Calculate total sales revenue for current period
  - Calculate total number of transactions
  - Identify best-selling products
  - Identify worst-selling products
  - Count total users by role
  - Count active UMKM businesses
  - Identify critical stock products
  - Implement real-time dashboard updates using WebSocket
  - _Requirements: 22.1, 22.2, 22.3, 22.4, 22.5, 22.6, 22.7, 22.8, 22.9_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 4.3, 7.2, 8.3_


- [ ] 15.3 Create executive dashboard UI in Flutter
  - Design comprehensive admin dashboard with cards for key metrics
  - Display AI-powered insights prominently
  - Show restock recommendations from AI
  - Display dead stock alerts
  - Show inventory anomalies requiring attention
  - Display high-risk products from risk scoring
  - Show top community-requested products
  - Display demand forecast for next month
  - Show UMKM growth metrics and trends
  - Display transaction trends and patterns
  - Implement auto-refresh for real-time updates
  - _Requirements: 34.1-34.12, 22.1-22.9_
  - _Priority: High_
  - _Estimated Effort: 10 hours_
  - _Dependencies: 15.1, 15.2, 2.7_

- [ ] 15.4 Create data visualization components
  - Implement chart library (fl_chart or similar)
  - Create sales trend line chart
  - Create product performance bar chart
  - Create category distribution pie chart
  - Create UMKM growth chart
  - Add interactive tooltips and legends
  - _Requirements: 22.4, 22.5, 34.10, 34.11_
  - _Priority: Medium_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 15.3_

- [ ]* 15.5 Write integration tests for dashboard
  - Test dashboard data aggregation
  - Test metrics calculation accuracy
  - Test real-time updates
  - _Requirements: 22.1-22.9, 34.1-34.12_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 15.1, 15.2_

- [ ] 15.6 Checkpoint - Verify executive dashboard
  - Test dashboard data display
  - Test AI insights integration
  - Test real-time metrics updates
  - Test data visualizations
  - Ask the user if questions arise.


### Epic 16: Notification System

- [ ] 16.1 Set up Firebase Cloud Messaging (FCM)
  - Create Firebase project and configure for Android/iOS
  - Install FCM dependencies in Flutter and NestJS
  - Configure Firebase credentials
  - Set up device token management
  - Implement token refresh handling
  - _Requirements: 35.1, 35.2, 35.3, 35.4, 35.5, 35.6, 35.7, 35.8_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 1.5_

- [ ] 16.2 Implement push notification service in NestJS
  - Create Notification service
  - Implement sendNotification method using FCM
  - Create notification templates for different event types
  - Store notification history in database
  - Implement user notification preferences
  - _Requirements: 35.1, 35.2, 35.3, 35.4, 35.5, 35.6, 35.7, 35.8_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 16.1_

- [ ] 16.3 Integrate notifications with order events
  - Send notification on order status change
  - Send notification when courier marks delivery complete
  - Send notification when pre-ordered product is available
  - _Requirements: 35.1, 35.2, 35.3_
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 16.2, 4.5, 6.3, 4.4_

- [ ] 16.4 Integrate notifications with UMKM events
  - Send notification to UMKM on new orders
  - Send notification on product approval/rejection
  - _Requirements: 35.4, 35.5_
  - _Priority: High_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 16.2, 7.3_


- [ ] 16.5 Integrate notifications with delivery events
  - Send notification to courier on delivery assignment
  - _Requirements: 35.6_
  - _Priority: High_
  - _Estimated Effort: 2 hours_
  - _Dependencies: 16.2, 6.2_

- [ ] 16.6 Integrate notifications with inventory events
  - Send notification to admin on critical stock alerts
  - _Requirements: 35.7_
  - _Priority: High_
  - _Estimated Effort: 2 hours_
  - _Dependencies: 16.2, 8.3_

- [ ] 16.7 Implement email notification service
  - Configure email service (NodeMailer or similar)
  - Create email templates for important events
  - Implement password reset email
  - Implement order confirmation email
  - Implement UMKM approval/rejection email
  - _Requirements: 35.1-35.8 (email as alternative channel)_
  - _Priority: Medium_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 16.2_

- [ ] 16.8 Create notification preferences UI in Flutter
  - Design notification settings screen
  - Allow users to enable/disable notification types
  - Implement save preferences functionality
  - Handle FCM token registration
  - _Requirements: 35.8_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 16.1, 16.2_

- [ ] 16.9 Implement notification display in Flutter
  - Handle foreground notifications with in-app display
  - Handle background notifications with system tray
  - Implement notification action handling (tap to open relevant screen)
  - Display notification history in app
  - _Requirements: 35.1-35.7_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 16.1, 16.8_


- [ ]* 16.10 Write integration tests for notifications
  - Test FCM token management
  - Test notification sending
  - Test notification preferences
  - _Requirements: 35.1-35.8_
  - _Priority: Medium_
  - _Estimated Effort: 3 hours_
  - _Dependencies: 16.2, 16.3, 16.4, 16.5, 16.6_

- [ ] 16.11 Checkpoint - Verify notification system
  - Test push notifications on mobile devices
  - Test email notifications
  - Test notification preferences
  - Test notification display and actions
  - Ask the user if questions arise.

### Epic 17: Admin Management Features

- [ ] 17.1 Implement user management for admin
  - Create user list endpoint with role filtering
  - Create getUserById endpoint
  - Implement updateUser endpoint (admin only)
  - Implement deactivate/activate user account
  - Display user activity logs
  - _Requirements: 22.6, 21.1, 21.2_
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 2.1, 2.2_

- [ ] 17.2 Implement courier management for admin
  - Create registerCourier endpoint (admin only)
  - Implement getCouriers endpoint with performance metrics
  - Calculate delivery metrics (completed deliveries, average time)
  - Implement courier activation/deactivation
  - Flag performance issues based on thresholds
  - _Requirements: 21.1, 21.2, 21.3, 21.4, 21.5, 21.6_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 6.4, 17.1_


- [ ] 17.3 Implement transaction monitoring for admin
  - Create admin order list endpoint with advanced filtering
  - Filter by status, date range, payment method
  - Create getOrderDetails endpoint
  - Implement COD payment confirmation endpoint
  - Generate sales reports for time periods
  - Calculate total revenue, transaction count, average order value
  - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6_
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 4.3, 5.2_

- [ ] 17.4 Create admin user management UI in Flutter
  - Design user list screen with role filter
  - Display user details with edit capability
  - Implement user activation/deactivation toggle
  - Show user activity logs
  - _Requirements: 22.6, 21.1, 21.2_
  - _Priority: Medium_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 17.1, 2.7_

- [ ] 17.5 Create courier management UI in Flutter
  - Design courier list with performance metrics
  - Display delivery completion rate
  - Show average delivery time per courier
  - Highlight performance issues
  - Implement courier registration form
  - Add activation/deactivation controls
  - _Requirements: 21.1, 21.2, 21.3, 21.4, 21.5, 21.6_
  - _Priority: Medium_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 17.2, 2.7_

- [ ] 17.6 Create transaction monitoring UI in Flutter
  - Design admin orders screen with filters
  - Implement date range picker
  - Add status and payment method filters
  - Display order details with customer info
  - Add COD payment confirmation button
  - Show sales report with charts
  - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6_
  - _Priority: High_
  - _Estimated Effort: 7 hours_
  - _Dependencies: 17.3, 2.7_


- [ ]* 17.7 Write unit tests for admin features
  - Test user management operations
  - Test courier management and metrics
  - Test transaction monitoring and filtering
  - Test sales report generation
  - _Requirements: 19.1-19.6, 21.1-21.6, 22.6_
  - _Priority: Medium_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 17.1, 17.2, 17.3_

- [ ] 17.8 Checkpoint - Verify admin features
  - Test user management operations
  - Test courier management
  - Test transaction monitoring
  - Test sales reports
  - Ask the user if questions arise.

### Epic 18: Deployment & DevOps

- [ ] 18.1 Configure production Docker Compose
  - Create production docker-compose.yml
  - Configure all services (backend, PostgreSQL, Redis, MinIO, Qdrant)
  - Set up volume mounts for data persistence
  - Configure environment variables for production
  - Set up service dependencies and health checks
  - Configure resource limits
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 1.7_

- [ ] 18.2 Set up Nginx reverse proxy
  - Install and configure Nginx
  - Create Nginx configuration for backend API
  - Configure SSL/TLS certificates (Let's Encrypt)
  - Set up load balancing if multiple backend instances
  - Configure rate limiting
  - Set up static file serving for uploaded images
  - Configure WebSocket proxy for real-time features
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 18.1_


- [ ] 18.3 Set up Prometheus monitoring
  - Install and configure Prometheus
  - Add Prometheus metrics endpoint to NestJS
  - Configure metrics collection (HTTP requests, response times, errors)
  - Set up custom metrics for business KPIs
  - Configure scrape intervals
  - Set up retention policies
  - _Priority: High_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 18.1_

- [ ] 18.4 Set up Grafana dashboards
  - Install and configure Grafana
  - Connect Grafana to Prometheus data source
  - Create system health dashboard (CPU, memory, disk)
  - Create API performance dashboard (request rates, latency)
  - Create business metrics dashboard (orders, revenue, users)
  - Create AI service monitoring dashboard
  - Configure alerting rules
  - _Priority: High_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 18.3_

- [ ] 18.5 Set up Sentry error tracking
  - Create Sentry project
  - Install Sentry SDK in NestJS
  - Install Sentry SDK in Flutter
  - Configure error reporting with context
  - Set up release tracking
  - Configure error grouping and filtering
  - Set up alert notifications for critical errors
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 1.1, 1.5_

- [ ] 18.6 Configure database backup strategy
  - Set up automated PostgreSQL backups
  - Configure backup schedule (daily, weekly)
  - Set up backup retention policy
  - Store backups in separate storage (S3 or similar)
  - Create backup restoration procedure documentation
  - Test backup and restore process
  - _Priority: Critical_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 18.1_


- [ ] 18.7 Configure logging infrastructure
  - Set up centralized logging (ELK stack or similar)
  - Configure log aggregation from all services
  - Set up log retention policies
  - Create log analysis dashboards
  - Configure log-based alerts
  - _Priority: Medium_
  - _Estimated Effort: 5 hours_
  - _Dependencies: 18.1_

- [ ] 18.8 Create deployment documentation
  - Document deployment process step-by-step
  - Create infrastructure diagram
  - Document environment variable configuration
  - Create troubleshooting guide
  - Document scaling strategies
  - Create disaster recovery procedures
  - _Priority: High_
  - _Estimated Effort: 4 hours_
  - _Dependencies: 18.1, 18.2, 18.6_

- [ ] 18.9 Build and deploy Flutter applications
  - Build Android APK/AAB for production
  - Build iOS IPA for App Store
  - Build Windows desktop installer
  - Build Linux desktop package
  - Build macOS desktop app
  - Test installations on target platforms
  - Upload to distribution platforms (Play Store, App Store)
  - _Requirements: 36.1, 36.2, 36.3, 36.4, 36.5_
  - _Priority: Critical_
  - _Estimated Effort: 8 hours_
  - _Dependencies: 1.5, all frontend tasks_

- [ ] 18.10 Perform security hardening
  - Configure firewall rules
  - Disable unnecessary services
  - Set up fail2ban for intrusion prevention
  - Configure security headers in Nginx
  - Review and secure API endpoints
  - Implement API key rotation strategy
  - Conduct security audit of authentication flow
  - _Priority: Critical_
  - _Estimated Effort: 6 hours_
  - _Dependencies: 18.1, 18.2_


- [ ] 18.11 Final system integration testing
  - Test complete user flows end-to-end
  - Test all role-based access controls
  - Test payment flows (QRIS and COD)
  - Test delivery tracking with multiple concurrent orders
  - Test AI assistants with various queries
  - Test notification delivery across all channels
  - Test system under load with multiple concurrent users
  - Verify data consistency across all modules
  - Test backup and recovery procedures
  - _Requirements: All requirements_
  - _Priority: Critical_
  - _Estimated Effort: 12 hours_
  - _Dependencies: All epics completed_

- [ ] 18.12 Checkpoint - Final deployment verification
  - Verify all services are running in production
  - Verify monitoring and alerting are functional
  - Verify backups are being created
  - Verify mobile apps are deployed
  - Conduct final security review
  - Ask the user if questions arise.

## Notes

### Task Prioritization
- **Critical**: Core functionality that blocks other work or is essential for MVP
- **High**: Important features that significantly impact user experience
- **Medium**: Valuable features that can be delivered after core functionality
- **Low**: Nice-to-have features for future iterations

### Optional Tasks
- Tasks marked with `*` are optional and primarily consist of unit/integration tests
- These can be skipped for faster MVP delivery but are recommended for production quality
- Non-test tasks are NOT marked as optional and must be implemented

### Implementation Notes
- Each task references specific requirements for traceability
- Tasks are ordered to minimize dependencies and allow parallel work where possible
- Checkpoints ensure validation at key milestones
- Estimated efforts are in hours and can be adjusted based on team velocity


### Technical Architecture Summary
- **Frontend**: Flutter with Clean Architecture (Presentation → Domain → Data)
- **State Management**: Riverpod with StateNotifiers
- **Backend**: NestJS with modular architecture
- **Database**: PostgreSQL with Prisma ORM
- **Caching**: Redis for sessions and frequently accessed data
- **Storage**: MinIO for images, Isar for local mobile storage
- **AI Layer**: LangChain/LangGraph orchestration, Gemini/GPT for LLM, XGBoost for ML, IndoBERT for NLP, Qdrant for vectors
- **Real-time**: WebSocket (Socket.IO) for delivery tracking
- **Monitoring**: Prometheus + Grafana + Sentry
- **Infrastructure**: Docker Compose + Nginx

### Task Execution Strategy
1. **Start with Epic 1**: Core infrastructure must be in place first
2. **Parallel execution**: After core setup, Epics 2-4 can be worked on in parallel
3. **AI modules**: Can be developed independently after Epic 1 is complete
4. **Frontend**: Can progress in parallel with backend API development
5. **Integration points**: Checkpoints ensure proper integration between epics
6. **Testing**: Optional test tasks can be executed in parallel or deferred

### Development Phases
**Phase 1 - Foundation (Epics 1-2)**: Infrastructure and authentication
**Phase 2 - Core Features (Epics 3-6)**: Product, order, payment, delivery
**Phase 3 - Marketplace (Epic 7)**: UMKM features
**Phase 4 - Operations (Epic 8)**: Inventory management
**Phase 5 - Intelligence (Epics 9-13)**: AI assistants and analytics
**Phase 6 - Management (Epics 14-17)**: Community features, dashboards, admin
**Phase 7 - Production (Epic 18)**: Deployment and DevOps


## Task Dependency Graph

```json
{
  "waves": [
    {
      "id": 0,
      "tasks": ["1.1", "1.5"]
    },
    {
      "id": 1,
      "tasks": ["1.2", "1.3", "1.4", "1.6", "1.7"]
    },
    {
      "id": 2,
      "tasks": ["1.8", "2.1", "3.1", "4.1", "6.1", "7.1", "8.1", "9.1", "14.1", "16.1"]
    },
    {
      "id": 3,
      "tasks": ["2.2", "2.3", "2.4", "3.2", "3.3", "11.1", "17.1"]
    },
    {
      "id": 4,
      "tasks": ["2.5", "2.6", "3.4", "3.5", "4.2", "6.5", "7.2", "8.2", "13.1", "16.2"]
    },
    {
      "id": 5,
      "tasks": ["2.7", "2.8", "3.6", "3.8", "4.3", "6.2", "7.3", "8.3", "9.2", "10.1", "11.2", "11.3", "12.1", "14.2", "17.2"]
    },
    {
      "id": 6,
      "tasks": ["3.7", "3.9", "3.10", "4.4", "4.5", "5.1", "5.2", "6.3", "6.4", "7.4", "7.5", "8.4", "9.3", "11.4", "12.2", "13.2", "13.3", "17.3"]
    },
    {
      "id": 7,
      "tasks": ["4.6", "4.7", "5.3", "5.5", "6.6", "6.7", "7.6", "7.7", "7.12", "7.13", "8.5", "8.6", "9.4", "9.5", "10.2", "11.5", "12.3", "13.4", "14.3", "14.4", "16.3", "16.4", "16.5", "16.6", "17.4", "17.5"]
    },
    {
      "id": 8,
      "tasks": ["4.8", "4.9", "4.10", "4.11", "5.4", "6.8", "6.9", "6.10", "7.8", "7.9", "10.3", "10.4", "12.4", "13.5", "13.6", "14.5", "15.1", "15.2", "16.7", "16.8", "17.6"]
    },
    {
      "id": 9,
      "tasks": ["7.10", "7.11", "13.7", "15.3", "16.9", "16.10", "17.7"]
    },
    {
      "id": 10,
      "tasks": ["15.4", "15.5", "18.1"]
    },
    {
      "id": 11,
      "tasks": ["18.2", "18.3", "18.5", "18.6", "18.7"]
    },
    {
      "id": 12,
      "tasks": ["18.4", "18.8", "18.10"]
    },
    {
      "id": 13,
      "tasks": ["18.9"]
    },
    {
      "id": 14,
      "tasks": ["18.11"]
    }
  ]
}
```
