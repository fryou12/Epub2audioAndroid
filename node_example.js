const { PythonShell } = require('python-shell');
const path = require('path');

class PythonInterface {
    constructor() {
        this.pythonPath = 'python'; // Assurez-vous que Python est dans votre PATH
    }

    async updateSettings(settings) {
        const options = {
            mode: 'text',
            pythonPath: this.pythonPath,
            pythonOptions: ['-u'],
            scriptPath: __dirname
        };

        const settingsJson = JSON.stringify(settings);

        const script = `
import asyncio
from python_bridge import PythonBridge
import json

bridge = PythonBridge()
settings = json.loads('${settingsJson}')
bridge.update_settings(settings)
        `;

        return new Promise((resolve, reject) => {
            PythonShell.runString(script, options, (err, results) => {
                if (err) reject(err);
                resolve();
            });
        });
    }

    async getAvailableVoices() {
        const options = {
            mode: 'json',
            pythonPath: this.pythonPath,
            pythonOptions: ['-u'],
            scriptPath: __dirname
        };

        const script = `
import asyncio
from python_bridge import PythonBridge
import json

async def main():
    bridge = PythonBridge()
    voices = await bridge.get_available_voices()
    print(json.dumps(voices))

asyncio.run(main())
        `;

        return new Promise((resolve, reject) => {
            PythonShell.runString(script, options, (err, results) => {
                if (err) reject(err);
                resolve(JSON.parse(results[0]));
            });
        });
    }

    async textToSpeech(text, voice = 'fr-FR-HenriNeural', outputFile = 'output.mp3') {
        const options = {
            mode: 'text',
            pythonPath: this.pythonPath,
            pythonOptions: ['-u'],
            scriptPath: __dirname,
            args: [text, voice, outputFile]
        };

        const script = `
import asyncio
from python_bridge import PythonBridge

async def main():
    bridge = PythonBridge()
    await bridge.text_to_speech("${text}", "${voice}", "${outputFile}")

asyncio.run(main())
        `;

        return new Promise((resolve, reject) => {
            PythonShell.runString(script, options, (err, results) => {
                if (err) reject(err);
                resolve(results);
            });
        });
    }

    async batchTextToSpeech(chapters, voice, outputPrefix = 'chapter') {
        const options = {
            mode: 'json',
            pythonPath: this.pythonPath,
            pythonOptions: ['-u'],
            scriptPath: __dirname
        };

        const chaptersJson = JSON.stringify(chapters);

        const script = `
import asyncio
from python_bridge import PythonBridge
import json

async def main():
    bridge = PythonBridge()
    chapters = json.loads('${chaptersJson}')
    output_files = await bridge.batch_text_to_speech(chapters, "${voice}", "${outputPrefix}")
    print(json.dumps(output_files))

asyncio.run(main())
        `;

        return new Promise((resolve, reject) => {
            PythonShell.runString(script, options, (err, results) => {
                if (err) reject(err);
                resolve(JSON.parse(results[0]));
            });
        });
    }

    async extract(method, content) {
        const options = {
            mode: 'json',
            pythonPath: this.pythonPath,
            pythonOptions: ['-u'],
            scriptPath: __dirname,
            args: [method, content]
        };

        const script = `
from python_bridge import PythonBridge
import json

bridge = PythonBridge()
method = "${method}"
content = """${content}"""

result = None
if method == "dom":
    result = bridge.extract_dom_based(content)
elif method == "pattern":
    result = bridge.extract_pattern_based(content)
elif method == "semantic":
    result = bridge.extract_semantic(content)
elif method == "toc":
    result = bridge.extract_toc_based(content)

print(json.dumps(result))
        `;

        return new Promise((resolve, reject) => {
            PythonShell.runString(script, options, (err, results) => {
                if (err) reject(err);
                resolve(JSON.parse(results[0]));
            });
        });
    }
}

// Exemple d'utilisation
async function example() {
    const python = new PythonInterface();
    
    // Exemple de mise à jour des paramètres
    try {
        await python.updateSettings({
            max_parallel_chapters: 5,
            voice_settings: {
                rate: "+10%",
                volume: "+20%",
                pitch: "+5Hz"
            }
        });
        console.log("Paramètres mis à jour avec succès");
    } catch (error) {
        console.error("Erreur lors de la mise à jour des paramètres:", error);
    }

    // Exemple de génération de plusieurs chapitres
    try {
        const chapters = [
            ["Chapitre 1", "Contenu du premier chapitre"],
            ["Chapitre 2", "Contenu du deuxième chapitre"],
            ["Chapitre 3", "Contenu du troisième chapitre"]
        ];
        const outputFiles = await python.batchTextToSpeech(chapters, "fr-FR-HenriNeural", "chapitre");
        console.log("Fichiers audio générés:", outputFiles);
    } catch (error) {
        console.error("Erreur lors de la génération audio:", error);
    }

    // Récupérer la liste des voix disponibles
    try {
        const voices = await python.getAvailableVoices();
        console.log("Voix disponibles par langue:", voices);
    } catch (error) {
        console.error("Erreur lors de la récupération des voix:", error);
    }
}

example();
