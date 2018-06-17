const Resemble = require(process.argv[5]);
const File = require("fs");

const file1 = File.readFileSync(process.argv[2]);
const file2 = File.readFileSync(process.argv[3]);

Resemble.compare(file1, file2, {}, (err, data) => {
  if (err) {
    console.log(JSON.stringify({"error": err}));
  } else {
    File.writeFileSync(process.argv[4], data.getBuffer());
    console.log(JSON.stringify({"diff": data}));
  }
});
