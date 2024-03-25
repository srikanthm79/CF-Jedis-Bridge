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
    property name="jedisMaxTotalpool"      type="numeric";
    property name="jedisMaxIdlePool"       type="numeric";
    property name="cacheDurationInSeconds" type="numeric";

    /**
     * Initializes the Jedis settings and creates a Redis connection pool.
     *
     * @reset Indicates whether to reset the settings and recreate the connection pool. Defaults to false.
     */
    function init( boolean reset = false ) {
        // Check if the jedisPool does not exist in the application scope or if reset is true.
        if ( !structKeyExists( application, "jedisPool" ) || arguments.reset ) {
            // Load jedis settings
            loadSettings();
            var jedisPoolConfig = createObject(
                "java",
                "redis.clients.jedis.JedisPoolConfig"
            ).init();
            jedisPoolConfig.setMaxTotal( getJedisMaxTotalpool() );
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
    }

    /**
     * Retrieves a Jedis resource from the Jedis pool.
     *
     * @return A Jedis resource from the Jedis pool
     * @throws com.madishetti.JedisManager.getJedisResource.error
     */
    private function getJedisResource() {
        try {
            return application.jedisPool.getResource();
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.getJedisResource.error",
                message = "JedisManager error, retrieving a Jedis resource from the Jedis pool: " & e.message,
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
     * @throws com.madishetti.JedisManager.cacheInsert.error
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
                cacheData = arguments.dataToCache.toJson();
            }
            // Use the Jedis resource
            jedis.setex(
                arguments.cacheKey,
                arguments.cacheDurationInSeconds,
                cacheData
            );
        } catch ( "JedisManager.retriveJedis.resource.error" e ) {
            rethrow;
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.cacheInsert.error",
                message = "JedisManager insert cache error: " & e.message,
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
     * @throws com.madishetti.JedisManager.cacheGet.error
     * @throws com.madishetti.JedisManager.retriveJedis.resource.error
     */
    public any function cacheGet( required string cacheKey ) {
        var jedis = "";
        try {
            // Get a Jedis resource from the pool
            jedis = getJedisResource();
            // Retrieve data from the cache
            var cacheData = jedis.get( arguments.cacheKey );
            // Check if the data is a non-simple value
            if(isJson(cacheData)){
                cacheData = deserializeJson(cacheData);
            }
            return cacheData;
        } catch ( "com.madishetti.JedisManager.retriveJedis.resource.error" e ) {
            rethrow;
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.cacheGet.error",
                message = "JedisManager get cache error: " & e.message,
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
     * @throws com.madishetti.JedisManager.retriveJedis.resource.error
     * @throws com.madishetti.JedisManager.cacheExists.error
     */
    public boolean function cacheExists( required string cacheKey ) {
        var jedis = "";
        try {
            // Get a Jedis resource from the pool
            jedis = getJedisResource();

            // Check key exists in the cache
            return jedis.exists( arguments.cacheKey );
        } catch ( "com.madishetti.JedisManager.retriveJedis.resource.error" e ) {
            rethrow;
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.cacheExists.error",
                message = "com.madishetti.JedisManager check cache exists error: " & e.message,
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
     * @throws com.madishetti.JedisManager.cacheClear.error
     */
    public numeric function cacheClear( required string cacheKey ) {
        var jedis = "";
        try {
            // Get a Jedis resource from the pool
            jedis = getJedisResource();

            // Delete the key from cache
            return jedis.del( arguments.cacheKey );
        } catch ( Exception e ) {
            throw(
                type    = "com.madishetti.JedisManager.cacheClear.error",
                message = "JedisManager clear cache error: " & e.message,
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
     * @throws com.madishetti.JedisManager.loadSettings.error
     */
    private void function loadSettings() {
        try {
            // Deserialize settings json
            var jedisSettings = deserializeJSON( fileRead( expandPath( "." ) & "/JedisSettings.json" ) );

            // Store jedis settings in variables scope
            jedisServerName        = jedisSettings.jedisServerName;
            jedisServerPort        = jedisSettings.jedisServerPort;
            jedisMaxTotalpool      = jedisSettings.jedisMaxTotalpool;
            jedisMaxIdlePool       = jedisSettings.jedisMaxIdlePool;
            cacheDurationInSeconds = jedisSettings.defaultCacheDurationInSeconds;
        } catch ( any e ) {
            throw(
                type    = "com.madishetti.JedisManager.loadSettings.error",
                message = "JedisManager load settings error: " & e.message,
                detail  = e.detail
            );
        }
    }

}
