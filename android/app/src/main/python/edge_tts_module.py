import edge_tts
import asyncio
import json
import sys
import traceback
import platform
from datetime import datetime
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
import threading
from typing import List, Dict
import re
import uuid

# Utiliser le répertoire des données de l'application
APP_DATA_DIR = "/data/data/com.example.epub_to_audio/files"
LOG_FILE = os.path.join(APP_DATA_DIR, "edge_tts_log.txt")

# Constantes
MAX_TEXT_LENGTH = 3000  # Caractères maximum par segment
MAX_THREADS = 5  # Nombre maximum de threads simultanés
THREAD_TIMEOUT = 300  # Timeout en secondes par thread

def ensure_log_file():
    try:
        os.makedirs(APP_DATA_DIR, exist_ok=True)
        if not os.path.exists(LOG_FILE):
            with open(LOG_FILE, 'w') as f:
                f.write("=== Edge TTS Log File ===\n")
    except Exception as e:
        print(f"Erreur création fichier log: {str(e)}")

def log_to_file(message):
    try:
        with open(LOG_FILE, 'a') as f:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"{timestamp} - {message}\n")
    except Exception as e:
        print(f"Erreur écriture log: {str(e)}")

def log_debug(message):
    print(f"[EdgeTTS] DEBUG: {message}")
    log_to_file(f"DEBUG: {message}")

def log_error(message):
    print(f"[EdgeTTS] ERROR: {message}", file=sys.stderr)
    log_to_file(f"ERROR: {message}")

def check_internet():
    try:
        # Try multiple reliable endpoints
        urls = [
            'https://1.1.1.1',  # Cloudflare DNS
            'https://8.8.8.8',  # Google DNS
            'https://edge.microsoft.com'  # Edge TTS service
        ]
        
        for url in urls:
            try:
                urllib.request.urlopen(url, timeout=3)
                log_debug(f"Connexion Internet établie via {url}")
                return True
            except Exception:
                continue
                
        log_error("Impossible d'établir une connexion Internet avec les serveurs de test")
        return False
    except Exception as e:
        log_error(f"Erreur lors de la vérification de la connexion: {str(e)}")
        return False

async def list_voices():
    try:
        ensure_log_file()
        log_debug("=== Démarrage de list_voices ===")
        
        # Vérifier la connexion Internet
        if not check_internet():
            error_msg = 'Pas de connexion Internet'
            log_error(error_msg)
            return json.dumps({'error': error_msg})

        try:
            # Utiliser l'ancienne API
            voices = await edge_tts.list_voices()
            formatted_voices = []
            
            for voice in voices:
                voice_data = {
                    'Name': voice['Name'],
                    'ShortName': voice['ShortName'],
                    'Gender': voice['Gender'],
                    'Locale': voice['Locale']
                }
                formatted_voices.append(voice_data)
            
            log_debug(f"Nombre de voix trouvées : {len(formatted_voices)}")
            return json.dumps({'voices': formatted_voices})
            
        except Exception as e:
            error_msg = f"Erreur lors de la récupération des voix: {str(e)}"
            log_error(error_msg)
            return json.dumps({'error': error_msg})
            
    except Exception as e:
        error_msg = f"Erreur générale: {str(e)}"
        log_error(error_msg)
        return json.dumps({'error': error_msg})

def get_voices():
    """Wrapper synchrone pour list_voices"""
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    
    try:
        return loop.run_until_complete(list_voices())
    except Exception as e:
        error_msg = f"Erreur dans get_voices: {str(e)}"
        log_error(error_msg)
        return json.dumps({'error': error_msg})

def analyze_text(text: str) -> List[str]:
    """Divise le texte en segments sans faire la synthèse"""
    if len(text) <= MAX_TEXT_LENGTH:
        return [text]
    
    segments = []
    current_segment = ""
    
    sentences = re.split('([.!?]+)', text)
    
    for i in range(0, len(sentences)-1, 2):
        sentence = sentences[i] + (sentences[i+1] if i+1 < len(sentences) else '')
        if len(current_segment) + len(sentence) <= MAX_TEXT_LENGTH:
            current_segment += sentence
        else:
            if current_segment:
                segments.append(current_segment)
            current_segment = sentence
    
    if current_segment:
        segments.append(current_segment)
    
    return segments

def analyze_chapters(chapters: List[str]) -> Dict:
    """Analyse tous les chapitres et retourne le nombre total de segments"""
    total_segments = 0
    segments_per_chapter = {}
    
    for i, chapter in enumerate(chapters):
        segments = analyze_text(chapter)
        segments_per_chapter[i] = len(segments)
        total_segments += len(segments)
    
    return {
        'total_segments': total_segments,
        'segments_per_chapter': segments_per_chapter
    }

def split_text(text: str) -> List[str]:
    """Divise le texte en segments plus petits en respectant les phrases"""
    if len(text) <= MAX_TEXT_LENGTH:
        return [text]
    
    segments = []
    current_segment = ""
    
    # Divise aux points, points d'exclamation et points d'interrogation
    sentences = re.split('([.!?]+)', text)
    
    for i in range(0, len(sentences)-1, 2):
        sentence = sentences[i] + (sentences[i+1] if i+1 < len(sentences) else '')
        if len(current_segment) + len(sentence) <= MAX_TEXT_LENGTH:
            current_segment += sentence
        else:
            if current_segment:
                segments.append(current_segment)
            current_segment = sentence
    
    if current_segment:
        segments.append(current_segment)
    
    return segments

def process_text_segment(text: str, voice_id: str, output_file: str) -> Dict:
    """Traite un segment de texte dans un thread séparé"""
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        async def _synthesize():
            communicate = edge_tts.Communicate(text, voice_id)
            await communicate.save(output_file)
            return {'success': True, 'output_file': output_file}
            
        result = loop.run_until_complete(_synthesize())
        loop.close()
        return result
    except Exception as e:
        return {'error': str(e), 'output_file': output_file}

def get_unique_filename(base_file: str, chapter_idx: int, segment_idx: int) -> str:
    """Génère un nom de fichier unique pour chaque segment"""
    unique_id = str(uuid.uuid4())[:8]
    base_name, ext = os.path.splitext(base_file)
    return f"{base_name}_ch{chapter_idx}_seg{segment_idx}_{unique_id}{ext}"

def synthesize(text: str, voice_id: str, output_file: str) -> str:
    try:
        ensure_log_file()
        log_debug("=== Démarrage de synthesize ===")
        
        try:
            chapters = json.loads(text)
            if isinstance(chapters, list):
                # Analyse préalable de tous les chapitres
                analysis = analyze_chapters(chapters)
                total_segments = analysis['total_segments']
                log_debug(f"Nombre total de segments à traiter: {total_segments}")
                
                # Traitement par lots de 5 chapitres
                all_results = []
                batch_size = 5
                completed_segments = 0
                
                for batch_start in range(0, len(chapters), batch_size):
                    batch_end = min(batch_start + batch_size, len(chapters))
                    batch_chapters = chapters[batch_start:batch_end]
                    log_debug(f"Traitement du lot de chapitres {batch_start} à {batch_end-1}")
                    
                    with ThreadPoolExecutor(max_workers=MAX_THREADS) as executor:
                        future_to_chapter = {}
                        
                        # Création des tâches pour chaque segment de chaque chapitre du lot
                        for chapter_idx, chapter_text in enumerate(batch_chapters, start=batch_start):
                            log_debug(f"Préparation du chapitre {chapter_idx}")
                            segments = analyze_text(chapter_text)
                            log_debug(f"Chapitre {chapter_idx}: {len(segments)} segments")
                            
                            for segment_idx, segment in enumerate(segments):
                                segment_output = get_unique_filename(output_file, chapter_idx, segment_idx)
                                log_debug(f"Création tâche pour chapitre {chapter_idx}, segment {segment_idx}: {segment_output}")
                                
                                future = executor.submit(
                                    process_text_segment,
                                    segment,
                                    voice_id,
                                    segment_output
                                )
                                future_to_chapter[future] = {
                                    'chapter': chapter_idx,
                                    'segment': segment_idx,
                                    'output_file': segment_output,
                                    'total_segments': total_segments
                                }
                        
                        # Collecte des résultats
                        for future in as_completed(future_to_chapter):
                            info = future_to_chapter[future]
                            try:
                                result = future.result(timeout=THREAD_TIMEOUT)
                                completed_segments += 1
                                log_debug(f"Segment complété: Chapitre {info['chapter']}, Segment {info['segment']}, Fichier: {info['output_file']}")
                                all_results.append({
                                    'chapter': info['chapter'],
                                    'segment': info['segment'],
                                    'output_file': info['output_file'],
                                    'progress': completed_segments,
                                    'total': total_segments,
                                    **result
                                })
                            except Exception as e:
                                log_error(f"Erreur sur segment: Chapitre {info['chapter']}, Segment {info['segment']}, Fichier: {info['output_file']}")
                                all_results.append({
                                    'chapter': info['chapter'],
                                    'segment': info['segment'],
                                    'output_file': info['output_file'],
                                    'progress': completed_segments,
                                    'total': total_segments,
                                    'error': str(e)
                                })
                
                log_debug(f"Traitement terminé: {completed_segments}/{total_segments} segments")
                return json.dumps({
                    'success': True,
                    'results': all_results,
                    'total_segments': total_segments
                })
                
        except json.JSONDecodeError:
            # Traitement d'un seul texte
            segments = analyze_text(text)
            total_segments = len(segments)
            all_results = []
            completed_segments = 0
            
            with ThreadPoolExecutor(max_workers=MAX_THREADS) as executor:
                future_to_segment = {
                    executor.submit(
                        process_text_segment,
                        segment,
                        voice_id,
                        get_unique_filename(output_file, 0, i)
                    ): {'segment': i, 'total_segments': total_segments}
                    for i, segment in enumerate(segments)
                }
                
                for future in as_completed(future_to_segment):
                    info = future_to_segment[future]
                    try:
                        result = future.result(timeout=THREAD_TIMEOUT)
                        completed_segments += 1
                        all_results.append({
                            'segment': info['segment'],
                            'progress': completed_segments,
                            'total': total_segments,
                            **result
                        })
                    except Exception as e:
                        all_results.append({
                            'segment': info['segment'],
                            'progress': completed_segments,
                            'total': total_segments,
                            'error': str(e)
                        })
            
            return json.dumps({
                'success': True,
                'results': all_results,
                'total_segments': total_segments
            })
            
    except Exception as e:
        error_msg = f"Erreur dans synthesize : {str(e)}"
        log_error(error_msg)
        log_error(f"Traceback complet:\n{traceback.format_exc()}")
        return json.dumps({'error': error_msg})

# Gestionnaire d'événements asyncio pour Android
def _get_event_loop():
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    return loop
