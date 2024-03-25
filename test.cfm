
<cftry>
    <cfoutput>
        <cfset variables.redisObj = new com.madishetti.JedisManager()>
        <cfset variables.redisObj.init()>
        <!--- Verify whether data exists in the cache for the specified key and set it with a duration of 30 seconds --->
        <cfif not variables.redisObj.cacheExists(cacheKey="cacheTest:key")>
            <p>Cache does not exist, thus data is being set in the cache for the "cacheTest:key" key</p>
            <cfset variables.redisObj.cacheInsert(cacheKey="cacheTest:key",dataToCache="This is test string",cacheDurationInSeconds=30)>
        </cfif>
        <p>The cached data is: #redisObj.cacheget(cacheKey="cacheTest:key")#</p>
        <cfset variables.redisObj.cacheClear(cacheKey="cacheTest:key")>
        <p>Deleted the key "cacheTest:key" from cache</p>
    </cfoutput>
    <cfcatch type="any">
        <cfoutput>
            <p>We have an error in settings or getting the data from the cache: #cfcatch.message#</p>
        </cfoutput>
    </cfcatch>
</cftry>