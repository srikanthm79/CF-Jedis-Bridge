<cfscript>
    sourceMaps = [
        {
            "mapping" : "com.madishetti",
            "dir"     : expandPath("./com/madishetti")
        }
    ];

docbox = new docbox.DocBox()
    .addStrategy(
        "HTML",
        {
            projectTitle : "CF-Jedis-Bridge",
            outputDir    : expandPath( "./docs" )
        }
    )
    .generate(
        source = sourceMaps,
        excludes = ".*\.docbox\..*|.*\.coldbox\..*|.*\.testbox\..*"
    );
</cfscript>
