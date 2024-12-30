from bs4 import BeautifulSoup
import re
from . import ChapterExtractor

class SemanticExtractor(ChapterExtractor):
    """Extracteur de chapitres basé sur l'analyse sémantique du contenu."""
    
    def __init__(self):
        self.semantic_indicators = {
            'chapter_start': [
                r'chapitre\s+\d+',
                r'chapter\s+\d+',
                r'partie\s+\d+',
                r'part\s+\d+',
                r'section\s+\d+'
            ],
            'chapter_end': [
                r'fin\s+du?\s+chapitre',
                r'end\s+of\s+chapter',
                r'fin\s+de\s+la?\s+partie',
                r'end\s+of\s+part'
            ]
        }
    
    def extract_chapters(self, epub_file, content):
        chapters = []
        found_chapters = set()
        
        # Parser le contenu HTML
        soup = BeautifulSoup(content, 'html.parser')
        text_blocks = self._get_text_blocks(soup)
        
        current_chapter = None
        chapter_content = []
        
        for block in text_blocks:
            # Vérifier si c'est un début de chapitre
            chapter_info = self._is_chapter_start(block)
            if chapter_info:
                # Si on avait déjà un chapitre en cours, on le sauvegarde
                if current_chapter and len('\n'.join(chapter_content)) >= 100:
                    chapter_data = self._create_chapter_data(
                        current_chapter['number'],
                        current_chapter['title'],
                        '\n'.join(chapter_content)
                    )
                    if chapter_data['number'] not in found_chapters:
                        chapters.append(chapter_data)
                        found_chapters.add(chapter_data['number'])
                
                current_chapter = chapter_info
                chapter_content = []
                continue
            
            # Si on est dans un chapitre, on ajoute le contenu
            if current_chapter:
                chapter_content.append(block)
        
        # Ne pas oublier le dernier chapitre
        if current_chapter and len('\n'.join(chapter_content)) >= 100:
            chapter_data = self._create_chapter_data(
                current_chapter['number'],
                current_chapter['title'],
                '\n'.join(chapter_content)
            )
            if chapter_data['number'] not in found_chapters:
                chapters.append(chapter_data)
        
        return sorted(chapters, key=lambda x: x['number'])
    
    def _get_text_blocks(self, soup):
        """Extrait les blocs de texte du document."""
        blocks = []
        for element in soup.find_all(['p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']):
            text = element.get_text().strip()
            if text:
                blocks.append(text)
        return blocks
    
    def _is_chapter_start(self, text):
        """Vérifie si le texte correspond à un début de chapitre."""
        text_lower = text.lower()
        
        for pattern in self.semantic_indicators['chapter_start']:
            match = re.search(pattern, text_lower)
            if match:
                # Chercher le numéro de chapitre
                number_match = re.search(r'\d+', text)
                if number_match:
                    chapter_number = int(number_match.group())
                    if 1 <= chapter_number <= 100:  # Limite raisonnable
                        # Extraire le titre
                        title = text[number_match.end():].strip(' -:')
                        if not title:
                            title = text
                        
                        return {
                            'number': chapter_number,
                            'title': title
                        }
        
        return None
    
    def _create_chapter_data(self, number, title, content):
        """Crée un dictionnaire de données pour un chapitre."""
        return {
            'number': number,
            'title': f'Chapitre {number} - {title}',
            'content': content
        }
