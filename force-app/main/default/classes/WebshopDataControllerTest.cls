@isTest 
private without sharing class WebshopDataControllerTest {
    @TestSetup
    static void makeData() {
        WebStore webstore = new WebStore(Name = System.Label.WebshopDoNotTranslateStoreName);
        insert webstore;

        // Create a mock Account
        Account account = new Account(Name = 'Test Account');
        insert account;


        WebshopStaticSlider__c slider = new WebshopStaticSlider__c(Name = 'TestSlider');
        insert slider;

        // Create a WebshopBrand
        WebshopBrand__c brand = new WebshopBrand__c(
            Name = 'Test Brand',
            BrandLogo__c = 'https://example.com/logo.png',
            BrandText__c = 'Test brand text',
            WebshopStaticSlider__c = slider.Id
        );
        insert brand;

        // Create a Product
        Product2 product = new Product2(
            BrandWebshop__c = brand.Id, 
            Name = 'Test Product', ProductCode = 'TEST1', 
            IsActive = true, Tenant__c = '001'
        );
        insert product;

        // Create a Wishlist
        Wishlist wishlist = new Wishlist(
            Name = 'Test Wishlist',
            WebstoreId = webstore.Id,
            AccountId = account.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert wishlist;

        // Create a WishlistItem
        WishlistItem wishlistItem = new WishlistItem(
            WishlistId = wishlist.Id,
            Product2Id = product.Id,
            Name = product.Name
        );
        insert wishlistItem;

        // Create a Cart and CartItem
        WebCart cart = new WebCart(AccountId = account.Id, WebstoreId = webstore.Id, Name = 'My Cart');
        insert cart;

        CartDeliveryGroup cdg = new CartDeliveryGroup(Name = 'test', CartId = cart.Id);
        insert cdg;

        CartItem cartItem = new CartItem(
            CartId = cart.Id,
            Product2Id = product.Id,
            Quantity = 1,
            ListPrice = 100.00,
            TotalLineAmount = 100.00,
            Name = 'myitem',
            CartDeliveryGroupId = cdg.Id
        );
        insert cartItem;

        ProductCatalog myCatalog = new ProductCatalog(Name = 'test');
        insert myCatalog;

        // Create a ProductCategory
        ProductCategory category = new ProductCategory(Name = 'Test Category', Subheader__c = 'Test Subheader', CatalogId = myCatalog.Id);
        insert category;

        Contact con = new Contact(LastName = 'test', AccountId = account.Id);
        insert con;

        OrderDeliveryMethod orderDeliveryMethod = new OrderDeliveryMethod(
          Name = 'software-shipping'
        );
        insert orderDeliveryMethod;

        // Create an Order
        Order order = new Order(
            AccountId = account.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            CurrencyIsoCode = 'EUR'
        );
        insert order;

        // Create OrderItem
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            ListPrice = 100.00,
            UnitPrice = 100.00,
            Quantity = 1
        );
        insert orderItem;

        order.Status = 'Activated';
        update order;
    }

    // Helper method to create a CommerceEntitlementProduct for a test account
    private static CommerceEntitlementProduct createTestEntitlementProduct(Id accountId, Id productId) {
        CommerceEntitlementPolicy cep = new CommerceEntitlementPolicy(
            Name = 'Test',
            Description = 'Test',
            IsActive = true,
            Account__c = accountId
        );
        insert cep;
        CommerceEntitlementProduct entitlement = new CommerceEntitlementProduct(
            PolicyId = cep.Id,
            ProductId = productId
        );
        insert entitlement;
        return entitlement;
    }

    @isTest
    static void testAddProductToWishlistNoWishlist() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 newProduct = new Product2(Name = 'New Test Product', ProductCode = 'TEST2', IsActive = true, Tenant__c = '001');
        insert newProduct;
        delete [SELECT Id FROM WishlistItem];
        delete [SELECT Id FROM Wishlist];
        Test.startTest();
            Boolean result = WebshopDataController.addProductToWishlist(account.Id, newProduct.Id);
        Test.stopTest();
        System.assertEquals(true, result, 'Product should be added successfully');
        System.assertEquals(1, [SELECT COUNT() FROM WishlistItem], 'There should be one item in the wishlist');
    }

    @isTest
    static void testAddProductToWishlist() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 newProduct = new Product2(Name = 'New Test Product', ProductCode = 'TEST2', IsActive = true, Tenant__c = '001');
        insert newProduct;
        Test.startTest();
            Boolean result = WebshopDataController.addProductToWishlist(account.Id, newProduct.Id);
        Test.stopTest();
        System.assertEquals(true, result, 'Product should be added successfully');
        System.assertEquals(2, [SELECT COUNT() FROM WishlistItem], 'There should be two items in the wishlist');
    }

    @isTest
    static void testAddProductToWishlistFail() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            Boolean result = WebshopDataController.addProductToWishlist(account.Id, '123');
        Test.stopTest();
        System.assertEquals(false, result, 'Product should be added successfully');
    }

    @isTest
    static void testCountItemsInCart() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        String accountId = testAccount.Id;
        Integer itemCount;
        Test.startTest();
            itemCount = WebshopDataController.countItemsInCart(accountId, cart.Id);
        Test.stopTest();
        System.assertNotEquals(null, itemCount, 'Item count should not be null.');
        System.assertEquals(1, itemCount, 'Cart should contain 1 item.');
    }

    @isTest
    static void testGetCartItems() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        Test.startTest();
            List<WebshopDataController.CartItemWrapper> cartItems = WebshopDataController.getCartItems(account.Id, cart.Id);
        Test.stopTest();
        System.assertNotEquals(null, cartItems, 'Cart items should not be null');
        System.assertEquals(1, cartItems.size(), 'There should be one cart item');
    }

    @isTest
    static void testRemoveItemFromCart() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        CartItem cartItem = [SELECT Id, Product2Id FROM CartItem LIMIT 1];
        Test.startTest();
            Boolean result = WebshopDataController.removeItemFromCart(cart.Id, acc.Id, cartItem.Product2Id);
        Test.stopTest();
        System.assertEquals(true, result, 'Cart item should be removed successfully');
        System.assertEquals(0, [SELECT COUNT() FROM CartItem], 'There should be no cart items remaining');
    }

    @isTest
    static void testRemoveItemFromEmptyCart() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        Product2 p2 = [SELECT Id FROM Product2 LIMIT 1];
        delete [SELECT Id, Product2Id FROM CartItem];
        Test.startTest();
            Boolean result = WebshopDataController.removeItemFromCart(cart.Id, acc.Id, p2.Id);
        Test.stopTest();
        System.assertEquals(true, result, 'Cart item should be removed successfully');
        System.assertEquals(0, [SELECT COUNT() FROM CartItem], 'There should be no cart items remaining');
    }

    @isTest
    static void testChangeCartQuantity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        CartItem cartItem = [SELECT Id, Product2Id FROM CartItem LIMIT 1];
        Integer newQuantity = 5;
        Test.startTest();
            Boolean result = WebshopDataController.changeCartQuantity(cart.Id, acc.Id, cartItem.Product2Id, newQuantity);
        Test.stopTest();
        System.assertEquals(true, result, 'Cart quantity should be updated successfully');
        CartItem updatedCartItem = [SELECT Quantity FROM CartItem WHERE Id = :cartItem.Id];
        System.assertEquals(newQuantity, updatedCartItem.Quantity, 'Cart item quantity should match the new value');
    }

    @isTest
    static void testGetSliderDataByIdQuery() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        WebshopProductSlider__c slider = new WebshopProductSlider__c(
            Name = 'Test Slider',
            Type__c = 'Query',
            Query__c = 'SELECT Id FROM Product2'
        );
        insert slider;
        Product2 product = new Product2();
        product.ExternalId = 'TestProduct';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        insert product;
        CommerceEntitlementProduct entitlementProduct = createTestEntitlementProduct(testAccount.Id, product.Id);  // Assuming Product2 Id
        Test.startTest();
            WebshopDataController.WebshopProductSuperiorWrapper sliderData = WebshopDataController.getSliderDataById(slider.Id, testAccount.Id, 0, '', null, '', false);
        Test.stopTest();
    }

    @isTest
    static void testGetSliderDataById() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        WebshopProductSlider__c slider = new WebshopProductSlider__c(
            Name = 'Test Slider',
            Type__c = 'List'
        );
        insert slider;
        Product2 product = new Product2();
        product.ExternalId = 'TestProduct';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        insert product;
        WebshopProductSliderItem__c item = new WebshopProductSliderItem__c(
            Product__c = product.Id,
            WebshopProductSlider__c = slider.Id,
            Order__c = 1
        );
        insert item;
        CommerceEntitlementProduct entitlementProduct = createTestEntitlementProduct(testAccount.Id, product.Id);  // Assuming Product2 Id
        Test.startTest();
            WebshopDataController.WebshopProductSuperiorWrapper sliderData = WebshopDataController.getSliderDataById(slider.Id, testAccount.Id, 0, '', null,  '', false);
        Test.stopTest();
    }

    @isTest
    static void testGetSliderDataByName() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        WebshopProductSlider__c slider = new WebshopProductSlider__c(
            Name = 'Test Slider',
            Type__c = 'Query',
            Query__c = 'SELECT Id FROM Product2'
        );
        insert slider;
        Product2 product = new Product2();
        product.ExternalId = 'TestProduct';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        insert product;
        CommerceEntitlementProduct entitlementProduct = createTestEntitlementProduct(testAccount.Id, product.Id);  // Assuming Product2 Id
        Test.startTest();
            WebshopDataController.WebshopProductSuperiorWrapper sliderData = WebshopDataController.getSliderDataByName('Test Slider', testAccount.Id, 0, '', null, '', false);
        Test.stopTest();
        System.assertEquals(sliderData.showPagination, false, 'Pagination should be false');
    }
    
    @isTest
    static void testGetSliderDataByNameQuery() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        WebshopProductSlider__c slider = new WebshopProductSlider__c(
            Name = 'Test Slider',
            Type__c = 'List'
        );
        insert slider;
        Product2 product = new Product2();
        product.ExternalId = 'TestProduct';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        insert product;
        WebshopProductSliderItem__c item = new WebshopProductSliderItem__c(
            Product__c = product.Id,
            WebshopProductSlider__c = slider.Id,
            Order__c = 1
        );
        insert item;
        CommerceEntitlementProduct entitlementProduct = createTestEntitlementProduct(testAccount.Id, product.Id);  // Assuming Product2 Id
        Test.startTest();
            WebshopDataController.WebshopProductSuperiorWrapper sliderData = WebshopDataController.getSliderDataByName('Test Slider', testAccount.Id, 0, '', null, '', false);
        Test.stopTest();
    }

    @isTest
    static void testGetSliderDataByCategory() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 product = new Product2();
        product.ExternalId = 'TestProduct';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        insert product;
        ProductCatalog catalog = new ProductCatalog(Name = 'TestCatalog');
        insert catalog;
        ProductCategory cat = new ProductCategory(Name = 'TestCategory', CatalogId = catalog.Id);
        insert cat;
        ProductCategoryProduct pcp = new ProductCategoryProduct(ProductCategoryId = cat.Id, ProductId = product.Id);
        insert pcp;
        WebshopProductSlider__c slider = new WebshopProductSlider__c(
            Name = 'Test Slider',
            Type__c = 'Category',
            Category__c = cat.Id
        );
        insert slider;
        CommerceEntitlementProduct entitlementProduct = createTestEntitlementProduct(testAccount.Id, product.Id);  // Assuming Product2 Id
        Test.startTest();
            WebshopDataController.WebshopProductSuperiorWrapper categoryData = WebshopDataController.getSliderDataByCategory(cat.Id, testAccount.Id, 0, '', null, '', false, product.Id, '');
        Test.stopTest();
    }

    @isTest
    static void testGetSliderDataByBrand() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        WebshopBrand__c brand = new WebshopBrand__c(
            Name = 'test'
        );
        insert brand;
        Product2 product = new Product2();
        product.ExternalId = 'TestProduct';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        product.BrandWebshop__c = brand.Id;
        insert product;
        ProductCatalog catalog = new ProductCatalog(Name = 'TestCatalog');
        insert catalog;
        ProductCategory cat = new ProductCategory(Name = 'TestCategory', CatalogId = catalog.Id);
        insert cat;
        ProductCategoryProduct pcp = new ProductCategoryProduct(ProductCategoryId = cat.Id, ProductId = product.Id);
        insert pcp;
        WebshopProductSlider__c slider = new WebshopProductSlider__c(
            Name = 'Test Slider',
            Type__c = 'Category',
            Category__c = cat.Id
        );
        insert slider;
        CommerceEntitlementProduct entitlementProduct = createTestEntitlementProduct(testAccount.Id, product.Id);  // Assuming Product2 Id
        Test.startTest();
            WebshopDataController.WebshopProductSuperiorWrapper myProductsData = WebshopDataController.getSliderDataByBrand(brand.Id, testAccount.Id, 0, '', null, '', false, null, false);
        Test.stopTest();
    }

    @isTest
    static void testGetSliderDataByMyProducts() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 product = new Product2();
        product.ExternalId = 'TestProduct';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        insert product;
        ProductCatalog catalog = new ProductCatalog(Name = 'TestCatalog');
        insert catalog;
        ProductCategory cat = new ProductCategory(Name = 'TestCategory', CatalogId = catalog.Id);
        insert cat;
        ProductCategoryProduct pcp = new ProductCategoryProduct(ProductCategoryId = cat.Id, ProductId = product.Id);
        insert pcp;
        WebshopProductSlider__c slider = new WebshopProductSlider__c(
            Name = 'Test Slider',
            Type__c = 'Category',
            Category__c = cat.Id
        );
        insert slider;
        CommerceEntitlementProduct entitlementProduct = createTestEntitlementProduct(testAccount.Id, product.Id);  // Assuming Product2 Id
        Test.startTest();
            WebshopDataController.WebshopProductSuperiorWrapper myProductsData = WebshopDataController.getSliderDataByMyProducts(testAccount.Id, 0, '', null, '', false);
        Test.stopTest();
    }

    @isTest
    static void testGetSliderDataBySearchTerm() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 product = new Product2();
        product.ExternalId = 'TestProduct';
        product.Name = 'MyTestCoffee';
        product.Tenant__c = '001';
        product.Type = 'Base';
        product.IsActive = true;
        insert product;
        ProductCatalog catalog = new ProductCatalog(Name = 'TestCatalog');
        insert catalog;
        ProductCategory cat = new ProductCategory(Name = 'TestCategory', CatalogId = catalog.Id);
        insert cat;
        ProductCategoryProduct pcp = new ProductCategoryProduct(ProductCategoryId = cat.Id, ProductId = product.Id);
        insert pcp;
        WebshopProductSlider__c slider = new WebshopProductSlider__c(
            Name = 'Test Slider',
            Type__c = 'Category',
            Category__c = cat.Id
        );
        insert slider;
        CommerceEntitlementProduct entitlementProduct = createTestEntitlementProduct(testAccount.Id, product.Id);  // Assuming Product2 Id
        Test.startTest();
            WebshopDataController.WebshopProductSuperiorWrapper searchTermData = WebshopDataController.getSliderDataBySearchTerm('Coffee', testAccount.Id, 0, '', null, 'priceDesc', true);
        Test.stopTest();
    }

    @isTest
    static void testGetProductDataById() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Test.startTest();
            WebshopDataController.WebshopProductWrapper result = WebshopDataController.getProductDataById(product.Id, account.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Product data should not be null');
    }

    @isTest
    static void testGetCategoryById() {
        ProductCategory category = [SELECT Id, Name FROM ProductCategory LIMIT 1];
        Test.startTest();
            WebshopDataController.WebshopCategoryWrapper result = WebshopDataController.getCategoryById(category.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Category data should not be null');
        System.assertEquals(category.Name, result.category.Name, 'Category name should match');
    }

    @isTest
    static void testGetBrandData() {
        WebshopBrand__c brand = [SELECT Id, Name FROM WebshopBrand__c LIMIT 1];
        Test.startTest();
            WebshopBrand__c result = WebshopDataController.getBrandData(brand.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Brand data should not be null');
        System.assertEquals(brand.Name, result.Name, 'Brand name should match');
    }

    /*
    @isTest
    static void testCreateOrder() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        String accountId = testAccount.Id;
        String phoneNumber = '1234567890';
        String orderNumber = 'ORD123';
        String comment = 'Test order comment';
        Boolean setNewsletter = true;
        Test.startTest(); 
            Map<String, String> order = WebshopDataController.createOrder(accountId, phoneNumber, orderNumber, comment, setNewsletter, null, cart.Id);
        Test.stopTest();
        System.assertNotEquals(null, order.get('orderId'), 'Order ID should not be null.');
        Order createdOrder = [SELECT Id, Status, PoNumber, WebshopPhone__c, WebshopComment__c FROM Order WHERE Id = :order.get('orderId')];
        System.assertEquals(phoneNumber, createdOrder.WebshopPhone__c, 'Phone number should match.');
        System.assertEquals(comment, createdOrder.WebshopComment__c, 'Comment should match.');
    }
        */

    @isTest
    static void testGetMegaMenu() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        WebshopMegaMenu__c mm = new WebshopMegaMenu__c(
            Name = 'Test Mega Menu'
        );
        insert mm;
        WebshopMegaMenuItem__c testMenuItem = new WebshopMegaMenuItem__c(
            Name = 'Test Mega Menu',
            ParentMegaMenu__c = mm.Id,
            Hierarchy__c = 1
        );
        insert testMenuItem;
        WebshopMegaMenuItem__c testMenuItem2 = new WebshopMegaMenuItem__c(
            Name = 'Test Mega Menu Lvl 2',
            ParentMegaMenu__c = mm.Id,
            ParentMegaMenuItem__c = testMenuItem.Id,
            Hierarchy__c = 2
        );
        insert testMenuItem2;
        WebshopMegaMenuItem__c testMenuItem3Featured = new WebshopMegaMenuItem__c(
            Name = 'Test Mega Menu Lvl 3',
            ParentMegaMenu__c = mm.Id,
            ParentMegaMenuItem__c = testMenuItem2.Id,
            Hierarchy__c = 3,
            ThirdLevelFeatured__c = true
        );
        insert testMenuItem3Featured;
        WebshopMegaMenuItem__c testMenuItem3NonFeatured = new WebshopMegaMenuItem__c(
            Name = 'Test Mega Menu Lvl 3 Non Featured',
            ParentMegaMenu__c = mm.Id,
            ParentMegaMenuItem__c = testMenuItem2.Id,
            Hierarchy__c = 3,
            ThirdLevelFeatured__c = false
        );
        insert testMenuItem3NonFeatured;
        Test.startTest();
            WebshopDataController.WebshopMegaMenuSuperiorWrapper megaMenu = WebshopDataController.getMegaMenu('Test Mega Menu', testAccount.Id, Url.getOrgDomainUrl().toExternalForm(), '', '', '');
        Test.stopTest();
        System.assert(!megaMenu.wrappers.isEmpty(), 'Mega menu data should not be empty');
        System.assertEquals(megaMenu.hasBrands, false);
        System.assertEquals(megaMenu.wrappers[0].childrenColStyle, 'display: none;');
        System.assertEquals(megaMenu.wrappers[0].hasFeaturedAd, false);
        System.assertEquals(megaMenu.wrappers[0].hasChildren, true);
        System.assertEquals(megaMenu.wrappers[0].hasFeaturedChildren, false);
    }

    @isTest
    static void testGetFeaturedAdByName() {
        WebshopFeaturedAd__c featuredAd = new WebshopFeaturedAd__c(
            Name = 'Test Ad',
            Title__c = 'Test Ad',
            StartDate__c = Date.today().addDays(-1), 
            EndDate__c = Date.today().addDays(5)
        );
        insert featuredAd;
        Test.startTest();
            WebshopFeaturedAd__c ad = WebshopDataController.getFeaturedAdByName(featuredAd.Name);
        Test.stopTest();
        System.assertNotEquals(null, ad, 'Featured ad should not be null');
        System.assertEquals(featuredAd.Id, ad.Id, 'Featured ad ID should match the inserted record');
    }

    @isTest
    static void testGetFeaturedAdById() {
        WebshopFeaturedAd__c featuredAd = new WebshopFeaturedAd__c(
            Title__c = 'Test Ad',
            StartDate__c = Date.today().addDays(-1), 
            EndDate__c = Date.today().addDays(5)
        );
        insert featuredAd;
        Test.startTest();
            WebshopFeaturedAd__c ad = WebshopDataController.getFeaturedAdById(featuredAd.Id);
        Test.stopTest();
        System.assertNotEquals(null, ad, 'Featured ad should not be null');
        System.assertEquals(featuredAd.Id, ad.Id, 'Featured ad ID should match the inserted record');
    }

    @isTest
    static void testGetStaticSliderDataByName() {
        WebshopStaticSlider__c slider = [SELECT ID FROM WebshopStaticSlider__c LIMIT 1];
        WebshopStaticSliderItem__c staticSliderItem = new WebshopStaticSliderItem__c(
            Text__c = 'Test Static Slider',
            ParentStaticSlider__c = slider.Id
        );
        insert staticSliderItem;
        Test.startTest();
            List<WebshopStaticSliderItem__c> sliderData = WebshopDataController.getStaticSliderDataByName('TestSlider');
        Test.stopTest();
        System.assert(!sliderData.isEmpty(), 'Static slider data should not be empty');
    }

    @isTest
    static void testGetStaticSliderDataById() {
        // Create test data
        WebshopStaticSlider__c slider = [SELECT ID FROM WebshopStaticSlider__c LIMIT 1];
        WebshopStaticSliderItem__c staticSliderItem = new WebshopStaticSliderItem__c(
            Text__c = 'Test Static Slider',
            ParentStaticSlider__c = slider.Id
        );
        insert staticSliderItem;
        Test.startTest();
        List<WebshopStaticSliderItem__c> sliderData = WebshopDataController.getStaticSliderDataById(slider.Id);
        Test.stopTest();

        // Assert that results are returned
        System.assert(!sliderData.isEmpty(), 'Static slider data should not be empty');
    }

    @isTest
    static void testGetIcons() {
        WebshopIcon__c icon = new WebshopIcon__c(Image__c = 'test', Active__c = TRUE, Category__c = 'Certifications');
        insert icon;
        String iconCategory = 'Certifications';
        Test.startTest();
            List<WebshopIcon__c> icons = WebshopDataController.getIcons(iconCategory);
        Test.stopTest();
        System.assertNotEquals(null, icons, 'Icons list should not be null.');
        System.assert(icons.size() > 0, 'Icons list should not be empty.');
    }

    @isTest
    static void testGetAccountSwitcherOptions() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            List<WebshopDataController.OptionWrapper> options = WebshopDataController.getAccountSwitcherOptions(account.Id);
        Test.stopTest();
        System.assertNotEquals(null, options, 'Options should not be null.');
        System.assert(!options.isEmpty(), 'Options should not be empty.');
    }

    @isTest
    static void testRetrieveNewsletterOptIn() {
        Test.startTest();
            Boolean optIn = WebshopDataController.retrieveNewsletterOptIn();
        Test.stopTest();
        System.assertNotEquals(null, optIn, 'OptIn should not be null.');
    }

    @isTest
    static void testSetNewsletterOptIn() {
        User u = [SELECT Id FROM User WHERE IsActive = TRUE AND ContactId != NULL AND Profile.name = 'Customer Community Plus User' ORDER BY CreatedDate DESC LIMIT 1];
        Boolean result;
        Test.startTest();
            System.runAs(u){
                result = WebshopDataController.setNewsletterOptIn();
            }
        Test.stopTest();
        System.assertEquals(true, result, 'Setting newsletter opt-in should succeed.');
    }

    @isTest
    static void testGetUserImage() {
        Test.startTest();
            String imageUrl = WebshopDataController.getUserImage();
        Test.stopTest();
        System.assertNotEquals(null, imageUrl, 'Image URL should not be null.');
    }

    @isTest
    static void testGetShowPriceInfo() {
        Test.startTest();
            Account ac = [SELECT Id FROM Account LIMIT 1];
            System.assertEquals(null, WebshopDataController.getShowPriceInfo(ac.Id), 'ShowPriceInfo should be null.');
        Test.stopTest();
        
    }

    @isTest
    static void testGetActiveAccountInfo() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            Account activeAccount = WebshopDataController.getActiveAccountInfo(account.Id);
        Test.stopTest();
        System.assertNotEquals(null, activeAccount, 'ActiveAccountInfo should not be null.');
    }

    @isTest
    static void testGetShowDoubleOptIn() {
        Test.startTest();
            Boolean showDoubleOptIn = WebshopDataController.getShowDoubleOptIn();
        Test.stopTest();
        System.assertNotEquals(null, showDoubleOptIn, 'ShowDoubleOptIn should not be null.');
    }

    @isTest
    static void testGetShowDoubleOptInCheckout() {
        Test.startTest();
            Boolean showDoubleOptInCheckout = WebshopDataController.getShowDoubleOptInCheckout();
        Test.stopTest();
        System.assertNotEquals(null, showDoubleOptInCheckout, 'ShowDoubleOptInCheckout should not be null.');
    }

    @isTest
    static void testSetDoubleOptInModalSeen() {
        User u = [SELECT Id FROM User WHERE IsActive = TRUE AND ContactId != NULL AND Profile.name = 'Customer Community Plus User' ORDER BY CreatedDate DESC LIMIT 1];
        Boolean result;
        Test.startTest();
            System.runAs(u){
                result = WebshopDataController.setDoubleOptInModalSeen();
            }
        Test.stopTest();
        System.assertEquals(true, result, 'Setting double opt-in modal seen should succeed.');
    }

    @isTest
    static void testSetDoubleOptIn() {
        User u = [SELECT Id FROM User WHERE IsActive = TRUE AND ContactId != NULL AND Profile.name = 'Customer Community Plus User' ORDER BY CreatedDate DESC LIMIT 1];
        Boolean result;
        Test.startTest();
            System.runAs(u){
                result = WebshopDataController.setDoubleOptIn(true);
            }
        Test.stopTest();
        System.assertEquals(true, result, 'Setting double opt-in should succeed.');
    }

    @isTest
    static void testGetCurrentUserInfo() {
        Test.startTest();
            User result = WebshopDataController.getCurrentUserInfo();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Current user info should not be null');
    }

    @isTest
    static void testSetPersonal() {
        Test.startTest();
            Boolean result = WebshopDataController.setPersonal('UpdatedFirstName', 'UpdatedLastName', 'updatedemail@example.com', '1234567890');
        Test.stopTest();

        System.assertEquals(true, result, 'Personal details should be updated successfully');
        User updatedUser = [SELECT FirstName, LastName, Email, MobilePhone FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals('UpdatedFirstName', updatedUser.FirstName, 'First name should match');
        System.assertEquals('UpdatedLastName', updatedUser.LastName, 'Last name should match');
        System.assertEquals('updatedemail@example.com', updatedUser.Email, 'Email should match');
        System.assertEquals('1234567890', updatedUser.MobilePhone, 'Mobile phone should match');
    }

    @isTest
    static void testSetConsent() {
        User u = [SELECT Id FROM User WHERE IsActive = TRUE AND ContactId != NULL AND Profile.name = 'Customer Community Plus User' ORDER BY CreatedDate DESC LIMIT 1];
        Boolean result;
        Contact updatedContact;
        Test.startTest();
            System.runAs(u){
                result = WebshopDataController.setConsent(null, false);
            }
        Test.stopTest();
        u = [SELECT Contact.HasOptedOutOfEmail, Contact.DoubleOptInAbandonedCart__c FROM User WHERE Id = : u.Id];
        System.assertEquals(true, result, 'Consent settings should be updated successfully');
        System.assertEquals(false, u.Contact.HasOptedOutOfEmail, 'Opt-out should match');
        System.assertEquals(false, u.Contact.DoubleOptInAbandonedCart__c, 'Abandoned cart consent should match');

    }

    @isTest
    static void testSetCurrentUserInfo() {
        String language = 'en_US';
        String timezone = 'GMT';
        Test.startTest();
            Boolean result = WebshopDataController.setCurrentUserInfo(language, timezone);
        Test.stopTest();
        System.assertEquals(true, result, 'Method should return true.');
        User updatedUser = [SELECT Id, LanguageLocaleKey, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals(language, updatedUser.LanguageLocaleKey, 'Language should match.');
        System.assertEquals(timezone, updatedUser.TimeZoneSidKey, 'Timezone should match.');
    }

    @isTest
    static void testSetCurrentUserInfoFail() {
        String language = 'x';
        String timezone = 'y';
        Boolean result;
        Test.startTest();
            result = WebshopDataController.setCurrentUserInfo(language, timezone);
        Test.stopTest();
        System.assertEquals(false, result, 'Method should return false.');
    }

    @isTest
    static void testGetSingleOutlet() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        WebshopDataController.OutletWrapper result;
        Test.startTest();
            result = WebshopDataController.getSingleOutlet(testAccount.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'The returned account should not be null');
        System.assertEquals(testAccount.Id, result.outletData.Id, 'The returned account ID should match the input ID');
    }

    @isTest
    static void testGetAllOutlets() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            List<Account> result = WebshopDataController.getAllOutlets(testAccount.Id, 10);
        Test.stopTest();
        System.assertNotEquals(null, result, 'The returned list of accounts should not be null');
    }

    @isTest
    static void testHandleChangeManager() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            Boolean result = WebshopDataController.handleChangeManager(testContact.Id, testAccount.Id, true);
        Test.stopTest();
        System.assertEquals(true, result, 'The method should return true when update succeeds');
        Contact updatedContact = [SELECT Manager__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(true, updatedContact.Manager__c, 'The Manager__c field should be updated to true');
    }

    @isTest
    static void testHandleChangePriceVisible() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
            Boolean result = WebshopDataController.handleChangePriceVisible(testContact.Id, [SELECT Id FROM Account LIMIT 1].Id, true);
        Test.stopTest();
        System.assertEquals(true, result, 'The method should return true when update succeeds');
        Contact updatedContact = [SELECT PriceVisible__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(true, updatedContact.PriceVisible__c, 'The PriceVisible__c field should be updated to true');
    }

    @isTest
    static void testCheckCurrentUserIsManager() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            System.assertEquals(null, WebshopDataController.checkCurrentUserIsManager(testAccount.Id), 'The method should return null');
        Test.stopTest();
    }

    @isTest
    static void testSendMessageNotLoggedIn() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Boolean result;
        Test.startTest();
            result = WebshopDataController.sendMessageNotLoggedIn(
                'Test Subject',
                false,
                'Test Message',
                testAccount.Id,
                'Test Name',
                'test@example.com',
                '1234567890',
                false
            );
        Test.stopTest();
        System.assertEquals(true, result, 'The method should return true when case creation succeeds');
    }
    
    @isTest
    static void testSendMessage() {
        User u = [SELECT Id FROM User WHERE IsActive = TRUE AND ContactId != NULL AND Profile.name = 'Customer Community Plus User' ORDER BY CreatedDate DESC LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Boolean result;
        Test.startTest();
            System.runAs(u){
                result = WebshopDataController.sendMessage(
                    'Test Subject',
                    false,
                    'Test Message',
                    testAccount.Id
                );
            }
        Test.stopTest();
        System.assertEquals(true, result, 'The method should return true when case creation succeeds');
    }

    @isTest
    static void testGetLexOriginUrl() {
        Test.startTest();
            String result = WebshopDataController.getLexOriginUrl();
        Test.stopTest();
        System.assertNotEquals(null, result, 'The returned URL should not be null');
    }

    @isTest
    static void testGetCartSummaryOrCreateCartFail() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        delete [SELECT Id FROM WebCart];
        Test.startTest();
            String summary = WebshopDataController.getCartSummaryOrCreateCart(testAccount.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetAllOrders() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Test.startTest();
            List<Order> orders = WebshopDataController.getAllOrders(testAccount.Id, 10);
        Test.stopTest();
        System.assertNotEquals(null, orders, 'Orders list should not be null');
        System.assert(orders.size() > 0, 'Orders list should contain records');
    }

    @isTest
    static void testGetOrderInfoByOrderId() {
        Order testOrder = [SELECT Id, AccountId FROM Order LIMIT 1];
        Test.startTest();
            WebshopDataController.OrderWrapper orderWrapper = WebshopDataController.getOrderInfoByOrderId(testOrder.Id, testOrder.AccountId);
        Test.stopTest();
        System.assertNotEquals(null, orderWrapper, 'OrderWrapper should not be null');
        System.assertEquals(testOrder.Id, orderWrapper.order.Id, 'OrderWrapper should match the provided OrderId');
    }

    @isTest
    static void testGetSelfServiceStats() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Test.startTest();
            WebshopDataController.SelfServiceStatsWrapper statsWrapper = WebshopDataController.getSelfServiceStats(testAccount.Id);
        Test.stopTest();
        System.assertNotEquals(null, statsWrapper, 'SelfServiceStatsWrapper should not be null');
        System.assert(statsWrapper.orderCount > 0, 'Order count should be greater than 0');
        System.assert(statsWrapper.individualItemCount > 0, 'Individual item count should be greater than 0');
    }

    @isTest
    static void testGetAllOrdersWithInvalidAccountId() {
        Test.startTest();
            List<Order> orders = WebshopDataController.getAllOrders('invalidId', 10);
        Test.stopTest();
        System.assertEquals(0, orders.size(), 'Orders list should be null for invalid accountId');
    }

    @isTest
    static void testGetOrderInfoByOrderIdWithInvalidId() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Test.startTest();
            WebshopDataController.OrderWrapper orderWrapper = WebshopDataController.getOrderInfoByOrderId('invalidId', testAccount.Id);
        Test.stopTest();
        System.assertEquals(null, orderWrapper, 'OrderWrapper should be null for invalid orderId');
    }

    @isTest
    static void testGetAllTeamMembers() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            List<WebshopDataController.TeamMemberWrapper> result = WebshopDataController.getAllTeamMembers(testAccount.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'TeamMemberWrapper list should not be null');
    }

    @isTest
    static void testGetAllTeamMembersInvalid() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            List<WebshopDataController.TeamMemberWrapper> result = WebshopDataController.getAllTeamMembers('InvalidAccountId');
        Test.stopTest();
        System.assertEquals(0, result.size(), 'TeamMemberWrapper list should be empty for invalid AccountId');
    }

    @isTest
    static void testReorder() {
        Order testOrder = [SELECT Id, AccountId FROM Order LIMIT 1];
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        User u = [SELECT Id FROM User WHERE IsActive = TRUE AND ContactId != NULL AND Profile.name = 'Customer Community Plus User' ORDER BY CreatedDate DESC LIMIT 1];
        Boolean result;
        Test.startTest();
            System.runAs(u){
                result = WebshopDataController.reorder(testOrder.Id, testAccount.Id, cart.Id);
            }
        Test.stopTest();
        System.assertEquals(true, result, 'Reorder should return true for valid input');
    }

    @isTest
    static void testGetProductImageDataByIdInvalid() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            List<String> result = WebshopDataController.getProductImageDataById(testAccount.Id, 'InvalidProductId');
        Test.stopTest();
        System.assertEquals(null, result, 'Result should be null for invalid ProductId');
    }

    /*
    @isTest
    static void testWebshopProductWrapperInit() {
        List<WebshopDataController.WebshopProductWrapper> wrappers = new List<WebshopDataController.WebshopProductWrapper>();
        Test.startTest();
            WebshopDataController.WebshopProductWrapper wrapper = new WebshopDataController.WebshopProductWrapper('test', 1);
            WebshopDataController.WebshopProductWrapper wrapper2 = new WebshopDataController.WebshopProductWrapper(new ConnectApi.ProductOverview(), 2, true);
            WebshopDataController.WebshopProductWrapper wrapper3 = new WebshopDataController.WebshopProductWrapper(new ConnectApi.ProductOverview(), '3', true);
            wrappers.add(wrapper);
            wrappers.add(wrapper2);
            wrappers.add(wrapper3);
        Test.stopTest();
        System.assertNotEquals(wrapper, null);
        System.assertNotEquals(wrapper2, null);
        System.assertNotEquals(wrapper3, null);
        wrappers.sort();
        System.assertEquals(wrappers[0].price, '1.00');
    }
    */

    @isTest
    static void testCategoryOptionWrapper() {
        Test.startTest();
            WebshopDataController.CategoryOptionWrapper wrapper = new WebshopDataController.CategoryOptionWrapper('test', 'Name', null, null, null, null, 0);
        Test.stopTest();
        System.assertNotEquals(wrapper, null);
    }

    @isTest
    static void testSliderFilterWrapper() {
        List<WebshopDataController.WebshopSliderFilterWrapper> wrappers = new List<WebshopDataController.WebshopSliderFilterWrapper>();
        Test.startTest();
            WebshopDataController.WebshopSliderFilterWrapper wrapper = new WebshopDataController.WebshopSliderFilterWrapper('test', 'Name', true, false, false, false, false, 1);
            WebshopDataController.WebshopSliderFilterWrapper wrapper2 = new WebshopDataController.WebshopSliderFilterWrapper('test', 'Name', true, false, false, false, false, 2);
            wrappers.add(wrapper);
            wrappers.add(wrapper2);
        Test.stopTest();
        System.assertNotEquals(wrapper, null);
        System.assertEquals(wrapper.show, false);
        wrappers.sort();
        System.assertEquals(wrappers[0].order, 1);
    }
}