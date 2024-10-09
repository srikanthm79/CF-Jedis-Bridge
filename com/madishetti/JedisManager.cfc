/**
 * JedisManager is a ColdFusion component (CFC) designed to manage caching with Jedis,
 * a Java client library for Redis. This component provides methods for initializing
 * Jedis settings, setting configuration values, and utilizing caching methods such as
 * cacheGet, cacheExists, and cacheInsert.
 *
 * The target platform for this CFC is mainly Adobe ColdFusion, levaring the underlying
 * Jedis Java library supplied with ACF. However, it should be generally compatible with
 * Lucee as well provided the Jedis library is available in the classpath.
 *
 * @author Srikanth Madishetti
 * @version 1.0
 */

component accessors="true" {

    property name="jedisServerName"        type="string";
    property name="jedisServerPort"        type="numeric";
    property name="jedisMaxTotalPool"      type="numeric";
    property name="jedisMaxIdlePool"       type="numeric";
    property name="cacheDurationInSeconds" type="numeric";

    /**
     * Initializes the Jedis settings and creates a Redis connection pool.
     *
     * @reset Indicates whether to reset the settings and recreate the connection pool. Defaults to false.
     */
    function init( boolean reset = false, struct config = {}) {

        // Check if the jedisPool does not exist in the application scope or if reset is true.
        if ( !structKeyExists( application, "jedisPool" ) || arguments.reset ) {
                        
            if (!structIsEmpty( arguments.config)) {
                // set jedis settings from config structre passed in arguments
                parseConfig( arguments.config );

            } else {
                // Load jedis settings from json file -default
                loadSettings();
            }
            var jedisPoolConfig = createObject(
                "java",
                "redis.clients.jedis.JedisPoolConfig"
            ).init();
            jedisPoolConfig.setMaxTotal( getJedisMaxTotalPool() );
            jedisPoolConfig.setMaxIdle( getJedisMaxIdlePool() );
            // Store the Redis connection pool within the application scope.
            lock scope="application" type="exclusive" timeout="5" {
                application.jedisPool = createObject(
                    "java",
                    "redis.clients.jedis.JedisPool"
                ).init(
                    jedisPoolConfig,
                    getJedisServerName(),
                    getJedisServerPort()
                );
            }
        }
        return this;
    }

    /**
     * Retrieves a Jedis resource from the Jedis pool.
     *
     * @return A Jedis resource from the Jedis pool
     * @throws com.madishetti.JedisManager.JedisResourceRetrievalException
     */
    private function getJedisResource() {
        try {
            return application.jedisPool.getResource();
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.JedisResourceRetrievalException",
                message = "JedisManager - problem retrieving a Jedis resource from the Jedis pool: " & e.message,
                detail  = e.detail
            );
        }
    }

    /**
     * Returns a borrowed Jedis resource back to the Jedis pool.
     *
     * @jedis A Jedis resource to return to the pool.
     */
    private function returnJedisResource( required any jedis ) {
        arguments.jedis.close();
    }

    /**
     * Caches a value with the given key for a specified duration.
     *
     * @cacheKey The key to cache the value (string, required)
     * @dataToCache The value to cache (any, required)
     * @cacheDurationInSeconds The duration for which the value should be cached, in seconds. Defaults to value set in settings. (numeric, optional)
     *
     * @throws com.madishetti.JedisManager.CacheInsertException
     * @throws com.madishetti.JedisManager.CacheInsertTypeException
     * @throws com.madishetti.JedisManager.JedisResourceRetrievalException
     */
    public void function cacheInsert(
        required string cacheKey,
        required any dataToCache,
        numeric cacheDurationInSeconds = getCacheDurationInSeconds()
    ) {
        var jedis = "";
        try {
            // Get a Jedis resource from the pool
            jedis = getJedisResource();

            var cacheData = arguments.dataToCache;
            // Check if the data to cache is a non-simple value
            if (!isSimpleValue(cacheData)) {
                // Check and throw an exception if the data is an object and not a struct, array, or query.
                // Need isObject check because isStruct will return true for an object
                if (isObject(cacheData) || !(isStruct(cacheData) || isArray(cacheData) || isQuery(cacheData))) {
                    throw(
                        type = "com.madishetti.JedisManager.CacheInsertTypeException",
                        message = "Jedis Manager - invalid data type for caching. Data to cache must be a struct, array, query or simple value."
                    );
                }
                cacheData = serializeJson(cacheData);
            }

            // Use the Jedis resource
            jedis.setex(
                arguments.cacheKey,
                arguments.cacheDurationInSeconds,
                cacheData
            );
        } catch ( "com.madishetti.JedisManager.JedisResourceRetrievalException" e ) {
            rethrow;
        }  catch ( "com.madishetti.JedisManager.CacheInsertTypeException" e ) {
            rethrow;
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.CacheInsertException",
                message = "JedisManager - problem inserting into the cache: " & e.message,
                detail  = e.detail
            );
        } finally {
            // Return the Jedis resource to the pool
            if ( isObject( jedis ) ) {
                returnJedisResource( jedis );
            }
        }
    }

    /**
     * Retrieves the cached value for the given cache key.
     *
     * @cacheKey The key for which to retrieve the cached value. (string, required)
     *
     * @return The cached value associated with the cache key, or `null` if the key is not found.
     * @throws com.madishetti.JedisManager.CacheGetException
     * @throws com.madishetti.JedisManager.JedisResourceRetrievalException
     */
    public any function cacheGet( required string cacheKey ) {
        var jedis = "";
        try {
            // Get a Jedis resource from the pool
            jedis = getJedisResource();
            // Retrieve data from the cache
            var cacheData = jedis.get( arguments.cacheKey );
            // Check if the cacheData is a json value
            if(isJson(cacheData)){
                cacheData = deserializeJson(cacheData);
            }
            return cacheData;
        } catch ( "com.madishetti.JedisManager.JedisResourceRetrievalException" e ) {
            rethrow;
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.CacheGetException",
                message = "JedisManager - problem getting an element from the cache: " & e.message,
                detail  = e.detail
            );
        } finally {
            // Return the Jedis resource to the pool
            if ( isObject( jedis ) ) {
                returnJedisResource( jedis );
            }
        }
    }

    /**
     * Checks if a value exists in the cache for the given cache key.
     *
     * @cacheKey The key to check for existence in the cache. (string, required)
     *
     * @return `true` if a value exists for the cache key, `false` otherwise.
     * @throws com.madishetti.JedisManager.JedisResourceRetrievalException
     * @throws com.madishetti.JedisManager.CacheExistsException
     */
    public boolean function cacheExists( required string cacheKey ) {
        var jedis = "";
        try {
            // Get a Jedis resource from the pool
            jedis = getJedisResource();

            // Check key exists in the cache
            return jedis.exists( arguments.cacheKey );
        } catch ( "com.madishetti.JedisManager.JedisResourceRetrievalException" e ) {
            rethrow;
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.CacheExistsException",
                message = "JedisManager - problem when checking if an element exists: " & e.message,
                detail  = e.detail
            );
        } finally {
            // Return the Jedis resource to the pool
            if ( isObject( jedis ) ) {
                returnJedisResource( jedis );
            }
        }
    }

    /**
     * Delete the given key and associated value from cache.
     *
     * We are using DEL instead of UNLINK because UNLINK is not supported with the
     * Jedis version shipped with CF 2021. Once UNLINK is available,
     * consider switching to it, as it removes keys asynchronously in the background,
     * allowing non-blocking operation.
     *
     * @cacheKey The key to remove from the cache. (string, required)
     *
     * @return `1` if the key is found and deleted; otherwise, returns `0`.
     * @throws com.madishetti.JedisManager.CacheClearException
     * @throws com.madishetti.JedisManager.JedisResourceRetrievalException
     */
    public numeric function cacheClear( required string cacheKey ) {
        var jedis = "";
        try {
            // Get a Jedis resource from the pool
            jedis = getJedisResource();

            // Delete the key from cache
            return jedis.del( arguments.cacheKey );
        } catch ( "com.madishetti.JedisManager.JedisResourceRetrievalException" e ) {
            rethrow;
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.CacheClearException",
                message = "JedisManager - problem when trying to clear an element from the cache: " & e.message,
                detail  = e.detail
            );
        } finally {
            // Return the Jedis resource to the pool
            if ( isObject( jedis ) ) {
                returnJedisResource( jedis );
            }
        }
    }

    /**
     * Loads Jedis settings from a JSON file and stores them in the variables scope.
     * This function reads the 'JedisSettings.json' file located in the same directory.
     * It deserializes the JSON content and assigns the settings to corresponding variables in the variables scope.
     *
     * @throws com.madishetti.JedisManager.SettingsException
     */
    private void function loadSettings() {
        try {
            // Deserialize settings json
            var jedisSettings = deserializeJSON( fileRead( expandPath( "." ) & "/JedisSettings.json" ) );

            // Store jedis settings in variables scope
            jedisServerName        = jedisSettings.jedisServerName;
            jedisServerPort        = jedisSettings.jedisServerPort;
            jedisMaxTotalPool      = jedisSettings.jedisMaxTotalPool;
            jedisMaxIdlePool       = jedisSettings.jedisMaxIdlePool;
            cacheDurationInSeconds = jedisSettings.defaultCacheDurationInSeconds;
        } catch ( any e ) {
            throw(
                type    = "com.madishetti.JedisManager.SettingsException",
                message = "JedisManager - setting couldn't be loaded: " & e.message,
                detail  = e.detail
            );
        }
    }

      /**
     * Loads Jedis settings from a argument struct and stores them in the variables scope.
     * This function parses the 'arguments.config' var passed.
     * It assigns the settings to corresponding variables in the variables scope.
     *
     * @throws com.madishetti.JedisManager.ConfigSettingsException
     */

    private void function parseConfig(required struct config) {
        var property="";
        var jedisProperties = getMetadata(this).properties;
        try {
            
            // loop through the jedis struct and validate the config structure

                for (property in jedisProperties) {
                    // Check if the property exists in config passed
                    if (!structKeyExists(config, property.name)) {
                        throw(
                            type    = "com.madishetti.JedisManager.ConfigSettingsException",
                            message = "JedisManager - setting couldn't be loaded.",
                            detail  =  property.name & " is missing in passed config structure"
                        );   
                    } 
                    invoke( this,"set#property.name#" , { "#property.name#" = arguments.config["#property.name#"] } );            
                }
            }
            catch ( any e ) {
            throw(
                type    = "com.madishetti.JedisManager.ConfigSettingsException",
                message = "JedisManager - setting couldn't be loaded: " & e.message,
                detail  = e.detail
            );
        }
    }
}
