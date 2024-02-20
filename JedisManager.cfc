/**
 * JedisManager.cfc
 * 
 * Author: Srikanth Madishetti
 * 
 * JedisManager is a ColdFusion component (CFC) designed to manage caching with Jedis, 
 * a Java client library for Redis. This component provides methods for initializing 
 * Jedis settings, setting configuration values, and utilizing caching methods such as
 * cacheGet, cacheExists, and cacheInsert.
 * 
 * @author Srikanth Madishetti
 * @version 1.0
 */
component {
    
    function init(
        boolean reset = false
    )
    {     
        if( !structKeyExists(application,"jedisPool") || arguments.reset){
            // Load jedis settings
            loadSettings();
            var jedisPoolConfig = createObject("java", "redis.clients.jedis.JedisPoolConfig").init();
            jedisPoolConfig.setMaxTotal(variables.jedisMaxTotalpool);
            jedisPoolConfig.setMaxIdle(variables.jedisMaxIdlePool);
            // Store the Redis connection pool within the application scope.
            lock scope="application" type="exclusive" timeout="5" {
                application.jedisPool = createObject("java", "redis.clients.jedis.JedisPool").init(
                    jedisPoolConfig,
                    variables.jedisServerName,
                    variables.jedisServerPort
                );
            }
        }
        
    }
    
    /**
     * Retrieves a Jedis resource from the Jedis pool.
    */
    private function getJedisResource() {
        return application.jedisPool.getResource();
    }
    
    /**
     * Returns a borrowed Jedis resource back to the Jedis pool.
     * jedis : The Jedis resource to return to the pool.
    */
    private function returnJedisResource(
        required any jedis
    ) {
        arguments.jedis.close();
    }

    /**
     * Caches a value with the given key for a specified duration.
     * cacheKey : The key to cache the value.
     * dataToCache : The value to cache.
     * cacheDurationInSeconds : The duration for which the value should be cached, in seconds.
    */
    public void function cacheInsert(
        required string cacheKey,
        required any dataToCache,
                 numeric cacheDurationInSeconds = variables.cacheDurationInSeconds
    )
    {
        try {
            // Get a Jedis resource from the pool
            var jedis = getJedisResource();
            // Use the Jedis resource
            jedis.setex(arguments.cacheKey, arguments.cacheDurationInSeconds, arguments.dataToCache);
        
        } catch (Exception e) {
            throw(message="JedisManager insert cache error: "&e.message, detail=e.detail);
        } finally {
            // Return the Jedis resource to the pool
            returnJedisResource(jedis);
        }
    }

    /**
     * Retrieves the cached value for the given cache key.
     * cacheKey : The key for which to retrieve the cached value.
     * Returns the cached value associated with the cache key, or null if the key is not found.
    */
    public any function cacheGet(
        required string cacheKey
    )
    {
        try {
            // Get a Jedis resource from the pool
            var jedis = getJedisResource();
            // Retrieve data from the cache
            return jedis.get(arguments.cacheKey);
        } catch (Exception e) {
            throw(message="JedisManager get cache error: "&e.message, detail=e.detail);
        } finally {
            // Return the Jedis resource to the pool
            returnJedisResource(jedis);
        }
    }

    /**
     * Checks if a value exists in the cache for the given cache key.
     * cacheKey : The key to check for existence in the cache.
     * Returns true if a value exists for the cache key, false otherwise.
    */
    public boolean function cacheExists(
        required string cacheKey
    )
    {
        try {
            // Get a Jedis resource from the pool
            var jedis = getJedisResource();

            // Check key exists in the cache
            return jedis.exists(arguments.cacheKey);
        } catch (Exception e) {
            throw(message="JedisManager check cache exists error: "&e.message, detail=e.detail);
        } finally {
            // Return the Jedis resource to the pool
            returnJedisResource(jedis);
        }
    }

     /**
     * Delete the given key and associated value from cache.
     * We are using DEL instead of UNLINK because UNLINK is not supported with the
     * Jedis version shipped with CF 2021. Once UNLINK is available, 
     * consider switching to it, as it removes keys asynchronously in the background,
     * allowing non-blocking operation.
     * cacheKey : The key to remove from the cache.
     * Returns 1 if the key is found and deleted; otherwise, returns 0.
    */
    public numeric function cacheClear(
        required string cacheKey
    )
    {
        var jedis = "";
        try {
            // Get a Jedis resource from the pool
            jedis = getJedisResource();

            // Delete the key from cache
            return jedis.del(arguments.cacheKey);
        } catch (Exception e) {
            throw(message="JedisManager clear cache error: "&e.message, detail=e.detail);
        } finally {
            // Return the Jedis resource to the pool
            if(isObject(jedis))
            {
                returnJedisResource(jedis);
            }
        }
    }

    private void function loadSettings() {
        try {
            // Deserialize settings json
            var jedisSsettings = deserializeJSON(fileRead(expandpath(".")&'/JedisSettings.json'));

            // Store jedis settings in variables scope
            variables.jedisServerName        = jedisSsettings.jedisServerName;
            variables.jedisServerPort        = jedisSsettings.jedisServerPort;
            variables.jedisMaxTotalpool      = jedisSsettings.jedisMaxTotalpool;
            variables.jedisMaxIdlePool       = jedisSsettings.jedisMaxIdlePool;
            variables.cacheDurationInSeconds = jedisSsettings.defaultCacheDurationInSeconds;

        } catch (any e) {
            throw(message="JedisManager load settings error: "&e.message, detail=e.detail);
        }
    }
    
    
}