import edge_tts
import asyncio
from extractors.dom_based import DOMBasedExtractor
from extractors.pattern_based import PatternBasedExtractor
from extractors.semantic import SemanticExtractor
from extractors.toc_based import TOCBasedExtractor
import json

class PythonBridge:
    def __init__(self):
        self.voices = None
        self.default_settings = {
            "max_parallel_chapters": 3,
            "voice_settings": {
                "rate": "+0%",    # Entre -100% et +100%
                "volume": "+0%",  # Entre -100% et +100%
                "pitch": "+0Hz"   # Entre -100Hz et +100Hz
            }
        }
        self.settings = self.default_settings.copy()

    def update_settings(self, new_settings):
        """Met à jour les paramètres avec validation"""
        if "max_parallel_chapters" in new_settings:
            value = int(new_settings["max_parallel_chapters"])
            self.settings["max_parallel_chapters"] = max(1, min(10, value))
        
        if "voice_settings" in new_settings:
            vs = new_settings["voice_settings"]
            if "rate" in vs:
                self.settings["voice_settings"]["rate"] = self._validate_percentage(vs["rate"])
            if "volume" in vs:
                self.settings["voice_settings"]["volume"] = self._validate_percentage(vs["volume"])
            if "pitch" in vs:
                self.settings["voice_settings"]["pitch"] = self._validate_pitch(vs["pitch"])

    def _validate_percentage(self, value):
        """Valide et formate une valeur en pourcentage"""
        try:
            value = float(str(value).rstrip('%'))
            value = max(-100, min(100, value))
            return f"{value:+}%"
        except ValueError:
            return "+0%"

    def _validate_pitch(self, value):
        """Valide et formate une valeur de pitch"""
        try:
            value = float(str(value).rstrip('Hz'))
            value = max(-100, min(100, value))
            return f"{value:+}Hz"
        except ValueError:
            return "+0Hz"

    @staticmethod
    async def text_to_speech(text, voice="fr-FR-HenriNeural", output_file="output.mp3", voice_settings=None):
        if voice_settings is None:
            voice_settings = {}
        
        # Construire la chaîne de paramètres de voix
        voice_params = []
        if "rate" in voice_settings:
            voice_params.append(f"rate={voice_settings['rate']}")
        if "volume" in voice_settings:
            voice_params.append(f"volume={voice_settings['volume']}")
        if "pitch" in voice_settings:
            voice_params.append(f"pitch={voice_settings['pitch']}")

        communicate = edge_tts.Communicate(
            text,
            voice,
            " ".join(voice_params)
        )
        await communicate.save(output_file)
        return output_file

    async def batch_text_to_speech(self, chapters, voice, output_prefix="chapter"):
        """
        Génère des fichiers audio pour plusieurs chapitres en parallèle
        """
        all_tasks = []
        output_files = []
        
        # Traiter les chapitres par lots selon max_parallel_chapters
        for i, (title, content) in enumerate(chapters):
            output_file = f"{output_prefix}_{i+1}.mp3"
            task = self.text_to_speech(
                content,
                voice,
                output_file,
                self.settings["voice_settings"]
            )
            all_tasks.append(task)
            output_files.append(output_file)

            # Si nous atteignons la limite de parallélisation, attendons que ce lot soit terminé
            if len(all_tasks) >= self.settings["max_parallel_chapters"]:
                await asyncio.gather(*all_tasks)
                all_tasks = []

        # Traiter les tâches restantes
        if all_tasks:
            await asyncio.gather(*all_tasks)

        return output_files

    async def get_available_voices(self):
        voices = await edge_tts.list_voices()
        voices_by_language = {}
        for voice in voices:
            lang = voice["Locale"]
            if lang not in voices_by_language:
                voices_by_language[lang] = []
            
            voice_info = {
                "name": voice["ShortName"],
                "gender": voice["Gender"],
                "locale": voice["Locale"],
                "display_name": voice["FriendlyName"]
            }
            voices_by_language[lang].append(voice_info)
        
        return voices_by_language

    @staticmethod
    def extract_dom_based(content, **kwargs):
        extractor = DOMBasedExtractor()
        return extractor.extract(content, **kwargs)

    @staticmethod
    def extract_pattern_based(content, **kwargs):
        extractor = PatternBasedExtractor()
        return extractor.extract(content, **kwargs)

    @staticmethod
    def extract_semantic(content, **kwargs):
        extractor = SemanticExtractor()
        return extractor.extract(content, **kwargs)

    @staticmethod
    def extract_toc_based(content, **kwargs):
        extractor = TOCBasedExtractor()
        return extractor.extract(content, **kwargs)

# Cette fonction sera appelée par FFI pour initialiser la classe
def create_bridge():
    return PythonBridge()
