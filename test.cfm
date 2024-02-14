
<cftry>
    <cfoutput>
        <cfset variables.redisObj = new JedisManager()>
        <cfset variables.redisObj.init()>
        <!--- Verify whether data exists in the cache for the specified key and set it with a duration of 30 seconds --->
        <cfif not variables.redisObj.cacheExists(cacheKey="cacheTest:key")>
            <p> Cache does not exist, thus data is being set in the cache for the "cacheTest:key" key</p>
            <cfset variables.redisObj.cacheinsert(cacheKey="cacheTest:key",dataToCache="This is test string",cacheDurationInSeconds=30)>
        </cfif>
        <p>The cached data is : #redisObj.cacheget(cacheKey='cacheTest:key')#</p>
    </cfoutput>
    <cfcatch type="any">
        <cfoutput>
            <p>We have error in setting or getting the data from the cache : #cfcatch.message#</p>
        </cfoutput>
    </cfcatch>
</cftry>