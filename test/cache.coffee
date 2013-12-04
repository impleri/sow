cache = require "../src/cache"

describe "cache ::", ->
    describe "generate", ->
        cached = cache "client"
        it "should generate a cache file if there is none", ->
            expect(cached.clients).to.not.be.empty

        it "should not generate a cache if one is recent", ->
            expect(cache("client").generated).to.equal cached.generated

