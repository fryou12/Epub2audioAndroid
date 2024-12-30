const { PythonShell } = require('python-shell');
const path = require('path');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

class EpubExtractor {
  constructor(pythonPath = 'python3') {
    this.pythonPath = pythonPath;
  }

  async extractChapters(epubPath, outputDir, extractorType = 'semantic') {
    return new Promise((resolve, reject) => {
      const scriptPath = path.join(__dirname, 'extractors', `${extractorType}.py`);
      console.log(`Running extractor: ${scriptPath}`);
      console.log(`Input file: ${epubPath}`);
      console.log(`Output directory: ${outputDir}`);

      const options = {
        pythonPath: this.pythonPath,
        args: [epubPath, outputDir]
      };

      PythonShell.run(scriptPath, options, (err, results) => {
        if (err) {
          console.error('Error running Python script:', err);
          reject(err);
        } else {
          console.log('Python script output:', results);
          resolve(results);
        }
      });
    });
  }
}

// If running as a script
if (require.main === module) {
  const argv = yargs(hideBin(process.argv))
    .option('input', {
      alias: 'i',
      description: 'Input ePub file path',
      type: 'string',
      demandOption: true
    })
    .option('output', {
      alias: 'o',
      description: 'Output directory path',
      type: 'string',
      demandOption: true
    })
    .option('extractor', {
      alias: 'e',
      description: 'Extractor type to use',
      type: 'string',
      choices: ['semantic', 'dom_based', 'pattern_based', 'toc_based'],
      default: 'semantic'
    })
    .option('python', {
      alias: 'p',
      description: 'Python executable path',
      type: 'string',
      default: 'python3'
    })
    .help()
    .argv;

  const extractor = new EpubExtractor(argv.python);
  extractor.extractChapters(argv.input, argv.output, argv.extractor)
    .then(() => {
      console.log('Extraction completed successfully');
      process.exit(0);
    })
    .catch(err => {
      console.error('Extraction failed:', err);
      process.exit(1);
    });
} else {
  module.exports = EpubExtractor;
}
