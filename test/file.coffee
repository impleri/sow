file = require "../src/file"

describe "file ::", ->
    describe "saveFile()", ->
        testData = {
            name: "test",
            number: 2
        }
        it "should save a file to the storage directory", ->
            expect(file.save "test", testData).to.be.true

        it "should not save a file to a non-existent directory", ->
            expect(file.save "test/bad", testData).to.be.false

    describe "readFile()", ->
        it "should read a file", ->
            expect(file.read "test").to.not.be.empty

        it "should not read a file from a non-existent directory", ->
            expect(file.read "test/bad").to.be.empty
