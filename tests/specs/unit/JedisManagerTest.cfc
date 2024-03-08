
component
    extends="coldbox.system.testing.BaseModelTest"
{

    /*********************************** LIFE CYCLE Methods ***********************************/

    function beforeAll() {
        super.beforeAll();
        // setup
		model = createMock( "JedisManager");
		model.$("loadSettings");
		model.$property( "jedisServerPort", "variables", "6379" );
		model.$property( "jedisServerName", "variables", "localhost" );
		model.$property( "jedisMaxTotalpool", "variables", 100 );
		model.$property( "jedisMaxIdlePool", "variables", 10 );
		model.$property( "cacheDurationInSeconds", "variables", 20 );
		model.init();
    }

    function afterAll() {
        super.afterAll();
    }

    /*********************************** BDD SUITES ***********************************/

    function run() {
        describe( "JedisManager suite", function() {
            beforeEach( function( currentSpec ) {
            } );

            it( "Can be created", function() {
                expect( model ).toBeComponent();
            } );

			it( "set and get value", function() {
                // Arrange
				var key   = "testKey";
				var value = "testValue";
				model.cacheInsert(key, value,10);

				// Act
				var retrievedValue = model.cacheGet(key);

				// Assert
				assertEquals(value, retrievedValue, "getValue should return the expected value");
            } );

			it( "cacheGet - should return null for a non-existent key", function() {
                // Arrange
				var key = "testKeyNew";

				// Act
				var nonExistentValue = model.cacheGet(key);

				// Assert
				expect(isDefined("nonExistentValue")).toBeFalse("The var 'nonExistentValue' should not be defined");
            } );

			it( "cacheExists - should return false for a non-existent key", function() {
                // Arrange
				var key = "testKeyNew";

				// Act
				var nonExistentKey = model.cacheExists(key);

				// Assert
				expect(nonExistentKey).toBeFalse();
            } );

			it( "cacheExists - should return true for existing key", function() {
                // Arrange
				var key   = "testKey";
				var value = "testValue";
				model.cacheInsert(key, value,10);

				// Act
				var existsKey = model.cacheExists(key);

				// Assert
				expect(existsKey).toBeTrue();
            } );

			it( "cacheClear - should clear existing key and return 1", function() {
                // Arrange
				var key   = "testKey";
				var value = "testValue";
				model.cacheInsert(key, value,10);

				// Act
				var clearKey = model.cacheClear(key);

				// Assert
				expect(clearKey).toBe(1);
            } );

			it( "cacheClear - should return 0 for a non-existent key", function() {
                // Arrange
				var key   = "testKeyNew";

				// Act
				var clearKey = model.cacheClear(key);

				// Assert
				expect(clearKey).toBe(0);
            } );

		} );
	}

}
