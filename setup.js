/**
 * Cross-platform node.js postinstall & test script for coffeescript projects.
 *
 * Adapted from setup.js provided by Brunch.
 */

var exec = require("child_process").exec,
    sysPath = require("path"),
    fs = require("fs"),
    mode = process.argv[2],
    fsExists = fs.exists || sysPath.exists,
    fsExistsSync = fs.existsSync || sysPath.existsSync,
    FILE_ENCODING = "utf-8",
    EOL = "\n";

var getBinaryPath = function (binary) {
    var path;

    if (fsExistsSync(path = sysPath.join("node_modules", ".bin", binary))) {
        return path;
    }

    if (fsExistsSync(path = sysPath.join("..", ".bin", binary))) {
        return path;
    }

    return binary;
};

var execute = function (script, params, callback) {
    var path = getBinaryPath(script),
        command = path + " " + params;

    console.log("Executing", command);

    exec(command, function (error, stdout, stderr) {
        if (error !== null) {
            return process.stderr.write(stderr.toString());
        }
        console.log(stdout.toString());

        if (callback && typeof callback === "function") {
            callback();
        }
    });

};

var concat = function (opts) {
    var fileList = opts.src,
        distPath = opts.dest,
        out = fileList.map(function (filePath) {
            return fs.readFileSync(filePath, FILE_ENCODING);
        });

    fs.writeFileSync(distPath, out.join(EOL), FILE_ENCODING);
    console.log(" " + distPath + " built.");
};

var compileCoffee = function () {
    execute("coffee", "-bc -o build/ src/", function () {
        fs.exists("./bin", function (exists) {
            if (!exists) {
                fs.mkdirSync("./bin");
            }
            concat({
                src: ["src/hashbang.txt", "build/sow.js"],
                dest: "bin/sow"
            });
        });
    });
};

var togglePostinstall = function (add) {
    var pkg = require("./package.json");

    if (add) {
        if (!pkg.scripts) {
            pkg.scripts = {};
        }
        pkg.scripts.postinstall = "node setup.js postinstall";
    } else if (pkg.scripts && pkg.scripts.postinstall) {
        delete pkg.scripts.postinstall;
    }

    fs.writeFileSync("package.json", JSON.stringify(pkg, null, 4) + "\n");
};

switch (mode) {
// Remove `.postinstall` script to prevent stupid npm bugs.
case "prepublish":
    togglePostinstall(false);
    compileCoffee();
    break;

// Bring back `.postinstall` script.
case "postpublish":
    togglePostinstall(true);
    break;

// Compile coffeescript for git users.
case "postinstall":
    fsExists(sysPath.join(__dirname, "build"), function (exists) {
        if (exists) {
            return;
        }
        compileCoffee();
    });
    break;

// Run tests.
case "test":
    execute(
        "mocha",
        "--compilers coffee:coffee-script --require test/common.coffee --colors"
    );
    break;
}
