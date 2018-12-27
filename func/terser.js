const Terser = require('terser');
const fs = require('fs')
const options = { ecma: undefined,
  warnings: undefined,
  parse: {},
  compress: {},
  mangle: true,
  output:
   { shebang: true,
     comments: /^\**!|@preserve|@license|@cc_on/i,
     beautify: false,
     semicolons: true },
  module: undefined,
  sourceMap: null,
  toplevel: undefined,
  nameCache: undefined,
  ie8: undefined,
  keep_classnames: undefined,
  keep_fnames: undefined,
  safari10: undefined }
const file = fs.readFileSync('input.js', "utf8")
const result = Terser.minify(file, options)
console.log(result.code)
